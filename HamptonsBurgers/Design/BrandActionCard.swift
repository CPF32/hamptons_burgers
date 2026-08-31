import SwiftUI

/// Groups the logo and primary actions in a card, used on Order and Account.
struct BrandActionCard<Actions: View>: View {
    var logoSize: CGFloat = 160
    var actionsHeight: CGFloat? = Theme.actionCardActionsHeight
    var onLogoTap: (() -> Void)?
    @ViewBuilder var actions: () -> Actions

    var body: some View {
        VStack(spacing: 20) {
            Group {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: logoSize, height: logoSize)
                    .accessibilityLabel("\(BrandConfig.appName) logo")
            }
            .modifier(LogoTapModifier(onLogoTap: onLogoTap))

            Group {
                if let actionsHeight {
                    actions()
                        .frame(maxWidth: .infinity)
                        .frame(height: actionsHeight, alignment: .top)
                } else {
                    actions()
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 26)
        .frame(maxWidth: 320)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Theme.primary.opacity(0.08), radius: 12, y: 4)
        .padding(.horizontal, 24)
    }
}

private struct LogoTapModifier: ViewModifier {
    let onLogoTap: (() -> Void)?

    func body(content: Content) -> some View {
        if let onLogoTap {
            content.adminLogoTapToUnlock(onUnlock: onLogoTap)
        } else {
            content
        }
    }
}
