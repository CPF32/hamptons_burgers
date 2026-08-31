import Foundation
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

enum FirestorePointsHistoryWriter {
    #if canImport(FirebaseFirestore)
    private static var db: Firestore { Firestore.firestore() }

    private static func collection(email: String) -> CollectionReference {
        db.collection(BrandConfig.firestoreRewardsUsersCollection)
            .document(FirestoreRewardsUserWriter.normalizeEmail(email))
            .collection(BrandConfig.firestorePointHistorySubcollection)
    }
    #endif

    static func addListener(
        email: String,
        onChange: @escaping (Result<[PointsHistoryEntry], Error>) -> Void
    ) -> Any? {
        #if canImport(FirebaseFirestore)
        return collection(email: email)
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onChange(.failure(error))
                    return
                }
                guard let snapshot else {
                    onChange(.success([]))
                    return
                }
                let entries = snapshot.documents.compactMap { decode($0.data(), id: $0.documentID) }
                onChange(.success(entries))
            }
        #else
        return nil
        #endif
    }

    #if canImport(FirebaseFirestore)
    static func writeEntry(
        transaction: Transaction,
        email: String,
        entryID: String,
        delta: Int,
        pointsAfter: Int,
        description: String,
        type: String,
        dollars: Double? = nil
    ) throws {
        let ref = collection(email: email).document(entryID)
        var payload: [String: Any] = [
            "delta": delta,
            "pointsAfter": pointsAfter,
            "description": description,
            "type": type,
            "createdAt": Timestamp(date: Date()),
            "adminWriteSecret": BrandConfig.firestoreAdminWriteSecret
        ]
        if let dollars {
            payload["dollars"] = dollars
        }
        transaction.setData(payload, forDocument: ref)
    }

    static func redemptionAlreadyProcessed(email: String, nonce: String) async throws -> Bool {
        let snapshot = try await collection(email: email).document(nonce).getDocument()
        return snapshot.exists
    }

    private static func decode(_ data: [String: Any], id: String) -> PointsHistoryEntry? {
        guard let delta = intValue(data["delta"]),
              let pointsAfter = intValue(data["pointsAfter"]),
              let description = data["description"] as? String,
              let type = data["type"] as? String else {
            return nil
        }
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        return PointsHistoryEntry(
            id: id,
            delta: delta,
            pointsAfter: pointsAfter,
            description: description,
            createdAt: createdAt,
            type: type
        )
    }

    private static func intValue(_ value: Any?) -> Int? {
        if let int = value as? Int { return int }
        if let int64 = value as? Int64 { return Int(int64) }
        if let number = value as? NSNumber { return number.intValue }
        return nil
    }
    #endif
}
