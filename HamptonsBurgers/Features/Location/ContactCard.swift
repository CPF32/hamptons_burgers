import SwiftUI

struct ContactCard: View {
    @Environment(AppConfigStore.self) private var appConfig

    private var location: LocationContent { appConfig.location }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Contact")
                .font(.headline)
                .foregroundStyle(Theme.text)

            VStack(alignment: .leading, spacing: 8) {
                if let mapsURL = location.mapsURL {
                    Link(destination: mapsURL) {
                        Label(location.fullAddress, systemImage: "mappin.and.ellipse")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(Theme.primary)
                }

                if let phoneURL = URL(string: "tel:\(location.phone.filter(\.isNumber))") {
                    Link(destination: phoneURL) {
                        Label(location.phone, systemImage: "phone.fill")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(Theme.primary)
                }

                if let mailURL = URL(string: "mailto:\(location.email)") {
                    Link(destination: mailURL) {
                        Label(location.email, systemImage: "envelope.fill")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(Theme.primary)
                }

                ForEach(BrandConfig.instagramHandles, id: \.self) { handle in
                    Link(destination: BrandConfig.instagramURL(for: handle)) {
                        Label("@\(handle)", systemImage: "camera.fill")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(Theme.primary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
