import Foundation
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

enum FirestoreStoreStatusWriter {
    #if canImport(FirebaseFirestore)
    private static var collection: CollectionReference {
        Firestore.firestore().collection(BrandConfig.firestoreCollection)
    }

    private static var document: DocumentReference {
        collection.document(BrandConfig.firestoreDocumentID)
    }
    #endif

    static func addListener(
        onChange: @escaping (Result<StoreStatus, Error>) -> Void
    ) -> Any? {
        #if canImport(FirebaseFirestore)
        return document.addSnapshotListener { snapshot, error in
            if let error {
                onChange(.failure(error))
                return
            }
            guard let snapshot, snapshot.exists, let data = snapshot.data() else {
                onChange(.success(.default))
                return
            }
            onChange(.success(decode(data)))
        }
        #else
        return nil
        #endif
    }

    static func save(_ status: StoreStatus) async throws {
        #if canImport(FirebaseFirestore)
        try await document.setData(encode(status), merge: true)
        #else
        throw FirestoreUnavailableError.sdkMissing
        #endif
    }

    #if canImport(FirebaseFirestore)
    /// Dual-writes the legacy weekly field names alongside the new daily ones so guests still
    /// running the pre-daily-count build (awaiting App Store approval / not yet updated) keep
    /// reading correct values from `pattyCount` / `pattyCapacity` / `isSoldOut`.
    /// Safe to remove once all guests have updated to a build that only reads the new fields.
    private static func encode(_ status: StoreStatus) -> [String: Any] {
        [
            "isOffDay": status.isOffDay,
            "isSoldOutForDay": status.isSoldOutForDay,
            "isSoldOutForWeek": status.isSoldOutForWeek,
            "dailyPattyCount": status.dailyPattyCount,
            "dailyPattyCapacity": status.dailyPattyCapacity,
            // Legacy mirrors for guests on the old build:
            "pattyCount": status.dailyPattyCount,
            "pattyCapacity": status.dailyPattyCapacity,
            "isSoldOut": status.isSoldOutForDay || status.isSoldOutForWeek,
            "noticeTitle": status.noticeTitle,
            "noticeBody": status.noticeBody,
            "orderClosedMessage": status.orderClosedMessage,
            "updatedAt": Timestamp(date: status.updatedAt),
            "adminWriteSecret": BrandConfig.firestoreAdminWriteSecret
        ]
    }

    /// Reads the new daily fields first, falling back to the legacy weekly fields — covers the
    /// case where the live document was last written by an admin still on the old build (merge
    /// writes never touch fields that build doesn't know about, so the new fields would be
    /// absent, not stale, right after such a write).
    private static func decode(_ data: [String: Any]) -> StoreStatus {
        let legacySoldOut = data["isSoldOut"] as? Bool ?? false
        return StoreStatus(
            isOffDay: data["isOffDay"] as? Bool ?? false,
            isSoldOutForDay: data["isSoldOutForDay"] as? Bool ?? false,
            isSoldOutForWeek: data["isSoldOutForWeek"] as? Bool ?? legacySoldOut,
            dailyPattyCount: data["dailyPattyCount"] as? Int ?? data["pattyCount"] as? Int ?? StoreStatus.default.dailyPattyCount,
            dailyPattyCapacity: data["dailyPattyCapacity"] as? Int ?? data["pattyCapacity"] as? Int ?? StoreStatus.default.dailyPattyCapacity,
            noticeTitle: data["noticeTitle"] as? String ?? "",
            noticeBody: data["noticeBody"] as? String ?? "",
            orderClosedMessage: data["orderClosedMessage"] as? String ?? "",
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
    #endif
}

enum FirestoreUnavailableError: LocalizedError {
    case sdkMissing

    var errorDescription: String? {
        "Firebase SDK is not linked. Add FirebaseCore + FirebaseFirestore package products to the app target."
    }
}
