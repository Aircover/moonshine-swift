// Aircover fork: the Moonshine xcframework ships a macOS arm64 slice only.
// SPM compiles this whole module into a single object, so without this guard an
// x86_64 build pulls every Swift wrapper in and fails to link against C symbols
// that have no x86_64 slice. Guarded, the module is simply empty on Intel and the
// consuming app keeps building universal. See scripts/build-swift-macos-arm64.sh.
#if arch(arm64)

import Foundation

/// Protocol for objects that can listen to transcript events.
/// 
/// Implement this protocol to receive notifications about transcription events.
/// All methods have default no-op implementations, so you only need to override
/// the ones you care about.
public protocol TranscriptEventListener: AnyObject {
    /// Called when a new transcription line starts.
    func onLineStarted(_ event: LineStarted)
    
    /// Called when an existing transcription line is updated.
    func onLineUpdated(_ event: LineUpdated)
    
    /// Called when the text of a transcription line changes.
    func onLineTextChanged(_ event: LineTextChanged)
    
    /// Called when the speaker spans of a transcription line change. Can be
    /// called for lines that are already complete.
    func onLineSpeakersChanged(_ event: LineSpeakersChanged)
    
    /// Called when a transcription line is completed.
    func onLineCompleted(_ event: LineCompleted)
    
    /// Called when an error occurs.
    func onError(_ event: TranscriptError)
}

/// Default implementations that do nothing.
public extension TranscriptEventListener {
    func onLineStarted(_ event: LineStarted) {}
    func onLineUpdated(_ event: LineUpdated) {}
    func onLineTextChanged(_ event: LineTextChanged) {}
    func onLineSpeakersChanged(_ event: LineSpeakersChanged) {}
    func onLineCompleted(_ event: LineCompleted) {}
    func onError(_ event: TranscriptError) {}
}

#endif // arch(arm64)
