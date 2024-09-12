import SwiftUI

let logPipe = Pipe()

struct LogView: View {
    @State var log: String = ""
    @State var ran = false
    let willReboot: Bool
    let mobileGestaltURL: URL
    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                ScrollView {
                    Text(log)
                        .font(.system(size: 12).monospaced())
                        .fixedSize(horizontal: false, vertical: false)
                        .textSelection(.enabled)
                    Spacer()
                        .id(0)
                }
                .onAppear {
                    guard !ran else { return }
                    ran = true
                    
                    logPipe.fileHandleForReading.readabilityHandler = { fileHandle in
                        let data = fileHandle.availableData
                        if !data.isEmpty, let logString = String(data: data, encoding: .utf8) {
                            log.append(logString)
                            proxy.scrollTo(0)
                        }
                    }
                    
                    DispatchQueue.global(qos: .background).async {
                        performRestore()
                    }
                }
            }
        }
        .navigationTitle("Log output")
    }
    
    init(mgURL: URL, reboot: Bool) {
        setvbuf(stdout, nil, _IOLBF, 0) // make stdout line-buffered
        setvbuf(stderr, nil, _IONBF, 0) // make stderr unbuffered
        
        // create the pipe and redirect stdout and stderr
        dup2(logPipe.fileHandleForWriting.fileDescriptor, fileno(stdout))
        dup2(logPipe.fileHandleForWriting.fileDescriptor, fileno(stderr))
        
        mobileGestaltURL = mgURL
        willReboot = reboot
    }
    
    func performRestore() {
        let deviceList = MobileDevice.deviceList()
        guard deviceList.count == 1 else {
            print("Invalid device count: \(deviceList.count)")
            return
        }
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = documentsDirectory.appendingPathComponent(deviceList.first!, conformingTo: .data)
        
        do {
            try? FileManager.default.removeItem(at: folder)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
            
            let mbdb = createBackupFile(from: mobileGestaltURL, to: URL(filePath: "/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/NOT.apple.MobileGestalt.plist"))
            try mbdb.writeTo(directory: folder)
            
            // Restore now
            var restoreArgs = [
                "idevicebackup2",
                "-n", "restore", "--system",
                documentsDirectory.path(percentEncoded: false)
            ]
            if !willReboot {
                restoreArgs.insert("--no-reboot", at: 3)
            }
            print("Executing args: \(restoreArgs)")
            var argv = restoreArgs.map{ strdup($0) }
            let result = idevicebackup2_main(Int32(restoreArgs.count), &argv)
            print("idevicebackup2 exited with code \(result)")
            logPipe.fileHandleForReading.readabilityHandler = nil
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    func createBackupFile(from: URL, to: URL) -> Backup {
        // open the file and read the contents
        let contents = try! Data(contentsOf: from)
        
        // required on iOS 17.0+ since /var/mobile is on a separate partition
        let basePath = to.path(percentEncoded: false).hasPrefix("/var/mobile/") ? "/var/mobile/backup" : "/var/backup"
        
        // create the backup
        return Backup(files: [
            Directory(path: "", domain: "RootDomain"),
            Directory(path: "Library", domain: "RootDomain"),
            Directory(path: "Library/Preferences", domain: "RootDomain"),
            ConcreteFile(path: "Library/Preferences/temp", domain: "RootDomain", contents: contents),
            Directory(path: "", domain: "SysContainerDomain-../../../../../../../..\(basePath)\(to.deletingLastPathComponent().path(percentEncoded: false))", owner: 501, group: 501),
            ConcreteFile(path: "", domain: "SysContainerDomain-../../../../../../../..\(basePath)\(to.path())", contents: Data(), owner: 501, group: 501),
            // Break the hard link
            ConcreteFile(path: "", domain: "SysContainerDomain-../../../../../../../../var/.backup.i/var/root/Library/Preferences/temp", contents: Data(), owner: 501, group: 501),
            ConcreteFile(path: "", domain: "SysContainerDomain-../../../../../../../../crash_on_purpose", contents: Data()),
        ])
    }
}
