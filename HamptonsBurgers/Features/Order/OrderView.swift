import SwiftUI

struct OrderView: View {
    @Environment(StoreStatusStore.self) private var store

    @State private var showOrdering = false
    @State private var showMissingToastURL = false
    @State private var showBlockedAlert = false
    @State private var showAdminPIN = false
    @State private var showAdminPanel = false

    private var canOrder: Bool {
        store.status.canPlaceOrder()
    }

    var body: some View {
        BrandActionCard(onLogoTap: { showAdminPIN = true }) {
            VStack(spacing: 12) {
                orderTagline

                Spacer(minLength: 0)

                PattyFuelGaugeView(
                    compact: true,
                    count: store.status.pattyCount,
                    capacity: store.status.pattyCapacity
                )

                Spacer(minLength: 28)

                Button {
                    guard BrandConfig.isToastOrderingConfigured else {
                        showMissingToastURL = true
                        return
                    }

                    if canOrder {
                        showOrdering = true
                    } else {
                        showBlockedAlert = true
                    }
                } label: {
                    Text("Order Pickup")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primaryAction(isEnabled: canOrder))
            }
            .frame(maxWidth: Theme.buttonMaxWidth, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
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
    }

    private var orderTagline: some View {
        VStack(spacing: 2) {
            ForEach(BrandConfig.orderTaglines, id: \.self) { line in
                Text(line)
            }
        }
        .font(.subheadline)
        .foregroundStyle(Theme.mutedText)
        .multilineTextAlignment(.center)
    }
}

#Preview {
    OrderView()
        .environment(StoreStatusStore())
}
