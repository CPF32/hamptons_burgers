import Foundation
import Observation

@Observable
final class RewardsStore {
    private(set) var account: RewardsAccount
    private(set) var pointsHistory: [PointsHistoryEntry] = []
    private(set) var redemptionCart: [String: Int] = [:]
    private(set) var lastSyncError: String?

    private let defaultsKey = "hamptons.rewardsAccount"
    private let cartKey = "hamptons.redemptionCart"

    private var redemptionItemsById: [String: RedemptionItem]
    private var userListener: Any?
    private var historyListener: Any?

    init() {
        redemptionItemsById = [:]
        account = Self.loadAccount() ?? .makeNew()
        redemptionCart = Self.loadCart()
        syncRedemptionCatalog(AppContent.bundled().redemption.items)
    }

    var hasRegisteredEmail: Bool {
        guard let email = account.email else { return false }
        return FirestoreRewardsUserWriter.isValidEmail(email)
    }

    var hasCompleteProfile: Bool {
        account.hasCompleteProfile
    }

    func redemptionQRPayload(nonce: String) -> String? {
        guard let email = account.email, hasRegisteredEmail, cartTotalPoints > 0 else { return nil }
        return RewardsQRCode.redeemPayload(
            email: email,
            points: cartTotalPoints,
            nonce: nonce
        )
    }

    func start() {
        guard hasRegisteredEmail, let email = account.email else { return }
        guard FirebaseBootstrap.isConfigured else { return }
        FirebaseBootstrap.configureIfNeeded()
        startUserListener(email: email)
        startHistoryListener(email: email)
    }

    @MainActor
    func recordSyncError(_ message: String) {
        lastSyncError = message
    }

    @MainActor
    func restoreSession(userID: String, email: String) async throws {
        guard FirebaseBootstrap.isConfigured else { return }
        FirebaseBootstrap.configureIfNeeded()

        let normalized = FirestoreRewardsUserWriter.normalizeEmail(email)
        stopListeners()

        if let remote = try await FirestoreRewardsUserWriter.fetch(email: normalized) {
            guard remote.memberId == userID else {
                throw RewardsUserError.emailAlreadyRegistered
            }
            account = RewardsAccount(
                memberId: userID,
                email: normalized,
                firstName: remote.firstName,
                lastName: remote.lastName,
                phone: remote.phone,
                birthday: remote.birthday,
                marketingOptIn: remote.marketingOptIn,
                points: remote.points,
                lifetimeSpend: remote.lifetimeSpend
            )
        } else {
            account = RewardsAccount(
                memberId: userID,
                email: normalized,
                firstName: "",
                lastName: "",
                phone: "",
                birthday: nil,
                marketingOptIn: false,
                points: 0,
                lifetimeSpend: 0
            )
            try await FirestoreRewardsUserWriter.saveUser(account)
        }

        persist()
        startUserListener(email: normalized)
        startHistoryListener(email: normalized)
        lastSyncError = nil
    }

    @MainActor
    func signOut() {
        stopListeners()
        account = .makeNew()
        pointsHistory = []
        redemptionCart = [:]
        lastSyncError = nil
        UserDefaults.standard.removeObject(forKey: defaultsKey)
        persistCart()
    }

    private func stopListeners() {
        userListener = nil
        historyListener = nil
    }

    func syncRedemptionCatalog(_ items: [RedemptionItem]) {
        redemptionItemsById = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
    }

    var cartItemCount: Int {
        redemptionCart.values.reduce(0, +)
    }

    var cartTotalPoints: Int {
        redemptionCart.reduce(0) { total, entry in
            guard let item = redemptionItemsById[entry.key] else { return total }
            return total + (item.pointsCost * entry.value)
        }
    }

    var cartTotalPrice: Double {
        redemptionCart.reduce(0) { total, entry in
            guard let item = redemptionItemsById[entry.key] else { return total }
            return total + (item.price * Double(entry.value))
        }
    }

    var cartLineItems: [RewardOrderLineItem] {
        redemptionCart.compactMap { itemId, quantity in
            guard quantity > 0, let item = redemptionItemsById[itemId] else { return nil }
            return RewardOrderLineItem(item: item, quantity: quantity)
        }
        .sorted { $0.name < $1.name }
    }

    var hasItemsInCart: Bool {
        cartItemCount > 0
    }

    var cartHasEnoughPoints: Bool {
        cartTotalPoints <= account.points
    }

    func quantityInCart(for itemId: String) -> Int {
        redemptionCart[itemId] ?? 0
    }

    func addToCart(_ item: RedemptionItem) {
        let current = redemptionCart[item.id] ?? 0
        redemptionCart[item.id] = current + 1
        persistCart()
    }

    func removeFromCart(_ item: RedemptionItem) {
        let current = redemptionCart[item.id] ?? 0
        guard current > 0 else { return }
        if current == 1 {
            redemptionCart.removeValue(forKey: item.id)
        } else {
            redemptionCart[item.id] = current - 1
        }
        persistCart()
    }

    func clearCart() {
        redemptionCart = [:]
        persistCart()
    }

    @MainActor
    func saveProfile(
        firstName: String,
        lastName: String,
        phone: String,
        birthday: Date?,
        marketingOptIn: Bool,
        authenticatedEmail: String
    ) async throws {
        let trimmedFirst = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLast = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = PhoneNumberFormatter.format(phone)

        guard FirestoreRewardsUserWriter.isValidEmail(authenticatedEmail) else {
            throw RewardsUserError.invalidEmail
        }
        guard !trimmedFirst.isEmpty, !trimmedLast.isEmpty, !trimmedPhone.isEmpty else {
            throw RewardsUserError.invalidProfile
        }

        let email = FirestoreRewardsUserWriter.normalizeEmail(authenticatedEmail)

        account.firstName = trimmedFirst
        account.lastName = trimmedLast
        account.email = email
        account.phone = trimmedPhone
        account.birthday = birthday
        account.marketingOptIn = marketingOptIn
        persist()

        if FirebaseBootstrap.isConfigured {
            FirebaseBootstrap.configureIfNeeded()
            do {
                try await FirestoreRewardsUserWriter.saveUser(account)
            } catch let error as NSError where error.domain == "RewardsUser" && error.code == 409 {
                throw RewardsUserError.emailAlreadyRegistered
            }
            if userListener == nil {
                startUserListener(email: email)
            }
            if historyListener == nil {
                startHistoryListener(email: email)
            }
            lastSyncError = nil
        }
    }

    @MainActor
    func completeRedemptionAfterScan(nonce: String) async {
        let lineItems = cartLineItems
        guard !lineItems.isEmpty else { return }

        let order = RewardMealOrder(
            memberId: account.memberId,
            email: account.email,
            lineItems: lineItems
        )
        clearCart()
        persist()

        if FirebaseBootstrap.isConfigured {
            FirebaseBootstrap.configureIfNeeded()
            do {
                try await FirestoreRewardOrderWriter.save(order)
                lastSyncError = nil
            } catch {
                lastSyncError = error.localizedDescription
            }
        }
    }

    @MainActor
    @discardableResult
    func adminCreditPoints(email: String, dollars: Double) async throws -> Int {
        guard dollars > 0 else { throw RewardsUserError.invalidEmail }
        guard FirebaseBootstrap.isConfigured else { throw RewardsUserError.firebaseUnavailable }
        FirebaseBootstrap.configureIfNeeded()
        let earned = try await FirestoreRewardsUserWriter.adminCreditPoints(email: email, dollars: dollars)
        lastSyncError = nil
        return earned
    }

    @MainActor
    func adminRedeemPoints(email: String, points: Int, nonce: String) async throws {
        guard points > 0 else { throw RewardsUserError.invalidRedemption }
        guard FirebaseBootstrap.isConfigured else { throw RewardsUserError.firebaseUnavailable }
        FirebaseBootstrap.configureIfNeeded()

        let description = "In-store redemption: \(points) points"
        try await FirestoreRewardsUserWriter.adminRedeemPoints(
            email: email,
            points: points,
            nonce: nonce,
            description: description
        )
        lastSyncError = nil
    }

    private func startUserListener(email: String) {
        userListener = FirestoreRewardsUserWriter.addListener(email: email) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success(let record):
                    var changed = false
                    if record.points != self.account.points {
                        self.account.points = record.points
                        changed = true
                    }
                    if record.lifetimeSpend != self.account.lifetimeSpend {
                        self.account.lifetimeSpend = record.lifetimeSpend
                        changed = true
                    }
                    if !record.firstName.isEmpty, self.account.firstName != record.firstName {
                        self.account.firstName = record.firstName
                        changed = true
                    }
                    if !record.lastName.isEmpty, self.account.lastName != record.lastName {
                        self.account.lastName = record.lastName
                        changed = true
                    }
                    if !record.phone.isEmpty, self.account.phone != record.phone {
                        self.account.phone = record.phone
                        changed = true
                    }
                    if record.birthday != self.account.birthday {
                        self.account.birthday = record.birthday
                        changed = true
                    }
                    if record.marketingOptIn != self.account.marketingOptIn {
                        self.account.marketingOptIn = record.marketingOptIn
                        changed = true
                    }
                    if changed {
                        self.persist()
                    }
                    self.lastSyncError = nil
                case .failure(let error):
                    self.lastSyncError = error.localizedDescription
                }
            }
        }
    }

    private func startHistoryListener(email: String) {
        historyListener = FirestorePointsHistoryWriter.addListener(email: email) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success(let entries):
                    self.pointsHistory = entries
                case .failure(let error):
                    self.lastSyncError = error.localizedDescription
                }
            }
        }
    }

    @MainActor
    private func syncUserToFirestore() async throws {
        guard account.email != nil, FirebaseBootstrap.isConfigured else { return }
        FirebaseBootstrap.configureIfNeeded()
        do {
            try await FirestoreRewardsUserWriter.saveUser(account)
            lastSyncError = nil
        } catch let error as NSError where error.domain == "RewardsUser" && error.code == 409 {
            lastSyncError = RewardsUserError.emailAlreadyRegistered.localizedDescription
            throw RewardsUserError.emailAlreadyRegistered
        } catch {
            lastSyncError = error.localizedDescription
            throw error
        }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(account) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    private func persistCart() {
        guard let data = try? JSONEncoder().encode(redemptionCart) else { return }
        UserDefaults.standard.set(data, forKey: cartKey)
    }

    private static func loadAccount() -> RewardsAccount? {
        guard let data = UserDefaults.standard.data(forKey: "hamptons.rewardsAccount"),
              let decoded = try? JSONDecoder().decode(RewardsAccount.self, from: data) else {
            return nil
        }
        return decoded
    }

    private static func loadCart() -> [String: Int] {
        guard let data = UserDefaults.standard.data(forKey: "hamptons.redemptionCart"),
              let decoded = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }
        return decoded
    }
}

enum RedemptionCartSubmitResult: Equatable {
    case success(order: RewardMealOrder)
    case invalidCode
    case emptyCart
    case insufficientPoints
}
