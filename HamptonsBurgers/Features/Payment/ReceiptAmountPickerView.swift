import SwiftUI

struct ReceiptAmountPickerView: View {
    let candidates: [ReceiptAmountCandidate]
    let onSelect: (Double) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                if candidates.isEmpty {
                    ContentUnavailableView(
                        "No amounts found",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Enter the subtotal manually.")
                    )
                } else {
                    List(candidates) { candidate in
                        Button {
                            onSelect(candidate.amount)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(candidate.kind.rawValue)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(kindColor(candidate.kind))

                                    Text(candidate.label)
                                        .font(.subheadline)
                                        .foregroundStyle(Theme.text)
                                        .multilineTextAlignment(.leading)
                                }

                                Spacer()

                                Text("$\(formatted(candidate.amount))")
                                    .font(.headline.monospacedDigit())
                                    .foregroundStyle(Theme.text)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Pick subtotal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }

    private func formatted(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    private func kindColor(_ kind: ReceiptAmountCandidate.Kind) -> Color {
        switch kind {
        case .subtotal: Theme.primary
        case .tax, .tip, .total: Theme.mutedText
        case .items, .other: Theme.secondary
        }
    }
}
