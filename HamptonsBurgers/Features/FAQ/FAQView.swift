import SwiftUI

struct FAQView: View {
    private let items = ContentConfig.faq.items

    var body: some View {
        NavigationStack {
            List {
                ForEach(items) { item in
                    DisclosureGroup {
                        Text(item.answer)
                            .font(.body)
                            .foregroundStyle(Theme.mutedText)
                            .padding(.vertical, 4)
                    } label: {
                        Text(item.question)
                            .font(.headline)
                            .foregroundStyle(Theme.text)
                    }
                    .listRowBackground(Theme.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("FAQ")
        }
    }
}

#Preview {
    FAQView()
}
