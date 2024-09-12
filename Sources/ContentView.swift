import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    let originalMobileGestalt: URL
    let modifiedMobileGestalt: URL
    @AppStorage("PairingFile") var pairingFile: String?
    @State var mobileGestalt: NSMutableDictionary
    @State var reboot = true
    @State var showPairingFileImporter = false
    @State var showErrorAlert = false
    @State var lastError: String?
    @State var path = NavigationPath()
    var body: some View {
        NavigationStack(path: $path) {
            Form {
                Section {
                    Button {
                        showPairingFileImporter.toggle()
                    } label: {
                        Text("Select pairing file")
                    }
                    .disabled(pairingFile != nil)
                    Button("[DEBUG] Reset pairing file") {
                        pairingFile = nil
                    }
                    .disabled(pairingFile == nil)
                } footer: {
                    if pairingFile != nil {
                        Text("Pairing file selected")
                    } else {
                        Text("Select a pairing file to continue")
                    }
                }
                Section {
                    Toggle("Action Button", isOn: bindingForMGKey("cT44WE1EohiwRzhsZ8xEsw"))
                    Toggle("Allow installing iPadOS apps", isOn: bindingForMGKey("9MZ5AdH43csAUajl/dU+IQ", type: [Int].self, defaultValue: [1], enableValue: [1, 2]))
                    Toggle("Always on Display (18.0+)", isOn: bindingForMGKey("j8/Omm6s1lsmTDFsXjsBfA"))
                    Toggle("Apple Pencil", isOn: bindingForMGKey("yhHcB0iH0d1XzPO/CFd3ow"))
                    Toggle("Boot chime", isOn: bindingForMGKey("QHxt+hGLaBPbQJbXiUJX3w"))
                    Toggle("Camera button (18.0rc+)", isOn: bindingForMGKey("CwvKxM2cEogD3p+HYgaW0Q"))
                    Toggle("Camera button (enable this too)", isOn: bindingForMGKey("oOV1jhJbdV3AddkcCg0AEA"))
                    Toggle("Charge limit", isOn: bindingForMGKey("37NVydb//GP/GrhuTN+exg"))
                    Toggle("Crash Detection (might not work)", isOn: bindingForMGKey("HCzWusHQwZDea6nNhaKndw"))
                    Toggle("Dynamic Island (17.4+ method)", isOn: bindingForMGKey("YlEtTtHlNesRBMal1CqRaA"))
                    Toggle("Internal Storage info", isOn: bindingForMGKey("LBJfwOEzExRxzlAnSuI7eg"))
                    Toggle("Metal HUD for all apps", isOn: bindingForMGKey("EqrsVvjcYDdxHBiQmGhAWw"))
                    Toggle("Stage Manager", isOn: bindingForMGKey("qeaj75wk3HF4DwQ8qbIi7g"))
                        .disabled(UIDevice.current.userInterfaceIdiom != .pad)
                    Toggle("Tap to Wake (iPhone SE)", isOn: bindingForMGKey("yZf3GTRMGTuwSV/lD7Cagw"))
                }
                Section {
                    Toggle("Reboot after finish restoring", isOn: $reboot)
                    Button("Apply changes") {
                        try! mobileGestalt.write(to: modifiedMobileGestalt)
                        applyChanges()
                    }
                    Button("Reset changes") {
                        try! FileManager.default.removeItem(at: modifiedMobileGestalt)
                        try! FileManager.default.copyItem(at: originalMobileGestalt, to: modifiedMobileGestalt)
                        mobileGestalt = try! NSMutableDictionary(contentsOf: modifiedMobileGestalt, error: ())
                        applyChanges()
                    }
                } footer: {
                    Text("""
A terrible app by @khanhduytran0. Use it at your own risk.
Thanks to:
@SideStore: em_proxy and minimuxer
@JJTech0130: SparseRestore and backup exploit
@PoomSmart: MobileGestalt dump
@libimobiledevice
""")
                }
            }
            .fileImporter(isPresented: $showPairingFileImporter, allowedContentTypes: [UTType(filenameExtension: "mobiledevicepairing", conformingTo: .data)!], onCompletion: { result in
                switch result {
                case .success(let url):
                    guard url.startAccessingSecurityScopedResource() else {
                        return
                    }
                    pairingFile = try! String(contentsOf: url)
                    url.stopAccessingSecurityScopedResource()
                    startMinimuxer()
                case .failure(let error):
                    lastError = error.localizedDescription
                    showErrorAlert.toggle()
                }
            })
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK") {}
            } message: {
                Text(lastError ?? "???")
            }
            .navigationDestination(for: String.self) { view in
                if view == "ApplyChanges" {
                    LogView(mobileGestaltURL: modifiedMobileGestalt, reboot: reboot)
                }
            }
            .navigationTitle("SparseBox")
        }
        .onAppear {
            _ = start_emotional_damage("127.0.0.1:51820")
            if let altPairingFile = Bundle.main.object(forInfoDictionaryKey: "ALTPairingFile") as? String, altPairingFile.count > 5000, pairingFile == nil {
                pairingFile = altPairingFile
            }
            startMinimuxer()
        }
    }
    
    init() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        originalMobileGestalt = documentsDirectory.appendingPathComponent("OriginalMobileGestalt.plist", conformingTo: .data)
        modifiedMobileGestalt = documentsDirectory.appendingPathComponent("ModifiedMobileGestalt.plist", conformingTo: .data)
        if !FileManager.default.fileExists(atPath: originalMobileGestalt.path) {
            let url = URL(filePath: "/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist")
            try! FileManager.default.copyItem(at: url, to: originalMobileGestalt)
            try! FileManager.default.copyItem(at: url, to: modifiedMobileGestalt)
        }
        mobileGestalt = try! NSMutableDictionary(contentsOf: modifiedMobileGestalt, error: ())
    }
    
    func applyChanges() {
        if ready() {
            path.append("ApplyChanges")
        } else {
            lastError = "minimuxer is not ready. Ensure you have WiFi and WireGuard VPN set up."
            showErrorAlert.toggle()
        }
    }
    
    func bindingForMGKey<T: Equatable>(_ key: String, type: T.Type = Int.self, defaultValue: T? = 0, enableValue: T? = 1) -> Binding<Bool> {
        Binding(
            get: {
                if let value = (mobileGestalt["CacheExtra"] as! NSMutableDictionary)[key] as? T?, let enableValue {
                    return value == enableValue
                }
                return false
            },
            set: { enabled in
                var cacheExtra = mobileGestalt["CacheExtra"] as! NSMutableDictionary
                if enabled {
                    cacheExtra[key] = enableValue
                } else {
                    // just remove the key as it will be pulled from device tree if missing
                    cacheExtra.removeObject(forKey: key)
                }
            }
        )
    }
    
    func startMinimuxer() {
        guard pairingFile != nil else {
            return
        }
        target_minimuxer_address()
        do {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].absoluteString
            try start(pairingFile!, documentsDirectory)
        } catch {
            lastError = error.localizedDescription
            showErrorAlert.toggle()
        }
    }
    
    public func withArrayOfCStrings<R>(
        _ args: [String],
        _ body: ([UnsafeMutablePointer<CChar>?]) -> R
    ) -> R {
        var cStrings = args.map { strdup($0) }
        cStrings.append(nil)
        defer {
            cStrings.forEach { free($0) }
        }
        return body(cStrings)
    }
}
