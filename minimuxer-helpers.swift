// Make sure to modify this file in the minimuxer repo, or your changes will be reset when a new minimuxer prebuild is fetched!
import Foundation

extension Data {
    /// Converts Data to a rust byte slice.
    public func toRustByteSlice() -> RustByteSlice {
        let bytes = RustByteSlice.allocate(capacity: self.count)
        let copied = self.copyBytes(to: bytes.inner, from: nil)
        if copied != self.count {
            // this should never happen but it will be useful to know if it does
            print("🚨 uh oh, data is \(self.count) bytes but only \(copied) bytes were copied 🚨")
        }
        return bytes
    }
}

extension UnsafeBufferPointer {
    /// Converts the rust byte slice into a Data.
    public func toData() -> Data {
        Data(buffer: self)
    }
}

/// A helper class to automatically deallocate the UnsafeMutableBufferPointer it is holding.
///
/// Make sure you put it in a variable, don't pass it directly.
///
/// Example of good usage:
/// ```swift
/// let data = Data("hello".utf8).toRustByteSlice()
/// minimuxer_function(data.forRust())
/// ```
/// Example of 🚨 bad usage 🚨:
/// ```swift
/// // this will not pass the data correctly!!
/// minimuxer_function(Data("hello".utf8).toRustByteSlice().forRust())
/// ```
public class RustByteSlice {
    let inner: UnsafeMutableBufferPointer<UInt8>

    init(inner: UnsafeMutableBufferPointer<UInt8>) {
        self.inner = inner
    }

    public func forRust() -> UnsafeBufferPointer<UInt8> {
        UnsafeBufferPointer(self.inner)
    }

    static public func allocate(capacity: Int) -> RustByteSlice {
        RustByteSlice(inner: UnsafeMutableBufferPointer<UInt8>.allocate(capacity: capacity))
    }

    deinit {
        inner.deallocate()
    }
}
