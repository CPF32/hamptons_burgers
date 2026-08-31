import SwiftUI

struct PaymentView: View {
    @Environment(RewardsStore.self) private var rewards
    @Environment(AppConfigStore.self) private var appConfig
    @Environment(AuthStore.self) private var auth

    @State private var showRedemptionCheckout = false
    @State private var showEarnPoints = false

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
        .sectionCard()
    }

    private func redemptionRow(_ item: RedemptionItem) -> some View {
        let quantity = rewards.quantityInCart(for: item.id)

        return HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.text)
                Text("\(item.pointsCost) pts each")
                    .font(.caption)
                    .foregroundStyle(Theme.mutedText)
            }

            Spacer()

            HStack(spacing: 12) {
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
                    .frame(minWidth: 20)

                Button {
                    rewards.addToCart(item)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Theme.background.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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

#Preview {
    PaymentView()
        .environment(RewardsStore())
        .environment(AppConfigStore())
        .environment(AuthStore())
}
