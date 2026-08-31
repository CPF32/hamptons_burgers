import SwiftUI

struct AdminView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RewardsStore.self) private var rewards
    @Environment(AppConfigStore.self) private var appConfig

    @State private var contentDraft: AppContent
    @State private var showContentSavedAlert = false
    @State private var contentPublishError: String?
    @State private var isPublishingContent = false

    init() {
        _contentDraft = State(initialValue: .bundled())
    }

    var body: some View {
        NavigationStack {
            Form {
                AdminLocationSection(location: $contentDraft.location)
                AdminHoursSection(hours: $contentDraft.location.hours)
                AdminFAQSection(items: $contentDraft.faq.items)
                AdminRedemptionSection(items: $contentDraft.redemption.items)
                AdminEmailsSection(adminEmails: $contentDraft.adminEmails)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Content admin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isPublishingContent ? "Publishing…" : "Publish") {
                        Task { await publishContent() }
                    }
                    .disabled(isPublishingContent || !FirebaseBootstrap.isConfigured)
                }
            }
            .alert("Content published", isPresented: $showContentSavedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Location, hours, contact, FAQ, redemption menu, and admin access updates are syncing to all devices.")
            }
            .alert("Could not publish", isPresented: publishErrorPresented) {
                Button("OK", role: .cancel) {
                    contentPublishError = nil
                }
            } message: {
                if let contentPublishError {
                    Text(contentPublishError)
                }
            }
        }
        .onAppear {
            contentDraft = appConfig.content
        }
    }

    private var publishErrorPresented: Binding<Bool> {
        Binding(
            get: { contentPublishError != nil },
            set: { isPresented in
                if !isPresented {
                    contentPublishError = nil
                }
            }
        )
    }

    private func publishContent() async {
        isPublishingContent = true
        contentPublishError = nil
        defer { isPublishingContent = false }

        do {
            try await appConfig.publishContent(contentDraft)
            contentDraft = appConfig.content
            rewards.syncRedemptionCatalog(appConfig.redemption.items)
            showContentSavedAlert = true
        } catch {
            contentPublishError = error.localizedDescription
        }
    }
}
