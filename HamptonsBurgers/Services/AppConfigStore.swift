import Foundation
import Observation

@Observable
final class AppConfigStore {
    private(set) var content: AppContent
    private(set) var lastSyncError: String?
    private(set) var isUsingRemoteConfig = false

    var configVersion: Int { content.configVersion }
    var location: LocationContent { content.location }
    var faq: FAQContent { content.faq }
    var redemption: RedemptionContent { content.redemption }
    var adminEmails: [String] { content.adminEmails }

    func isAdmin(email: String?) -> Bool {
        guard let email, FirestoreRewardsUserWriter.isValidEmail(email) else { return false }
        let normalized = FirestoreRewardsUserWriter.normalizeEmail(email)
        return content.adminEmails
            .map(FirestoreRewardsUserWriter.normalizeEmail)
            .contains(normalized)
    }

    private let cacheKey = "hamptons.appContent"
    private var firestoreListener: Any?
    private var usingFirestore = false

    init() {
        content = Self.loadCached() ?? .bundled()
        OperatingHours.locationHours = content.location.hours
    }

    func start() {
        if FirebaseBootstrap.isConfigured {
            FirebaseBootstrap.configureIfNeeded()
            usingFirestore = true
            startFirestoreListener()
        }
    }

    @MainActor
    func publishContent(_ draft: AppContent) async throws {
        var next = draft
        next.configVersion = max(content.configVersion, draft.configVersion) + 1
        try await FirestoreAppConfigWriter.save(next)
        apply(next, fromRemote: true)
    }

    @MainActor
    func publishBundledToFirestore(bumpVersion: Bool = true) async throws {
        var next = AppContent.bundled()
        if bumpVersion {
            next.configVersion = max(content.configVersion, next.configVersion) + 1
        } else {
            next.configVersion = max(content.configVersion, 1)
        }
        try await FirestoreAppConfigWriter.save(next)
        apply(next, fromRemote: true)
    }

    private func startFirestoreListener() {
        firestoreListener = FirestoreAppConfigWriter.addListener { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success(let remote):
                    guard remote.configVersion != self.content.configVersion else { return }
                    self.apply(remote, fromRemote: true)
                    self.lastSyncError = nil
                case .failure(let error):
                    if (error as? FirestoreAppConfigError) == .documentMissing {
                        self.lastSyncError = nil
                    } else {
                        self.lastSyncError = error.localizedDescription
                    }
                }
            }
        }
    }

    private func apply(_ next: AppContent, fromRemote: Bool) {
        content = next
        isUsingRemoteConfig = fromRemote || isUsingRemoteConfig
        OperatingHours.locationHours = next.location.hours
        cache(next)
    }

    private func cache(_ content: AppContent) {
        guard let data = try? JSONEncoder().encode(content) else { return }
        UserDefaults.standard.set(data, forKey: cacheKey)
    }

    private static func loadCached() -> AppContent? {
        guard let data = UserDefaults.standard.data(forKey: "hamptons.appContent"),
              let decoded = try? JSONDecoder().decode(AppContent.self, from: data) else {
            return nil
        }
        return decoded
    }
}
