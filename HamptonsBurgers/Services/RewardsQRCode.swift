import Foundation

/// QR payloads for in-store rewards (member earn + redemption).
enum RewardsQRCode {
    private static let scheme = "hamptons"
    private static let host = "rewards"

    enum Payload: Equatable {
        case member(email: String, subtotal: Double?)
        case redeem(email: String, points: Int, nonce: String)
    }

    static func memberPayload(email: String, subtotal: Double? = nil) -> String {
        let normalized = FirestoreRewardsUserWriter.normalizeEmail(email)
        var url = "\(scheme)://\(host)/member?e=\(urlEncode(normalized))"
        if let subtotal, subtotal > 0 {
            url += "&d=\(formattedAmount(subtotal))"
        }
        return url
    }

    static func redeemPayload(email: String, points: Int, nonce: String) -> String {
        let normalized = FirestoreRewardsUserWriter.normalizeEmail(email)
        return "\(scheme)://\(host)/redeem?e=\(urlEncode(normalized))&p=\(points)&n=\(urlEncode(nonce))"
    }

    static func parse(_ raw: String) -> Payload? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let components = URLComponents(string: trimmed),
              components.scheme == scheme,
              components.host == host else {
            return nil
        }

        let query: [String: String] = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).compactMap { item -> (String, String)? in
                guard let value = item.value else { return nil }
                return (item.name, value)
            }
        )

        let path = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        switch path {
        case "member":
            guard let email = query["e"],
                  FirestoreRewardsUserWriter.isValidEmail(email) else { return nil }
            let subtotal = query["d"].flatMap(Double.init).map { RewardsPointsMath.roundToCents($0) }
            return .member(
                email: FirestoreRewardsUserWriter.normalizeEmail(email),
                subtotal: subtotal
            )
        case "redeem":
            guard let email = query["e"],
                  let pointsString = query["p"],
                  let points = Int(pointsString),
                  let nonce = query["n"],
                  !nonce.isEmpty,
                  points > 0,
                  FirestoreRewardsUserWriter.isValidEmail(email) else { return nil }
            return .redeem(
                email: FirestoreRewardsUserWriter.normalizeEmail(email),
                points: points,
                nonce: nonce
            )
        default:
            return nil
        }
    }

    private static func formattedAmount(_ value: Double) -> String {
        String(format: "%.2f", RewardsPointsMath.roundToCents(value))
    }

    private static func urlEncode(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
    }
}
