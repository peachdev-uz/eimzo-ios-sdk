import SwiftUI
import EimzoSDK

/// Sample app entry point. Receives `eimzo://sign?qc=…` deeplinks via
/// `onOpenURL` and forwards them to `ContentView`.
@main
struct EimzoExampleApp: App {
    @State private var incomingDeepLink: String?

    var body: some Scene {
        WindowGroup {
            ContentView(incomingDeepLink: $incomingDeepLink)
                .onOpenURL { url in
                    guard url.scheme == "eimzo" else { return }
                    incomingDeepLink = url.absoluteString
                }
        }
    }
}
