import SwiftUI

private enum AppTab: Hashable {
    case order
    case rewards
    case location
    case faq
    case account
}

struct ContentView: View {
    @Environment(StoreStatusStore.self) private var store
    @Environment(RewardsStore.self) private var rewards
    @Environment(AppConfigStore.self) private var appConfig
    @Environment(AuthStore.self) private var auth

    @State private var selectedTab = ContentView.initialTab

    init() {
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        tabAppearance.backgroundColor = UIColor(Theme.surface)

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }

    private static var initialTab: AppTab {
        launchScreenshotTab ?? .order
    }

    private static var launchScreenshotTab: AppTab? {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-ScreenshotTab"),
              index + 1 < args.count else { return nil }

        switch args[index + 1].lowercased() {
        case "order": return .order
        case "rewards", "payment": return .rewards
        case "findus", "location": return .location
        case "faq": return .faq
        case "account": return .account
        default: return nil
        }
    }

    private var isAdmin: Bool {
        auth.isSignedIn && appConfig.isAdmin(email: auth.userEmail)
    }

    var body: some View {
        mainTabs
            .background(Theme.background.ignoresSafeArea())
            .dismissKeyboardOnTap()
    }

    private var mainTabs: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedTab) {
                OrderView()
                    .tag(AppTab.order)
                    .tabItem {
                        Label("Order", systemImage: "bag.fill")
                    }

                PaymentView()
                    .tag(AppTab.rewards)
                    .tabItem {
                        Label("Rewards", systemImage: "star.fill")
                    }

                LocationView()
                    .tag(AppTab.location)
                    .tabItem {
                        Label("Find Us", systemImage: "location.fill")
                    }

                FAQView()
                    .tag(AppTab.faq)
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
                    .tag(AppTab.account)
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
