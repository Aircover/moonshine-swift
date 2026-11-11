// Aircover fork: see Transcriber.close() and Stream.owner.
#if arch(arm64)

import Foundation
import XCTest

@testable import MoonshineVoice

/// A streaming transcriber held its default stream and the stream held it back, so
/// once ``Transcriber/start()`` had made that stream, deinit -- and with it
/// ``Transcriber/close()`` -- never ran. Every transcriber an app ever started kept its
/// native engine: its model weights and an ONNX Runtime thread pool per session. A
/// call that restarted transcription a dozen times had about a thousand idle pool
/// threads and gigabytes of weights when it crashed.
///
/// These load a real engine, so they run under the same switch as the download tests
/// (`MOONSHINE_DOWNLOAD_TESTS=1`), which fetch the tiny streaming model.
final class TranscriberLifecycleTests: XCTestCase {

    nonisolated(unsafe) private static var modelRoot: URL?

    override func setUp() async throws {
        try await super.setUp()
        let raw = ProcessInfo.processInfo.environment["MOONSHINE_DOWNLOAD_TESTS"]?
            .lowercased() ?? ""
        guard ["1", "true", "yes"].contains(raw) else {
            throw XCTSkip("Set MOONSHINE_DOWNLOAD_TESTS=1 to run tests that load a real engine")
        }
        if Self.modelRoot == nil {
            let root = FileManager.default.temporaryDirectory
                .appendingPathComponent("moonshine-lifecycle-tiny-streaming")
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            _ = try await AssetDownloader().ensureModelPresent(
                root: root, spec: .stt(language: "en", modelArch: .tinyStreaming))
            Self.modelRoot = root
        }
    }

    private func makeStartedTranscriber() throws -> Transcriber {
        let transcriber = try Transcriber(
            modelPath: Self.modelRoot!.path, modelArch: .tinyStreaming)
        try transcriber.start()
        try transcriber.addAudio([Float](repeating: 0, count: 16000), sampleRate: 16000)
        return transcriber
    }

    private static func threadCount() -> Int {
        var threads: thread_act_array_t?
        var count: mach_msg_type_number_t = 0
        guard task_threads(mach_task_self_, &threads, &count) == KERN_SUCCESS, let threads else {
            return -1
        }
        for i in 0..<Int(count) {
            mach_port_deallocate(mach_task_self_, threads[i])
        }
        vm_deallocate(
            mach_task_self_, vm_address_t(UInt(bitPattern: threads)),
            vm_size_t(Int(count) * MemoryLayout<thread_t>.stride))
        return Int(count)
    }

    func testAStartedTranscriberIsFreedWhenReleased() throws {
        weak var released: Transcriber?
        weak var releasedStream: MoonshineVoice.Stream?
        try autoreleasepool {
            let transcriber = try makeStartedTranscriber()
            try transcriber.stop()
            released = transcriber
            releasedStream = try transcriber.getDefaultStream()
        }
        XCTAssertNil(released, "the default stream must not keep its transcriber alive")
        XCTAssertNil(releasedStream)
    }

    /// The native side of the same leak: each engine's thread pools go with it.
    func testRestartingDoesNotAccumulateEngineThreads() throws {
        // One engine first, so lazily made process-wide threads are already counted.
        try autoreleasepool { _ = try makeStartedTranscriber() }
        let baseline = Self.threadCount()

        for _ in 0..<5 {
            try autoreleasepool {
                let transcriber = try makeStartedTranscriber()
                try transcriber.stop()
            }
        }
        // Pool threads exit asynchronously once their pool is torn down.
        let deadline = Date().addingTimeInterval(5)
        while Self.threadCount() > baseline + 2 && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.1)
        }
        XCTAssertLessThanOrEqual(
            Self.threadCount(), baseline + 2,
            "five released transcribers left their engine threads behind")
    }

    /// The native layer hands a freed handle's ID to the next transcriber it loads, so
    /// closing twice -- an explicit close() and then deinit's -- must not free the
    /// newer transcriber that now has that ID.
    func testClosingTwiceLeavesTheNextTranscriberAlone() throws {
        let first = try makeStartedTranscriber()
        try first.stop()
        first.close()

        let second = try makeStartedTranscriber()
        first.close()
        XCTAssertNoThrow(
            try second.addAudio([Float](repeating: 0, count: 16000), sampleRate: 16000))
        XCTAssertNoThrow(try second.stop())
        second.close()
    }

    func testAClosedTranscribersStreamRefusesWork() throws {
        let transcriber = try makeStartedTranscriber()
        let stream = try transcriber.getDefaultStream()
        transcriber.close()

        XCTAssertTrue(transcriber.isClosed)
        XCTAssertThrowsError(try transcriber.getDefaultStream())
        XCTAssertThrowsError(try stream.start())
        XCTAssertThrowsError(try stream.updateTranscription())
        // addAudio on an inactive stream is a no-op rather than an error, as before.
        XCTAssertNoThrow(try stream.addAudio([0], sampleRate: 16000))
    }
}

#endif
