import Foundation

struct RedemptionItem: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var price: Double
    var pointsCost: Int
    var category: String

    var priceDisplay: String {
        String(format: "$%.2f", price)
    }
}

struct RedemptionContent: Codable, Equatable {
    var items: [RedemptionItem]
}
