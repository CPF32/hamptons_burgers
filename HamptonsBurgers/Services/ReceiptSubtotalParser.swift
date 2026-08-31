import Foundation

enum ReceiptSubtotalParser {
    /// Finds the food/items subtotal on a receipt (not tax, tip, or final total).
    static func parseSubtotal(from lines: [String]) -> Double? {
        let trimmedLines = lines
            .map(normalizeLine)
            .filter { !$0.isEmpty }

        let fullText = trimmedLines.joined(separator: "\n")

        if let amount = matchInlineSubtotal(in: fullText) {
            return amount
        }

        if let amount = findLabeledSubtotal(in: trimmedLines) {
            return amount
        }

        if let amount = findAmountBeforeTax(in: trimmedLines) {
            return amount
        }

        return nil
    }

    private static func normalizeLine(_ line: String) -> String {
        line
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func matchInlineSubtotal(in text: String) -> Double? {
        let pattern = #"(?i)sub\s*-?\s*tota[l1i]?\s*[:.]?\s*(?:\$|S)\s*(\d[\d,]*[.,:]\d{2})"#
        return firstAmount(in: text, pattern: pattern)
    }

    private static func findLabeledSubtotal(in lines: [String]) -> Double? {
        for (index, line) in lines.enumerated() {
            guard isSubtotalLabel(line) else { continue }

            if let amount = extractAmount(from: line) {
                return amount
            }

            for offset in 1...3 where index + offset < lines.count {
                let next = lines[index + offset]
                if isExcludedLabel(next) { break }
                if let amount = extractAmount(from: next) {
                    return amount
                }
            }
        }

        return nil
    }

    private static func findAmountBeforeTax(in lines: [String]) -> Double? {
        for (index, line) in lines.enumerated() where isTaxLabel(line) {
            for offset in 1...2 {
                let candidateIndex = index - offset
                guard candidateIndex >= 0 else { continue }

                let candidate = lines[candidateIndex]
                guard !isTaxLabel(candidate), !isTipLabel(candidate), !isGrandTotalLabel(candidate) else {
                    continue
                }

                if let amount = extractAmount(from: candidate) {
                    return amount
                }
            }
        }

        return nil
    }

    private static func isSubtotalLabel(_ line: String) -> Bool {
        let lower = line.lowercased()
        let compact = lower.replacingOccurrences(of: " ", with: "")

        let hasSubtotalWord = lower.contains("subtotal")
            || lower.contains("sub total")
            || lower.contains("sub-total")
            || compact.contains("subtota")
            || lower.contains("food total")
            || lower.contains("item total")
            || lower.contains("items total")

        guard hasSubtotalWord else { return false }
        return !lower.contains("tax") && !lower.contains("tip")
    }

    private static func isTaxLabel(_ line: String) -> Bool {
        let lower = line.lowercased()
        return lower.contains("sales tax")
            || lower.contains("state tax")
            || lower.contains("local tax")
            || (lower.contains("tax") && !lower.contains("subtotal") && !lower.contains("sub total"))
    }

    private static func isTipLabel(_ line: String) -> Bool {
        let lower = line.lowercased()
        return lower.contains("tip") || lower.contains("gratuity")
    }

    private static func isGrandTotalLabel(_ line: String) -> Bool {
        let lower = line.lowercased()
        return (lower.contains("total") || lower.contains("amount due") || lower.contains("balance due"))
            && !lower.contains("sub")
    }

    private static func isExcludedLabel(_ line: String) -> Bool {
        isTaxLabel(line) || isTipLabel(line) || isGrandTotalLabel(line)
    }

    private static func extractAmount(from line: String) -> Double? {
        let candidates = [line, normalizeOCRAmounts(in: line)]

        let patterns = [
            #"(?:\$|S)\s*(\d{1,3}(?:,\d{3})*\.\d{2})"#,
            #"(?:\$|S)\s*(\d+\.\d{2})"#,
            #"(?:\$|S)\s*(\d+)[.,:](\d{2})\b"#,
            #"\b(\d{1,3}(?:,\d{3})*\.\d{2})\b"#,
            #"\b(\d+\.\d{2})\b"#,
            #"\b(\d+)[.,:](\d{2})\b"#
        ]

        for candidate in candidates {
            for pattern in patterns {
                if let amount = lastAmount(in: candidate, pattern: pattern) {
                    return RewardsPointsMath.roundToCents(amount)
                }
            }
        }

        return nil
    }

    private static func normalizeOCRAmounts(in line: String) -> String {
        var result = line.replacingOccurrences(of: "\u{00A0}", with: " ")

        if let regex = try? NSRegularExpression(pattern: #"\bS(\d)"#) {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            result = regex.stringByReplacingMatches(
                in: result,
                range: range,
                withTemplate: "$$1"
            )
        }

        if let regex = try? NSRegularExpression(pattern: #"([\dOIl]{1,4}[.,:][\dOIl]{2})"#) {
            let nsRange = NSRange(result.startIndex..<result.endIndex, in: result)
            let matches = regex.matches(in: result, range: nsRange)
            for match in matches.reversed() {
                guard let range = Range(match.range(at: 1), in: result) else { continue }
                let token = String(result[range])
                    .replacingOccurrences(of: "O", with: "0")
                    .replacingOccurrences(of: "o", with: "0")
                    .replacingOccurrences(of: "l", with: "1")
                    .replacingOccurrences(of: "I", with: "1")
                    .replacingOccurrences(of: ":", with: ".")
                result.replaceSubrange(range, with: token)
            }
        }

        return result
    }

    private static func firstAmount(in text: String, pattern: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range) else { return nil }
        return amount(from: match, in: text)
    }

    private static func lastAmount(in text: String, pattern: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, range: range)
        guard let last = matches.last else { return nil }
        return amount(from: last, in: text)
    }

    private static func amount(from match: NSTextCheckingResult, in text: String) -> Double? {
        if match.numberOfRanges == 3,
           let wholeRange = Range(match.range(at: 1), in: text),
           let fractionRange = Range(match.range(at: 2), in: text) {
            let whole = text[wholeRange].replacingOccurrences(of: ",", with: "")
            let fraction = text[fractionRange]
            return Double("\(whole).\(fraction)")
        }

        guard match.numberOfRanges >= 2,
              let amountRange = Range(match.range(at: 1), in: text) else {
            return nil
        }

        let raw = text[amountRange].replacingOccurrences(of: ",", with: "").replacingOccurrences(of: ":", with: ".")
        return Double(raw)
    }
}
