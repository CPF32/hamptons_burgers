import SwiftUI

struct OrderView: View {
    @State private var showOrdering = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 28) {
                    Spacer(minLength: 24)

                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 160, maxHeight: 160)
                        .accessibilityLabel("\(BrandConfig.appName) logo")

                    VStack(spacing: 10) {
                        Text(BrandConfig.appName)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.text)
                            .multilineTextAlignment(.center)

                        Text("Pickup orders through Toast. Browse the menu, pay in-app, and pick up when ready.")
                            .font(.body)
                            .foregroundStyle(Theme.mutedText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                    }

                    VStack(spacing: 12) {
                        Button {
                            showOrdering = true
                        } label: {
                            Text("Order Pickup")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Theme.primary)
                                .foregroundStyle(Theme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        Text("Menu, checkout, and payment open in Toast Online Ordering.")
                            .font(.footnote)
                            .foregroundStyle(Theme.mutedText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                    Spacer()
                }
            }
            .navigationTitle("Order")
            .navigationBarTitleDisplayMode(.inline)
            .toastSafari(isPresented: $showOrdering, url: BrandConfig.toastOrderingURL)
        }
    }
}

#Preview {
    OrderView()
}
