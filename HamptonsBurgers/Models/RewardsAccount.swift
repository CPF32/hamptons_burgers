import Foundation

struct RewardsAccount: Codable, Equatable {
    let memberId: String
    var email: String?
    var firstName: String
    var lastName: String
    var phone: String
    var birthday: Date?
    var marketingOptIn: Bool
    var points: Int
    /// Cumulative dollars spent toward rewards (cents carry across purchases).
    var lifetimeSpend: Double

    static func makeNew() -> RewardsAccount {
        RewardsAccount(
            memberId: UUID().uuidString.lowercased(),
            email: nil,
            firstName: "",
            lastName: "",
            phone: "",
            birthday: nil,
            marketingOptIn: false,
            points: 0,
            lifetimeSpend: 0
        )
    }

    var displayName: String {
        let parts = [firstName, lastName]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? "Guest" : parts.joined(separator: " ")
    }

    var hasCompleteProfile: Bool {
        guard let email, FirestoreRewardsUserWriter.isValidEmail(email) else { return false }
        return !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var profileInitial: String {
        let trimmed = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        if let first = trimmed.first {
            return String(first).uppercased()
        }
        if let email, let first = email.first {
            return String(first).uppercased()
        }
        return "?"
    }

    enum CodingKeys: String, CodingKey {
        case memberId, email, firstName, lastName, fullName, phone, birthday, marketingOptIn, points, lifetimeSpend
    }

    init(
        memberId: String,
        email: String?,
        firstName: String,
        lastName: String,
        phone: String,
        birthday: Date?,
        marketingOptIn: Bool,
        points: Int,
        lifetimeSpend: Double
    ) {
        self.memberId = memberId
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.phone = phone
        self.birthday = birthday
        self.marketingOptIn = marketingOptIn
        self.points = points
        self.lifetimeSpend = lifetimeSpend
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        memberId = try container.decode(String.self, forKey: .memberId)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        phone = try container.decodeIfPresent(String.self, forKey: .phone) ?? ""
        birthday = try container.decodeIfPresent(Date.self, forKey: .birthday)
        marketingOptIn = try container.decodeIfPresent(Bool.self, forKey: .marketingOptIn) ?? false
        points = try container.decode(Int.self, forKey: .points)
        lifetimeSpend = try container.decodeIfPresent(Double.self, forKey: .lifetimeSpend) ?? 0

        let decodedFirst = try container.decodeIfPresent(String.self, forKey: .firstName) ?? ""
        let decodedLast = try container.decodeIfPresent(String.self, forKey: .lastName) ?? ""
        if decodedFirst.isEmpty, decodedLast.isEmpty,
           let legacy = try container.decodeIfPresent(String.self, forKey: .fullName),
           !legacy.isEmpty {
            let parts = legacy.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
            firstName = parts.first.map(String.init) ?? ""
            lastName = parts.count > 1 ? String(parts[1]) : ""
        } else {
            firstName = decodedFirst
            lastName = decodedLast
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(memberId, forKey: .memberId)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(phone, forKey: .phone)
        try container.encodeIfPresent(birthday, forKey: .birthday)
        try container.encode(marketingOptIn, forKey: .marketingOptIn)
        try container.encode(points, forKey: .points)
        try container.encode(lifetimeSpend, forKey: .lifetimeSpend)
    }
}

struct PointsTransaction: Codable, Equatable, Identifiable {
    let id: String
    let date: Date
    let delta: Int
    let description: String

    init(delta: Int, description: String) {
        id = UUID().uuidString.lowercased()
        date = Date()
        self.delta = delta
        self.description = description
    }
}
