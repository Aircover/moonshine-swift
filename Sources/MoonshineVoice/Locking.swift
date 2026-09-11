// Aircover fork: the Moonshine xcframework ships a macOS arm64 slice only.
// SPM compiles this whole module into a single object, so without this guard an
// x86_64 build pulls every Swift wrapper in and fails to link against C symbols
// that have no x86_64 slice. Guarded, the module is simply empty on Intel and the
// consuming app keeps building universal. See scripts/build-swift-macos-arm64.sh.
#if arch(arm64)

import Foundation

/// A mutex with a scoped `withLock`, usable from `async` code.
///
/// `NSLock.lock()` is unavailable in asynchronous contexts (holding it across a
/// suspension point would block a cooperative thread), and its own `withLock`
/// needs a newer deployment target than this package has, so the engines share
/// this small wrapper. Nothing here ever awaits while holding the lock.
final class Mutex: @unchecked Sendable {
    private let underlying = NSLock()

    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        underlying.lock()
        defer { underlying.unlock() }
        return try body()
    }
}

#endif // arch(arm64)
