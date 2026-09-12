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
                    Spacer(minLength: metrics.topBreathingRoom)

                    brandBlock(logoSize: metrics.logoSize)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)

                    Spacer(minLength: metrics.midBreathingRoom)

                    PattyFuelGaugeView(
                        compact: false,
                        count: store.status.pattyCount,
                        capacity: store.status.pattyCapacity,
                        canOrder: canOrder,
                        onOrder: handleOrderTap
                    )
                    .frame(maxWidth: metrics.contentWidth)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)

                    Spacer(minLength: metrics.bottomBreathingRoom)
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
            withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
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
        ZStack {
            Theme.background

            RadialGradient(
                colors: [
                    Theme.secondary.opacity(0.16),
                    Theme.secondary.opacity(0.05),
                    .clear
                ],
                center: .top,
                startRadius: 20,
                endRadius: 320
            )
            .offset(y: -40)

            RadialGradient(
                colors: [
                    Theme.primary.opacity(0.06),
                    .clear
                ],
                center: .bottom,
                startRadius: 40,
                endRadius: 280
            )
            .offset(y: 80)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func brandBlock(logoSize: CGFloat) -> some View {
        VStack(spacing: metricsSpacing(for: logoSize)) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: logoSize, height: logoSize)
                .shadow(color: Theme.primary.opacity(0.10), radius: 20, y: 8)
                .accessibilityLabel("\(BrandConfig.appName) logo")
                .adminLogoTapToUnlock(onUnlock: { showAdminPIN = true })

            orderTagline
        }
    }

    private func metricsSpacing(for logoSize: CGFloat) -> CGFloat {
        logoSize < 150 ? 12 : 16
    }

    private var orderTagline: some View {
        VStack(spacing: 7) {
            ForEach(Array(BrandConfig.orderTaglines.enumerated()), id: \.element) { index, line in
                Text(line)
                    .font(.subheadline.weight(.medium))
                    .tracking(0.4)
                    .foregroundStyle(Theme.text.opacity(0.78))
                    .minimumScaleFactor(0.9)
                    .lineLimit(1)

                if index < BrandConfig.orderTaglines.count - 1 {
                    Capsule()
                        .fill(Theme.secondary.opacity(0.55))
                        .frame(width: 18, height: 2)
                }
            }
        }
        .multilineTextAlignment(.center)
    }
}

/// Keeps Order tab proportions stable from SE-class phones through Pro Max.
private struct OrderLayoutMetrics {
    let size: CGSize

    var horizontalPadding: CGFloat {
        size.width < 360 ? 20 : 28
    }

    var contentWidth: CGFloat {
        min(340, size.width - (horizontalPadding * 2))
    }

    var logoSize: CGFloat {
        // Short phones (SE / mini landscape-ish heights) shrink first.
        if size.height < 700 {
            return 132
        }
        if size.height < 780 {
            return 156
        }
        if size.height < 900 {
            return 176
        }
        return 188
    }

    var topBreathingRoom: CGFloat {
        size.height < 700 ? 12 : 20
    }

    var midBreathingRoom: CGFloat {
        size.height < 700 ? 16 : 24
    }

    var bottomBreathingRoom: CGFloat {
        size.height < 700 ? 12 : 20
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
