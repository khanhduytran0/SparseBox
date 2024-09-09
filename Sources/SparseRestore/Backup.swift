import CryptoKit
import Foundation

let MODE_DEFAULT = S_IRUSR | S_IWUSR | S_IXUSR | S_IRGRP | S_IXGRP | S_IROTH | S_IXOTH

class BackupFile {
    var path: String
    var domain: String
    init(path: String, domain: String) {
        self.path = path
        self.domain = domain
    }

    public func toRecord() -> MBDBRecord {
        fatalError("Subclass must implement this function");
    }
}

class ConcreteFile: BackupFile {
    var contents: Data
    var owner: Int32
    var group: Int32
    var inode: UInt64?
    var mode: UInt16
    
    init(path: String, domain: String, contents: Data, owner: Int32 = 0, group: Int32 = 0, inode: UInt64? = nil, mode: UInt16 = MODE_DEFAULT) {
        self.contents = contents
        self.owner = owner
        self.group = group
        self.inode = inode
        self.mode = mode
        super.init(path: path, domain: domain)
    }
    
    override public func toRecord() -> MBDBRecord {
        let time = UInt32(Date().timeIntervalSince1970)
        return MBDBRecord(
            domain: domain,
            filename: path,
            link: "",
            hash: Data(Insecure.SHA1.hash(data: contents)),
            key: Data(),
            mode: mode | S_IFREG,
            inode: inode ?? UInt64(Date().timeIntervalSince1970*10000000),
            user_id: owner,
            group_id: group,
            mtime: time,
            atime: time,
            ctime: time,
            size: UInt64(contents.count),
            flags: 4,
            properties: [:])
    }
}

class SymbolicLink: BackupFile {
    var target: String
    var owner: Int32
    var group: Int32
    var inode: UInt64?
    var mode: UInt16
    
    init(path: String, domain: String, target: String, owner: Int32 = 0, group: Int32 = 0, inode: UInt64? = nil, mode: UInt16 = MODE_DEFAULT) {
        self.target = target
        self.owner = owner
        self.group = group
        self.inode = inode
        self.mode = mode
        super.init(path: path, domain: domain)
    }
    
    override public func toRecord() -> MBDBRecord {
        let time = UInt32(Date().timeIntervalSince1970)
        return MBDBRecord(
            domain: domain,
            filename: path,
            link: target,
            hash: Data(),
            key: Data(),
            mode: mode | S_IFLNK,
            inode: inode ?? UInt64(Date().timeIntervalSince1970*10000000),
            user_id: owner,
            group_id: group,
            mtime: time,
            atime: time,
            ctime: time,
            size: 0,
            flags: 4,
            properties: [:])
    }
}

class Directory: BackupFile {
    var owner: Int32
    var group: Int32
    var mode: UInt16
    
    init(path: String, domain: String, owner: Int32 = 0, group: Int32 = 0, mode: UInt16 = MODE_DEFAULT) {
        self.owner = owner
        self.group = group
        self.mode = mode
        super.init(path: path, domain: domain)
    }
    
    override public func toRecord() -> MBDBRecord {
        let time = UInt32(Date().timeIntervalSince1970)
        return MBDBRecord(
            domain: domain,
            filename: path,
            link: "",
            hash: Data(),
            key: Data(),
            mode: mode | S_IFDIR,
            inode: 0,
            user_id: owner,
            group_id: group,
            mtime: time,
            atime: time,
            ctime: time,
            size: 0,
            flags: 4,
            properties: [:])
    }
}

class Backup {
    var files: [BackupFile]
 
    init(files: [BackupFile]) {
        self.files = files
    }
    
    func writeTo(directory: URL) throws {
        for file in files {
            if file is ConcreteFile {
                let fileName = file.domain + "-" + file.path
                let hashedFileName = Data(Insecure.SHA1.hash(data: fileName.data(using: .utf8)!))
                    .map { String(format: "%02hhx", $0) }.joined()
                let filePath = directory.appendingPathComponent(hashedFileName, conformingTo: .data)
                try (file as! ConcreteFile).contents.write(to: filePath)
            }
        }
        
        let manifestDBPath = directory.appendingPathComponent("Manifest.mbdb", conformingTo: .data)
        try generateManifestDB().write(to: manifestDBPath)
        
        let statusPath = directory.appendingPathComponent("Status.plist", conformingTo: .data)
        try PropertyListSerialization.data(fromPropertyList: generateStatus(), format: .xml, options: 0)
            .write(to: statusPath)
        
        let manifestPlistPath = directory.appendingPathComponent("Manifest.plist", conformingTo: .data)
        try PropertyListSerialization.data(fromPropertyList: generateManifest(), format: .xml, options: 0)
            .write(to: manifestPlistPath)
        
        let infoPlistPath = directory.appendingPathComponent("Info.plist", conformingTo: .data)
        try PropertyListSerialization.data(fromPropertyList: [:], format: .xml, options: 0)
            .write(to: infoPlistPath)
    }

    func generateManifestDB() -> Data {
        var records = [MBDBRecord]()
        for file in files {
            records.append(file.toRecord())
        }
        return MobileBackupDatabase(records: records).toData()
    }

    func generateStatus() -> [String : Any] {
        return [
            "BackupState": "new",
            "Date": Date(),
            //datetime.fromisoformat("1970-01-01T00:00:00+00:00"),
            "IsFullBackup": false,
            "SnapshotState": "finished",
            "UUID": "00000000-0000-0000-0000-000000000000",
            "Version": "2.4"
        ]
    }
    
    func generateManifest() -> [String : Any] {
        return [
            "BackupKeyBag": Data(base64Encoded: """
            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
            Z8FDgd7YoALY1g==
            """, options: .ignoreUnknownCharacters)!,
            "Lockdown": [:],
            "SystemDomainsVersion": "20.0",
            "Version": "9.1"
        ]
    }
}
