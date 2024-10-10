import SwiftUI

let logPipe = Pipe()

struct LogView: View {
    let udid: String
    let willReboot: Bool
    let mbdb: Backup
    @State var log: String = ""
    @State var ran = false
    @State var isRebooting = false
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
                        if !data.isEmpty, var logString = String(data: data, encoding: .utf8) {
                            if logString.contains(udid) {
                                logString = logString.replacingOccurrences(of: udid, with: "<redacted>")
                            }
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
        .navigationTitle(isRebooting ? "Rebooting device" : "Log output")
    }
    
    init(mbdb: Backup, reboot: Bool) {
        setvbuf(stdout, nil, _IOLBF, 0) // make stdout line-buffered
        setvbuf(stderr, nil, _IONBF, 0) // make stderr unbuffered
        
        // create the pipe and redirect stdout and stderr
        dup2(logPipe.fileHandleForWriting.fileDescriptor, fileno(stdout))
        dup2(logPipe.fileHandleForWriting.fileDescriptor, fileno(stderr))
        
        self.mbdb = mbdb
        self.willReboot = reboot
        
        let deviceList = MobileDevice.deviceList()
        guard deviceList.count == 1 else {
            print("Invalid device count: \(deviceList.count)")
            udid = "invalid"
            return
        }
        udid = deviceList.first!
    }
    
    func performRestore() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = documentsDirectory.appendingPathComponent(udid, conformingTo: .data)
        
        do {
            try? FileManager.default.removeItem(at: folder)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
            try mbdb.writeTo(directory: folder)
            
            // Restore now
            var restoreArgs = [
                "idevicebackup2",
                "-n", "restore", "--no-reboot", "--system",
                documentsDirectory.path(percentEncoded: false)
            ]
            print("Executing args: \(restoreArgs)")
            var argv = restoreArgs.map{ strdup($0) }
            let result = idevicebackup2_main(Int32(restoreArgs.count), &argv)
            print("idevicebackup2 exited with code \(result)")
            
            if log.contains("Domain name cannot contain a slash") {
                print("ERROR: this iOS version is not supported.")
            } else if log.contains("crash_on_purpose") {
                print("Restore succeeded")
                if willReboot && result == 0 {
                    isRebooting.toggle()
                    MobileDevice.rebootDevice(udid: udid)
                }
            }
            
            logPipe.fileHandleForReading.readabilityHandler = nil
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    
}
