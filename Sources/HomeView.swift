import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @Environment(\.scenePhase) var scenePhase
    @State var pairingFile: String?
    @State var mbdb: Backup?
    @State var heartbeatReady = false
    @State var ddiMounted = false
    @State var showPairingFileImporter = false
    @State var showErrorAlert = false
    @State var taskRunning = false
    @State var initError: String?
    @State var lastError: String?
    @State var path = NavigationPath()
    var body: some View {
        NavigationStack(path: $path) {
            Form {
                Section {
                    HStack {
                        Text("Heartbeat status")
                        Spacer()
                        Text(heartbeatReady ? AttributedString("running", attributes: .init([.foregroundColor: UIColor.systemGreen])) : AttributedString("not started", attributes: .init([.foregroundColor: UIColor.systemRed])))
                    }
                    HStack {
                        Text("Developer Disk Image")
                        Spacer()
                        Text(ddiMounted ? AttributedString("mounted", attributes: .init([.foregroundColor: UIColor.systemGreen])) : AttributedString("not mounted", attributes: .init([.foregroundColor: UIColor.systemRed])))
                    }
                    Button(pairingFile == nil ? "Select pairing file" : "Reset pairing file") {
                        if pairingFile == nil {
                            showPairingFileImporter.toggle()
                        } else {
                            pairingFile = nil
                        }
                    }
                    .dropDestination(for: Data.self) { items, location in
                        guard let item = items.first else { return false }
                        pairingFile = String(decoding: item, as: UTF8.self)
                        guard pairingFile?.contains("DeviceCertificate") ?? false else {
                            lastError = "The file you just dropped is not a pairing file"
                            showErrorAlert.toggle()
                            pairingFile = nil
                            return false
                        }
                        savePairingFile()
                        startHeartbeat()
                        return true
                    }
                } footer: {
                    if pairingFile == nil {
                        Text("Select or drag and drop a pairing file to continue. More info: https://docs.sidestore.io/docs/getting-started/pairing-file")
                    } else if !heartbeatReady {
                        Text("Heartbeat is starting")
                    } else if !ddiMounted {
                        HStack {
                            Text("Developer Disk Image is not mounted. Please open StikDebug to mount it to continue.")
                        }
                    } else {
                        Text("Pairing file selected")
                    }
                }
                
                if !ddiMounted {
                    Section {
                        Button("Open StikDebug") {
                            if let url = URL(string: "stikjit://") {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                }
                
                Section {
                    let tempUnavailable = true
                    Button("Bypass 3 app limit") {
                        testBypassAppLimit()
                    }
                    .disabled(tempUnavailable || Restore.supportedExploitLevel() != .dotAndSlashes || !heartbeatReady || taskRunning)
                } header: {
                    Text("SparseRestore exploit")
                } footer: {
                    Text(
                        "Hide free developer apps from installd, so you could install more than 3 apps. You need to apply this for each 3 apps you install or update." +
                        "\nThis feature is currently unavailable when using idevice library." +
                        (Restore.supportedExploitLevel() == .dotAndSlashes ? "" : "\nYour iOS version (\(UIDevice.current.systemVersion)) does not support SparseRestore.")
                    )
                }
                
                Section {
                    NavigationLink("AFC") {
                        AFCBrowseView()
                    }
                } header: {
                    Text("Other tools")
                }
                
                Section {
                } footer: {
                    VStack {
                        Text("""
A terrible app by @khanhduytran0. Use it at your own risk.
Thanks to:
@SideStore team: idevice, C bindings from StikDebug
@JJTech0130: SparseRestore and backup exploit
@hanakim3945: bl_sbx exploit files and writeup
@PoomSmart: MobileGestalt dump
@Lakr233: BBackupp
@libimobiledevice
""")
                    }
                }
            }
            .fileImporter(isPresented: $showPairingFileImporter, allowedContentTypes: [UTType(filenameExtension: "mobiledevicepairing", conformingTo: .data)!, .propertyList], onCompletion: { result in
                switch result {
                case .success(let url):
                    pairingFile = try! String(contentsOf: url)
                    savePairingFile()
                    startHeartbeat()
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
                if view == "Apply3AppLimitBypass" {
                    Text("TODO")
                } else {
                    Text("Unknown view: \(view)")
                }
            }
            .navigationTitle("SparseBox")
        }
        .onAppear {
            if initError != nil {
                lastError = initError
                initError = nil
                showErrorAlert.toggle()
                return
            }
            
            if pairingFile == nil {
                pairingFile = try? String(contentsOf: URL.documentsDirectory.appendingPathComponent("pairingFile.plist"))
            }
            
            if let altPairingFile = Bundle.main.object(forInfoDictionaryKey: "ALTPairingFile") as? String, altPairingFile.count > 5000, pairingFile == nil {
                pairingFile = altPairingFile
                savePairingFile()
            }
            
            if pairingFile != nil {
                startHeartbeat()
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
    
    func savePairingFile() {
        try? pairingFile?.write(to: URL.documentsDirectory.appendingPathComponent("pairingFile.plist"), atomically: true, encoding: .utf8)
    }

    func testBypassAppLimit() {
        guard Restore.supportedExploitLevel() == .dotAndSlashes else {
            lastError = "Unsupported iOS version. Must be running iOS 18.1b4 or older."
            showErrorAlert.toggle()
            return
        }
        Task {
            taskRunning = true
            mbdb = Restore.createBypassAppLimit()
            path.append("Apply3AppLimitBypass")
            taskRunning = false
        }
    }
    
    func startHeartbeat() {
        guard pairingFile != nil else {
            return
        }
        //let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].absoluteString
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try JITEnableContext.shared.startHeartbeat()
                heartbeatReady = true
                print("Heartbeat started successfully")
                
                // quick way to check if DDI is mounted
                let ddiPath: String
                if #available(iOS 17.0, *) {
                    ddiPath = "/System/Developer/Library"
                } else {
                    ddiPath = "/Developer/Library"
                }
                ddiMounted = FileManager.default.fileExists(atPath: ddiPath)
                
                // TODO: mount DDI
//                DispatchQueue.main.async {
//                    let trustcachePath = URL.documentsDirectory.appendingPathComponent("DDI/Image.dmg.trustcache").path
//                    guard FileManager.default.fileExists(atPath: trustcachePath),
//                          !MountingProgress.shared.coolisMounted,
//                          MountingProgress.shared.mountingThread == nil else { return }
//                    MountingProgress.shared.pubMount()
//                }
            } catch {
                let err2 = error as NSError
                let code = err2.code
                print("Error: \(error.localizedDescription) (Code: \(code))")
                DispatchQueue.main.async {
                    if code == -9 {
                        do {
                            try FileManager.default.removeItem(at: URL.documentsDirectory.appendingPathComponent("pairingFile.plist"))
                            print("Removed invalid pairing file")
                        } catch {
                            print("Error removing invalid pairing file: \(error)")
                        }
                        
                        lastError = "The pairing file is invalid or expired. Please select a new pairing file."
                        showErrorAlert.toggle()
                    } else {
                        lastError = "Failed to connect to Heartbeat (\(code)). Make sure Wi‑Fi and LocalDevVPN are connected and that the device is reachable. Launch the app at least once while online before trying again."
                        showErrorAlert.toggle()
                    }
                }
            }
        }
    }
    
    func performApply3AppLimitBypass() {
        lastError = "3 app limit bypass is temporarily disabled."
        showErrorAlert.toggle()
        /*
        let deviceList = MobileDevice.deviceList()
        guard deviceList.count == 1 else {
            print("Invalid device count: \(deviceList.count)")
            return
        }
        Utils.udid = deviceList.first!
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = documentsDirectory.appendingPathComponent(Utils.udid, conformingTo: .data)
        try? FileManager.default.removeItem(at: folder)
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
            try mbdb!.writeTo(directory: folder)
            // Restore now
            let restoreArgs = [
                "idevicebackup2",
                "-n", "restore", "--no-reboot", "--system",
                documentsDirectory.path(percentEncoded: false)
            ]
            print("Executing args: \(restoreArgs)")
            var argv = restoreArgs.map{ strdup($0) }
            let result = 0 //idevicebackup2_main(Int32(restoreArgs.count), &argv)
            print("idevicebackup2 exited with code \(result)")
            
            print()
            let log = GLOBAL_LOG.text
            if log.contains("Domain name cannot contain a slash") {
                print("Result: this iOS version is not supported.")
            } else if log.contains("crash_on_purpose") || result == 0 {
                print("Result: restore successful.")
                if reboot {
                    //MobileDevice.rebootDevice(udid: Utils.udid)
                }
            }
            
            logPipe.fileHandleForReading.readabilityHandler = nil
        } catch {
            print(error.localizedDescription)
            return
        }
         */
    }
    
    func ready() -> Bool {
        heartbeatReady
    }
}
