import SwiftUI

enum Theme {
    static var primary: Color { Color(hex: BrandConfig.primaryHex) }
    static var secondary: Color { Color(hex: BrandConfig.secondaryHex) }
    static var background: Color { Color(hex: BrandConfig.backgroundHex) }
    static var surface: Color { Color(hex: BrandConfig.surfaceHex) }
    static var text: Color { Color(hex: BrandConfig.textHex) }
    static var mutedText: Color { Color(hex: BrandConfig.mutedTextHex) }
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
            (a, r, g, b) = (255, 26, 26, 26)
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
