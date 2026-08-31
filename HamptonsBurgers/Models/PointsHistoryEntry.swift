import Foundation

struct PointsHistoryEntry: Codable, Equatable, Identifiable {
    let id: String
    let delta: Int
    let pointsAfter: Int
    let description: String
    let createdAt: Date
    let type: String

    var isEarn: Bool { type == "earn" }
    var isRedeem: Bool { type == "redeem" }
}
