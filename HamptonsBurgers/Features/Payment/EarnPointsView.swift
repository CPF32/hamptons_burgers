import SwiftUI

struct EarnPointsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RewardsStore.self) private var rewards

    @State private var subtotalText = ""
    @State private var showCamera = false
    @State private var isScanning = false
    @State private var scanError: String?

    private var subtotal: Double? {
        guard let value = Double(subtotalText), value > 0 else { return nil }
        return RewardsPointsMath.roundToCents(value)
    }

    private var qrPayload: String? {
        guard let email = rewards.account.email,
              let subtotal,
              rewards.hasRegisteredEmail else { return nil }
        return RewardsQRCode.memberPayload(email: email, subtotal: subtotal)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 44))
                            .foregroundStyle(Theme.secondary)

                        Text("Earn points")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Theme.text)

                        Text("Scan your receipt subtotal, confirm the amount, then show the QR code to staff.")
                            .font(.footnote)
                            .foregroundStyle(Theme.mutedText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    Button {
                        showCamera = true
                    } label: {
                        Label(isScanning ? "Reading receipt…" : "Scan receipt", systemImage: "camera.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.primary)
                            .foregroundStyle(Theme.onPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .disabled(isScanning)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Subtotal (before tax & tip)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.text)

                        TextField("0.00", text: $subtotalText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .font(.title3.monospacedDigit())
                            .padding()
                            .background(Theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    if let scanError {
                        Text(scanError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    if let subtotal, let payload = qrPayload {
                        VStack(spacing: 12) {
                            Text("$\(formatted(subtotal)) subtotal")
                                .font(.title2.weight(.bold).monospacedDigit())
                                .foregroundStyle(Theme.text)

                            Text("Show this to staff to earn points.")
                                .font(.caption)
                                .foregroundStyle(Theme.mutedText)

                            QRCodeImageView(payload: payload, size: 200)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(24)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                ReceiptCameraCaptureView(
                    onImage: { image in
                        showCamera = false
                        Task { await processReceipt(image) }
                    },
                    onCancel: { showCamera = false }
                )
                .ignoresSafeArea()
            }
        }
    }

    private func formatted(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    private func processReceipt(_ image: UIImage) async {
        isScanning = true
        scanError = nil
        defer { isScanning = false }

        do {
            if let detected = try await ReceiptTextRecognizer.parseSubtotal(from: image) {
                subtotalText = formatted(detected)
            } else {
                scanError = "Couldn't find a subtotal on this receipt. Enter the amount manually."
            }
        } catch {
            scanError = "Couldn't read the receipt. Enter the amount manually."
        }
    }
}
