// Aircover fork: the Moonshine xcframework ships a macOS arm64 slice only.
// SPM compiles this whole module into a single object, so without this guard an
// x86_64 build pulls every Swift wrapper in and fails to link against C symbols
// that have no x86_64 slice. Guarded, the module is simply empty on Intel and the
// consuming app keeps building universal. See scripts/build-swift-macos-arm64.sh.
#if arch(arm64)

import Foundation

/// Base error class for all Moonshine Voice errors.
public enum MoonshineError: Error {
    case unknown(message: String = "Unknown error")
    case invalidHandle(message: String = "Invalid handle")
    case invalidArgument(message: String = "Invalid argument")
    case busy(
        message: String =
            "A streaming reply is in flight. Finish it with endInput(), or drop it with cancelStream()."
    )
    case custom(message: String, code: Int32)
    
    /// Error code associated with the error
    public var errorCode: Int32 {
        switch self {
        case .unknown:
            return -1
        case .invalidHandle:
            return -2
        case .invalidArgument:
            return -3
        case .busy:
            return -4
        case .custom(_, let code):
            return code
        }
    }
    
    /// Human-readable error message
    public var message: String {
        switch self {
        case .unknown(let message):
            return message
        case .invalidHandle(let message):
            return message
        case .invalidArgument(let message):
            return message
        case .busy(let message):
            return message
        case .custom(let message, _):
            return message
        }
    }
}

/// Helper function to check error codes and throw appropriate Swift errors
internal func checkError(_ errorCode: Int32) throws {
    guard errorCode >= 0 else {
        switch errorCode {
        case -1:
            throw MoonshineError.unknown()
        case -2:
            throw MoonshineError.invalidHandle()
        case -3:
            throw MoonshineError.invalidArgument()
        case -4:
            throw MoonshineError.busy()
        default:
            throw MoonshineError.custom(message: "Unknown error code: \(errorCode)", code: errorCode)
        }
    }
}

#endif // arch(arm64)
