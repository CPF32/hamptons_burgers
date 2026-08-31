import Foundation

struct RewardsUserRecord: Codable, Equatable {
    let email: String
    let memberId: String
    var points: Int
    var lifetimeSpend: Double
    var firstName: String
    var lastName: String
    var phone: String
    var birthday: Date?
    var marketingOptIn: Bool
    var updatedAt: Date

    var displayName: String {
        let parts = [firstName, lastName]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return parts.joined(separator: " ")
    }
}

enum RewardsUserError: LocalizedError {
    case invalidEmail
    case invalidProfile
    case userNotFound
    case firebaseUnavailable
    case emailAlreadyRegistered
    case insufficientPoints
    case invalidRedemption
    case redemptionAlreadyProcessed

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Enter a valid email address."
        case .invalidProfile:
            return "Add your first name, last name, email, and phone number."
        case .userNotFound:
            return "No rewards account found for that email."
        case .firebaseUnavailable:
            return "Firebase is not configured."
        case .emailAlreadyRegistered:
            return "That email is already linked to another rewards account."
        case .insufficientPoints:
            return "Guest does not have enough points for this redemption."
        case .invalidRedemption:
            return "Invalid redemption QR code."
        case .redemptionAlreadyProcessed:
            return "This redemption was already processed."
        }
    }
}
