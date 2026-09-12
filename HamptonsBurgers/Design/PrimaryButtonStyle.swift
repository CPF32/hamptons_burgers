import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true
    var fillsWidth: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .tracking(0.3)
            .frame(maxWidth: fillsWidth ? .infinity : Theme.buttonMaxWidth)
            .padding(.vertical, 17)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.primary.opacity(isEnabled ? 1 : 0.45))
            )
            .foregroundStyle(Theme.onPrimary.opacity(isEnabled ? 1 : 0.85))
            .scaleEffect(isEnabled && configuration.isPressed ? 0.97 : 1)
            .opacity(isEnabled && configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primaryAction: PrimaryButtonStyle { PrimaryButtonStyle() }

    static func primaryAction(isEnabled: Bool, fillsWidth: Bool = false) -> PrimaryButtonStyle {
        PrimaryButtonStyle(isEnabled: isEnabled, fillsWidth: fillsWidth)
    }
}
