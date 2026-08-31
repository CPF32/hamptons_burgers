import SwiftUI
import MapKit

private struct BottomSectionsHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct LocationView: View {
    @Environment(AppConfigStore.self) private var appConfig

    @State private var position: MapCameraPosition = .automatic
    @State private var bottomSectionsHeight: CGFloat = 300

    private var location: LocationContent { appConfig.location }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: Theme.sectionGap) {
                    mapSection
                        .frame(height: mapHeight(in: proxy.size.height))

                    bottomSections
                        .background {
                            GeometryReader { sectionProxy in
                                Color.clear.preference(
                                    key: BottomSectionsHeightKey.self,
                                    value: sectionProxy.size.height
                                )
                            }
                        }
                }
                .padding(.vertical, Theme.sectionGap)
                .frame(minHeight: proxy.size.height, alignment: .top)
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .onPreferenceChange(BottomSectionsHeightKey.self) { bottomSectionsHeight = $0 }
        .onAppear { updateMapPosition() }
        .onChange(of: appConfig.configVersion) { _, _ in
            updateMapPosition()
        }
    }

    private var bottomSections: some View {
        VStack(spacing: Theme.sectionGap) {
            hoursCard
            ContactCard()
                .padding(.horizontal, 20)
        }
    }

    private var mapSection: some View {
        Map(position: $position) {
            Marker(location.name, coordinate: location.coordinate)
        }
        .mapStyle(.standard)
        .disabled(true)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            Color.clear
                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .onTapGesture(perform: openInMaps)
        }
        .padding(.horizontal, 20)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("Open location in Maps")
        .accessibilityHint("Opens Apple Maps with the restaurant location")
    }

    private var hoursCard: some View {
        VStack(alignment: .leading, spacing: 10) {
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
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, 20)
    }

    private func mapHeight(in availableHeight: CGFloat) -> CGFloat {
        let verticalPadding = Theme.sectionGap * 2
        let sectionGap = Theme.sectionGap
        let remaining = availableHeight - verticalPadding - sectionGap - bottomSectionsHeight
        return max(160, remaining)
    }

    private func updateMapPosition() {
        position = .region(
            MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        )
    }

    private func openInMaps() {
        guard let mapsURL = location.mapsURL else { return }
        UIApplication.shared.open(mapsURL)
    }
}

#Preview {
    LocationView()
        .environment(AppConfigStore())
}
