import SwiftUI

struct AdminPinView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreStatusStore.self) private var store

    @State private var pin = ""
    @State private var showError = false

    var onSuccess: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Admin Access")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Theme.text)

                SecureField("PIN", text: $pin)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .multilineTextAlignment(.center)
                    .font(.title3.monospacedDigit())
                    .padding()
                    .background(Theme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Button("Unlock") {
                    if store.authenticateAdmin(pin: pin) {
                        dismiss()
                        onSuccess()
                    } else {
                        showError = true
                        pin = ""
                    }
                }
                .buttonStyle(.primaryAction)
                .disabled(pin.count < 4)

                if showError {
                    Text("Incorrect PIN.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Spacer()
            }
            .padding(24)
            .background(Theme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
