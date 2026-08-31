import SwiftUI

struct ContentView: View {
    @Environment(StoreStatusStore.self) private var store
    @Environment(RewardsStore.self) private var rewards
    @Environment(AppConfigStore.self) private var appConfig
    @Environment(AuthStore.self) private var auth

    init() {
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        tabAppearance.backgroundColor = UIColor(Theme.surface)

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }

    private var isAdmin: Bool {
        auth.isSignedIn && appConfig.isAdmin(email: auth.userEmail)
    }

    var body: some View {
        mainTabs
            .background(Theme.background.ignoresSafeArea())
    }

    private var mainTabs: some View {
        ZStack(alignment: .top) {
            TabView {
                OrderView()
                    .tabItem {
                        Label("Order", systemImage: "bag.fill")
                    }

                PaymentView()
                    .tabItem {
                        Label("Rewards", systemImage: "star.fill")
                    }

                LocationView()
                    .tabItem {
                        Label("Find Us", systemImage: "location.fill")
                    }

                FAQView()
                    .tabItem {
                        Label("FAQ", systemImage: "questionmark.circle")
                    }

                if isAdmin {
                    AdminScanRewardsView(presentation: .tab)
                        .tabItem {
                            Label("Scan", systemImage: "qrcode.viewfinder")
                        }

                    AdminOperationsView()
                        .tabItem {
                            Label("Admin", systemImage: "shield.fill")
                        }
                }

                AccountView()
                    .tabItem {
                        Label("Account", systemImage: "person.crop.circle")
                    }
            }

            if store.shouldShowStatusBanner || store.shouldShowCustomerNoticeBanner {
                VStack(spacing: 8) {
                    if store.shouldShowStatusBanner {
                        StoreNoticeBanner(
                            systemImage: "exclamationmark.triangle.fill",
                            title: store.status.statusBannerTitle,
                            bodyText: store.status.statusBannerMessage(),
                            onDismiss: { store.dismissStatusBanner() }
                        )
                    }

                    if store.shouldShowCustomerNoticeBanner {
                        StoreNoticeBanner(
                            title: store.status.displayNoticeTitle,
                            bodyText: store.status.noticeBody,
                            onDismiss: { store.dismissCustomerNoticeBanner() }
                        )
                    }
                }
                .frame(maxWidth: Theme.noticeBannerMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .zIndex(1)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(StoreStatusStore())
        .environment(RewardsStore())
        .environment(AppConfigStore())
        .environment(AuthStore())
}
