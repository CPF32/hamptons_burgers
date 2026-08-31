import Foundation
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

enum FirestoreRewardsUserWriter {
    #if canImport(FirebaseFirestore)
    private static var collection: CollectionReference {
        Firestore.firestore().collection(BrandConfig.firestoreRewardsUsersCollection)
    }
    #endif

    static func normalizeEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func isValidEmail(_ email: String) -> Bool {
        let normalized = normalizeEmail(email)
        return normalized.contains("@") && normalized.contains(".") && normalized.count >= 5
    }

    static func fetch(email: String) async throws -> RewardsUserRecord? {
        #if canImport(FirebaseFirestore)
        let docId = normalizeEmail(email)
        let snapshot = try await collection.document(docId).getDocument()
        guard snapshot.exists, let data = snapshot.data() else { return nil }
        return decode(data, email: docId)
        #else
        return nil
        #endif
    }

    static func saveUser(_ account: RewardsAccount) async throws {
        #if canImport(FirebaseFirestore)
        guard let email = account.email else { return }
        let docId = normalizeEmail(email)
        let payload = encodeUser(account, docId: docId)
        let ref = collection.document(docId)

        _ = try await Firestore.firestore().runTransaction { transaction, errorPointer in
            let snapshot: DocumentSnapshot
            do {
                snapshot = try transaction.getDocument(ref)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }

            if snapshot.exists {
                let existingMemberId = snapshot.data()?["memberId"] as? String ?? ""
                if existingMemberId != account.memberId {
                    let nsError = NSError(
                        domain: "RewardsUser",
                        code: 409,
                        userInfo: [NSLocalizedDescriptionKey: RewardsUserError.emailAlreadyRegistered.localizedDescription ?? ""]
                    )
                    errorPointer?.pointee = nsError
                    return nil
                }
                transaction.setData(payload, forDocument: ref, merge: true)
            } else {
                transaction.setData(payload, forDocument: ref)
            }
            return nil
        }
        #else
        throw FirestoreUnavailableError.sdkMissing
        #endif
    }

    static func adminCreditPoints(email: String, dollars: Double) async throws -> Int {
        #if canImport(FirebaseFirestore)
        let docId = normalizeEmail(email)
        guard dollars > 0 else { return 0 }

        let ref = collection.document(docId)
        let historyID = UUID().uuidString.lowercased()

        let earned = try await Firestore.firestore().runTransaction { transaction, errorPointer -> Int in
            let snapshot: DocumentSnapshot
            do {
                snapshot = try transaction.getDocument(ref)
            } catch {
                errorPointer?.pointee = error as NSError
                return 0
            }

            guard snapshot.exists, let data = snapshot.data() else {
                let nsError = NSError(
                    domain: "RewardsUser",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: RewardsUserError.userNotFound.localizedDescription ?? ""]
                )
                errorPointer?.pointee = nsError
                return 0
            }

            let currentPoints = intValue(data["points"]) ?? 0
            let previousSpend = doubleValue(data["lifetimeSpend"]) ?? 0
            let result = RewardsPointsMath.pointsEarned(previousSpend: previousSpend, adding: dollars)
            let newPoints = currentPoints + result.earned

            transaction.setData([
                "email": docId,
                "points": newPoints,
                "lifetimeSpend": result.updatedSpend,
                "updatedAt": Timestamp(date: Date()),
                "adminWriteSecret": BrandConfig.firestoreAdminWriteSecret
            ], forDocument: ref, merge: true)

            let description = String(format: "In-store purchase: $%.2f", dollars)
            do {
                try FirestorePointsHistoryWriter.writeEntry(
                    transaction: transaction,
                    email: docId,
                    entryID: historyID,
                    delta: result.earned,
                    pointsAfter: newPoints,
                    description: description,
                    type: "earn",
                    dollars: dollars
                )
            } catch {
                errorPointer?.pointee = error as NSError
                return 0
            }

            return result.earned
        } as? Int ?? 0

        return earned
        #else
        throw RewardsUserError.firebaseUnavailable
        #endif
    }

    static func adminRedeemPoints(
        email: String,
        points: Int,
        nonce: String,
        description: String
    ) async throws {
        #if canImport(FirebaseFirestore)
        let docId = normalizeEmail(email)
        guard points > 0 else { throw RewardsUserError.invalidRedemption }

        if try await FirestorePointsHistoryWriter.redemptionAlreadyProcessed(email: docId, nonce: nonce) {
            throw RewardsUserError.redemptionAlreadyProcessed
        }

        let ref = collection.document(docId)

        try await Firestore.firestore().runTransaction { transaction, errorPointer in
            let snapshot: DocumentSnapshot
            do {
                snapshot = try transaction.getDocument(ref)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }

            guard snapshot.exists, let data = snapshot.data() else {
                let nsError = NSError(
                    domain: "RewardsUser",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: RewardsUserError.userNotFound.localizedDescription ?? ""]
                )
                errorPointer?.pointee = nsError
                return nil
            }

            let currentPoints = intValue(data["points"]) ?? 0
            guard currentPoints >= points else {
                let nsError = NSError(
                    domain: "RewardsUser",
                    code: 400,
                    userInfo: [NSLocalizedDescriptionKey: RewardsUserError.insufficientPoints.localizedDescription ?? ""]
                )
                errorPointer?.pointee = nsError
                return nil
            }

            let newPoints = currentPoints - points
            transaction.setData([
                "email": docId,
                "points": newPoints,
                "updatedAt": Timestamp(date: Date()),
                "adminWriteSecret": BrandConfig.firestoreAdminWriteSecret
            ], forDocument: ref, merge: true)

            do {
                try FirestorePointsHistoryWriter.writeEntry(
                    transaction: transaction,
                    email: docId,
                    entryID: nonce,
                    delta: -points,
                    pointsAfter: newPoints,
                    description: description,
                    type: "redeem"
                )
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }

            return nil
        }
        #else
        throw RewardsUserError.firebaseUnavailable
        #endif
    }

    static func addListener(
        email: String,
        onChange: @escaping (Result<RewardsUserRecord, Error>) -> Void
    ) -> Any? {
        #if canImport(FirebaseFirestore)
        let docId = normalizeEmail(email)
        return collection.document(docId).addSnapshotListener { snapshot, error in
            if let error {
                onChange(.failure(error))
                return
            }
            guard let snapshot, snapshot.exists, let data = snapshot.data() else {
                onChange(.failure(RewardsUserError.userNotFound))
                return
            }
            if let record = decode(data, email: docId) {
                onChange(.success(record))
            } else {
                onChange(.failure(RewardsUserError.userNotFound))
            }
        }
        #else
        return nil
        #endif
    }

    #if canImport(FirebaseFirestore)
    private static func encodeUser(_ account: RewardsAccount, docId: String) -> [String: Any] {
        let firstName = account.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastName = account.lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        var payload: [String: Any] = [
            "email": docId,
            "memberId": account.memberId,
            "points": account.points,
            "lifetimeSpend": account.lifetimeSpend,
            "firstName": firstName,
            "lastName": lastName,
            "fullName": [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " "),
            "phone": account.phone.trimmingCharacters(in: .whitespacesAndNewlines),
            "marketingOptIn": account.marketingOptIn,
            "updatedAt": Timestamp(date: Date())
        ]
        if let birthday = account.birthday {
            payload["birthday"] = Timestamp(date: birthday)
        } else {
            payload["birthday"] = NSNull()
        }
        return payload
    }

    private static func decode(_ data: [String: Any], email: String) -> RewardsUserRecord? {
        guard let memberId = data["memberId"] as? String,
              let points = intValue(data["points"]) else {
            return nil
        }
        let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        let birthday = (data["birthday"] as? Timestamp)?.dateValue()

        var firstName = data["firstName"] as? String ?? ""
        var lastName = data["lastName"] as? String ?? ""
        if firstName.isEmpty, lastName.isEmpty, let legacy = data["fullName"] as? String, !legacy.isEmpty {
            let parts = legacy.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
            firstName = parts.first.map(String.init) ?? ""
            lastName = parts.count > 1 ? String(parts[1]) : ""
        }

        return RewardsUserRecord(
            email: email,
            memberId: memberId,
            points: points,
            lifetimeSpend: doubleValue(data["lifetimeSpend"]) ?? 0,
            firstName: firstName,
            lastName: lastName,
            phone: data["phone"] as? String ?? "",
            birthday: birthday,
            marketingOptIn: data["marketingOptIn"] as? Bool ?? false,
            updatedAt: updatedAt
        )
    }

    private static func intValue(_ value: Any?) -> Int? {
        if let int = value as? Int { return int }
        if let int64 = value as? Int64 { return Int(int64) }
        if let number = value as? NSNumber { return number.intValue }
        return nil
    }

    private static func doubleValue(_ value: Any?) -> Double? {
        if let double = value as? Double { return double }
        if let number = value as? NSNumber { return number.doubleValue }
        return nil
    }
    #endif
}
