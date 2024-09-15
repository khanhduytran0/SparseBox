import SwiftUI

@main
struct MyApp: App {
    init() {
        //setenv("RUST_LOG", "trace", 1)
        //set_debug(true)
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
