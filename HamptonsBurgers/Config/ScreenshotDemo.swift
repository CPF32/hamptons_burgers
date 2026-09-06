import Foundation

/// Launch-arg helpers for App Store marketing screenshots.
/// Pass `-ScreenshotDemo` (and optionally `-ScreenshotTab <tab>`) via the simulator.
enum ScreenshotDemo {
    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("-ScreenshotDemo")
    }

    @MainActor
    static func applyIfNeeded(
        storeStatus: StoreStatusStore,
        rewards: RewardsStore,
        auth: AuthStore
    ) {
        guard isEnabled else { return }
        auth.applyScreenshotDemo()
        rewards.applyScreenshotDemo()
        storeStatus.applyScreenshotDemo()
    }
}
