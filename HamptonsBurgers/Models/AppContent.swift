import Foundation

/// Remote-managed app content (location, FAQ, redemption menu).
/// `configVersion` is bumped by admins whenever any of this data changes.
struct AppContent: Codable, Equatable {
    var configVersion: Int
    var location: LocationContent
    var faq: FAQContent
    var redemption: RedemptionContent
    var adminEmails: [String]

    static func bundled() -> AppContent {
        AppContent(
            configVersion: 0,
            location: ContentConfig.loadBundled("location", as: LocationContent.self),
            faq: ContentConfig.loadBundled("faq", as: FAQContent.self),
            redemption: ContentConfig.loadBundled("redemption", as: RedemptionContent.self),
            adminEmails: []
        )
    }
}
