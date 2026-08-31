import MapKit
import SwiftUI

struct AdminMapPickerView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var coordinate: LocationContent.Coordinates
    let placeName: String

    @State private var position: MapCameraPosition
    @State private var pinCoordinate: CLLocationCoordinate2D

    init(coordinate: Binding<LocationContent.Coordinates>, placeName: String) {
        _coordinate = coordinate
        self.placeName = placeName

        let initial = CLLocationCoordinate2D(
            latitude: coordinate.wrappedValue.latitude,
            longitude: coordinate.wrappedValue.longitude
        )
        _pinCoordinate = State(initialValue: initial)
        _position = State(initialValue: .region(
            MKCoordinateRegion(
                center: initial,
                span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
            )
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            MapReader { proxy in
                Map(position: $position) {
                    Marker(placeName.isEmpty ? "Restaurant" : placeName, coordinate: pinCoordinate)
                }
                .mapStyle(.standard)
                .onTapGesture { point in
                    if let tapped = proxy.convert(point, from: .local) {
                        pinCoordinate = tapped
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 8) {
                Text("Tap the map to place the pin.")
                    .font(.footnote)
                    .foregroundStyle(Theme.mutedText)

                if let mapsURL = mapsURL(for: pinCoordinate) {
                    Link("Preview in Apple Maps", destination: mapsURL)
                        .font(.footnote.weight(.semibold))
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Theme.surface)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Map location")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    coordinate.latitude = pinCoordinate.latitude
                    coordinate.longitude = pinCoordinate.longitude
                    dismiss()
                }
            }
        }
    }

    private func mapsURL(for coordinate: CLLocationCoordinate2D) -> URL? {
        var components = URLComponents(string: "https://maps.apple.com/")
        components?.queryItems = [
            URLQueryItem(name: "ll", value: "\(coordinate.latitude),\(coordinate.longitude)"),
            URLQueryItem(name: "q", value: placeName.isEmpty ? "Restaurant" : placeName)
        ]
        return components?.url
    }
}

struct AdminLocationSection: View {
    @Binding var location: LocationContent

    var body: some View {
        Section("Location & contact") {
            TextField("Restaurant name", text: $location.name)
            TextField("Address line 1", text: $location.addressLine1)
            TextField("Address line 2", text: $location.addressLine2)
            TextField("Phone", text: $location.phone)
                .keyboardType(.phonePad)
            TextField("Email", text: $location.email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            NavigationLink {
                AdminMapPickerView(coordinate: $location.coordinates, placeName: location.name)
            } label: {
                Text("Set location on map")
            }

            if let mapsURL = location.mapsURL {
                Link("Open current pin in Apple Maps", destination: mapsURL)
                    .font(.subheadline)
            }
        }
    }
}

struct AdminHoursSection: View {
    @Binding var hours: [LocationContent.HoursEntry]

    var body: some View {
        Section("Hours of operation") {
            ForEach($hours) { $entry in
                HStack(alignment: .firstTextBaseline) {
                    Text(entry.day)
                        .frame(width: 90, alignment: .leading)
                        .foregroundStyle(Theme.mutedText)
                    TextField("Hours", text: $entry.hours)
                }
            }
        }
    }
}

struct AdminFAQSection: View {
    @Binding var items: [FAQItem]

    var body: some View {
        Section("FAQ") {
            if items.isEmpty {
                Text("No FAQ items yet.")
                    .font(.caption)
                    .foregroundStyle(Theme.mutedText)
            }

            ForEach($items) { $item in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        TextField("Question", text: $item.question, axis: .vertical)
                            .lineLimit(2...4)
                        Button(role: .destructive) {
                            deleteItem(id: item.id)
                        } label: {
                            Image(systemName: "trash")
                                .font(.body)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Delete FAQ")
                    }

                    TextField("Answer", text: $item.answer, axis: .vertical)
                        .lineLimit(3...8)
                        .font(.subheadline)
                }
                .padding(.vertical, 4)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteItem(id: item.id)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }

            Button("Add FAQ item") {
                addItem()
            }
        }
    }

    private func addItem() {
        let item = FAQItem(
            id: "faq-\(UUID().uuidString.lowercased().prefix(8))",
            question: "New question",
            answer: ""
        )
        items.append(item)
    }

    private func deleteItem(id: String) {
        items.removeAll { $0.id == id }
    }
}

struct AdminRedemptionSection: View {
    @Binding var items: [RedemptionItem]

    var body: some View {
        Section("Redeem in store") {
            if items.isEmpty {
                Text("No redemption items yet.")
                    .font(.caption)
                    .foregroundStyle(Theme.mutedText)
            }

            ForEach($items) { $item in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        TextField("Item name", text: $item.name)
                        Button(role: .destructive) {
                            deleteItem(id: item.id)
                        } label: {
                            Image(systemName: "trash")
                                .font(.body)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Delete redemption item")
                    }

                    HStack(alignment: .center, spacing: 12) {
                        HStack(spacing: 4) {
                            TextField(
                                "Price",
                                value: $item.price,
                                format: .currency(code: "USD")
                            )
                            .keyboardType(.decimalPad)
                            .font(.subheadline)
                            .foregroundStyle(Theme.text)
                            .frame(width: 72)

                            Text("·")
                                .font(.subheadline)
                                .foregroundStyle(Theme.mutedText)

                            Text("\(item.pointsCost) pts")
                                .font(.subheadline)
                                .foregroundStyle(Theme.mutedText)
                                .fixedSize()
                        }

                        Spacer(minLength: 0)

                        pointsStepper(pointsCost: $item.pointsCost)
                    }
                }
                .padding(.vertical, 4)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteItem(id: item.id)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }

            Button("Add redemption item") {
                addItem()
            }

            Text("Shown on the Rewards tab. Publish app content to push changes to guests.")
                .font(.caption)
                .foregroundStyle(Theme.mutedText)
        }
    }

    private func addItem() {
        items.append(
            RedemptionItem(
                id: "item-\(UUID().uuidString.lowercased().prefix(8))",
                name: "New item",
                price: 0,
                pointsCost: 50,
                category: "burgers"
            )
        )
    }

    private func deleteItem(id: String) {
        items.removeAll { $0.id == id }
    }

    private func pointsStepper(pointsCost: Binding<Int>) -> some View {
        HStack(spacing: 0) {
            Button {
                pointsCost.wrappedValue = max(1, pointsCost.wrappedValue - 5)
            } label: {
                Image(systemName: "minus")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 34, height: 32)
            }
            .disabled(pointsCost.wrappedValue <= 1)
            .accessibilityLabel("Decrease points")

            Divider()
                .frame(height: 18)

            Button {
                pointsCost.wrappedValue = min(10_000, pointsCost.wrappedValue + 5)
            } label: {
                Image(systemName: "plus")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 34, height: 32)
            }
            .disabled(pointsCost.wrappedValue >= 10_000)
            .accessibilityLabel("Increase points")
        }
        .foregroundStyle(Theme.primary)
        .background(Theme.background.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Theme.mutedText.opacity(0.25), lineWidth: 1)
        }
        .buttonStyle(.plain)
    }
}

struct AdminEmailsSection: View {
    @Binding var adminEmails: [String]
    @State private var newEmail = ""

    var body: some View {
        Section("Admin access") {
            if adminEmails.isEmpty {
                Text("No admin emails yet.")
                    .font(.caption)
                    .foregroundStyle(Theme.mutedText)
            }

            ForEach(adminEmails, id: \.self) { email in
                Text(email)
                    .font(.caption.monospaced())
            }
            .onDelete { offsets in
                adminEmails.remove(atOffsets: offsets)
            }

            HStack {
                TextField("Add admin email", text: $newEmail)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Button("Add") {
                    addEmail()
                }
                .disabled(!FirestoreRewardsUserWriter.isValidEmail(newEmail))
            }

            Text("Signed-in users with these emails get Admin and Scan tabs for store status and rewards scanning.")
                .font(.caption)
                .foregroundStyle(Theme.mutedText)
        }
    }

    private func addEmail() {
        let normalized = FirestoreRewardsUserWriter.normalizeEmail(newEmail)
        guard FirestoreRewardsUserWriter.isValidEmail(normalized) else { return }
        guard !adminEmails.map(FirestoreRewardsUserWriter.normalizeEmail).contains(normalized) else {
            newEmail = ""
            return
        }
        adminEmails.append(normalized)
        newEmail = ""
    }
}
