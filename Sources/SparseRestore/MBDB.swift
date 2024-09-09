import Foundation

struct MBDBRecord {
    var domain: String
    var filename: String
    var link: String
    var hash: Data
    var key: Data
    var mode: UInt16
    var inode: UInt64
    var user_id: Int32
    var group_id: Int32
    var mtime: UInt32
    var atime: UInt32
    var ctime: UInt32
    var size: UInt64
    var flags: UInt8
    var properties: [String: String]
    // var properties: list
    
    init(domain: String, filename: String, link: String, hash: Data, key: Data, mode: UInt16, inode: UInt64, user_id: Int32, group_id: Int32, mtime: UInt32, atime: UInt32, ctime: UInt32, size: UInt64, flags: UInt8, properties: [String : String]) {
        self.domain = domain
        self.filename = filename
        self.link = link
        self.hash = hash
        self.key = key
        self.mode = mode
        self.inode = inode
        self.user_id = user_id
        self.group_id = group_id
        self.mtime = mtime
        self.atime = atime
        self.ctime = ctime
        self.size = size
        self.flags = flags
        self.properties = properties
    }
    
    init(buffer: inout ByteBuffer) {
        let domain_len = Int(buffer.readInteger(endianness: .big, as: Int16.self)!)
        domain = buffer.readString(length: domain_len)!
        
        let filename_len = Int(buffer.readInteger(endianness: .big, as: Int16.self)!)
        filename = buffer.readString(length: filename_len)!
        
        let link_len = Int(buffer.readInteger(endianness: .big, as: Int16.self)!)
        link = buffer.readString(length: link_len)!
        
        let hash_len = Int(buffer.readInteger(endianness: .big, as: Int16.self)!)
        if hash_len != 0xffff {
            hash = buffer.readData(length: hash_len)!
        } else {
            hash = Data()
        }
        
        let key_len = Int(buffer.readInteger(endianness: .big, as: Int16.self)!)
        if key_len != 0xffff {
            key = buffer.readData(length: key_len)!
        } else {
            key = Data()
        }
  
        mode = buffer.readInteger(endianness: .big, as: UInt16.self)!
        //unknown2 = int.from_bytes(d.read(4), "big")
        //unknown3 = int.from_bytes(d.read(4), "big")
        inode = buffer.readInteger(endianness: .big, as: UInt64.self)!
        user_id = buffer.readInteger(endianness: .big, as: Int32.self)!
        group_id = buffer.readInteger(endianness: .big, as: Int32.self)!
        mtime = buffer.readInteger(endianness: .big, as: UInt32.self)!
        atime = buffer.readInteger(endianness: .big, as: UInt32.self)!
        ctime = buffer.readInteger(endianness: .big, as: UInt32.self)!
        size = buffer.readInteger(endianness: .big, as: UInt64.self)!
        flags = buffer.readInteger(endianness: .big, as: UInt8.self)!
        properties = [:]
        
        let properties_count = buffer.readInteger(endianness: .big, as: UInt8.self)!
        
        /*
        print("domainlen \(domain_len) domain \(domain)")
        print("filenamelen \(filename_len) filename \(filename)")
        print("linklen \(link_len) link \(link)")
        print("hashlen \(hash_len) hash \(hash)")
        print("keylen \(key_len) key \(key)")
        print("mode \(mode)")
        print("inode \(inode)")
        print("uid \(user_id)")
        print("gid \(group_id)")
        print("mtime \(mtime)")
        print("atime \(atime)")
        print("ctime \(ctime)")
        print("size \(size)")
        print("flags \(flags)")
        print("props \(properties_count)")
        */
        
        for _ in 0..<properties_count {
            var name = ""
            var value = ""
            let name_len = Int(buffer.readInteger(endianness: .big, as: UInt16.self)!)
            print("name len \(name_len)")
            if name_len != 0xffff {
                name = buffer.readString(length: name_len)!
            }
            let value_len = Int(buffer.readInteger(endianness: .big, as: UInt16.self)!)
            if value_len != 0xffff {
                value = buffer.readString(length: value_len)!
            }
            properties[name] = value
        }
    }
    
    init(data: Data) {
        var buffer = ByteBuffer(data: data)
        self.init(buffer: &buffer)
    }
    
    func toData() -> Data {
        // FIXME: any better way?
        var capacity = 2*5 + domain.count + filename.count + link.count + hash.count + key.count + 2 + 8 + 4*5 + 8 + 1 + 1
        for (name, value) in properties {
            capacity += 2*2 + name.count + value.count
        }
        var buffer = ByteBufferAllocator().buffer(capacity: capacity)
        
        buffer.writeInteger(Int16(domain.count), endianness: .big, as: Int16.self)
        buffer.writeString(domain)
        
        buffer.writeInteger(Int16(filename.count), endianness: .big, as: Int16.self)
        buffer.writeString(filename)
        
        buffer.writeInteger(Int16(link.count), endianness: .big, as: Int16.self)
        buffer.writeString(link)
        
        buffer.writeInteger(Int16(hash.count), endianness: .big, as: Int16.self)
        buffer.writeData(hash)
        
        buffer.writeInteger(Int16(key.count), endianness: .big, as: Int16.self)
        buffer.writeData(key)
        
        buffer.writeInteger(mode, endianness: .big, as: UInt16.self)
        buffer.writeInteger(inode, endianness: .big, as: UInt64.self)
        buffer.writeInteger(user_id, endianness: .big, as: Int32.self)
        buffer.writeInteger(group_id, endianness: .big, as: Int32.self)
        buffer.writeInteger(mtime, endianness: .big, as: UInt32.self)
        buffer.writeInteger(atime, endianness: .big, as: UInt32.self)
        buffer.writeInteger(ctime, endianness: .big, as: UInt32.self)
        buffer.writeInteger(size, endianness: .big, as: UInt64.self)
        buffer.writeInteger(flags, endianness: .big, as: UInt8.self)
        
        buffer.writeInteger(UInt8(properties.count), endianness: .big, as: UInt8.self)
        for (name, value) in properties {
            buffer.writeInteger(UInt16(name.count), endianness: .big, as: UInt16.self)
            buffer.writeString(name)
            buffer.writeInteger(UInt16(value.count), endianness: .big, as: UInt16.self)
            buffer.writeString(value)
        }
        
        return buffer.readData(length: buffer.readableBytes)!
    }
}

struct MobileBackupDatabase {
    let magic = "mbdb"
    let version: [UInt8] = [0x05, 0x00];
    var records: [MBDBRecord]
    
    init(data: Data) {
        var buffer = ByteBuffer(data: data)
        if let dataMagic = buffer.readString(length: 4) {
            if dataMagic != magic {
                fatalError("Wrong magic")
            }
        } else {
            fatalError("Can't parse magic")
        }
        if let dataVersion = buffer.readInteger(endianness: .big, as: UInt16.self) {
            print("Version: \(dataVersion)")
        } else {
            fatalError("Can't parse version")
        }
        
        records = [MBDBRecord]()
        while buffer.readableBytes > 0 {
            records.append(MBDBRecord(buffer: &buffer))
        }
    }
    
    init(records: [MBDBRecord]) {
        self.records = records
    }
    
    func toData() -> Data {
        var result = NSMutableData()
        result.append(Data(magic.utf8))
        result.append(version, length: version.count)
        for record in records {
            result.append(record.toData())
        }
        return result as Data
    }
}
