// Aircover fork: the Moonshine xcframework ships a macOS arm64 slice only.
// SPM compiles this whole module into a single object, so without this guard an
// x86_64 build pulls every Swift wrapper in and fails to link against C symbols
// that have no x86_64 slice. Guarded, the module is simply empty on Intel and the
// consuming app keeps building universal. See scripts/build-swift-macos-arm64.sh.
#if arch(arm64)

import Foundation

/// Model architecture types supported by Moonshine Voice.
public enum ModelArch: UInt32, Sendable {
    case tiny = 0
    case base = 1
    case tinyStreaming = 2
    case baseStreaming = 3
    case smallStreaming = 4
    case mediumStreaming = 5
}

#endif // arch(arm64)
