import Foundation

struct RewardOrderLineItem: Codable, Equatable, Identifiable {
    var id: String { itemId }
    let itemId: String
    let name: String
    let quantity: Int
    let unitPrice: Double
    let unitPointsCost: Int

    var linePrice: Double { unitPrice * Double(quantity) }
    var linePoints: Int { unitPointsCost * quantity }

    init(item: RedemptionItem, quantity: Int) {
        itemId = item.id
        name = item.name
        self.quantity = quantity
        unitPrice = item.price
        unitPointsCost = item.pointsCost
    }

    init(itemId: String, name: String, quantity: Int, unitPrice: Double, unitPointsCost: Int) {
        self.itemId = itemId
        self.name = name
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.unitPointsCost = unitPointsCost
    }
}

struct RewardMealOrder: Codable, Equatable, Identifiable {
    let id: String
    let memberId: String
    let email: String?
    let lineItems: [RewardOrderLineItem]
    let totalPrice: Double
    let totalPoints: Int
    let createdAt: Date

    init(memberId: String, email: String?, lineItems: [RewardOrderLineItem]) {
        id = UUID().uuidString.lowercased()
        self.memberId = memberId
        self.email = email
        self.lineItems = lineItems
        totalPrice = lineItems.reduce(0) { $0 + $1.linePrice }
        totalPoints = lineItems.reduce(0) { $0 + $1.linePoints }
        createdAt = Date()
    }

    init(
        id: String,
        memberId: String,
        email: String?,
        lineItems: [RewardOrderLineItem],
        totalPrice: Double,
        totalPoints: Int,
        createdAt: Date
    ) {
        self.id = id
        self.memberId = memberId
        self.email = email
        self.lineItems = lineItems
        self.totalPrice = totalPrice
        self.totalPoints = totalPoints
        self.createdAt = createdAt
    }

    var itemCount: Int {
        lineItems.reduce(0) { $0 + $1.quantity }
    }

    var summary: String {
        lineItems.map { "\($0.quantity)× \($0.name)" }.joined(separator: ", ")
    }
}
