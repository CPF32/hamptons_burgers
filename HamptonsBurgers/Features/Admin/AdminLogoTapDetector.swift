import SwiftUI

struct AdminLogoTapDetector: ViewModifier {
    let onUnlock: () -> Void

    @State private var tapCount = 0
    @State private var resetTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .onTapGesture {
                tapCount += 1
                resetTask?.cancel()
                resetTask = Task {
                    try? await Task.sleep(for: .seconds(2))
                    if !Task.isCancelled {
                        tapCount = 0
                    }
                }
                if tapCount >= 5 {
                    tapCount = 0
                    resetTask?.cancel()
                    onUnlock()
                }
            }
    }
}

extension View {
    func adminLogoTapToUnlock(onUnlock: @escaping () -> Void) -> some View {
        modifier(AdminLogoTapDetector(onUnlock: onUnlock))
    }
}
