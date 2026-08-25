import SwiftUI
import MapKit

struct LocationView: View {
    private let location = ContentConfig.location

    @State private var position: MapCameraPosition

    init() {
        let loc = ContentConfig.location
        _position = State(initialValue: .region(
            MKCoordinateRegion(
                center: loc.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Map(position: $position) {
                        Marker(location.name, coordinate: location.coordinate)
                    }
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .mapStyle(.standard)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(location.name)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Theme.text)

                        Text(location.addressLine1)
                            .foregroundStyle(Theme.mutedText)
                        Text(location.addressLine2)
                            .foregroundStyle(Theme.mutedText)

                        if let mapsURL = location.mapsURL {
                            Link("Open in Maps", destination: mapsURL)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.secondary)
                                .padding(.top, 4)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Hours")
                            .font(.headline)
                            .foregroundStyle(Theme.text)

                        ForEach(location.hours) { entry in
                            HStack {
                                Text(entry.day)
                                    .foregroundStyle(Theme.text)
                                Spacer()
                                Text(entry.hours)
                                    .foregroundStyle(Theme.mutedText)
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    if let phoneURL = URL(string: "tel:\(location.phone.filter(\.isNumber))") {
                        Link(destination: phoneURL) {
                            Label(location.phone, systemImage: "phone.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Theme.primary)
                                .foregroundStyle(Theme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                }
                .padding(20)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Location")
        }
    }
}

#Preview {
    LocationView()
}
