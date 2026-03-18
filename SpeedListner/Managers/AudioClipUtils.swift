//
//  AudioClipUtils.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 21/07/25.
//



import AVFoundation

class AudioClipUtils {

  
    static func extractClip(
        from inputURL: URL,
        startTime: TimeInterval,
        endTime: TimeInterval,
        identifier: String,
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

        // 🔒 Safety clamp (but DO NOT recalculate logic)
        let safeStart = max(0, startTime)
        let safeEnd = min(duration, endTime)

        let outputURL = clipsFolderURL.appendingPathComponent("clip_\(identifier).m4a")

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

