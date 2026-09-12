import SwiftUI

struct OrderView: View {
    @Environment(StoreStatusStore.self) private var store

    @State private var showOrdering = false
    @State private var showMissingToastURL = false
    @State private var showBlockedAlert = false
    @State private var showAdminPIN = false
    @State private var showAdminPanel = false
    @State private var appeared = false

    private var canOrder: Bool {
        store.status.canPlaceOrder()
    }

    var body: some View {
        GeometryReader { geo in
            let metrics = OrderLayoutMetrics(size: geo.size)

            ZStack {
                atmosphere

                VStack(spacing: 0) {
                    Spacer(minLength: metrics.edgeBreathingRoom)

                    VStack(spacing: metrics.stackSpacing) {
                        brandBlock(logoSize: metrics.logoSize)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 8)

                        PattyFuelGaugeView(
                            compact: false,
                            count: store.status.pattyCount,
                            capacity: store.status.pattyCapacity,
                            canOrder: canOrder,
                            onOrder: handleOrderTap
                        )
                        .frame(maxWidth: metrics.contentWidth)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                        .animation(
                            .spring(response: 0.55, dampingFraction: 0.88).delay(0.06),
                            value: appeared
                        )
                    }

                    Spacer(minLength: metrics.edgeBreathingRoom)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, metrics.horizontalPadding)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
        .toastSafari(isPresented: $showOrdering, url: BrandConfig.toastOrderingURL)
        .sheet(isPresented: $showAdminPIN) {
            AdminPinView {
                showAdminPanel = true
            }
        }
        .sheet(isPresented: $showAdminPanel) {
            AdminView()
        }
        .alert(store.status.orderBlockedTitle(), isPresented: $showBlockedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.status.orderBlockedMessage())
        }
        .alert("Toast URL not set", isPresented: $showMissingToastURL) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Set BrandConfig.toastOrderingURL to your restaurant’s Toast Online Ordering link (from Toast Web → Takeout & delivery → Restaurant info), then rebuild.")
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                appeared = true
            }
        }
    }

    private func handleOrderTap() {
        guard BrandConfig.isToastOrderingConfigured else {
            showMissingToastURL = true
            return
        }

        if canOrder {
            showOrdering = true
        } else {
            showBlockedAlert = true
        }
    }

    private var atmosphere: some View {
        LinearGradient(
            colors: [
                Theme.background,
                Theme.secondary.opacity(0.07),
                Theme.background
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func brandBlock(logoSize: CGFloat) -> some View {
        VStack(spacing: 18) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: logoSize, height: logoSize)
                .accessibilityLabel("\(BrandConfig.appName) logo")
                .adminLogoTapToUnlock(onUnlock: { showAdminPIN = true })

            orderTagline
        }
    }

    /// Single-line brand lockup — scales down slightly on narrow phones so nothing clips.
    private var orderTagline: some View {
        Text(BrandConfig.orderTaglines.joined(separator: " · "))
            .font(.caption2.weight(.semibold))
            .tracking(0.6)
            .textCase(.uppercase)
            .foregroundStyle(Theme.text.opacity(0.62))
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .minimumScaleFactor(0.65)
            .allowsTightening(true)
            .padding(.horizontal, 2)
    }
}

/// Keeps Order tab proportions stable from SE-class phones through Pro Max.
private struct OrderLayoutMetrics {
    let size: CGSize

    var horizontalPadding: CGFloat {
        size.width < 360 ? 20 : 24
    }

    var contentWidth: CGFloat {
        min(360, size.width - (horizontalPadding * 2))
    }

    var logoSize: CGFloat {
        if size.height < 700 {
            return 148
        }
        if size.height < 780 {
            return 168
        }
        if size.height < 900 {
            return 186
        }
        return 198
    }

    var stackSpacing: CGFloat {
        size.height < 700 ? 28 : 36
    }

    var edgeBreathingRoom: CGFloat {
        size.height < 700 ? 20 : 28
    }
}

#Preview("SE-ish") {
    OrderView()
        .environment(StoreStatusStore())
        .frame(width: 320, height: 568)
}

#Preview("Pro") {
    OrderView()
        .environment(StoreStatusStore())
        .frame(width: 393, height: 852)
}

#Preview("Pro Max") {
    OrderView()
        .environment(StoreStatusStore())
        .frame(width: 430, height: 932)
}
