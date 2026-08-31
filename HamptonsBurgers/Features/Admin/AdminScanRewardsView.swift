import SwiftUI

struct AdminScanRewardsView: View {
    enum Presentation {
        case sheet
        case tab
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(RewardsStore.self) private var rewards

    var presentation: Presentation = .sheet

    @State private var scannedPayload: RewardsQRCode.Payload?
    @State private var purchaseAmount = ""
    @State private var statusMessage: String?
    @State private var isProcessing = false
    @State private var showScanner = true

    private var navigationTitle: String {
        presentation == .tab ? "Scan" : "Scan rewards QR"
    }

    var body: some View {
        NavigationStack {
            Group {
                if showScanner {
                    QRCodeScannerView(
                        onScan: handleScan,
                        onCancel: handleScannerCancel
                    )
                    .ignoresSafeArea()
                } else if let payload = scannedPayload {
                    form(for: payload)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !showScanner {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Scan again") {
                            resetForNewScan()
                        }
                    }
                    if presentation == .sheet {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Close") { dismiss() }
                        }
                    }
                }
            }
        }
    }

    private func handleScannerCancel() {
        if presentation == .sheet {
            dismiss()
        }
    }

    @ViewBuilder
    private func form(for payload: RewardsQRCode.Payload) -> some View {
        Form {
            switch payload {
            case .member(let email, let subtotal):
                Section("Guest") {
                    Text(email)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }

                Section("Credit points") {
                    if let subtotal {
                        LabeledContent("From QR") {
                            Text("$\(String(format: "%.2f", subtotal))")
                                .font(.headline.monospacedDigit())
                        }
                    }

                    TextField("Purchase amount ($)", text: $purchaseAmount)
                        .keyboardType(.decimalPad)

                    Text(subtotal == nil
                         ? "No amount on this QR — enter the receipt subtotal."
                         : "Confirm or edit the subtotal before crediting.")
                        .font(.caption)
                        .foregroundStyle(Theme.mutedText)

                    Button(isProcessing ? "Crediting…" : "Add points") {
                        Task { await creditMember(email: email) }
                    }
                    .disabled(isProcessing || Double(purchaseAmount) == nil)
                }

            case .redeem(let email, let points, let nonce):
                Section("Redemption") {
                    LabeledContent("Guest") {
                        Text(email)
                            .font(.caption.monospaced())
                    }
                    LabeledContent("Points") {
                        Text("\(points)")
                            .font(.headline.monospacedDigit())
                    }
                }

                Section {
                    Button(isProcessing ? "Processing…" : "Confirm redemption") {
                        Task { await redeem(email: email, points: points, nonce: nonce) }
                    }
                    .disabled(isProcessing)
                }
            }

            if let statusMessage {
                Section {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(statusMessage.hasPrefix("Added") || statusMessage.hasPrefix("Recorded") || statusMessage.hasPrefix("Redeemed")
                            ? .green
                            : .red)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
    }

    private func handleScan(_ raw: String) {
        guard let payload = RewardsQRCode.parse(raw) else {
            statusMessage = "Unrecognized QR code."
            showScanner = false
            return
        }
        scannedPayload = payload
        statusMessage = nil
        switch payload {
        case .member(_, let subtotal):
            purchaseAmount = subtotal.map { String(format: "%.2f", $0) } ?? ""
        case .redeem:
            purchaseAmount = ""
        }
        showScanner = false
    }

    private func resetForNewScan() {
        scannedPayload = nil
        purchaseAmount = ""
        statusMessage = nil
        showScanner = true
    }

    private func creditMember(email: String) async {
        guard let dollars = Double(purchaseAmount), dollars > 0 else {
            statusMessage = "Enter a valid purchase amount."
            return
        }

        isProcessing = true
        defer { isProcessing = false }

        do {
            let earned = try await rewards.adminCreditPoints(email: email, dollars: dollars)
            statusMessage = earned == 0
                ? "Recorded $\(String(format: "%.2f", dollars)) toward next point for \(email)."
                : "Added \(earned) points to \(email)."
            purchaseAmount = ""
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func redeem(email: String, points: Int, nonce: String) async {
        isProcessing = true
        defer { isProcessing = false }

        do {
            try await rewards.adminRedeemPoints(email: email, points: points, nonce: nonce)
            statusMessage = "Redeemed \(points) points for \(email)."
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}
