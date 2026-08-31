import SwiftUI

struct RedemptionCheckoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RewardsStore.self) private var rewards

    @State private var redemptionNonce = UUID().uuidString.lowercased()
    @State private var startingPoints = 0
    @State private var redeemedPoints = 0
    @State private var showSuccess = false
    @State private var didComplete = false

    private var qrPayload: String? {
        rewards.redemptionQRPayload(nonce: redemptionNonce)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Theme.secondary)

                    Text("Redeem in store")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Theme.text)

                    Text("Show this QR code to staff. Points are deducted after they scan it.")
                        .font(.footnote)
                        .foregroundStyle(Theme.mutedText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 12)

                VStack(spacing: 10) {
                    ForEach(rewards.cartLineItems) { line in
                        HStack {
                            Text("\(line.quantity)× \(line.name)")
                                .font(.subheadline)
                                .foregroundStyle(Theme.text)
                            Spacer()
                            Text("\(line.linePoints) pts")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.secondary)
                        }
                    }

                    Divider()

                    HStack {
                        Text("Total")
                            .font(.headline)
                            .foregroundStyle(Theme.text)
                        Spacer()
                        Text("\(rewards.cartTotalPoints) pts")
                            .font(.headline)
                            .foregroundStyle(Theme.secondary)
                    }
                }
                .padding()
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 24)

                if !rewards.cartHasEnoughPoints {
                    Text("You need \(rewards.cartTotalPoints - rewards.account.points) more points to redeem this order.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                } else if let payload = qrPayload {
                    QRCodeImageView(payload: payload, size: 200)
                }

                if showSuccess {
                    Text("Redemption complete. \(redeemedPoints) points were deducted.")
                        .font(.footnote)
                        .foregroundStyle(.green)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding(24)
            .background(Theme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                startingPoints = rewards.account.points
                redeemedPoints = rewards.cartTotalPoints
            }
            .onChange(of: rewards.account.points) { _, newPoints in
                guard !didComplete,
                      redeemedPoints > 0,
                      newPoints == startingPoints - redeemedPoints else { return }
                didComplete = true
                showSuccess = true
                Task {
                    await rewards.completeRedemptionAfterScan(nonce: redemptionNonce)
                    try? await Task.sleep(for: .seconds(1.5))
                    dismiss()
                }
            }
        }
    }
}
