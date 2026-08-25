import Foundation

/// Central place to customize restaurant branding and Toast Online Ordering links.
/// Update these values (and Assets.xcassets logos) without touching feature screens.
enum BrandConfig {
    static let appName = "Hamptons Burgers"

    /// Toast Online Ordering public URL from Toast Web → Takeout & delivery → Restaurant info.
    /// Example: https://www.toasttab.com/your-restaurant-slug
    static let toastOrderingURL = URL(string: "https://www.toasttab.com/YOUR-RESTAURANT-SLUG")!

    /// Optional deep link into Toast guest account / past orders.
    /// Leave nil to reuse `toastOrderingURL` (guests sign in from the Toast ordering flow).
    static let toastAccountURL: URL? = nil

    static let supportPhone = "(555) 555-0100"
    static let supportEmail = "hello@hamptonsburgers.example"

    // MARK: - Colors (hex without #)

    static let primaryHex = "1A1A1A"
    static let secondaryHex = "C4A35A"
    static let backgroundHex = "F7F4EF"
    static let surfaceHex = "FFFFFF"
    static let textHex = "1A1A1A"
    static let mutedTextHex = "6B6560"
}
