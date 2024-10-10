import SwiftUI
import UniformTypeIdentifiers

extension UIDocumentPickerViewController {
    @objc func fix_init(forOpeningContentTypes contentTypes: [UTType], asCopy: Bool) -> UIDocumentPickerViewController {
        return fix_init(forOpeningContentTypes: contentTypes, asCopy: true)
    }
}

struct ContentView: View {
    let os = ProcessInfo().operatingSystemVersion
    let origMGURL, modMGURL, featFlagsURL: URL
    @AppStorage("PairingFile") var pairingFile: String?
    @State var mbdb: Backup?
    @State var eligibilityData = Data()
    @State var featureFlagsData = Data()
    @State var mobileGestalt: NSMutableDictionary
    @State var productType = machineName()
    @State var minimuxerReady = false
    @State var reboot = true
    @State var showPairingFileImporter = false
    @State var showErrorAlert = false
    @State var taskRunning = false
    @State var lastError: String?
    @State var path = NavigationPath()
    var body: some View {
        NavigationStack(path: $path) {
            Form {
                Section {
                    Button(pairingFile == nil ? "Select pairing file" : "Reset pairing file") {
                        if pairingFile == nil {
                            showPairingFileImporter.toggle()
                        } else {
                            pairingFile = nil
                        }
                    }
                    .dropDestination(for: Data.self) { items, location in
                        guard let item = items.first else { return false }
                        pairingFile = try! String(decoding: item, as: UTF8.self)
                        guard pairingFile?.contains("DeviceCertificate") ?? false else {
                            lastError = "The file you just dropped is not a pairing file"
                            showErrorAlert.toggle()
                            pairingFile = nil
                            return false
                        }
                        startMinimuxer()
                        return true
                    }
                } footer: {
                    if pairingFile != nil {
                        Text("Pairing file selected")
                    } else {
                        Text("Select or drag and drop a pairing file to continue. More info: https://docs.sidestore.io/docs/getting-started/pairing-file")
                    }
                }
                Section {
                    Toggle("Action Button", isOn: bindingForMGKeys(["cT44WE1EohiwRzhsZ8xEsw"]))
                        .disabled(requiresVersion(17))
                    Toggle("Allow installing iPadOS apps", isOn: bindingForMGKeys(["9MZ5AdH43csAUajl/dU+IQ"], type: [Int].self, defaultValue: [1], enableValue: [1, 2]))
                    Toggle("Always on Display (18.0+)", isOn: bindingForMGKeys(["j8/Omm6s1lsmTDFsXjsBfA", "2OOJf1VhaM7NxfRok3HbWQ"]))
                        .disabled(requiresVersion(18))
                    Toggle("Apple Intelligence", isOn: bindingForAppleIntelligence())
                        .disabled(requiresVersion(18))
                    Toggle("Apple Pencil", isOn: bindingForMGKeys(["yhHcB0iH0d1XzPO/CFd3ow"]))
                    Toggle("Boot chime", isOn: bindingForMGKeys(["QHxt+hGLaBPbQJbXiUJX3w"]))
                    Toggle("Camera button (18.0rc+)", isOn: bindingForMGKeys(["CwvKxM2cEogD3p+HYgaW0Q", "oOV1jhJbdV3AddkcCg0AEA"]))
                        .disabled(requiresVersion(18))
                    Toggle("Charge limit", isOn: bindingForMGKeys(["37NVydb//GP/GrhuTN+exg"]))
                        .disabled(requiresVersion(17))
                    Toggle("Crash Detection (might not work)", isOn: bindingForMGKeys(["HCzWusHQwZDea6nNhaKndw"]))
                    Toggle("Dynamic Island (17.4+, might not work)", isOn: bindingForMGKeys(["YlEtTtHlNesRBMal1CqRaA"]))
                        .disabled(requiresVersion(17, 4))
                    Toggle("Internal Storage info", isOn: bindingForMGKeys(["LBJfwOEzExRxzlAnSuI7eg"]))
                    Toggle("Metal HUD for all apps", isOn: bindingForMGKeys(["EqrsVvjcYDdxHBiQmGhAWw"]))
                    Toggle("Stage Manager", isOn: bindingForMGKeys(["qeaj75wk3HF4DwQ8qbIi7g"]))
                        .disabled(UIDevice.current.userInterfaceIdiom != .pad)
                    if let isSE = UIDevice.perform(Selector("_hasHomeButton")) {
                        Toggle("Tap to Wake (iPhone SE)", isOn: bindingForMGKeys(["yZf3GTRMGTuwSV/lD7Cagw"]))
                    }
                } header: {
                    Text("MobileGestalt")
                }
                Section {
                    Picker("Device model", selection:$productType) {
                        Text("unchanged").tag(ContentView.machineName())
                        if UIDevice.current.userInterfaceIdiom == .pad {
                            Text("iPad Pro 11 inch 5th Gen").tag("iPad16,3")
                        } else {
                            Text("iPhone 15 Pro Max").tag("iPhone16,2")
                            Text("iPhone 16 Pro Max").tag("iPhone17,2")
                        }
                    }
                    //.disabled(requiresVersion(18, 1))
                } header: {
                    Text("Device spoofing")
                } footer: {
                    Text("Only change device model if you're downloading Apple Intelligence models. Face ID may break.")
                }
                Section {
                    Button("Bypass 3 app limit") {
                        testBypassAppLimit()
                    }
                    .disabled(taskRunning)
                } footer: {
                    Text("Hide free developer apps from installd, so you could install more than 3 apps. You need to apply this for each 3 apps you install or update.")
                }
                Section {
                    Toggle("Reboot after finish restoring", isOn: $reboot)
                    Button("Apply changes") {
                        saveProductType()
                        try! mobileGestalt.write(to: modMGURL)
                        applyChanges()
                    }
                    .disabled(taskRunning)
                    Button("Reset changes") {
                        try! FileManager.default.removeItem(at: modMGURL)
                        try! FileManager.default.copyItem(at: origMGURL, to: modMGURL)
                        mobileGestalt = try! NSMutableDictionary(contentsOf: modMGURL, error: ())
                        applyChanges()
                    }
                    .disabled(taskRunning)
                } footer: {
                    VStack {
                        Text("""
A terrible app by @khanhduytran0. Use it at your own risk.
Thanks to:
@SideStore: em_proxy and minimuxer
@JJTech0130: SparseRestore and backup exploit
@PoomSmart: MobileGestalt dump
@Lakr233: BBackupp
@libimobiledevice
""")
                    }
                }
            }
            .fileImporter(isPresented: $showPairingFileImporter, allowedContentTypes: [UTType(filenameExtension: "mobiledevicepairing", conformingTo: .data)!], onCompletion: { result in
                switch result {
                case .success(let url):
                    pairingFile = try! String(contentsOf: url)
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
                    LogView(mbdb: mbdb!, reboot: reboot)
                } else if view == "BypassAppLimit" {
                    LogView(mbdb: mbdb!, reboot: false)
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
            
            let cacheExtra = mobileGestalt["CacheExtra"] as! NSMutableDictionary
            productType = cacheExtra["h9jDsbgj7xIVeIQ8S3/X3Q"] as! String
        }
    }
    
    init() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        featFlagsURL = documentsDirectory.appendingPathComponent("FeatureFlags.plist", conformingTo: .data)
        origMGURL = documentsDirectory.appendingPathComponent("OriginalMobileGestalt.plist", conformingTo: .data)
        modMGURL = documentsDirectory.appendingPathComponent("ModifiedMobileGestalt.plist", conformingTo: .data)
        if !FileManager.default.fileExists(atPath: origMGURL.path) {
            let url = URL(filePath: "/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist")
            try! FileManager.default.copyItem(at: url, to: origMGURL)
            try! FileManager.default.copyItem(at: url, to: modMGURL)
        }
        _mobileGestalt = State(initialValue: try! NSMutableDictionary(contentsOf: modMGURL, error: ()))
        
        // Fix file picker
        let fixMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.fix_init(forOpeningContentTypes:asCopy:)))!
        let origMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.init(forOpeningContentTypes:asCopy:)))!
        method_exchangeImplementations(origMethod, fixMethod)
    }
    
    func testBypassAppLimit() {
        if ready() {
            Task {
                taskRunning = true
                mbdb = Restore.createBypassAppLimit()
                taskRunning = false
                path.append("BypassAppLimit")
            }
        } else {
            lastError = "minimuxer is not ready. Ensure you have WiFi and WireGuard VPN set up."
            showErrorAlert.toggle()
        }
    }
    
    func applyChanges() {
        if ready() {
            Task {
                mbdb = Restore.createBackupFiles(files: generateFilesToRestore())
                taskRunning = false
                path.append("ApplyChanges")
            }
        } else {
            lastError = "minimuxer is not ready. Ensure you have WiFi and WireGuard VPN set up."
            showErrorAlert.toggle()
        }
    }
    
    func bindingForAppleIntelligence() -> Binding<Bool> {
        let cacheExtra = mobileGestalt["CacheExtra"] as! NSMutableDictionary
        let key = "A62OafQ85EJAiiqKn4agtg"
        return Binding(
            get: {
                if let value = cacheExtra[key] as? Int? {
                    return value == 1
                }
                return false
            },
            set: { enabled in
                if enabled {
                    eligibilityData = try! Data(contentsOf: Bundle.main.url(forResource: "eligibility", withExtension: "plist")!)
                    cacheExtra[key] = 1
                    featureFlagsData = try! Data(contentsOf: Bundle.main.url(forResource: "FeatureFlags_Global", withExtension: "plist")!)
                    cacheExtra[key] = 1
                } else {
                    featureFlagsData = try! PropertyListSerialization.data(fromPropertyList: [:], format: .xml, options: 0)
                    eligibilityData = featureFlagsData
                    // just remove the key as it will be pulled from device tree if missing
                    cacheExtra.removeObject(forKey: key)
                }
            }
        )
    }
    
    func bindingForMGKeys<T: Equatable>(_ keys: [String], type: T.Type = Int.self, defaultValue: T? = 0, enableValue: T? = 1) -> Binding<Bool> {
        let cacheExtra = mobileGestalt["CacheExtra"] as! NSMutableDictionary
        return Binding(
            get: {
                if let value = cacheExtra[keys.first!] as? T?, let enableValue {
                    return value == enableValue
                }
                return false
            },
            set: { enabled in
                for key in keys {
                    if enabled {
                        cacheExtra[key] = enableValue
                    } else {
                        // just remove the key as it will be pulled from device tree if missing
                        cacheExtra.removeObject(forKey: key)
                    }
                }
            }
        )
    }
    
    func generateFilesToRestore() -> [FileToRestore] {
        return [
            FileToRestore(from: modMGURL, to: URL(filePath: "/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist"), owner: 501, group: 501),
            FileToRestore(contents: eligibilityData, to: URL(filePath: "/var/db/eligibilityd/eligibility.plist")),
            FileToRestore(contents: featureFlagsData, to: URL(filePath: "/var/preferences/FeatureFlags/Global.plist")),
        ]
    }
    
    // https://stackoverflow.com/questions/26028918/how-to-determine-the-current-iphone-device-model
    // read device model from kernel
    static func machineName() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }
    
    func saveProductType() {
        let cacheExtra = mobileGestalt["CacheExtra"] as! NSMutableDictionary
        cacheExtra["h9jDsbgj7xIVeIQ8S3/X3Q"] = productType
    }
    
    func startMinimuxer() {
        guard pairingFile != nil else {
            return
        }
        // set USBMUXD_SOCKET_ADDRESS
        target_minimuxer_address()
        do {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].absoluteString
            try start(pairingFile!, documentsDirectory)
        } catch {
            lastError = error.localizedDescription
            showErrorAlert.toggle()
        }
    }
    
    func requiresVersion(_ major : Int, _ minor: Int = 0, _ patch: Int = 0) -> Bool {
        // XXYYZZ: major XX, minor YY, patch ZZ
        let requiredVersion = major*10000 + minor*100 + patch
        let currentVersion = os.majorVersion*10000 + os.minorVersion*100 + os.patchVersion
        return currentVersion < requiredVersion
    }
}
