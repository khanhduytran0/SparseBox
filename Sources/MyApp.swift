import SwiftUI

@main
struct MyApp: App {
    init() {
        setenv("USBMUXD_SOCKET_ADDRESS", "127.0.0.1:27015", 1)
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
