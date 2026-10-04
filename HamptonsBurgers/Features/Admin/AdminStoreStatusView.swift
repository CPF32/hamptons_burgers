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
            Text("Live store status, daily patty count, and notices are syncing to all guest devices.")
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

            Toggle("Sold out for today", isOn: $status.isSoldOutForDay)
                .onChange(of: status.isSoldOutForDay) { _, isSoldOutForDay in
                    if isSoldOutForDay {
                        status.dailyPattyCount = 0
                    } else {
                        status.dailyPattyCount = status.dailyPattyCapacity
                    }
                }

            Toggle("Sold out for the week", isOn: $status.isSoldOutForWeek)

            Stepper("Patties left today: \(status.dailyPattyCount)", value: $status.dailyPattyCount, in: 0...max(status.dailyPattyCapacity, 1))
            Stepper("Daily capacity: \(status.dailyPattyCapacity)", value: $status.dailyPattyCapacity, in: 1...1000)
                .onChange(of: status.dailyPattyCapacity) { _, newValue in
                    status.dailyPattyCount = min(status.dailyPattyCount, newValue)
                }

            HStack(spacing: 12) {
                Button("-10") { status.dailyPattyCount = max(0, status.dailyPattyCount - 10) }
                Button("-1") { status.dailyPattyCount = max(0, status.dailyPattyCount - 1) }
                Button("+1") {
                    status.dailyPattyCount = min(status.dailyPattyCapacity, status.dailyPattyCount + 1)
                }
                Button("+10") {
                    status.dailyPattyCount = min(status.dailyPattyCapacity, status.dailyPattyCount + 10)
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
