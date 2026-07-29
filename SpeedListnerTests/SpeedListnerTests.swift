//
//  SpeedListnerTests.swift
//  SpeedListnerTests
//
//  Created by YATIN  KALRA on 09/09/24.
//

import XCTest
import AVFoundation
@testable import SpeedListner

final class SpeedListnerTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testBookmarkClipRangeUsesFiveSecondPreRollAndFifteenSecondPostRoll() {
        let range = AudioClipUtils.clipRange(around: 100, duration: 1_000)

        XCTAssertEqual(range.start, 95, accuracy: 0.001)
        XCTAssertEqual(range.end, 115, accuracy: 0.001)
    }

    func testBookmarkClipRangeClampsAtBookBoundaries() {
        let beginning = AudioClipUtils.clipRange(around: 2, duration: 100)
        XCTAssertEqual(beginning.start, 0, accuracy: 0.001)
        XCTAssertEqual(beginning.end, 17, accuracy: 0.001)

        let ending = AudioClipUtils.clipRange(around: 98, duration: 100)
        XCTAssertEqual(ending.start, 93, accuracy: 0.001)
        XCTAssertEqual(ending.end, 100, accuracy: 0.001)
    }

    func testBookmarkClipRangeClampsTimestampOutsideBookDuration() {
        let beforeBeginning = AudioClipUtils.clipRange(around: -10, duration: 100)
        XCTAssertEqual(beforeBeginning.start, 0, accuracy: 0.001)
        XCTAssertEqual(beforeBeginning.end, 15, accuracy: 0.001)

        let afterEnding = AudioClipUtils.clipRange(around: 110, duration: 100)
        XCTAssertEqual(afterEnding.start, 95, accuracy: 0.001)
        XCTAssertEqual(afterEnding.end, 100, accuracy: 0.001)
    }

    func testBookmarkExtractionUsesRequestedDecodedAudioFrames() throws {
        let fileManager = FileManager.default
        let inputURL = fileManager.temporaryDirectory
            .appendingPathComponent("bookmark_input_\(UUID().uuidString).m4a")
        let outputURL = fileManager.temporaryDirectory
            .appendingPathComponent("bookmark_output_\(UUID().uuidString).m4a")
        defer {
            try? fileManager.removeItem(at: inputURL)
            try? fileManager.removeItem(at: outputURL)
        }

        let sampleRate = 44_100.0
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 128_000
        ]
        var inputFile: AVAudioFile? = try AVAudioFile(
            forWriting: inputURL,
            settings: settings
        )
        let format = try XCTUnwrap(inputFile?.processingFormat)
        let frameCount = AVAudioFrameCount(sampleRate * 4)
        let buffer = try XCTUnwrap(
            AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)
        )
        buffer.frameLength = frameCount
        let samples = try XCTUnwrap(buffer.floatChannelData?[0])

        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let frequency = time < 2 ? 440.0 : 1_760.0
            samples[frame] = Float(sin(2 * .pi * frequency * time) * 0.5)
        }
        try inputFile?.write(from: buffer)
        inputFile = nil
        try Data("old clip".utf8).write(to: outputURL)

        let extractionFinished = expectation(description: "Decoded clip extraction finished")
        var extractedURL: URL?
        AudioClipUtils.extractClip(
            from: inputURL,
            startTime: 2.25,
            endTime: 3.25,
            outputURL: outputURL
        ) { url in
            extractedURL = url
            extractionFinished.fulfill()
        }
        wait(for: [extractionFinished], timeout: 10)

        let extractedFile = try AVAudioFile(forReading: XCTUnwrap(extractedURL))
        XCTAssertEqual(
            Double(extractedFile.length) / extractedFile.processingFormat.sampleRate,
            1,
            accuracy: 0.08
        )

        let extractedBuffer = try XCTUnwrap(
            AVAudioPCMBuffer(
                pcmFormat: extractedFile.processingFormat,
                frameCapacity: AVAudioFrameCount(extractedFile.length)
            )
        )
        try extractedFile.read(into: extractedBuffer)
        let extractedSamples = try XCTUnwrap(extractedBuffer.floatChannelData?[0])
        var zeroCrossings = 0
        for frame in 1..<Int(extractedBuffer.frameLength) {
            if extractedSamples[frame - 1] <= 0, extractedSamples[frame] > 0 {
                zeroCrossings += 1
            }
        }

        XCTAssertGreaterThan(zeroCrossings, 1_500)
    }

    func testOpenAIErrorUsesAPIMessage() throws {
        let data = try JSONSerialization.data(withJSONObject: [
            "error": [
                "message": "You exceeded your current quota.",
                "type": "insufficient_quota"
            ]
        ])
        let response = try XCTUnwrap(
            HTTPURLResponse(
                url: URL(string: "https://api.openai.com/v1/audio/transcriptions")!,
                statusCode: 429,
                httpVersion: nil,
                headerFields: nil
            )
        )

        let error = TranscriptionAI.openAIError(from: data, response: response)

        XCTAssertEqual(error?.localizedDescription, "You exceeded your current quota.")
    }

    func testRandomPlaybackCandidatesExcludeCurrentBook() {
        XCTAssertEqual(
            PlayerManager.randomCandidateIndices(queueCount: 4, excluding: 2),
            [0, 1, 3]
        )
        XCTAssertTrue(
            PlayerManager.randomCandidateIndices(queueCount: 1, excluding: 0).isEmpty
        )
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
