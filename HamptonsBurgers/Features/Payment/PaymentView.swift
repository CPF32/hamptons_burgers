import SwiftUI
import UIKit

struct PaymentView: View {
    @Environment(RewardsStore.self) private var rewards
    @Environment(AppConfigStore.self) private var appConfig
    @Environment(AuthStore.self) private var auth
    @Environment(\.sizeCategory) private var sizeCategory

    @State private var showRedemptionCheckout = false
    @State private var showEarnPoints = false
    @State private var nameColumnWidth: CGFloat = 0
    @State private var sharedNameFontSize: CGFloat = UIFont.preferredFont(forTextStyle: .subheadline).pointSize

    private var redemptionItems: [RedemptionItem] {
        appConfig.redemption.items
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: Theme.sectionGap) {
                    rewardsSection
                    redeemSection

                    if !rewards.pointsHistory.isEmpty {
                        transactionHistorySection
                    }
                }
                .padding(.vertical, Theme.sectionGap)
                .padding(.bottom, rewards.hasItemsInCart ? 88 : 0)
            }

            if rewards.hasItemsInCart {
                cartBar
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .sheet(isPresented: $showRedemptionCheckout) {
            RedemptionCheckoutView()
        }
        .sheet(isPresented: $showEarnPoints) {
            EarnPointsView()
        }
        .onChange(of: nameColumnWidth) { _, _ in
            updateSharedNameFontSize()
        }
        .onChange(of: redemptionItems.map(\.id)) { _, _ in
            updateSharedNameFontSize()
        }
        .onChange(of: sizeCategory) { _, _ in
            updateSharedNameFontSize()
        }
    }

    private var rewardsSection: some View {
        VStack(spacing: 16) {
            TabSectionHeader(title: "Rewards", systemImage: "star.fill") {
                Button("Earn points") {
                    showEarnPoints = true
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(auth.isSignedIn ? Theme.primary : Theme.mutedText)
                .disabled(!auth.isSignedIn)
            }

            VStack(spacing: 4) {
                Text("\(rewards.account.points)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.text)
                Text("points available")
                    .font(.subheadline)
                    .foregroundStyle(Theme.mutedText)
            }
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
        }
        .tabFirstSectionCard()
    }

    private var redeemSection: some View {
        VStack(spacing: 12) {
            TabSectionHeader(title: "Redeem in store", systemImage: "gift.fill")

            ForEach(redemptionItems) { item in
                redemptionRow(item)
            }
        }
        .onPreferenceChange(RedemptionNameColumnWidthKey.self) { width in
            if abs(width - nameColumnWidth) > 0.5 {
                nameColumnWidth = width
            }
        }
        .sectionCard()
    }

    private func redemptionRow(_ item: RedemptionItem) -> some View {
        let quantity = rewards.quantityInCart(for: item.id)

        return HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: sharedNameFontSize, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)

                Text("\(item.pointsCost) pts each")
                    .font(.caption)
                    .foregroundStyle(Theme.mutedText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: RedemptionNameColumnWidthKey.self,
                        value: proxy.size.width
                    )
                }
            }

            HStack(spacing: 10) {
                Button {
                    rewards.removeFromCart(item)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(quantity > 0 ? Theme.secondary : Theme.mutedText.opacity(0.4))
                }
                .buttonStyle(.plain)
                .disabled(quantity == 0)

                Text("\(quantity)")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Theme.text)
                    .frame(minWidth: 18)

                Button {
                    rewards.addToCart(item)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.primary)
                }
                .buttonStyle(.plain)
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Theme.background.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func updateSharedNameFontSize() {
        let base = UIFont.preferredFont(forTextStyle: .subheadline).pointSize
        guard nameColumnWidth > 0, !redemptionItems.isEmpty else {
            sharedNameFontSize = base
            return
        }

        let baseFont = UIFont.systemFont(ofSize: base, weight: .semibold)
        let longestNameWidth = redemptionItems
            .map { ($0.name as NSString).size(withAttributes: [.font: baseFont]).width }
            .max() ?? 0

        guard longestNameWidth > 0 else {
            sharedNameFontSize = base
            return
        }

        let scale = min(1, nameColumnWidth / longestNameWidth)
        sharedNameFontSize = max(base * 0.75, (base * scale * 10).rounded(.down) / 10)
    }

    private var cartBar: some View {
        Button {
            showRedemptionCheckout = true
        } label: {
            HStack {
                Image(systemName: "cart.fill")
                Text("\(rewards.cartItemCount) item\(rewards.cartItemCount == 1 ? "" : "s")")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(rewards.cartTotalPoints) pts")
                        .font(.subheadline.weight(.bold))
                    if !rewards.cartHasEnoughPoints {
                        Text("Need \(rewards.cartTotalPoints - rewards.account.points) more pts")
                            .font(.caption2)
                    }
                }
                Image(systemName: "chevron.up")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(Theme.onPrimary)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Theme.primary)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Theme.primary.opacity(0.25), radius: 12, y: -2)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .accessibilityLabel("Open redemption cart, \(rewards.cartItemCount) items, \(rewards.cartTotalPoints) points")
    }

    private var transactionHistorySection: some View {
        VStack(spacing: 12) {
            TabSectionHeader(title: "Recent activity", systemImage: "clock.fill")

            ForEach(rewards.pointsHistory.prefix(10)) { entry in
                HStack {
                    Text(entry.description)
                        .font(.caption)
                        .foregroundStyle(Theme.text)
                        .lineLimit(2)
                    Spacer()
                    Text(entry.delta > 0 ? "+\(entry.delta)" : "\(entry.delta)")
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(entry.delta > 0 ? .green : Theme.mutedText)
                }
            }
        }
        .sectionCard()
    }
}

private struct RedemptionNameColumnWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview {
    PaymentView()
        .environment(RewardsStore())
        .environment(AppConfigStore())
        .environment(AuthStore())
}
