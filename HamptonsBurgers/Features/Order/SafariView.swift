import SwiftUI
import SafariServices

/// Presents Toast Online Ordering (or guest account) in Safari with shared cookies/payments.
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.barCollapsingEnabled = true
        let controller = SFSafariViewController(url: url, configuration: config)
        controller.preferredControlTintColor = UIColor(Theme.secondary)
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct ToastSafariSheet: ViewModifier {
    @Binding var isPresented: Bool
    let url: URL

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            SafariView(url: url)
                .ignoresSafeArea()
        }
    }
}

extension View {
    func toastSafari(isPresented: Binding<Bool>, url: URL) -> some View {
        modifier(ToastSafariSheet(isPresented: isPresented, url: url))
    }
}
