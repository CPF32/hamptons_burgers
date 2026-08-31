import SwiftUI

struct AdminStoreStatusView: View {
    @Environment(StoreStatusStore.self) private var store

    @State private var statusDraft = StoreStatus.default
    @State private var showStatusSavedAlert = false

    var body: some View {
        Form {
            AdminStoreStatusSection(status: $statusDraft)

            if let error = store.lastSyncError {
                Section {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Admin")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(store.isSyncing ? "Saving…" : "Publish") {
                    Task { await publishStatus() }
                }
                .disabled(store.isSyncing)
            }
        }
        .alert("Status published", isPresented: $showStatusSavedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Live store status, patty count, and notices are syncing to all guest devices.")
        }
        .onAppear {
            statusDraft = store.status
        }
    }

    private func publishStatus() async {
        await store.save(statusDraft)
        showStatusSavedAlert = true
    }
}

struct AdminStoreStatusSection: View {
    @Binding var status: StoreStatus

    var body: some View {
        Section("Live store status") {
            Toggle("Off day (closed)", isOn: $status.isOffDay)
            Toggle("Sold out", isOn: $status.isSoldOut)
                .onChange(of: status.isSoldOut) { _, isSoldOut in
                    if isSoldOut {
                        status.pattyCount = 0
                    } else {
                        status.pattyCount = BrandConfig.defaultPattyCapacity
                        status.pattyCapacity = BrandConfig.defaultPattyCapacity
                    }
                }

            Stepper("Patties left: \(status.pattyCount)", value: $status.pattyCount, in: 0...max(status.pattyCapacity, 1))
            Stepper("Weekly capacity: \(status.pattyCapacity)", value: $status.pattyCapacity, in: 1...1000)
                .onChange(of: status.pattyCapacity) { _, newValue in
                    status.pattyCount = min(status.pattyCount, newValue)
                }

            HStack(spacing: 12) {
                Button("-10") { status.pattyCount = max(0, status.pattyCount - 10) }
                Button("-1") { status.pattyCount = max(0, status.pattyCount - 1) }
                Button("+1") {
                    status.pattyCount = min(status.pattyCapacity, status.pattyCount + 1)
                }
                Button("+10") {
                    status.pattyCount = min(status.pattyCapacity, status.pattyCount + 10)
                }
            }
            .buttonStyle(.bordered)

            TextField("Notice title (optional)", text: $status.noticeTitle)
            TextField("Customer notice message", text: $status.noticeBody, axis: .vertical)
                .lineLimit(3...6)

            TextField("Order button message when disabled", text: $status.orderClosedMessage, axis: .vertical)
                .lineLimit(2...5)

            Text("Syncs live to all guests via Firestore. Tap Publish when you're done.")
                .font(.caption)
                .foregroundStyle(Theme.mutedText)
        }
    }
}
