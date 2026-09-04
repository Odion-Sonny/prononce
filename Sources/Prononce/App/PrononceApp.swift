import SwiftUI
import AppKit

@main
struct PrononceApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Prononce lives exclusively in the macOS menu bar.
        // We provide a dummy Settings scene so SwiftUI does not instantiate
        // an unnecessary blank window on launch.
        Settings {
            EmptyView()
        }
    }
}
