//
//  AudioClipUtils.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 21/07/25.
//



import AVFoundation

class AudioClipUtils {

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
        extractClipPrecise(
            from: inputURL,
            startTime: startTime,
            endTime: endTime,
            clipId: clipId
        ) { preciseURL in
            if let preciseURL = preciseURL {
                completion(preciseURL)
            } else {
                // Safety fallback for unsupported formats / writer failures.
                extractClipLegacy(
                    from: inputURL,
                    startTime: startTime,
                    endTime: endTime,
                    clipId: clipId,
                    completion: completion
                )
            }
        }
    }

    private static func extractClipPrecise(
        from inputURL: URL,
        startTime: TimeInterval,
        endTime: TimeInterval,
        clipId: String,
        completion: @escaping (URL?) -> Void
    ) {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let clipsFolderURL = documentsURL.appendingPathComponent("Clips", isDirectory: true)

        // Create folder if needed
        if !fileManager.fileExists(atPath: clipsFolderURL.path) {
            try? fileManager.createDirectory(at: clipsFolderURL, withIntermediateDirectories: true)
        }

        let asset = AVAsset(url: inputURL)
        let duration = CMTimeGetSeconds(asset.duration)

        // Safety clamp.
        let safeStart = max(0, startTime)
        let safeEnd = min(duration, endTime)
        guard safeEnd > safeStart else {
            DispatchQueue.main.async { completion(nil) }
            return
        }

        let outputURL = clipsFolderURL.appendingPathComponent("clip_\(clipId).m4a")

        asset.loadValuesAsynchronously(forKeys: ["tracks"]) {
            var error: NSError?
            let status = asset.statusOfValue(forKey: "tracks", error: &error)
            guard status == .loaded else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            guard let track = asset.tracks(withMediaType: .audio).first else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            if fileManager.fileExists(atPath: outputURL.path) {
                try? fileManager.removeItem(at: outputURL)
            }

            guard let reader = try? AVAssetReader(asset: asset) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            let outputSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsNonInterleaved: false,
                AVLinearPCMIsBigEndianKey: false
            ]

            let readerOutput = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
            readerOutput.alwaysCopiesSampleData = false
            guard reader.canAdd(readerOutput) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            reader.add(readerOutput)

            let cmStart = CMTime(seconds: safeStart, preferredTimescale: 600)
            let cmDuration = CMTime(seconds: safeEnd - safeStart, preferredTimescale: 600)
            reader.timeRange = CMTimeRange(start: cmStart, duration: cmDuration)

            guard let writer = try? AVAssetWriter(outputURL: outputURL, fileType: .m4a) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            let streamDescriptions = track.formatDescriptions.compactMap { formatDescription -> AudioStreamBasicDescription? in
                let cfDescription = formatDescription as CFTypeRef
                guard CFGetTypeID(cfDescription) == CMFormatDescriptionGetTypeID() else {
                    return nil
                }
                let audioFormatDescription = unsafeBitCast(cfDescription, to: CMAudioFormatDescription.self)
                guard let streamDescription = CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatDescription)?.pointee else {
                    return nil
                }
                return streamDescription
            }

            let channelCount = max(1, streamDescriptions.first.map { Int($0.mChannelsPerFrame) } ?? 2)
            let sampleRate = streamDescriptions.first?.mSampleRate ?? 44100

            let writerSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: sampleRate,
                AVNumberOfChannelsKey: channelCount,
                AVEncoderBitRateKey: 128000
            ]

            let writerInput = AVAssetWriterInput(mediaType: .audio, outputSettings: writerSettings)
            writerInput.expectsMediaDataInRealTime = false
            guard writer.canAdd(writerInput) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            writer.add(writerInput)

            guard reader.startReading() else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            guard writer.startWriting() else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            writer.startSession(atSourceTime: .zero)

            let queue = DispatchQueue(label: "audio.clip.precise.writer")
            var firstPTS: CMTime?

            writerInput.requestMediaDataWhenReady(on: queue) {
                while writerInput.isReadyForMoreMediaData {
                    guard let sampleBuffer = readerOutput.copyNextSampleBuffer() else {
                        writerInput.markAsFinished()
                        writer.finishWriting {
                            DispatchQueue.main.async {
                                completion(writer.status == .completed ? outputURL : nil)
                            }
                        }
                        return
                    }

                    if firstPTS == nil {
                        firstPTS = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                    }

                    let adjustedBuffer: CMSampleBuffer
                    if let firstPTS = firstPTS,
                       let retimed = retimeSampleBuffer(sampleBuffer, bySubtracting: firstPTS) {
                        adjustedBuffer = retimed
                    } else {
                        adjustedBuffer = sampleBuffer
                    }

                    if !writerInput.append(adjustedBuffer) {
                        reader.cancelReading()
                        writerInput.markAsFinished()
                        writer.cancelWriting()
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                        return
                    }
                }
            }
        }
    }

    private static func extractClipLegacy(
        from inputURL: URL,
        startTime: TimeInterval,
        endTime: TimeInterval,
        clipId: String,
        completion: @escaping (URL?) -> Void
    ) {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let clipsFolderURL = documentsURL.appendingPathComponent("Clips", isDirectory: true)

        if !fileManager.fileExists(atPath: clipsFolderURL.path) {
            try? fileManager.createDirectory(at: clipsFolderURL, withIntermediateDirectories: true)
        }

        let asset = AVAsset(url: inputURL)
        let duration = CMTimeGetSeconds(asset.duration)
        let safeStart = max(0, startTime)
        let safeEnd = min(duration, endTime)
        let outputURL = clipsFolderURL.appendingPathComponent("clip_\(clipId).m4a")

        let composition = AVMutableComposition()

        asset.loadValuesAsynchronously(forKeys: ["tracks"]) {
            var error: NSError?
            let status = asset.statusOfValue(forKey: "tracks", error: &error)

            guard status == .loaded,
                  let track = asset.tracks(withMediaType: .audio).first else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            let cmStart = CMTime(seconds: safeStart, preferredTimescale: 600)
            let cmEnd = CMTime(seconds: safeEnd, preferredTimescale: 600)
            let timeRange = CMTimeRange(start: cmStart, end: cmEnd)

            do {
                let compTrack = composition.addMutableTrack(
                    withMediaType: .audio,
                    preferredTrackID: kCMPersistentTrackID_Invalid
                )
                try compTrack?.insertTimeRange(timeRange, of: track, at: .zero)
            } catch {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            if fileManager.fileExists(atPath: outputURL.path) {
                try? fileManager.removeItem(at: outputURL)
            }

            guard let exporter = AVAssetExportSession(
                asset: composition,
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
    }

    private static func retimeSampleBuffer(
        _ sampleBuffer: CMSampleBuffer,
        bySubtracting offset: CMTime
    ) -> CMSampleBuffer? {
        let sampleCount = CMSampleBufferGetNumSamples(sampleBuffer)
        guard sampleCount > 0 else { return sampleBuffer }

        var timingCount: CMItemCount = 0
        guard CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, entryCount: 0, arrayToFill: nil, entriesNeededOut: &timingCount) == noErr else {
            return nil
        }

        var timingInfo = Array(repeating: CMSampleTimingInfo(duration: .invalid, presentationTimeStamp: .invalid, decodeTimeStamp: .invalid), count: timingCount)
        guard CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, entryCount: timingCount, arrayToFill: &timingInfo, entriesNeededOut: &timingCount) == noErr else {
            return nil
        }

        for index in 0..<timingInfo.count {
            if timingInfo[index].presentationTimeStamp.isValid {
                timingInfo[index].presentationTimeStamp = CMTimeSubtract(timingInfo[index].presentationTimeStamp, offset)
            }
            if timingInfo[index].decodeTimeStamp.isValid {
                timingInfo[index].decodeTimeStamp = CMTimeSubtract(timingInfo[index].decodeTimeStamp, offset)
            }
        }

        var adjustedBuffer: CMSampleBuffer?
        let status = CMSampleBufferCreateCopyWithNewTiming(
            allocator: kCFAllocatorDefault,
            sampleBuffer: sampleBuffer,
            sampleTimingEntryCount: timingInfo.count,
            sampleTimingArray: &timingInfo,
            sampleBufferOut: &adjustedBuffer
        )
        return status == noErr ? adjustedBuffer : nil
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

    /// Deletes the saved 15-second clip at given path
    static func deleteClip(at path: String?) {
        guard let path = path else { return }
        let url = URL(fileURLWithPath: path)
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
                print("[INFO] Deleted clip at \(url.path)")
            } catch {
                print("[ERROR] Failed to delete clip: \(error)")
            }
        }
    }

    /// Returns a clip URL for a given timestamp identifier (if exists)
    static func getClipURL(for timestamp: TimeInterval) -> URL? {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let clipPath = documentsURL.appendingPathComponent("Clips/clip_\(Int(timestamp)).m4a")
        return FileManager.default.fileExists(atPath: clipPath.path) ? clipPath : nil
    }
}
