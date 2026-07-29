//
//  AudioClipUtils.swift
//  SpeedListner
//
//  Created by YATIN KALRA on 21/07/25.
//

import AVFoundation

class AudioClipUtils {

    static let bookmarkPreRoll: TimeInterval = 5.0
    static let bookmarkPostRoll: TimeInterval = 15.0

    static func clipRange(
        around timestamp: TimeInterval,
        duration: TimeInterval
    ) -> (start: TimeInterval, end: TimeInterval) {
        let safeDuration = max(0, duration)
        let safeTimestamp = min(max(timestamp, 0), safeDuration)
        return (
            start: max(0, safeTimestamp - bookmarkPreRoll),
            end: min(safeDuration, safeTimestamp + bookmarkPostRoll)
        )
    }

    static func makeClipId(bookIdentifier: String, timestamp: TimeInterval) -> String {
        let safeBookId = bookIdentifier.replacingOccurrences(of: " ", with: "_")
        let millis = Int((timestamp * 1000.0).rounded())
        return "\(safeBookId)_\(millis)_\(UUID().uuidString)"
    }

    static func buildClipURL(clipId: String) -> URL {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let clipsFolderURL = documentsURL.appendingPathComponent("Clips", isDirectory: true)

        if !fileManager.fileExists(atPath: clipsFolderURL.path) {
            try? fileManager.createDirectory(at: clipsFolderURL, withIntermediateDirectories: true)
        }
        return clipsFolderURL.appendingPathComponent("clip_\(clipId).m4a")
    }

    static func resolveClipURL(for bookmark: BookmarksModel) -> URL? {
        if let directPath = bookmark.audioClipPath,
           FileManager.default.fileExists(atPath: directPath.path) {
            return directPath
        }

        if let clipId = bookmark.clipId {
            let clipURL = buildClipURL(clipId: clipId)
            if FileManager.default.fileExists(atPath: clipURL.path) {
                return clipURL
            }
        }

        return getClipURL(for: bookmark.timeStamp)
    }

    static func extractClip(
        from inputURL: URL,
        startTime: TimeInterval,
        endTime: TimeInterval,
        clipId: String,
        completion: @escaping (URL?) -> Void
    ) {
        extractClip(
            from: inputURL,
            startTime: startTime,
            endTime: endTime,
            outputURL: buildClipURL(clipId: clipId),
            completion: completion
        )
    }

    /// Extracts using decoded audio frame positions. This matches the timeline
    /// AVAudioPlayer uses and avoids M4B/AAC presentation-time or edit-list offsets.
    static func extractClip(
        from inputURL: URL,
        startTime: TimeInterval,
        endTime: TimeInterval,
        outputURL: URL,
        completion: @escaping (URL?) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            var temporaryURL: URL?
            var stagedOutputURL: URL?

            do {
                guard startTime.isFinite, endTime.isFinite else {
                    throw NSError(
                        domain: "AudioClipUtils",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Clip times must be finite"]
                    )
                }

                let inputFile = try AVAudioFile(forReading: inputURL)
                let format = inputFile.processingFormat
                let sampleRate = format.sampleRate
                let totalFrames = inputFile.length

                guard sampleRate > 0, totalFrames > 0 else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }

                let startFrame = min(
                    max(
                        AVAudioFramePosition((max(0, startTime) * sampleRate).rounded(.down)),
                        0
                    ),
                    totalFrames
                )
                let endFrame = min(
                    max(
                        AVAudioFramePosition((max(startTime, endTime) * sampleRate).rounded(.up)),
                        startFrame
                    ),
                    totalFrames
                )
                var framesRemaining = endFrame - startFrame

                guard framesRemaining > 0 else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }

                let fileManager = FileManager.default
                try fileManager.createDirectory(
                    at: outputURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )

                let decodedURL = fileManager.temporaryDirectory
                    .appendingPathComponent("bookmark_pcm_\(UUID().uuidString).caf")
                temporaryURL = decodedURL
                let encodedURL = outputURL.deletingLastPathComponent()
                    .appendingPathComponent(".bookmark_\(UUID().uuidString).m4a")
                stagedOutputURL = encodedURL

                var temporaryFile: AVAudioFile? = try AVAudioFile(
                    forWriting: decodedURL,
                    settings: format.settings,
                    commonFormat: format.commonFormat,
                    interleaved: format.isInterleaved
                )

                inputFile.framePosition = startFrame
                let maximumBufferFrames: AVAudioFrameCount = 32_768

                while framesRemaining > 0 {
                    let requestedFrames = AVAudioFrameCount(
                        min(AVAudioFramePosition(maximumBufferFrames), framesRemaining)
                    )
                    guard let buffer = AVAudioPCMBuffer(
                        pcmFormat: format,
                        frameCapacity: requestedFrames
                    ) else {
                        throw NSError(
                            domain: "AudioClipUtils",
                            code: 1,
                            userInfo: [NSLocalizedDescriptionKey: "Unable to allocate audio buffer"]
                        )
                    }

                    try inputFile.read(into: buffer, frameCount: requestedFrames)
                    guard buffer.frameLength > 0 else { break }
                    try temporaryFile?.write(from: buffer)
                    framesRemaining -= AVAudioFramePosition(buffer.frameLength)
                }

                guard framesRemaining == 0 else {
                    throw NSError(
                        domain: "AudioClipUtils",
                        code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "Audio ended before the requested clip was decoded"]
                    )
                }

                // AVAudioFile finalizes its container when released.
                temporaryFile = nil
                exportDecodedClip(
                    from: decodedURL,
                    to: encodedURL
                ) { url in
                    try? fileManager.removeItem(at: decodedURL)

                    guard url != nil else {
                        try? fileManager.removeItem(at: encodedURL)
                        completion(nil)
                        return
                    }

                    do {
                        if fileManager.fileExists(atPath: outputURL.path) {
                            _ = try fileManager.replaceItemAt(
                                outputURL,
                                withItemAt: encodedURL
                            )
                        } else {
                            try fileManager.moveItem(at: encodedURL, to: outputURL)
                        }
                        completion(outputURL)
                    } catch {
                        print("[Bookmark] Failed to install extracted clip: \(error)")
                        try? fileManager.removeItem(at: encodedURL)
                        completion(nil)
                    }
                }
            } catch {
                print("[Bookmark] Audio frame extraction error: \(error)")
                if let temporaryURL {
                    try? FileManager.default.removeItem(at: temporaryURL)
                }
                if let stagedOutputURL {
                    try? FileManager.default.removeItem(at: stagedOutputURL)
                }
                DispatchQueue.main.async { completion(nil) }
            }
        }
    }

    private static func exportDecodedClip(
        from temporaryURL: URL,
        to outputURL: URL,
        completion: @escaping (URL?) -> Void
    ) {
        let asset = AVAsset(url: temporaryURL)
        guard let exporter = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetAppleM4A
        ) else {
            DispatchQueue.main.async { completion(nil) }
            return
        }

        exporter.outputURL = outputURL
        exporter.outputFileType = .m4a
        exporter.exportAsynchronously {
            DispatchQueue.main.async {
                completion(exporter.status == .completed ? outputURL : nil)
            }
        }
    }

    static func extractClip(
        from inputURL: URL,
        startTime: TimeInterval,
        endTime: TimeInterval,
        identifier: String,
        completion: @escaping (URL?) -> Void
    ) {
        extractClip(
            from: inputURL,
            startTime: startTime,
            endTime: endTime,
            clipId: identifier,
            completion: completion
        )
    }

    static func deleteClip(at path: String?) {
        guard let path else { return }
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: url.path) else { return }

        do {
            try FileManager.default.removeItem(at: url)
            print("[INFO] Deleted clip at \(url.path)")
        } catch {
            print("[ERROR] Failed to delete clip: \(error)")
        }
    }

    static func getClipURL(for timestamp: TimeInterval) -> URL? {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let clipPath = documentsURL.appendingPathComponent("Clips/clip_\(Int(timestamp)).m4a")
        return FileManager.default.fileExists(atPath: clipPath.path) ? clipPath : nil
    }
}
