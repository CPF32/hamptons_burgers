import Foundation

enum RewardsPointsMath {
    /// Whole points earned from cumulative spend so far.
    static func points(fromLifetimeSpend spend: Double) -> Int {
        guard spend > 0 else { return 0 }
        return Int(spend.rounded(.down)) * BrandConfig.rewardsPointsPerDollar
    }

    /// Points unlocked by adding `dollars` on top of `previousSpend` (cents carry over).
    static func pointsEarned(previousSpend: Double, adding dollars: Double) -> (earned: Int, updatedSpend: Double) {
        let updatedSpend = roundToCents(previousSpend + dollars)
        let earned = points(fromLifetimeSpend: updatedSpend) - points(fromLifetimeSpend: previousSpend)
        return (earned, updatedSpend)
    }

    static func roundToCents(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }
}
