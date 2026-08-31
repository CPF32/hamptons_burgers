import Foundation

enum PhoneNumberFormatter {
    /// Formats digits into `XXX-XXX-XXXX` (area code - exchange - line).
    static func format(_ raw: String) -> String {
        let digits = raw.filter(\.isNumber)
        let limited = String(digits.prefix(10))

        switch limited.count {
        case 0:
            return ""
        case 1...3:
            return limited
        case 4...6:
            let area = limited.prefix(3)
            let middle = limited.dropFirst(3)
            return "\(area)-\(middle)"
        default:
            let area = limited.prefix(3)
            let middle = limited.dropFirst(3).prefix(3)
            let last = limited.dropFirst(6)
            return "\(area)-\(middle)-\(last)"
        }
    }
}
