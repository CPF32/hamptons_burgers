import Foundation
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

enum FirestoreAppConfigWriter {
    #if canImport(FirebaseFirestore)
    private static var document: DocumentReference {
        Firestore.firestore()
            .collection(BrandConfig.firestoreAppConfigCollection)
            .document(BrandConfig.firestoreAppConfigDocumentID)
    }
    #endif

    static func addListener(
        onChange: @escaping (Result<AppContent, Error>) -> Void
    ) -> Any? {
        #if canImport(FirebaseFirestore)
        return document.addSnapshotListener { snapshot, error in
            if let error {
                onChange(.failure(error))
                return
            }
            guard let snapshot, snapshot.exists, let data = snapshot.data() else {
                onChange(.failure(FirestoreAppConfigError.documentMissing))
                return
            }
            guard let content = decode(data) else {
                onChange(.failure(FirestoreAppConfigError.invalidPayload))
                return
            }
            onChange(.success(content))
        }
        #else
        return nil
        #endif
    }

    static func save(_ content: AppContent) async throws {
        #if canImport(FirebaseFirestore)
        try await document.setData(encode(content))
        #else
        throw FirestoreUnavailableError.sdkMissing
        #endif
    }

    #if canImport(FirebaseFirestore)
    private static func encode(_ content: AppContent) -> [String: Any] {
        var payload: [String: Any] = [
            "configVersion": content.configVersion,
            "location": encodeLocation(content.location),
            "faq": encodeFAQ(content.faq),
            "redemption": encodeRedemption(content.redemption),
            "adminEmails": content.adminEmails,
            "updatedAt": Timestamp(date: Date()),
            "adminWriteSecret": BrandConfig.firestoreAdminWriteSecret
        ]
        return payload
    }

    private static func encodeLocation(_ location: LocationContent) -> [String: Any] {
        [
            "name": location.name,
            "addressLine1": location.addressLine1,
            "addressLine2": location.addressLine2,
            "phone": location.phone,
            "email": location.email,
            "coordinates": [
                "latitude": location.coordinates.latitude,
                "longitude": location.coordinates.longitude
            ],
            "hours": location.hours.map { ["day": $0.day, "hours": $0.hours] }
        ]
    }

    private static func encodeFAQ(_ faq: FAQContent) -> [String: Any] {
        [
            "items": faq.items.map { ["id": $0.id, "question": $0.question, "answer": $0.answer] }
        ]
    }

    private static func encodeRedemption(_ redemption: RedemptionContent) -> [String: Any] {
        [
            "items": redemption.items.map {
                [
                    "id": $0.id,
                    "name": $0.name,
                    "price": $0.price,
                    "pointsCost": $0.pointsCost,
                    "category": $0.category
                ]
            }
        ]
    }

    private static func decode(_ data: [String: Any]) -> AppContent? {
        guard let configVersion = intValue(data["configVersion"]),
              let locationData = data["location"] as? [String: Any],
              let faqData = data["faq"] as? [String: Any],
              let redemptionData = data["redemption"] as? [String: Any],
              let location = decodeLocation(locationData),
              let faq = decodeFAQ(faqData),
              let redemption = decodeRedemption(redemptionData) else {
            return nil
        }

        let adminEmails = (data["adminEmails"] as? [String])?
            .map(FirestoreRewardsUserWriter.normalizeEmail) ?? []

        return AppContent(
            configVersion: configVersion,
            location: location,
            faq: faq,
            redemption: redemption,
            adminEmails: adminEmails
        )
    }

    private static func decodeLocation(_ data: [String: Any]) -> LocationContent? {
        guard let name = data["name"] as? String,
              let addressLine1 = data["addressLine1"] as? String,
              let addressLine2 = data["addressLine2"] as? String,
              let phone = data["phone"] as? String,
              let email = data["email"] as? String,
              let coordinates = data["coordinates"] as? [String: Any],
              let latitude = doubleValue(coordinates["latitude"]),
              let longitude = doubleValue(coordinates["longitude"]),
              let hoursData = data["hours"] as? [[String: Any]] else {
            return nil
        }

        let hours: [LocationContent.HoursEntry] = hoursData.compactMap { entry in
            guard let day = entry["day"] as? String,
                  let hours = entry["hours"] as? String else { return nil }
            return LocationContent.HoursEntry(day: day, hours: hours)
        }

        return LocationContent(
            name: name,
            addressLine1: addressLine1,
            addressLine2: addressLine2,
            phone: phone,
            email: email,
            coordinates: LocationContent.Coordinates(latitude: latitude, longitude: longitude),
            hours: hours
        )
    }

    private static func decodeFAQ(_ data: [String: Any]) -> FAQContent? {
        guard let itemsData = data["items"] as? [[String: Any]] else { return nil }
        let items: [FAQItem] = itemsData.compactMap { item in
            guard let id = item["id"] as? String,
                  let question = item["question"] as? String,
                  let answer = item["answer"] as? String else { return nil }
            return FAQItem(id: id, question: question, answer: answer)
        }
        return FAQContent(items: items)
    }

    private static func decodeRedemption(_ data: [String: Any]) -> RedemptionContent? {
        guard let itemsData = data["items"] as? [[String: Any]] else { return nil }
        let items: [RedemptionItem] = itemsData.compactMap { item in
            guard let id = item["id"] as? String,
                  let name = item["name"] as? String,
                  let price = doubleValue(item["price"]),
                  let pointsCost = intValue(item["pointsCost"]),
                  let category = item["category"] as? String else { return nil }
            return RedemptionItem(id: id, name: name, price: price, pointsCost: pointsCost, category: category)
        }
        return RedemptionContent(items: items)
    }

    private static func intValue(_ value: Any?) -> Int? {
        if let int = value as? Int { return int }
        if let int64 = value as? Int64 { return Int(int64) }
        if let number = value as? NSNumber { return number.intValue }
        return nil
    }

    private static func doubleValue(_ value: Any?) -> Double? {
        if let double = value as? Double { return double }
        if let int = value as? Int { return Double(int) }
        if let number = value as? NSNumber { return number.doubleValue }
        return nil
    }
    #endif
}

enum FirestoreAppConfigError: LocalizedError {
    case documentMissing
    case invalidPayload

    var errorDescription: String? {
        switch self {
        case .documentMissing:
            return "App config document is missing in Firestore."
        case .invalidPayload:
            return "App config document has an invalid format."
        }
    }
}
