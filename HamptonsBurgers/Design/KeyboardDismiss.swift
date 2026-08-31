import SwiftUI
import UIKit

/// Window-level tap handling that closes whichever keyboard is open, including
/// the number and decimal pads that ship without a Done key.
@MainActor
final class KeyboardDismissGesture: NSObject, UIGestureRecognizerDelegate {
    static let shared = KeyboardDismissGesture()

    private let installedWindows = NSHashTable<UIWindow>.weakObjects()

    func install(in window: UIWindow) {
        guard !installedWindows.contains(window) else { return }
        installedWindows.add(window)

        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        // The gesture only observes; buttons, maps and the logo unlock tap all
        // still receive the same touch.
        recognizer.cancelsTouchesInView = false
        recognizer.requiresExclusiveTouchType = false
        recognizer.delegate = self
        window.addGestureRecognizer(recognizer)
    }

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard let window = recognizer.view as? UIWindow else { return }
        window.endEditing(true)
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        // Tapping straight from one field to another must not race the new
        // field taking focus.
        var view = touch.view
        while let candidate = view {
            if candidate is UITextInput { return false }
            view = candidate.superview
        }
        return true
    }
}

private struct KeyboardDismissInstaller: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        WindowTrackingView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    final class WindowTrackingView: UIView {
        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard let window else { return }
            KeyboardDismissGesture.shared.install(in: window)
        }
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        background {
            KeyboardDismissInstaller()
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
        }
    }
}
