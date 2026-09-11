// Aircover fork: the Moonshine xcframework ships a macOS arm64 slice only.
// SPM compiles this whole module into a single object, so without this guard an
// x86_64 build pulls every Swift wrapper in and fails to link against C symbols
// that have no x86_64 slice. Guarded, the module is simply empty on Intel and the
// consuming app keeps building universal. See scripts/build-swift-macos-arm64.sh.
#if arch(arm64)

import Foundation

/// Embedding model architectures.
public enum EmbeddingModelArch: UInt32, Sendable {
    case gemma300m = 0
}

#endif // arch(arm64)
