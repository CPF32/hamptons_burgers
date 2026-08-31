import SwiftUI

struct TabSectionHeader: View {
    let title: String
    let systemImage: String
    var trailing: AnyView?

    init(title: String, systemImage: String) {
        self.title = title
        self.systemImage = systemImage
        self.trailing = nil
    }

    init<Trailing: View>(title: String, systemImage: String, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.systemImage = systemImage
        self.trailing = AnyView(trailing())
    }

    var body: some View {
        HStack(alignment: .center) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .foregroundStyle(Theme.secondary)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Theme.text)
            }

            Spacer()

            if let trailing {
                trailing
            }
        }
    }
}

private struct SectionCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .frame(maxWidth: 360)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Theme.primary.opacity(0.06), radius: 8, y: 3)
            .padding(.horizontal, 20)
    }
}

extension View {
    func sectionCard() -> some View {
        modifier(SectionCardModifier())
    }

    func tabFirstSectionCard() -> some View {
        frame(maxWidth: .infinity, minHeight: Theme.tabFirstSectionMinHeight, alignment: .top)
            .sectionCard()
    }
}
