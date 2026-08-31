import Foundation

enum ReceiptSubtotalParser {
    /// Finds the food/items subtotal on a receipt (not tax, tip, or final total).
    static func parseSubtotal(from lines: [String]) -> Double? {
        let trimmedLines = lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        for (index, line) in trimmedLines.enumerated() {
            guard isSubtotalLabel(line) else { continue }

            if let amount = extractAmount(from: line) {
                return amount
            }
            if index + 1 < trimmedLines.count,
               let amount = extractAmount(from: trimmedLines[index + 1]),
               !isExcludedLabel(trimmedLines[index + 1]) {
                return amount
            }
        }

        return nil
    }

    private static func isSubtotalLabel(_ line: String) -> Bool {
        let lower = line.lowercased()
        guard lower.contains("subtotal") || lower.contains("sub total") || lower.contains("sub-total") else {
            return false
        }
        return !lower.contains("tax") && !lower.contains("tip")
    }

    private static func isExcludedLabel(_ line: String) -> Bool {
        let lower = line.lowercased()
        return lower.contains("tax")
            || lower.contains("tip")
            || lower.contains("gratuity")
            || (lower.contains("total") && !lower.contains("sub"))
    }

    private static func extractAmount(from line: String) -> Double? {
        let pattern = #"(?:\$\s*)?(\d{1,4}\.\d{2})"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }

        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        let matches = regex.matches(in: line, range: range)
        guard let last = matches.last, let matchRange = Range(last.range(at: 1), in: line) else {
            return nil
        }

        return Double(line[matchRange])
    }
}
