import Foundation
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

enum FirestoreRewardOrderWriter {
    #if canImport(FirebaseFirestore)
    private static var collection: CollectionReference {
        Firestore.firestore().collection(BrandConfig.firestoreRewardOrdersCollection)
    }
    #endif

    static func save(_ order: RewardMealOrder) async throws {
        #if canImport(FirebaseFirestore)
        try await collection.document(order.id).setData(encode(order))
        #else
        throw FirestoreUnavailableError.sdkMissing
        #endif
    }

    #if canImport(FirebaseFirestore)
    private static func encode(_ order: RewardMealOrder) -> [String: Any] {
        var payload: [String: Any] = [
            "memberId": order.memberId,
            "lineItems": order.lineItems.map { item in
                [
                    "itemId": item.itemId,
                    "name": item.name,
                    "quantity": item.quantity,
                    "unitPrice": item.unitPrice,
                    "unitPointsCost": item.unitPointsCost
                ]
            },
            "totalPrice": order.totalPrice,
            "totalPoints": order.totalPoints,
            "createdAt": Timestamp(date: order.createdAt),
            "adminWriteSecret": BrandConfig.firestoreAdminWriteSecret
        ]
        if let email = order.email {
            payload["email"] = email
        }
        return payload
    }

    private static func decode(_ data: [String: Any], id: String) -> RewardMealOrder? {
        guard let memberId = data["memberId"] as? String,
              let lineItemsData = data["lineItems"] as? [[String: Any]],
              let totalPrice = data["totalPrice"] as? Double,
              let totalPoints = data["totalPoints"] as? Int else {
            return nil
        }

        let lineItems: [RewardOrderLineItem] = lineItemsData.compactMap { item in
            guard let itemId = item["itemId"] as? String,
                  let name = item["name"] as? String,
                  let quantity = item["quantity"] as? Int,
                  let unitPrice = item["unitPrice"] as? Double,
                  let unitPointsCost = item["unitPointsCost"] as? Int else {
                return nil
            }
            return RewardOrderLineItem(
                itemId: itemId,
                name: name,
                quantity: quantity,
                unitPrice: unitPrice,
                unitPointsCost: unitPointsCost
            )
        }

        guard !lineItems.isEmpty else { return nil }

        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

        return RewardMealOrder(
            id: id,
            memberId: memberId,
            email: data["email"] as? String,
            lineItems: lineItems,
            totalPrice: totalPrice,
            totalPoints: totalPoints,
            createdAt: createdAt
        )
    }
    #endif
}
