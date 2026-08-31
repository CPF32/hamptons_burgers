import SwiftUI

@main
struct HamptonsBurgersApp: App {
    @State private var storeStatus = StoreStatusStore()
    @State private var rewards = RewardsStore()
    @State private var appConfig = AppConfigStore()
    @State private var auth = AuthStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(storeStatus)
                .environment(rewards)
                .environment(appConfig)
                .environment(auth)
                .preferredColorScheme(.light)
                .task {
                    storeStatus.start()
                    appConfig.start()
                    auth.start()
                    rewards.syncRedemptionCatalog(appConfig.redemption.items)
                    await restoreSessionIfNeeded()
                }
                .onChange(of: auth.isSignedIn) { _, isSignedIn in
                    if isSignedIn {
                        Task { await restoreSessionIfNeeded() }
                    }
                }
                .onChange(of: appConfig.configVersion) { _, _ in
                    rewards.syncRedemptionCatalog(appConfig.redemption.items)
                }
        }
    }

    @MainActor
    private func restoreSessionIfNeeded() async {
        guard auth.isSignedIn,
              let userID = auth.userID,
              let email = auth.userEmail else { return }

        do {
            try await rewards.restoreSession(userID: userID, email: email)
        } catch {
            await rewards.recordSyncError(error.localizedDescription)
        }
    }
}
