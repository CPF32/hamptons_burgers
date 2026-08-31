import Foundation
#if canImport(FirebaseCore)
import FirebaseCore
#endif

enum AppFirebaseEnvironment: String {
    case dev = "Dev"
    case prod = "Prod"

    var displayName: String {
        switch self {
        case .dev: return "Development"
        case .prod: return "Production"
        }
    }
}

enum FirebaseBootstrap {
    private static var didConfigure = false

    /// Injected by Xcode: Debug → Dev, Release → Prod.
    static var environment: AppFirebaseEnvironment {
        #if DEBUG
        return .dev
        #else
        return .prod
        #endif
    }

    static var projectID: String? {
        guard let dictionary = googleServiceInfoDictionary(),
              let projectID = dictionary["PROJECT_ID"] as? String,
              !projectID.isEmpty,
              !projectID.hasPrefix("REPLACE"),
              projectID != "your-project-id" else {
            return nil
        }
        return projectID
    }

    static var isSDKAvailable: Bool {
        #if canImport(FirebaseCore) && canImport(FirebaseFirestore)
        true
        #else
        false
        #endif
    }

    static var isConfigured: Bool {
        isSDKAvailable && projectID != nil
    }

    static func configureIfNeeded() {
        #if canImport(FirebaseCore)
        guard isConfigured, !didConfigure else { return }
        FirebaseApp.configure()
        didConfigure = true
        #endif
    }

    private static func googleServiceInfoDictionary() -> [String: Any]? {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let dictionary = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            return nil
        }
        return dictionary
    }
}
