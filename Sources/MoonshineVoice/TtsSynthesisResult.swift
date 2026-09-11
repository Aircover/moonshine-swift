// Aircover fork: the Moonshine xcframework ships a macOS arm64 slice only.
// SPM compiles this whole module into a single object, so without this guard an
// x86_64 build pulls every Swift wrapper in and fails to link against C symbols
// that have no x86_64 slice. Guarded, the module is simply empty on Intel and the
// consuming app keeps building universal. See scripts/build-swift-macos-arm64.sh.
#if arch(arm64)

import Foundation

/// Result of a text-to-speech synthesis call.
public struct TtsSynthesisResult {
    /// Mono PCM float samples, approximately in the range -1.0 to 1.0.
    public let samples: [Float]
    /// Sample rate in Hz (typically 24000).
    public let sampleRateHz: Int32
}

/// One piece of streamed audio from ``TextToSpeech/stream(_:)``.
public struct TtsChunk: Sendable {
    /// Mono PCM float samples, approximately in the range -1.0 to 1.0.
    public let samples: [Float]
    /// Sample rate in Hz (typically 24000).
    public let sampleRateHz: Int32
    /// The text this chunk covers, or `""` when the engine cannot attribute it.
    public let text: String
    /// Which queued utterance this chunk belongs to, counting from zero.
    public let utteranceId: UInt64
    /// True for the last chunk of an utterance.
    public let isFinal: Bool
}

#endif // arch(arm64)
