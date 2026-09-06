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
                    rewards.syncRedemptionCatalog(appConfig.redemption.items)

                    if ScreenshotDemo.isEnabled {
                        // Skip live Firebase so marketing shots stay deterministic.
                        ScreenshotDemo.applyIfNeeded(
                            storeStatus: storeStatus,
                            rewards: rewards,
                            auth: auth
                        )
                        return
                    }

                    storeStatus.start()
                    appConfig.start()
                    auth.start()
                    await restoreSessionIfNeeded()
                }
                .onChange(of: auth.isSignedIn) { _, isSignedIn in
                    guard !ScreenshotDemo.isEnabled, isSignedIn else { return }
                    Task { await restoreSessionIfNeeded() }
                }
                .onChange(of: appConfig.configVersion) { _, _ in
                    rewards.syncRedemptionCatalog(appConfig.redemption.items)
                }
        }
    }

    @MainActor
    private func restoreSessionIfNeeded() async {
        guard !ScreenshotDemo.isEnabled else { return }
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
