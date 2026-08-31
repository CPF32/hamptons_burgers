import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: Theme.buttonMaxWidth)
            .padding(.vertical, 16)
            .background(Theme.primary.opacity(isEnabled ? 1 : 0.45))
            .foregroundStyle(.white.opacity(isEnabled ? 1 : 0.85))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(isEnabled && configuration.isPressed ? 0.85 : 1)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primaryAction: PrimaryButtonStyle { PrimaryButtonStyle() }

    static func primaryAction(isEnabled: Bool) -> PrimaryButtonStyle {
        PrimaryButtonStyle(isEnabled: isEnabled)
    }
}
