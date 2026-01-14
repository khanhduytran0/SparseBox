import FlyingFox
import SQLite3
import SwiftUI
import UniformTypeIdentifiers

extension UIDocumentPickerViewController {
    @objc func fix_init(forOpeningContentTypes contentTypes: [UTType], asCopy: Bool) -> UIDocumentPickerViewController {
        return fix_init(forOpeningContentTypes: contentTypes, asCopy: true)
    }
}

@main
struct MyApp: App {
    init() {
        //setenv("RUST_LOG", "trace", 1)
        //set_debug(true)
        Task.detached {
            Utils.port = try Utils.reservePort()
            
            let server = HTTPServer(port: Utils.port)
            await server.appendRoute("GET /*", to: DirectoryHTTPHandler(root: URL.documentsDirectory))
            try await server.run()
        }
        
        // Fix file picker
        let fixMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.fix_init(forOpeningContentTypes:asCopy:)))!
        let origMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.init(forOpeningContentTypes:asCopy:)))!
        method_exchangeImplementations(origMethod, fixMethod)
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(Utils.model)
        }
    }
}
