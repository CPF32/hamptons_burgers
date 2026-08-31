import SwiftUI

struct PattyFuelGaugeView: View {
    var compact: Bool = false
    let count: Int
    let capacity: Int

    private var level: Double {
        guard capacity > 0 else { return 0 }
        return min(1, max(0, Double(count) / Double(capacity)))
    }

    private var gaugeColor: Color {
        switch level {
        case 0: return .red
        case ..<0.25: return .orange
        case ..<0.5: return .yellow
        default: return .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 5 : 8) {
            HStack {
                Text("Patties left")
                    .font(compact ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
                    .foregroundStyle(Theme.text)
                Spacer()
                Text("\(count)")
                    .font(compact ? .caption.weight(.bold) : .subheadline.weight(.bold))
                    .foregroundStyle(Theme.primary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.background)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [gaugeColor.opacity(0.85), gaugeColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(compact ? 12 : 18, proxy.size.width * level))
                }
            }
            .frame(height: compact ? 12 : 18)

            if !compact {
                Text(gaugeCaption)
                    .font(.caption)
                    .foregroundStyle(Theme.mutedText)
            }
        }
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
    PattyFuelGaugeView(compact: true, count: 24, capacity: 100)
        .frame(maxWidth: Theme.pattyGaugeMaxWidth)
        .padding()
}
