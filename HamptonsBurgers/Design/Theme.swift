import SwiftUI

enum Theme {
    static let buttonMaxWidth: CGFloat = 260
    /// Fixed height for content below the logo — Order and Account cards match.
    static let actionCardActionsHeight: CGFloat = 228
    static let authFieldHeight: CGFloat = 36
    static let pattyGaugeMaxWidth: CGFloat = 200
    static let noticeBannerMaxWidth: CGFloat = 320
    /// Vertical gap between stacked content cards (Find Us, Rewards, etc.).
    static let sectionGap: CGFloat = 12
    /// Inner content height for the first card on Find Us, Rewards, and FAQ.
    static let tabFirstSectionMinHeight: CGFloat = 106

    static var navy: Color { Color(hex: BrandConfig.navyHex) }
    static var background: Color { Color(hex: BrandConfig.backgroundHex) }
    static var surface: Color { Color(hex: BrandConfig.surfaceHex) }
    static var text: Color { Color(hex: BrandConfig.textHex) }
    static var mutedText: Color { Color(hex: BrandConfig.mutedTextHex) }
    static var primary: Color { Color(hex: BrandConfig.primaryHex) }
    static var onPrimary: Color { Color(hex: BrandConfig.onPrimaryHex) }
    static var secondary: Color { Color(hex: BrandConfig.secondaryHex) }
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let a, r, g, b: UInt64
        switch cleaned.count {
        case 6:
            (a, r, g, b) = (255, (value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF)
        case 8:
            (a, r, g, b) = ((value >> 24) & 0xFF, (value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF)
        default:
            (a, r, g, b) = (255, 25, 51, 82)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
