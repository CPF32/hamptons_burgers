import SwiftUI

struct FAQView: View {
    @Environment(AppConfigStore.self) private var appConfig

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.sectionGap) {
                VStack(alignment: .leading, spacing: 12) {
                    TabSectionHeader(title: "FAQ", systemImage: "questionmark.circle.fill")

                    ForEach(appConfig.faq.items) { item in
                        DisclosureGroup {
                            Text(item.answer)
                                .font(.body)
                                .foregroundStyle(Theme.mutedText)
                                .padding(.vertical, 4)
                        } label: {
                            Text(item.question)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.text)
                        }
                        .tint(Theme.primary)
                    }
                }
                .tabFirstSectionCard()
            }
            .padding(.vertical, Theme.sectionGap)
        }
        .background(Theme.background.ignoresSafeArea())
    }
}

#Preview {
    FAQView()
        .environment(AppConfigStore())
}
