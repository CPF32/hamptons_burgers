import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            OrderView()
                .tabItem {
                    Label("Order", systemImage: "bag.fill")
                }

            LocationView()
                .tabItem {
                    Label("Location", systemImage: "mappin.and.ellipse")
                }

            FAQView()
                .tabItem {
                    Label("FAQ", systemImage: "questionmark.circle")
                }

            AccountView()
                .tabItem {
                    Label("Account", systemImage: "person.crop.circle")
                }
        }
        .tint(Theme.secondary)
    }
}

#Preview {
    ContentView()
}
