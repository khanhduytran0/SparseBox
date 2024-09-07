// import RustXcframework
public func start_emotional_damage<GenericToRustStr: ToRustStr>(_ bind_addr: GenericToRustStr) -> Optional<EMPError> {
    return bind_addr.toRustStr({ bind_addrAsRustStr in
        __swift_bridge__$start_emotional_damage(bind_addrAsRustStr).intoSwiftRepr()
    })
}
public func stop_emotional_damage() {
    __swift_bridge__$stop_emotional_damage()
}
public func test_emotional_damage(_ timeout: UInt32) -> Optional<EMPError> {
    __swift_bridge__$test_emotional_damage(timeout).intoSwiftRepr()
}
public enum EMPError {
    case InvalidAddress
    case InvalidPort
    case InvalidSocket
    case AlreadyRunning
    case Unknown
}
extension EMPError {
    func intoFfiRepr() -> __swift_bridge__$EMPError {
        switch self {
        case EMPError.InvalidAddress:
            return __swift_bridge__$EMPError(tag: __swift_bridge__$EMPError$InvalidAddress)
        case EMPError.InvalidPort:
            return __swift_bridge__$EMPError(tag: __swift_bridge__$EMPError$InvalidPort)
        case EMPError.InvalidSocket:
            return __swift_bridge__$EMPError(tag: __swift_bridge__$EMPError$InvalidSocket)
        case EMPError.AlreadyRunning:
            return __swift_bridge__$EMPError(tag: __swift_bridge__$EMPError$AlreadyRunning)
        case EMPError.Unknown:
            return __swift_bridge__$EMPError(tag: __swift_bridge__$EMPError$Unknown)
        }
    }
}
extension __swift_bridge__$EMPError {
    func intoSwiftRepr() -> EMPError {
        switch self.tag {
        case __swift_bridge__$EMPError$InvalidAddress:
            return EMPError.InvalidAddress
        case __swift_bridge__$EMPError$InvalidPort:
            return EMPError.InvalidPort
        case __swift_bridge__$EMPError$InvalidSocket:
            return EMPError.InvalidSocket
        case __swift_bridge__$EMPError$AlreadyRunning:
            return EMPError.AlreadyRunning
        case __swift_bridge__$EMPError$Unknown:
            return EMPError.Unknown
        default:
            fatalError("Unreachable")
        }
    }
}
extension __swift_bridge__$Option$EMPError {
    @inline(__always)
    func intoSwiftRepr() -> Optional<EMPError> {
        if self.is_some {
            return self.val.intoSwiftRepr()
        } else {
            return nil
        }
    }
    @inline(__always)
    static func fromSwiftRepr(_ val: Optional<EMPError>) -> __swift_bridge__$Option$EMPError {
        if let v = val {
            return __swift_bridge__$Option$EMPError(is_some: true, val: v.intoFfiRepr())
        } else {
            return __swift_bridge__$Option$EMPError(is_some: false, val: __swift_bridge__$EMPError())
        }
    }
}
extension EMPError {
    public static func vecOfSelfNew() -> UnsafeMutableRawPointer {
        __swift_bridge__$Vec_EMPError$new()
    }
    
    public static func vecOfSelfFree(vecPtr: UnsafeMutableRawPointer) {
        __swift_bridge__$Vec_EMPError$drop(vecPtr)
    }
    
    public static func vecOfSelfPush(vecPtr: UnsafeMutableRawPointer, value: Self) {
        __swift_bridge__$Vec_EMPError$push(vecPtr, value.intoFfiRepr())
    }
    
    public static func vecOfSelfPop(vecPtr: UnsafeMutableRawPointer) -> Optional<Self> {
        let maybeEnum = __swift_bridge__$Vec_EMPError$pop(vecPtr)
        return maybeEnum.intoSwiftRepr()
    }
    
    public static func vecOfSelfGet(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<Self> {
        let maybeEnum = __swift_bridge__$Vec_EMPError$get(vecPtr, index)
        return maybeEnum.intoSwiftRepr()
    }
    
    public static func vecOfSelfGetMut(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<Self> {
        let maybeEnum = __swift_bridge__$Vec_EMPError$get_mut(vecPtr, index)
        return maybeEnum.intoSwiftRepr()
    }
    
    public static func vecOfSelfLen(vecPtr: UnsafeMutableRawPointer) -> UInt {
        __swift_bridge__$Vec_EMPError$len(vecPtr)
    }
}
extension EMPError: CustomDebugStringConvertible {
    public var debugDescription: String {
        RustString(ptr: __swift_bridge__$EMPError$Debug(self.intoFfiRepr())).toString()
    }
}
