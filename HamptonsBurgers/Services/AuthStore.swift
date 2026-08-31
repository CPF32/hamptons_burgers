import Foundation
import Observation
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

@Observable
final class AuthStore {
    private(set) var isSignedIn = false
    private(set) var userEmail: String?
    private(set) var userID: String?

    #if canImport(FirebaseAuth)
    private var authListener: AuthStateDidChangeListenerHandle?
    #endif

    @MainActor
    func start() {
        guard FirebaseBootstrap.isConfigured else { return }
        FirebaseBootstrap.configureIfNeeded()
        #if canImport(FirebaseAuth)
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.apply(user: user)
            }
        }
        apply(user: Auth.auth().currentUser)
        #endif
    }

    @MainActor
    func signIn(email: String, password: String) async throws {
        #if canImport(FirebaseAuth)
        guard FirebaseBootstrap.isConfigured else { throw AuthStoreError.firebaseUnavailable }
        FirebaseBootstrap.configureIfNeeded()
        let normalized = FirestoreRewardsUserWriter.normalizeEmail(email)
        guard FirestoreRewardsUserWriter.isValidEmail(normalized) else {
            throw AuthStoreError.invalidEmail
        }
        guard password.count >= 6 else {
            throw AuthStoreError.weakPassword
        }

        do {
            let result = try await Auth.auth().signIn(withEmail: normalized, password: password)
            apply(user: result.user)
        } catch {
            throw mapAuthError(error)
        }
        #else
        throw AuthStoreError.firebaseUnavailable
        #endif
    }

    @MainActor
    func signUp(email: String, password: String) async throws {
        #if canImport(FirebaseAuth)
        guard FirebaseBootstrap.isConfigured else { throw AuthStoreError.firebaseUnavailable }
        FirebaseBootstrap.configureIfNeeded()
        let normalized = FirestoreRewardsUserWriter.normalizeEmail(email)
        guard FirestoreRewardsUserWriter.isValidEmail(normalized) else {
            throw AuthStoreError.invalidEmail
        }
        guard password.count >= 6 else {
            throw AuthStoreError.weakPassword
        }

        do {
            let result = try await Auth.auth().createUser(withEmail: normalized, password: password)
            apply(user: result.user)
        } catch {
            throw mapAuthError(error)
        }
        #else
        throw AuthStoreError.firebaseUnavailable
        #endif
    }

    @MainActor
    func signOut() throws {
        #if canImport(FirebaseAuth)
        try Auth.auth().signOut()
        apply(user: nil)
        #else
        throw AuthStoreError.firebaseUnavailable
        #endif
    }

    #if canImport(FirebaseAuth)
    @MainActor
    private func apply(user: User?) {
        isSignedIn = user != nil
        userEmail = user?.email.map(FirestoreRewardsUserWriter.normalizeEmail)
        userID = user?.uid
    }

    private func mapAuthError(_ error: Error) -> AuthStoreError {
        let nsError = error as NSError
        guard nsError.domain == AuthErrorDomain,
              let code = AuthErrorCode(rawValue: nsError.code) else {
            return .unknown(error.localizedDescription)
        }

        switch code {
        case .invalidEmail:
            return .invalidEmail
        case .wrongPassword, .invalidCredential:
            return .wrongPassword
        case .userNotFound:
            return .userNotFound
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .weakPassword:
            return .weakPassword
        case .networkError:
            return .network
        default:
            return .unknown(error.localizedDescription)
        }
    }
    #else
    @MainActor
    private func apply(user: Any?) {
        isSignedIn = false
        userEmail = nil
        userID = nil
    }
    #endif
}

enum AuthStoreError: LocalizedError {
    case invalidEmail
    case weakPassword
    case wrongPassword
    case userNotFound
    case emailAlreadyInUse
    case firebaseUnavailable
    case network
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Enter a valid email address."
        case .weakPassword:
            return "Password must be at least 6 characters."
        case .wrongPassword:
            return "Incorrect email or password."
        case .userNotFound:
            return "No account found for that email."
        case .emailAlreadyInUse:
            return "An account already exists for that email."
        case .firebaseUnavailable:
            return "Sign-in is not available right now."
        case .network:
            return "Network error. Check your connection and try again."
        case .unknown(let message):
            return message
        }
    }
}
