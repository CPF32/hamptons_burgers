import SwiftUI

struct StoreNoticeBanner: View {
    var systemImage: String = "megaphone.fill"
    let title: String
    let bodyText: String
    var onDismiss: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let onDismiss {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.body)
                            .foregroundStyle(Theme.mutedText)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Dismiss")
                }
            }

            Text(bodyText)
                .font(.footnote)
                .foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.primary.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Theme.primary.opacity(0.12), radius: 8, y: 3)
    }
}

#Preview {
    StoreNoticeBanner(
        title: "Sold Out",
        bodyText: "Sorry, we've sold out for the week. Check back Tuesday at 11:00 AM.",
        onDismiss: {}
    )
    .padding()
}
