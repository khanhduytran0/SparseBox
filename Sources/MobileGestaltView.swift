import SwiftUI
import UniformTypeIdentifiers

struct MobileGestaltView: View {
    let origMGURL, modMGURL, featFlagsURL: URL
    @AppStorage("BookassetdContainerUUID") private var bookassetdUUID: String?
    @Environment(\.scenePhase) var scenePhase
    @State var mbdb: Backup?
    @State var eligibilityData = Data()
    @State var featureFlagsData = Data()
    @State var mobileGestalt: NSMutableDictionary
    @State var productType = machineName()
    @State var respring = true
    @State var showPairingFileImporter = false
    @State var showErrorAlert = false
    @State var taskRunning = false
    @State var initError: String?
    @State var lastError: String?
    
    @State var showBookassetdUUIDGuideAlert = false
    var body: some View {
        Form {
            Section {
                Text("HTTP server port \(Utils.port)")
            } header: {
                Text("Debug")
            }
            Section {
                Toggle("Action Button", isOn: bindingForMGKeys(["cT44WE1EohiwRzhsZ8xEsw"]))
                    .disabled(Utils.requiresVersion(17))
                Toggle("Allow installing iPadOS apps", isOn: bindingForMGKeys(["9MZ5AdH43csAUajl/dU+IQ"], type: [Int].self, defaultValue: [1], enableValue: [1, 2]))
                Toggle("Always on Display (18.0+)", isOn: bindingForMGKeys(["j8/Omm6s1lsmTDFsXjsBfA", "2OOJf1VhaM7NxfRok3HbWQ"]))
                    .disabled(Utils.requiresVersion(18))
                Toggle("Apple Intelligence", isOn: bindingForAppleIntelligence())
                    .disabled(Utils.requiresVersion(18))
                Toggle("Apple Pencil", isOn: bindingForMGKeys(["yhHcB0iH0d1XzPO/CFd3ow"]))
                Toggle("Boot chime", isOn: bindingForMGKeys(["QHxt+hGLaBPbQJbXiUJX3w"]))
                Toggle("Camera button (18.0rc+)", isOn: bindingForMGKeys(["CwvKxM2cEogD3p+HYgaW0Q", "oOV1jhJbdV3AddkcCg0AEA"]))
                    .disabled(Utils.requiresVersion(18))
                Toggle("Charge limit", isOn: bindingForMGKeys(["37NVydb//GP/GrhuTN+exg"]))
                    .disabled(Utils.requiresVersion(17))
                Toggle("Crash Detection (might not work)", isOn: bindingForMGKeys(["HCzWusHQwZDea6nNhaKndw"]))
                Toggle("Dynamic Island (17.4+, might not work)", isOn: bindingForMGKeys(["YlEtTtHlNesRBMal1CqRaA"]))
                    .disabled(Utils.requiresVersion(17, 4))
                Toggle("Disable region restrictions", isOn: bindingForRegionRestriction())
                Toggle("Internal Storage info", isOn: bindingForMGKeys(["LBJfwOEzExRxzlAnSuI7eg"]))
                Toggle("Internal stuff", isOn: bindingForInternalStuff())
                Toggle("Security Research Device", isOn: bindingForMGKeys(["XYlJKKkj2hztRP1NWWnhlw"]))
                Toggle("Metal HUD for all apps", isOn: bindingForMGKeys(["EqrsVvjcYDdxHBiQmGhAWw"]))
                Toggle("Stage Manager", isOn: bindingForMGKeys(["qeaj75wk3HF4DwQ8qbIi7g"]))
                    .disabled(UIDevice.current.userInterfaceIdiom != .pad)
                if UIDevice._hasHomeButton() {
                    Toggle("Tap to Wake (iPhone SE)", isOn: bindingForMGKeys(["yZf3GTRMGTuwSV/lD7Cagw"]))
                }
            } header: {
                Text("MobileGestalt")
            }
            Section {
                Picker("Device model", selection:$productType) {
                    Text("unchanged").tag(MobileGestaltView.machineName())
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        Text("iPad Pro 11 inch 5th Gen").tag("iPad16,3")
                    } else {
                        Text("iPhone 15 Pro Max").tag("iPhone16,2")
                        Text("iPhone 16 Pro Max").tag("iPhone17,2")
                    }
                }
                //.disabled(Utils.requiresVersion(18, 1))
            } header: {
                Text("Device spoofing")
            } footer: {
                Text("Only change device model if you're downloading Apple Intelligence models. Face ID may break.")
            }
            Section {
                let cacheExtra = mobileGestalt["CacheExtra"] as? NSMutableDictionary
                Toggle("Become iPadOS", isOn: bindingForTrollPad())
                // validate DeviceClass
                    .disabled(cacheExtra?["+3Uf0Pm5F8Xy7Onyvko0vA"] as? String != "iPhone")
            } footer: {
                Text("Override user interface idiom to iPadOS, so you could use all iPadOS multitasking features on iPhone. Gives you the same capabilities as TrollPad, but may cause some issues.\nPLEASE DO NOT TURN OFF SHOW DOCK IN STAGE MANAGER OTHERWISE YOUR PHONE WILL BOOTLOOP WHEN ROTATING TO LANDSCAPE.")
            }
            Section {
                Toggle("Respring after finish restoring", isOn: $respring)
                Button("Apply changes") {
                    Utils.model.selectedTab = .log
                    saveProductType()
                    try! mobileGestalt.write(to: modMGURL)
                    DispatchQueue.global(qos: .background).async {
                        Task {
                            do {
                                try await performApplyMobileGestalt()
                            } catch {
                                await MainActor.run {
                                    lastError = "\(error)"
                                    showErrorAlert = true
                                }
                            }
                        }
                    }
                }
                .disabled(taskRunning)
                Button("Reset changes") {
                    Utils.model.selectedTab = .log
                    try! FileManager.default.removeItem(at: modMGURL)
                    try! FileManager.default.copyItem(at: origMGURL, to: modMGURL)
                    mobileGestalt = try! NSMutableDictionary(contentsOf: modMGURL, error: ())
                    DispatchQueue.global(qos: .background).async {
                        Task {
                            do {
                                try await performApplyMobileGestalt()
                            } catch {
                                await MainActor.run {
                                    lastError = "\(error)"
                                    showErrorAlert = true
                                }
                            }
                        }
                    }
                }
                .disabled(taskRunning)
            }
            Section {
                //ShareLink("Export Modified MobileGestalt", item: modMGURL)
                Button("Export Modified MobileGestalt", systemImage: "square.and.arrow.up") {
                    saveProductType()
                    try! mobileGestalt.write(to: modMGURL)
                    let activityVC = UIActivityViewController(activityItems: [modMGURL], applicationActivities: nil)
                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        scene.windows.first?.rootViewController?.present(activityVC, animated: true, completion: nil)
                    }
                }
                ShareLink("Export Original MobileGestalt", item: origMGURL)
            }
            Section {
                Button("Clear bookassetd UUID") {
                    bookassetdUUID = nil
                }
                .disabled(bookassetdUUID == nil)
            } footer: {
                Text("For debugging only.")
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") {}
        } message: {
            Text(lastError ?? "???")
        }
        .alert("Instruction", isPresented: $showBookassetdUUIDGuideAlert) {
            Button("Got it") {
                LSApplicationWorkspaceDefaultWorkspace().openApplication(withBundleID: "com.apple.iBooks")
            }
        } message: {
            Text("SparseBox needs to get bookassetd UUID to continue. Please download a book from Apple Books app while this app is running, then come back here.")
        }
        .navigationTitle("MobileGestalt")
        .onAppear {
            if initError != nil {
                lastError = initError
                initError = nil
                showErrorAlert.toggle()
                return
            }
            
            if let cacheExtra = mobileGestalt["CacheExtra"] as? NSMutableDictionary {
                productType = cacheExtra["h9jDsbgj7xIVeIQ8S3/X3Q"] as! String
            }
        }
        .onChange(of: scenePhase) { newPhase in
            // keep HTTP server alive in the background for a while
            if scenePhase == .inactive {
                Utils.bgTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {
                    // This executes when time is about to run out
                    UIApplication.shared.endBackgroundTask(Utils.bgTask)
                    Utils.bgTask = .invalid
                })
                if Utils.bgTask == .invalid {
                    print("Failed to start background task")
                    return
                }
            } else if scenePhase == .active {
                if Utils.bgTask != .invalid {
                    UIApplication.shared.endBackgroundTask(Utils.bgTask)
                    Utils.bgTask = .invalid
                }
            }
        }
    }
    
    init() {
        let documentsDirectory = URL.documentsDirectory
        featFlagsURL = documentsDirectory.appendingPathComponent("FeatureFlags.plist", conformingTo: .data)
        origMGURL = documentsDirectory.appendingPathComponent("OriginalMobileGestalt.plist", conformingTo: .data)
        modMGURL = documentsDirectory.appendingPathComponent("ModifiedMobileGestalt.plist", conformingTo: .data)
        
        do {
            if !FileManager.default.fileExists(atPath: origMGURL.path) {
                let url = URL(filePath: "/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist")
                try FileManager.default.copyItem(at: url, to: origMGURL)
            }
            chmod(origMGURL.path, 0o644)
            
            if !FileManager.default.fileExists(atPath: modMGURL.path) {
                try FileManager.default.copyItem(at: origMGURL, to: modMGURL)
            }
            chmod(modMGURL.path, 0o644)
            
            _mobileGestalt = State(initialValue: try NSMutableDictionary(contentsOf: modMGURL, error: ()))
        } catch {
            _mobileGestalt = State(initialValue: [:])
            _initError = State(initialValue: "Failed to copy MobileGestalt: \(error)")
            taskRunning = true
        }
    }
    
    func bindingForAppleIntelligence() -> Binding<Bool> {
        guard let cacheExtra = mobileGestalt["CacheExtra"] as? NSMutableDictionary else {
            return State(initialValue: false).projectedValue
        }
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

    func bindingForRegionRestriction() -> Binding<Bool> {
        guard let cacheExtra = mobileGestalt["CacheExtra"] as? NSMutableDictionary else {
            return State(initialValue: false).projectedValue
        }
        return Binding<Bool>(
            get: {
                return cacheExtra["h63QSdBCiT/z0WU6rdQv6Q"] as? String == "US" &&
                    cacheExtra["zHeENZu+wbg7PUprwNwBWg"] as? String == "LL/A"
            },
            set: { enabled in
                if enabled {
                    cacheExtra["h63QSdBCiT/z0WU6rdQv6Q"] = "US"
                    cacheExtra["zHeENZu+wbg7PUprwNwBWg"] = "LL/A"
                } else {
                    cacheExtra.removeObject(forKey: "h63QSdBCiT/z0WU6rdQv6Q")
                    cacheExtra.removeObject(forKey: "zHeENZu+wbg7PUprwNwBWg")
                }
            }
        )
    }
    
    func bindingForInternalStuff() -> Binding<Bool> {
        // we need to do it via CacheData
        guard let cacheData = mobileGestalt["CacheData"] as? NSMutableData else {
            return State(initialValue: false).projectedValue
        }
        let off_appleInternalInstall = FindCacheDataOffset("EqrsVvjcYDdxHBiQmGhAWw")
        let off_HasInternalSettingsBundle = FindCacheDataOffset("Oji6HRoPi7rH7HPdWVakuw")
        let off_InternalBuild = FindCacheDataOffset("LBJfwOEzExRxzlAnSuI7eg")
        //print("Read value from \(cacheData.mutableBytes.load(fromByteOffset: valueOffset, as: Int.self))")
        
        return Binding(
            get: {
                return cacheData.bytes.load(fromByteOffset: off_appleInternalInstall, as: Int.self) == 1
            },
            set: { enabled in
                cacheData.mutableBytes.storeBytes(of: enabled ? 1 : 0, toByteOffset: off_appleInternalInstall, as: Int.self)
                cacheData.mutableBytes.storeBytes(of: enabled ? 1 : 0, toByteOffset: off_HasInternalSettingsBundle, as: Int.self)
                cacheData.mutableBytes.storeBytes(of: enabled ? 1 : 0, toByteOffset: off_InternalBuild, as: Int.self)
            }
        )
    }
    
    func bindingForTrollPad() -> Binding<Bool> {
        // We're going to overwrite DeviceClassNumber but we can't do it via CacheExtra, so we need to do it via CacheData instead
        guard let cacheData = mobileGestalt["CacheData"] as? NSMutableData,
              let cacheExtra = mobileGestalt["CacheExtra"] as? NSMutableDictionary else {
            return State(initialValue: false).projectedValue
        }
        let valueOffset = FindCacheDataOffset("mtrAoWJ3gsq+I90ZnQ0vQw")
        //print("Read value from \(cacheData.mutableBytes.load(fromByteOffset: valueOffset, as: Int.self))")
        
        let keys = [
            "uKc7FPnEO++lVhHWHFlGbQ", // ipad
            "mG0AnH/Vy1veoqoLRAIgTA", // MedusaFloatingLiveAppCapability
            "UCG5MkVahJxG1YULbbd5Bg", // MedusaOverlayAppCapability
            "ZYqko/XM5zD3XBfN5RmaXA", // MedusaPinnedAppCapability
            "nVh/gwNpy7Jv1NOk00CMrw", // MedusaPIPCapability,
            "qeaj75wk3HF4DwQ8qbIi7g", // DeviceSupportsEnhancedMultitasking
        ]
        return Binding(
            get: {
                if let value = cacheExtra[keys.first!] as? Int? {
                    return value == 1
                }
                return false
            },
            set: { enabled in
                cacheData.mutableBytes.storeBytes(of: enabled ? 3 : 1, toByteOffset: valueOffset, as: Int.self)
                for key in keys {
                    if enabled {
                        cacheExtra[key] = 1
                    } else {
                        // just remove the key as it will be pulled from device tree if missing
                        cacheExtra.removeObject(forKey: key)
                    }
                }
            }
        )
    }
    
    func bindingForMGKeys<T: Equatable>(_ keys: [String], type: T.Type = Int.self, defaultValue: T? = 0, enableValue: T? = 1) -> Binding<Bool> {
        guard let cacheExtra = mobileGestalt["CacheExtra"] as? NSMutableDictionary else {
            return State(initialValue: false).projectedValue
        }
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
    
    func performApplyMobileGestalt() async throws {
        let context = JITEnableContext.shared
        var line: String
        
        // get bookassetd container uuid
        if bookassetdUUID == nil {
            showBookassetdUUIDGuideAlert.toggle()
            
            print("Finding bookassetd container UUID...")
            print("Please open Books app and download a book to continue.")
            line = try await waitForSyslogLine(matches: { $0.contains("bookassetd") && $0.contains("/Documents/BLDownloads/") })
            
            // Return to SparseBox
            LSApplicationWorkspaceDefaultWorkspace().openApplication(withBundleID: Bundle.main.bundleIdentifier!)
            
            bookassetdUUID = line.components(separatedBy: "/var/containers/Shared/SystemGroup/")[1]
                .components(separatedBy: "/Documents/BLDownloads")[0]
            if bookassetdUUID == nil {
                lastError = "Failed to get bookassetd container UUID from syslog."
                showErrorAlert = true
                return
            }
        }
        
        print("bookassetd container UUID: \(bookassetdUUID!)")
        
        // copy files from bundle to Documents folder
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let d28LocalPath = documentsDirectory.appendingPathComponent("downloads.28.sqlitedb").path
        let bldLocalPath = documentsDirectory.appendingPathComponent("BLDatabaseManager.sqlite").path
        let bundle = Bundle.main
        if !FileManager.default.fileExists(atPath: d28LocalPath),
           let resourcePath = bundle.path(forResource: "downloads.28", ofType: "sqlitedb") {
            try? FileManager.default.copyItem(atPath: resourcePath, toPath: d28LocalPath)
        }
        if !FileManager.default.fileExists(atPath: bldLocalPath),
           let resourcePath = bundle.path(forResource: "BLDatabaseManager", ofType: "sqlite") {
            try? FileManager.default.copyItem(atPath: resourcePath, toPath: bldLocalPath)
        }
        if !FileManager.default.fileExists(atPath: bldLocalPath + "-shm"),
            let resourcePath = bundle.path(forResource: "BLDatabaseManager", ofType: "sqlite-shm") {
            try? FileManager.default.copyItem(atPath: resourcePath, toPath: bldLocalPath + "-shm")
        }
        if !FileManager.default.fileExists(atPath: bldLocalPath + "-wal"),
            let resourcePath = bundle.path(forResource: "BLDatabaseManager", ofType: "sqlite-wal") {
            try? FileManager.default.copyItem(atPath: resourcePath, toPath: bldLocalPath + "-wal")
        }
        
        print("Patching BLDatabaseManager.sqlite...")
        try Databases.patchDatabase(dbPath: d28LocalPath, uuid: bookassetdUUID!, ip: "localhost", port: Utils.port)
        
        // Kill bookassetd and Books processes to stop them from updating BLDatabaseManager.sqlite
        var processes: [Int32 : String?] = try getRunningProcesses()
        var pid_bookassetd = processes.first { $0.value?.hasSuffix("/bookassetd") == true }?.key
        var pid_Books = processes.first { $0.value?.hasSuffix("/Books") == true }?.key
        if let pid_bookassetd {
            print("Stopping bookassetd (pid \(pid_bookassetd))...")
            try context?.killProcess(withPID: pid_bookassetd, signal: SIGSTOP)
        }
        if let pid_Books {
            print("Killing Books (pid \(pid_Books))...")
            try context?.killProcess(withPID: pid_Books, signal: SIGKILL)
        }
        
        // Upload com.apple.MobileGestalt.plist
        print("Uploading com.apple.MobileGestalt.plist")
        try context?.afcPushFile(modMGURL.path(), toPath: "com.apple.MobileGestalt.plist")
        
        // Upload downloads.28.sqlitedb
        print("Uploading downloads.28.sqlitedb")
        try context?.afcPushFile(d28LocalPath, toPath: "Downloads/downloads.28.sqlitedb")
        try context?.afcPushFile(d28LocalPath + "-shm", toPath: "Downloads/downloads.28.sqlitedb-shm")
        try context?.afcPushFile(d28LocalPath + "-wal", toPath: "Downloads/downloads.28.sqlitedb-wal")
        // conn.close()
        
        // Kill itunesstored to trigger BLDataBaseManager.sqlite overwrite
        processes = try getRunningProcesses()
        let pid_itunesstored = processes.first { $0.value?.hasSuffix("/itunesstored") == true }?.key
        if let pid_itunesstored {
            print("Killing itunesstored (pid \(pid_itunesstored))...")
            try context?.killProcess(withPID: pid_itunesstored, signal: SIGKILL)
        }
        
        // Wait for itunesstored to finish download and raise an error
        print("Waiting for itunesstored to finish download...")
        // FIXME: syslog not working
        _ = try await waitForSyslogLine(matches: { $0.contains("Install complete for download: 6936249076851270152 result: Failed") }, timeout: 2)
        
        // Kill bookassetd and Books processes to trigger MobileGestalt overwrite
        pid_bookassetd = processes.first { $0.value?.hasSuffix("/bookassetd") == true }?.key
        pid_Books = processes.first { $0.value?.hasSuffix("/Books") == true }?.key
        if let pid_bookassetd {
            print("Killing bookassetd (pid \(pid_bookassetd))...")
            try context?.killProcess(withPID: pid_bookassetd, signal: SIGKILL)
        }
        if let pid_Books {
            print("Killing Books (pid \(pid_Books))...")
            try context?.killProcess(withPID: pid_Books, signal: SIGKILL)
        }
        
        // Re-open Books app
        LSApplicationWorkspaceDefaultWorkspace().openApplication(withBundleID: "com.apple.iBooks")
        LSApplicationWorkspaceDefaultWorkspace().openApplication(withBundleID: Bundle.main.bundleIdentifier!)
        
        print("Waiting for MobileGestalt overwrite to complete...")
        let success_message = "/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist) [Install-Mgr]: Marking download as [finished]"
        // FIXME: syslog not working
        _ = try await waitForSyslogLine(matches: { $0.contains(success_message) }, timeout: 3)
        
        if respring {
            print("Respringing...")
            let pid_backboardd = processes.first { $0.value?.hasSuffix("/backboardd") == true }?.key
            if let pid_backboardd {
                try context?.killProcess(withPID: pid_backboardd, signal: SIGKILL)
            }
        }
        
//        let deviceList = MobileDevice.deviceList()
//        guard deviceList.count == 1 else {
//            print("Invalid device count: \(deviceList.count)")
//            return
//        }
//        Utils.udid = deviceList.first!
//        D28BookChain.replaceMobileGestalt(udid: Utils.udid, path: "/aaaaa")
        
        /*
        MobileDevice.requireAppleFileConduitService(udid: Utils.udid) { client in
            var file: UInt64 = 0
            let ret = afc_file_open(client, "/Downloads/downloads.28.sqlitedb", AFC_FOPEN_RW, &file)
            guard ret == AFC_E_SUCCESS else {
                print("AFC open failed with code \(ret)")
                return
            }
            
            let d28LocalPath = Bundle.main.url(forResource: "downloads", withExtension: "28.sqlitedb")!
            let d28Data = try! Data(contentsOf: d28LocalPath)
            d28Data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
                let writeRet = afc_file_write(client, file, ptr.baseAddress!, UInt32(d28Data.count), <#UnsafeMutablePointer<UInt32>?#>)
                guard writeRet == AFC_E_SUCCESS else {
                    print("AFC write failed with code \(writeRet)")
                    return
                }
            }
        }
         */
    }
    
    func getRunningProcesses() throws -> [Int32 : String?] {
        Dictionary(
            uniqueKeysWithValues: (try JITEnableContext.shared?.fetchProcessList() as! [[String: Any]])
                .compactMap { item in
                    guard let pid = item["pid"] as? Int32 else { return nil }
                    let path = item["path"] as? String
                    return (pid, path)
                }
        )
    }
    
    func waitForSyslogLine(matches predicate: @escaping (String) -> Bool, timeout: TimeInterval? = nil) async throws -> String {
        let result = try await withCheckedThrowingContinuation { continuation in
            var resumed = false
            JITEnableContext.shared.startSyslogRelay { line in
                if predicate(line!) {
                    resumed = true
                    continuation.resume(returning: line!)
                }
            } onError: { error in
                resumed = true
                continuation.resume(throwing: error!)
            }
            
            if let timeout {
                DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                    if resumed { return }
                    continuation.resume(returning: "Timed out waiting for syslog line.")
                }
            }
        }
        JITEnableContext.shared.stopSyslogRelay()
        return result
    }
}
