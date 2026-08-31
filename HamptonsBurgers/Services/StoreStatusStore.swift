import Foundation
import Observation

@Observable
final class StoreStatusStore {
    private(set) var status: StoreStatus = .default
    private(set) var isSyncing = false
    private(set) var lastSyncError: String?
    var isAdminAuthenticated = false
    var dismissedStatusBannerToken: String?
    var dismissedCustomerNoticeToken: String?

    private let defaultsKey = "hamptons.storeStatus"
    private var firestoreListener: Any?
    private var usingFirestore = false

    func start() {
        if let cached = loadCachedStatus() {
            status = cached
        }

        if FirebaseBootstrap.isConfigured {
            FirebaseBootstrap.configureIfNeeded()
            usingFirestore = true
            startFirestoreListener()
        }
    }

    func verifyAdminPIN(_ pin: String) -> Bool {
        pin == BrandConfig.adminPIN
    }

    func authenticateAdmin(pin: String) -> Bool {
        let ok = verifyAdminPIN(pin)
        isAdminAuthenticated = ok
        return ok
    }

    func signOutAdmin() {
        isAdminAuthenticated = false
    }

    func dismissStatusBanner() {
        dismissedStatusBannerToken = status.statusBannerToken
    }

    func dismissCustomerNoticeBanner() {
        dismissedCustomerNoticeToken = status.customerNoticeToken
    }

    var shouldShowStatusBanner: Bool {
        status.showsStatusBanner && dismissedStatusBannerToken != status.statusBannerToken
    }

    var shouldShowCustomerNoticeBanner: Bool {
        status.showsCustomerNoticeBanner && dismissedCustomerNoticeToken != status.customerNoticeToken
    }

    @MainActor
    func save(_ updated: StoreStatus) async {
        var next = updated
        next.updatedAt = Date()
        isSyncing = true
        lastSyncError = nil
        defer { isSyncing = false }

        status = next
        cacheStatus(next)
        dismissedStatusBannerToken = nil
        dismissedCustomerNoticeToken = nil

        if usingFirestore {
            do {
                try await FirestoreStoreStatusWriter.save(next)
            } catch {
                lastSyncError = error.localizedDescription
            }
        }
    }

    @MainActor
    func adjustPattyCount(by delta: Int) async {
        var next = status
        next.pattyCount = max(0, min(next.pattyCapacity, next.pattyCount + delta))
        if next.pattyCount == 0 {
            next.isSoldOut = true
        }
        await save(next)
    }

    private func loadCachedStatus() -> StoreStatus? {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode(StoreStatus.self, from: data) else {
            return nil
        }
        return decoded
    }

    private func cacheStatus(_ status: StoreStatus) {
        guard let data = try? JSONEncoder().encode(status) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    private func startFirestoreListener() {
        firestoreListener = FirestoreStoreStatusWriter.addListener { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success(let remote):
                    self.status = remote
                    self.cacheStatus(remote)
                    if self.dismissedStatusBannerToken != remote.statusBannerToken {
                        self.dismissedStatusBannerToken = nil
                    }
                    if self.dismissedCustomerNoticeToken != remote.customerNoticeToken {
                        self.dismissedCustomerNoticeToken = nil
                    }
                case .failure(let error):
                    self.lastSyncError = error.localizedDescription
                }
            }
        }
    }
}
