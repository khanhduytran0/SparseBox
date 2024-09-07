public func describe_error(_ error: MinimuxerError) -> RustString {
    RustString(ptr: __swift_bridge__$describe_error(error.intoFfiRepr()))
}
public func ready() -> Bool {
    __swift_bridge__$ready()
}
public func set_debug(_ debug: Bool) {
    __swift_bridge__$set_debug(debug)
}
public enum MinimuxerError {
    case NoDevice
    case NoConnection
    case PairingFile
    case CreateDebug
    case CreateInstproxy
    case LookupApps
    case FindApp
    case BundlePath
    case MaxPacket
    case WorkingDirectory
    case Argv
    case LaunchSuccess
    case Detach
    case Attach
    case CreateAfc
    case RwAfc
    case InstallApp(RustString)
    case UninstallApp
    case CreateMisagent
    case ProfileInstall
    case ProfileRemove
}
extension MinimuxerError {
    func intoFfiRepr() -> __swift_bridge__$MinimuxerError {
        switch self {
            case MinimuxerError.NoDevice:
                return {var val = __swift_bridge__$MinimuxerError(); val.tag = __swift_bridge__$MinimuxerError$NoDevice; return val }()
            case MinimuxerError.NoConnection:
                return {var val = __swift_bridge__$MinimuxerError(); val.tag = __swift_bridge__$MinimuxerError$NoConnection; return val }()
            case MinimuxerError.PairingFile:
                return {var val = __swift_bridge__$MinimuxerError(); val.tag = __swift_bridge__$MinimuxerError$PairingFile; return val }()
            case MinimuxerError.CreateDebug:
                return {var val = __swift_bridge__$MinimuxerError(); val.tag = __swift_bridge__$MinimuxerError$CreateDebug; return val }()
            case MinimuxerError.CreateInstproxy:
                return {var val = __swift_bridge__$MinimuxerError(); val.tag = __swift_bridge__$MinimuxerError$CreateInstproxy; return val }()
            case MinimuxerError.LookupApps:
                return {var val = __swift_bridge__$MinimuxerError(); val.tag = __swift_bridge__$MinimuxerError$LookupApps; return val }()
            case MinimuxerError.FindApp:
                return {var val = __swift_bridge__$MinimuxerError(); val.tag = __swift_bridge__$MinimuxerError$FindApp; return val }()
            case MinimuxerError.BundlePath:
                return {var val = __swift_bridge__$MinimuxerError(); val.tag = __swift_bridge__$MinimuxerError$BundlePath; return val }()
            case MinimuxerError.MaxPacket:
                return {var val = __swift_bridge__$MinimuxerError(); val.tag = __swift_bridge__$MinimuxerError$MaxPacket; return val }()
            case MinimuxerError.WorkingDirectory:
                return {var val = __swift_bridge__$MinimuxerError(); val.tag = __swift_bridge__$MinimuxerError$WorkingDirectory; return val }()
            case MinimuxerError.Argv:
                return {var val = __swift_bridge__$MinimuxerError(); val.tag = __swift_bridge__$MinimuxerError$Argv; return val }()
            case MinimuxerError.LaunchSuccess:
                return {var val = __swift_bridge__$MinimuxerError(); val.tag = __swift_bridge__$MinimuxerError$LaunchSuccess; return val }()
            case MinimuxerError.Detach:
                return {var val = __swift_bridge__$MinimuxerError(); val.tag = __swift_bridge__$MinimuxerError$Detach; return val }()
            case MinimuxerError.Attach:
                return {var val = __swift_bridge__$MinimuxerError(); val.tag = __swift_bridge__$MinimuxerError$Attach; return val }()
            case MinimuxerError.CreateAfc:
                return {var val = __swift_bridge__$MinimuxerError(); val.tag = __swift_bridge__$MinimuxerError$CreateAfc; return val }()
            case MinimuxerError.RwAfc:
                return {var val = __swift_bridge__$MinimuxerError(); val.tag = __swift_bridge__$MinimuxerError$RwAfc; return val }()
            case MinimuxerError.InstallApp(let _0):
                return __swift_bridge__$MinimuxerError(tag: __swift_bridge__$MinimuxerError$InstallApp, payload: __swift_bridge__$MinimuxerErrorFields(InstallApp: __swift_bridge__$MinimuxerError$FieldOfInstallApp(_0: { let rustString = _0.intoRustString(); rustString.isOwned = false; return rustString.ptr }())))
            case MinimuxerError.UninstallApp:
                return {var val = __swift_bridge__$MinimuxerError(); val.tag = __swift_bridge__$MinimuxerError$UninstallApp; return val }()
            case MinimuxerError.CreateMisagent:
                return {var val = __swift_bridge__$MinimuxerError(); val.tag = __swift_bridge__$MinimuxerError$CreateMisagent; return val }()
            case MinimuxerError.ProfileInstall:
                return {var val = __swift_bridge__$MinimuxerError(); val.tag = __swift_bridge__$MinimuxerError$ProfileInstall; return val }()
            case MinimuxerError.ProfileRemove:
                return {var val = __swift_bridge__$MinimuxerError(); val.tag = __swift_bridge__$MinimuxerError$ProfileRemove; return val }()
        }
    }
}
extension __swift_bridge__$MinimuxerError {
    func intoSwiftRepr() -> MinimuxerError {
        switch self.tag {
            case __swift_bridge__$MinimuxerError$NoDevice:
                return MinimuxerError.NoDevice
            case __swift_bridge__$MinimuxerError$NoConnection:
                return MinimuxerError.NoConnection
            case __swift_bridge__$MinimuxerError$PairingFile:
                return MinimuxerError.PairingFile
            case __swift_bridge__$MinimuxerError$CreateDebug:
                return MinimuxerError.CreateDebug
            case __swift_bridge__$MinimuxerError$CreateInstproxy:
                return MinimuxerError.CreateInstproxy
            case __swift_bridge__$MinimuxerError$LookupApps:
                return MinimuxerError.LookupApps
            case __swift_bridge__$MinimuxerError$FindApp:
                return MinimuxerError.FindApp
            case __swift_bridge__$MinimuxerError$BundlePath:
                return MinimuxerError.BundlePath
            case __swift_bridge__$MinimuxerError$MaxPacket:
                return MinimuxerError.MaxPacket
            case __swift_bridge__$MinimuxerError$WorkingDirectory:
                return MinimuxerError.WorkingDirectory
            case __swift_bridge__$MinimuxerError$Argv:
                return MinimuxerError.Argv
            case __swift_bridge__$MinimuxerError$LaunchSuccess:
                return MinimuxerError.LaunchSuccess
            case __swift_bridge__$MinimuxerError$Detach:
                return MinimuxerError.Detach
            case __swift_bridge__$MinimuxerError$Attach:
                return MinimuxerError.Attach
            case __swift_bridge__$MinimuxerError$CreateAfc:
                return MinimuxerError.CreateAfc
            case __swift_bridge__$MinimuxerError$RwAfc:
                return MinimuxerError.RwAfc
            case __swift_bridge__$MinimuxerError$InstallApp:
                return MinimuxerError.InstallApp(RustString(ptr: self.payload.InstallApp._0))
            case __swift_bridge__$MinimuxerError$UninstallApp:
                return MinimuxerError.UninstallApp
            case __swift_bridge__$MinimuxerError$CreateMisagent:
                return MinimuxerError.CreateMisagent
            case __swift_bridge__$MinimuxerError$ProfileInstall:
                return MinimuxerError.ProfileInstall
            case __swift_bridge__$MinimuxerError$ProfileRemove:
                return MinimuxerError.ProfileRemove
            default:
                fatalError("Unreachable")
        }
    }
}
extension __swift_bridge__$Option$MinimuxerError {
    @inline(__always)
    func intoSwiftRepr() -> Optional<MinimuxerError> {
        if self.is_some {
            return self.val.intoSwiftRepr()
        } else {
            return nil
        }
    }
    @inline(__always)
    static func fromSwiftRepr(_ val: Optional<MinimuxerError>) -> __swift_bridge__$Option$MinimuxerError {
        if let v = val {
            return __swift_bridge__$Option$MinimuxerError(is_some: true, val: v.intoFfiRepr())
        } else {
            return __swift_bridge__$Option$MinimuxerError(is_some: false, val: __swift_bridge__$MinimuxerError())
        }
    }
}



public class RustDirectoryEntry: RustDirectoryEntryRefMut {
    var isOwned: Bool = true

    public override init(ptr: UnsafeMutableRawPointer) {
        super.init(ptr: ptr)
    }

    deinit {
        if isOwned {
            __swift_bridge__$RustDirectoryEntry$_free(ptr)
        }
    }
}
public class RustDirectoryEntryRefMut: RustDirectoryEntryRef {
    public override init(ptr: UnsafeMutableRawPointer) {
        super.init(ptr: ptr)
    }
}
public class RustDirectoryEntryRef {
    var ptr: UnsafeMutableRawPointer

    public init(ptr: UnsafeMutableRawPointer) {
        self.ptr = ptr
    }
}
extension RustDirectoryEntryRef {
    public func path() -> RustString {
        RustString(ptr: __swift_bridge__$RustDirectoryEntry$path(ptr))
    }

    public func parent() -> RustString {
        RustString(ptr: __swift_bridge__$RustDirectoryEntry$parent(ptr))
    }

    public func isFile() -> Bool {
        __swift_bridge__$RustDirectoryEntry$is_file(ptr)
    }

    public func size() -> Optional<UInt32> {
        __swift_bridge__$RustDirectoryEntry$size(ptr).intoSwiftRepr()
    }

    public func children() -> RustVec<RustDirectoryEntry> {
        RustVec(ptr: __swift_bridge__$RustDirectoryEntry$children(ptr))
    }
}
extension RustDirectoryEntry: Vectorizable {
    public static func vecOfSelfNew() -> UnsafeMutableRawPointer {
        __swift_bridge__$Vec_RustDirectoryEntry$new()
    }

    public static func vecOfSelfFree(vecPtr: UnsafeMutableRawPointer) {
        __swift_bridge__$Vec_RustDirectoryEntry$drop(vecPtr)
    }

    public static func vecOfSelfPush(vecPtr: UnsafeMutableRawPointer, value: RustDirectoryEntry) {
        __swift_bridge__$Vec_RustDirectoryEntry$push(vecPtr, {value.isOwned = false; return value.ptr;}())
    }

    public static func vecOfSelfPop(vecPtr: UnsafeMutableRawPointer) -> Optional<Self> {
        let pointer = __swift_bridge__$Vec_RustDirectoryEntry$pop(vecPtr)
        if pointer == nil {
            return nil
        } else {
            return (RustDirectoryEntry(ptr: pointer!) as! Self)
        }
    }

    public static func vecOfSelfGet(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<RustDirectoryEntryRef> {
        let pointer = __swift_bridge__$Vec_RustDirectoryEntry$get(vecPtr, index)
        if pointer == nil {
            return nil
        } else {
            return RustDirectoryEntryRef(ptr: pointer!)
        }
    }

    public static func vecOfSelfGetMut(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<RustDirectoryEntryRefMut> {
        let pointer = __swift_bridge__$Vec_RustDirectoryEntry$get_mut(vecPtr, index)
        if pointer == nil {
            return nil
        } else {
            return RustDirectoryEntryRefMut(ptr: pointer!)
        }
    }

    public static func vecOfSelfAsPtr(vecPtr: UnsafeMutableRawPointer) -> UnsafePointer<RustDirectoryEntryRef> {
        UnsafePointer<RustDirectoryEntryRef>(OpaquePointer(__swift_bridge__$Vec_RustDirectoryEntry$as_ptr(vecPtr)))
    }

    public static func vecOfSelfLen(vecPtr: UnsafeMutableRawPointer) -> UInt {
        __swift_bridge__$Vec_RustDirectoryEntry$len(vecPtr)
    }
}


public class AfcFileManager: AfcFileManagerRefMut {
    var isOwned: Bool = true

    public override init(ptr: UnsafeMutableRawPointer) {
        super.init(ptr: ptr)
    }

    deinit {
        if isOwned {
            __swift_bridge__$AfcFileManager$_free(ptr)
        }
    }
}
extension AfcFileManager {
    class public func remove<GenericIntoRustString: IntoRustString>(_ path: GenericIntoRustString) throws -> () {
        try { let val = __swift_bridge__$AfcFileManager$remove({ let rustString = path.intoRustString(); rustString.isOwned = false; return rustString.ptr }()); switch val.tag { case __swift_bridge__$ResultVoidAndErrors$ResultOk: return case __swift_bridge__$ResultVoidAndErrors$ResultErr: throw val.payload.err.intoSwiftRepr() default: fatalError() } }()
    }

    class public func createDirectory<GenericIntoRustString: IntoRustString>(_ path: GenericIntoRustString) throws -> () {
        try { let val = __swift_bridge__$AfcFileManager$create_directory({ let rustString = path.intoRustString(); rustString.isOwned = false; return rustString.ptr }()); switch val.tag { case __swift_bridge__$ResultVoidAndErrors$ResultOk: return case __swift_bridge__$ResultVoidAndErrors$ResultErr: throw val.payload.err.intoSwiftRepr() default: fatalError() } }()
    }

    class public func writeFile<GenericIntoRustString: IntoRustString>(_ to: GenericIntoRustString, _ bytes: UnsafeBufferPointer<UInt8>) throws -> () {
        try { let val = __swift_bridge__$AfcFileManager$write_file({ let rustString = to.intoRustString(); rustString.isOwned = false; return rustString.ptr }(), bytes.toFfiSlice()); switch val.tag { case __swift_bridge__$ResultVoidAndErrors$ResultOk: return case __swift_bridge__$ResultVoidAndErrors$ResultErr: throw val.payload.err.intoSwiftRepr() default: fatalError() } }()
    }

    class public func copyFileOutsideAfc<GenericIntoRustString: IntoRustString>(_ from: GenericIntoRustString, _ to: GenericIntoRustString) throws -> () {
        try { let val = __swift_bridge__$AfcFileManager$copy_file_outside_afc({ let rustString = from.intoRustString(); rustString.isOwned = false; return rustString.ptr }(), { let rustString = to.intoRustString(); rustString.isOwned = false; return rustString.ptr }()); switch val.tag { case __swift_bridge__$ResultVoidAndErrors$ResultOk: return case __swift_bridge__$ResultVoidAndErrors$ResultErr: throw val.payload.err.intoSwiftRepr() default: fatalError() } }()
    }
}
public class AfcFileManagerRefMut: AfcFileManagerRef {
    public override init(ptr: UnsafeMutableRawPointer) {
        super.init(ptr: ptr)
    }
}
public class AfcFileManagerRef {
    var ptr: UnsafeMutableRawPointer

    public init(ptr: UnsafeMutableRawPointer) {
        self.ptr = ptr
    }
}
extension AfcFileManagerRef {
    class public func contents() -> RustVec<RustDirectoryEntry> {
        RustVec(ptr: __swift_bridge__$AfcFileManager$contents())
    }
}
extension AfcFileManager: Vectorizable {
    public static func vecOfSelfNew() -> UnsafeMutableRawPointer {
        __swift_bridge__$Vec_AfcFileManager$new()
    }

    public static func vecOfSelfFree(vecPtr: UnsafeMutableRawPointer) {
        __swift_bridge__$Vec_AfcFileManager$drop(vecPtr)
    }

    public static func vecOfSelfPush(vecPtr: UnsafeMutableRawPointer, value: AfcFileManager) {
        __swift_bridge__$Vec_AfcFileManager$push(vecPtr, {value.isOwned = false; return value.ptr;}())
    }

    public static func vecOfSelfPop(vecPtr: UnsafeMutableRawPointer) -> Optional<Self> {
        let pointer = __swift_bridge__$Vec_AfcFileManager$pop(vecPtr)
        if pointer == nil {
            return nil
        } else {
            return (AfcFileManager(ptr: pointer!) as! Self)
        }
    }

    public static func vecOfSelfGet(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<AfcFileManagerRef> {
        let pointer = __swift_bridge__$Vec_AfcFileManager$get(vecPtr, index)
        if pointer == nil {
            return nil
        } else {
            return AfcFileManagerRef(ptr: pointer!)
        }
    }

    public static func vecOfSelfGetMut(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<AfcFileManagerRefMut> {
        let pointer = __swift_bridge__$Vec_AfcFileManager$get_mut(vecPtr, index)
        if pointer == nil {
            return nil
        } else {
            return AfcFileManagerRefMut(ptr: pointer!)
        }
    }

    public static func vecOfSelfAsPtr(vecPtr: UnsafeMutableRawPointer) -> UnsafePointer<AfcFileManagerRef> {
        UnsafePointer<AfcFileManagerRef>(OpaquePointer(__swift_bridge__$Vec_AfcFileManager$as_ptr(vecPtr)))
    }

    public static func vecOfSelfLen(vecPtr: UnsafeMutableRawPointer) -> UInt {
        __swift_bridge__$Vec_AfcFileManager$len(vecPtr)
    }
}



public func fetch_udid() -> Optional<RustString> {
    { let val = __swift_bridge__$fetch_udid(); if val != nil { return RustString(ptr: val!) } else { return nil } }()
}
public func test_device_connection() -> Bool {
    __swift_bridge__$test_device_connection()
}


public func yeet_app_afc<GenericIntoRustString: IntoRustString>(_ bundle_id: GenericIntoRustString, _ ipa_bytes: UnsafeBufferPointer<UInt8>) throws -> () {
    try { let val = __swift_bridge__$yeet_app_afc({ let rustString = bundle_id.intoRustString(); rustString.isOwned = false; return rustString.ptr }(), ipa_bytes.toFfiSlice()); switch val.tag { case __swift_bridge__$ResultVoidAndErrors$ResultOk: return case __swift_bridge__$ResultVoidAndErrors$ResultErr: throw val.payload.err.intoSwiftRepr() default: fatalError() } }()
}
public func install_ipa<GenericIntoRustString: IntoRustString>(_ bundle_id: GenericIntoRustString) throws -> () {
    try { let val = __swift_bridge__$install_ipa({ let rustString = bundle_id.intoRustString(); rustString.isOwned = false; return rustString.ptr }()); switch val.tag { case __swift_bridge__$ResultVoidAndErrors$ResultOk: return case __swift_bridge__$ResultVoidAndErrors$ResultErr: throw val.payload.err.intoSwiftRepr() default: fatalError() } }()
}
public func remove_app<GenericIntoRustString: IntoRustString>(_ bundle_id: GenericIntoRustString) throws -> () {
    try { let val = __swift_bridge__$remove_app({ let rustString = bundle_id.intoRustString(); rustString.isOwned = false; return rustString.ptr }()); switch val.tag { case __swift_bridge__$ResultVoidAndErrors$ResultOk: return case __swift_bridge__$ResultVoidAndErrors$ResultErr: throw val.payload.err.intoSwiftRepr() default: fatalError() } }()
}


public func debug_app<GenericIntoRustString: IntoRustString>(_ app_id: GenericIntoRustString) throws -> () {
    try { let val = __swift_bridge__$debug_app({ let rustString = app_id.intoRustString(); rustString.isOwned = false; return rustString.ptr }()); switch val.tag { case __swift_bridge__$ResultVoidAndErrors$ResultOk: return case __swift_bridge__$ResultVoidAndErrors$ResultErr: throw val.payload.err.intoSwiftRepr() default: fatalError() } }()
}
public func attach_debugger(_ pid: UInt32) throws -> () {
    try { let val = __swift_bridge__$attach_debugger(pid); switch val.tag { case __swift_bridge__$ResultVoidAndErrors$ResultOk: return case __swift_bridge__$ResultVoidAndErrors$ResultErr: throw val.payload.err.intoSwiftRepr() default: fatalError() } }()
}


public func start_auto_mounter<GenericIntoRustString: IntoRustString>(_ docs_path: GenericIntoRustString) {
    __swift_bridge__$start_auto_mounter({ let rustString = docs_path.intoRustString(); rustString.isOwned = false; return rustString.ptr }())
}


public func start<GenericIntoRustString: IntoRustString>(_ pairing_file: GenericIntoRustString, _ log_path: GenericIntoRustString) throws -> () {
    try { let val = __swift_bridge__$start({ let rustString = pairing_file.intoRustString(); rustString.isOwned = false; return rustString.ptr }(), { let rustString = log_path.intoRustString(); rustString.isOwned = false; return rustString.ptr }()); switch val.tag { case __swift_bridge__$ResultVoidAndErrors$ResultOk: return case __swift_bridge__$ResultVoidAndErrors$ResultErr: throw val.payload.err.intoSwiftRepr() default: fatalError() } }()
}
public func target_minimuxer_address() {
    __swift_bridge__$target_minimuxer_address()
}


public func install_provisioning_profile(_ profile: UnsafeBufferPointer<UInt8>) throws -> () {
    try { let val = __swift_bridge__$install_provisioning_profile(profile.toFfiSlice()); switch val.tag { case __swift_bridge__$ResultVoidAndErrors$ResultOk: return case __swift_bridge__$ResultVoidAndErrors$ResultErr: throw val.payload.err.intoSwiftRepr() default: fatalError() } }()
}
public func remove_provisioning_profile<GenericIntoRustString: IntoRustString>(_ id: GenericIntoRustString) throws -> () {
    try { let val = __swift_bridge__$remove_provisioning_profile({ let rustString = id.intoRustString(); rustString.isOwned = false; return rustString.ptr }()); switch val.tag { case __swift_bridge__$ResultVoidAndErrors$ResultOk: return case __swift_bridge__$ResultVoidAndErrors$ResultErr: throw val.payload.err.intoSwiftRepr() default: fatalError() } }()
}
public func dump_profiles<GenericIntoRustString: IntoRustString>(_ docs_path: GenericIntoRustString) throws -> RustString {
    try { let val = __swift_bridge__$dump_profiles({ let rustString = docs_path.intoRustString(); rustString.isOwned = false; return rustString.ptr }()); switch val.tag { case __swift_bridge__$ResultStringAndErrors$ResultOk: return RustString(ptr: val.payload.ok) case __swift_bridge__$ResultStringAndErrors$ResultErr: throw val.payload.err.intoSwiftRepr() default: fatalError() } }()
}




// tell Swift the MinimuxerError enum can be thrown
// TODO: do this through swift-bridge instead of manually
extension MinimuxerError: Error {}
