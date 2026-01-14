//
//  Utils.swift
//  SparseBox
//
//  Created by Duy Tran on 20/11/25.
//

enum TabIdentifier {
    case home
    case apps
    case afc
    case mobileGestalt
    case log
}

class SharedModel: ObservableObject {
    @Published var selectedTab: TabIdentifier = .home
}

class Utils {
    static let model = SharedModel()
    static let os = ProcessInfo().operatingSystemVersion
    static var udid = "0000-000000000000"
    static var port: UInt16 = 0
    static var bgTask: UIBackgroundTaskIdentifier = .invalid
    
    static func buildToUInt64(_ build: String) -> UInt64 {
        let bytes = Array(build.utf8)
        var value: UInt64 = 0
        
        for i in 0..<min(bytes.count, 8) {
            value = (value << 8) | UInt64(bytes[i])
        }
        
        // Pad missing bytes; treat "no suffix" as highest ASCII (0x7F)
        for _ in bytes.count..<8 {
            value = (value << 8) | 0x7F
        }
        
        return value
    }
    
    static func requiresVersion(_ major : Int, _ minor: Int = 0, _ patch: Int = 0) -> Bool {
        // XXYYZZ: major XX, minor YY, patch ZZ
        let requiredVersion = major*10000 + minor*100 + patch
        let currentVersion = os.majorVersion*10000 + os.minorVersion*100 + os.patchVersion
        return currentVersion < requiredVersion
    }
    
    // https://stackoverflow.com/a/77897502
    static func reservePort() throws -> UInt16 {
        let serverSock = socket(AF_INET, SOCK_STREAM, 0)
        guard serverSock >= 0 else {
            throw ServerError.cannotReservePort
        }
        defer {
            close(serverSock)
        }
        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_addr.s_addr = INADDR_ANY
        addr.sin_port = 0 // request an ephemeral port

        var len = socklen_t(MemoryLayout<sockaddr_in>.stride)
        let res = withUnsafeMutablePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                let res1 = bind(serverSock, $0, len)
                let res2 = getsockname(serverSock, $0, &len)
                return (res1, res2)
            }
        }
        guard res.0 == 0 && res.1 == 0 else {
            throw ServerError.cannotReservePort
        }

        guard listen(serverSock, 1) == 0 else {
            throw ServerError.cannotReservePort
        }

        let clientSock = socket(AF_INET, SOCK_STREAM, 0)
        guard clientSock >= 0 else {
            throw ServerError.cannotReservePort
        }
        defer {
            close(clientSock)
        }
        let res3 = withUnsafeMutablePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.connect(clientSock, $0, len)
            }
        }
        guard res3 == 0 else {
            throw ServerError.cannotReservePort
        }

        let acceptSock = accept(serverSock, nil, nil)
        guard acceptSock >= 0 else {
            throw ServerError.cannotReservePort
        }
        defer {
            close(acceptSock)
        }
        return addr.sin_port.byteSwapped
    }

    enum ServerError: Error {
        case cannotReservePort
    }

}
