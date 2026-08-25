import SwiftUI

struct AccountView: View {
    @State private var showAccount = false

    private var accountURL: URL {
        BrandConfig.toastAccountURL ?? BrandConfig.toastOrderingURL
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 56))
                        .foregroundStyle(Theme.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Your Toast guest account")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Theme.text)

                        Text("Order history, saved payment methods, and reorder live in Toast Online Ordering. Sign in with your Toast guest account to manage them.")
                            .font(.body)
                            .foregroundStyle(Theme.mutedText)
                    }

                    Button {
                        showAccount = true
                    } label: {
                        Text("Open Toast Account")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.primary)
                            .foregroundStyle(Theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Need help?")
                            .font(.headline)
                            .foregroundStyle(Theme.text)

                        if let phoneURL = URL(string: "tel:\(BrandConfig.supportPhone.filter(\.isNumber))") {
                            Link(BrandConfig.supportPhone, destination: phoneURL)
                                .foregroundStyle(Theme.secondary)
                        }

                        if let mailURL = URL(string: "mailto:\(BrandConfig.supportEmail)") {
                            Link(BrandConfig.supportEmail, destination: mailURL)
                                .foregroundStyle(Theme.secondary)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(24)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Account")
            .toastSafari(isPresented: $showAccount, url: accountURL)
        }
    }
}

#Preview {
    AccountView()
}
