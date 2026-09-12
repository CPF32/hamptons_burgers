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

    private var showsOrderAction: Bool {
        onOrder != nil && !compact
    }

    var body: some View {
        Group {
            if showsOrderAction {
                panelContent
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(panelBackground)
            } else {
                compactContent
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private var panelContent: some View {
        VStack(spacing: 20) {
            inventoryReadout

            if let onOrder {
                Button(action: onOrder) {
                    HStack(spacing: 8) {
                        Text("Order Pickup")
                        Image(systemName: "arrow.up.right")
                            .font(.footnote.weight(.bold))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primaryAction(isEnabled: canOrder, fillsWidth: true))
            }
        }
    }

    /// Editorial inventory board — remaining count first; capacity only drives the bar.
    private var inventoryReadout: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly inventory")
                .font(.caption.weight(.bold))
                .tracking(1.0)
                .textCase(.uppercase)
                .foregroundStyle(Theme.mutedText)

            HStack(alignment: .lastTextBaseline, spacing: 0) {
                Text("\(count)")
                    .font(.system(size: 48, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.primary)
                    .contentTransition(.numericText())
                    .monospacedDigit()

                Text(" remaining")
                    .font(.title3.weight(.regular))
                    .foregroundStyle(Theme.text.opacity(0.72))

                Spacer(minLength: 0)
            }

            progressTrack

            Text(statusLine)
                .font(.caption)
                .foregroundStyle(Theme.mutedText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var progressTrack: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.primary.opacity(0.08))

                Capsule()
                    .fill(Theme.primary.opacity(count <= 0 ? 0.25 : 0.85))
                    .frame(width: max(count > 0 ? 8 : 0, proxy.size.width * level))
            }
        }
        .frame(height: 4)
        .animation(.easeInOut(duration: 0.4), value: level)
    }

    private var compactContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Patties left")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.text)
                Spacer(minLength: 8)
                Text("\(count)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.primary)
                    .monospacedDigit()
            }
            progressTrack
                .frame(height: 3)
        }
    }

    private var statusLine: String {
        if count <= 0 {
            return "Sold out for the week — check back Tuesday at 11:00 AM."
        }
        if level < 0.25 {
            return "Running low — order soon if you can."
        }
        if level < 0.5 {
            return "Going fast — still a solid amount left this week."
        }
        return "Plenty of smash burgers left this week."
    }

    private var accessibilitySummary: String {
        "\(count) patties remaining this week. \(statusLine)"
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Theme.surface)
            .shadow(color: Theme.primary.opacity(0.05), radius: 10, y: 3)
    }
}

#Preview("Healthy") {
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

#Preview("Low") {
    PattyFuelGaugeView(
        compact: false,
        count: 28,
        capacity: 240,
        canOrder: true,
        onOrder: {}
    )
    .padding()
    .background(Theme.background)
}

#Preview("Sold out") {
    PattyFuelGaugeView(
        compact: false,
        count: 0,
        capacity: 240,
        canOrder: false,
        onOrder: {}
    )
    .padding()
    .background(Theme.background)
}
