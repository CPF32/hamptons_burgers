import SwiftUI

struct PattyFuelGaugeView: View {
    var compact: Bool = false
    let count: Int
    let capacity: Int
    var canOrder: Bool = true
    var onOrder: (() -> Void)? = nil

    private var level: Double {
        guard capacity > 0 else { return 0 }
        return min(1, max(0, Double(count) / Double(capacity)))
    }

    private var gaugeColor: Color {
        switch level {
        case 0: return .red
        case ..<0.25: return .orange
        case ..<0.5: return Color(hex: "E0B84A")
        default: return Color(hex: "3FAE6A")
        }
    }

    private var showsOrderAction: Bool {
        onOrder != nil && !compact
    }

    var body: some View {
        Group {
            if showsOrderAction {
                panelContent
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 16)
                    .frame(maxWidth: .infinity)
                    .background(panelBackground)
            } else {
                gaugeContent
            }
        }
    }

    private var panelContent: some View {
        VStack(spacing: 16) {
            gaugeContent

            if let onOrder {
                Button(action: onOrder) {
                    HStack(spacing: 10) {
                        Text("Order Pickup")
                        Image(systemName: "arrow.up.right")
                            .font(.subheadline.weight(.bold))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primaryAction(isEnabled: canOrder, fillsWidth: true))
                .shadow(
                    color: Theme.primary.opacity(canOrder ? 0.18 : 0),
                    radius: 12,
                    y: 6
                )
            }
        }
    }

    private var gaugeContent: some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Patties left")
                        .font(compact ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
                        .foregroundStyle(Theme.text)
                    if !compact {
                        Text("This week’s smash inventory")
                            .font(.caption2)
                            .foregroundStyle(Theme.mutedText)
                    }
                }

                Spacer(minLength: 8)

                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(count)")
                        .font(compact ? .title3.weight(.bold) : .title.weight(.bold))
                        .foregroundStyle(Theme.primary)
                        .contentTransition(.numericText())
                        .monospacedDigit()
                    if !compact, capacity > 0 {
                        Text("/ \(capacity)")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Theme.mutedText)
                            .monospacedDigit()
                    }
                }
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.primary.opacity(0.08))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    gaugeColor.opacity(0.75),
                                    gaugeColor
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(compact ? 14 : 20, proxy.size.width * level))
                        .shadow(color: gaugeColor.opacity(0.35), radius: 6, y: 0)
                }
            }
            .frame(height: compact ? 10 : 14)

            if !compact {
                Text(gaugeCaption)
                    .font(.caption)
                    .foregroundStyle(Theme.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Theme.surface.opacity(0.78))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Theme.primary.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: Theme.primary.opacity(0.06), radius: 14, y: 4)
    }

    private var gaugeCaption: String {
        if count <= 0 {
            return "Sold out for the week — check back Tuesday at 11:00 AM."
        }
        if level < 0.25 {
            return "Running low — order soon if you can."
        }
        return "Plenty of smash burgers left this week."
    }
}

#Preview {
    PattyFuelGaugeView(
        compact: false,
        count: 168,
        capacity: 240,
        canOrder: true,
        onOrder: {}
    )
    .padding()
    .background(Theme.background)
}
