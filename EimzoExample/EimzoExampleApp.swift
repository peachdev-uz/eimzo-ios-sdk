import SwiftUI
import EimzoSDK

/// Sample app entry point.
///
/// No `eimzo://` URL scheme and no `onOpenURL`: that scheme is the E-IMZO
/// app's. A sign request is made inside the app — see `ContentView`.
@main
struct EimzoExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
