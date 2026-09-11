// Aircover fork: the Moonshine xcframework ships a macOS arm64 slice only.
// SPM compiles this whole module into a single object, so without this guard an
// x86_64 build pulls every Swift wrapper in and fails to link against C symbols
// that have no x86_64 slice. Guarded, the module is simply empty on Intel and the
// consuming app keeps building universal. See scripts/build-swift-macos-arm64.sh.
#if arch(arm64)

import Foundation

/// The subset of ``Stream`` that ``MicTranscriber`` drives.
///
/// Abstracting the stream behind a protocol lets tests inject a stand-in that
/// makes the (normally native) transcription observable and deterministically
/// slow, so we can verify that transcription never runs on the audio capture
/// thread (see issue #196).
protocol TranscriptionStream: AnyObject {
    func start() throws
    func stop() throws
    func close()
    func addAudio(_ audioData: [Float], sampleRate: Int32) throws
    func addListener(_ listener: @escaping (TranscriptEvent) throws -> Void)
    func addListener(_ listener: TranscriptEventListener)
    func removeListener(_ listener: @escaping (TranscriptEvent) throws -> Void)
    func removeListener(_ listener: TranscriptEventListener)
    func removeAllListeners()
}

extension Stream: TranscriptionStream {}

#endif // arch(arm64)
