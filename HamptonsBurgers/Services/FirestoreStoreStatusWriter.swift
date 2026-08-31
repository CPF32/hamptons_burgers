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
    private static func encode(_ status: StoreStatus) -> [String: Any] {
        [
            "isOffDay": status.isOffDay,
            "isSoldOut": status.isSoldOut,
            "pattyCount": status.pattyCount,
            "pattyCapacity": status.pattyCapacity,
            "noticeTitle": status.noticeTitle,
            "noticeBody": status.noticeBody,
            "orderClosedMessage": status.orderClosedMessage,
            "updatedAt": Timestamp(date: status.updatedAt),
            "adminWriteSecret": BrandConfig.firestoreAdminWriteSecret
        ]
    }

    private static func decode(_ data: [String: Any]) -> StoreStatus {
        StoreStatus(
            isOffDay: data["isOffDay"] as? Bool ?? false,
            isSoldOut: data["isSoldOut"] as? Bool ?? false,
            pattyCount: data["pattyCount"] as? Int ?? StoreStatus.default.pattyCount,
            pattyCapacity: data["pattyCapacity"] as? Int ?? StoreStatus.default.pattyCapacity,
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
