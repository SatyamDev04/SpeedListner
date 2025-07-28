//
//  AudioClipUtils.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 21/07/25.
//


import AVFoundation

import AVFoundation

class AudioClipUtils {
    /// Extracts a 5-second clip centered around a given timestamp and saves it to persistent Documents/Clips folder
    static func extract5SecClip(from inputURL: URL, at timestamp: TimeInterval, completion: @escaping (URL?) -> Void) {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let clipsFolderURL = documentsURL.appendingPathComponent("Clips", isDirectory: true)

        // Create folder if it doesn't exist
        if !fileManager.fileExists(atPath: clipsFolderURL.path) {
            do {
                try fileManager.createDirectory(at: clipsFolderURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("[ERROR] Failed to create Clips folder: \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
        }

        let start = max(0, timestamp - 2.5)
        let end = start + 5.0
        let outputURL = clipsFolderURL.appendingPathComponent("clip_\(Int(timestamp)).m4a")

        let asset = AVAsset(url: inputURL)
        let composition = AVMutableComposition()

        asset.loadValuesAsynchronously(forKeys: ["tracks"]) {
            var error: NSError?
            let status = asset.statusOfValue(forKey: "tracks", error: &error)
            guard status == .loaded, let track = asset.tracks(withMediaType: .audio).first else {
                print("[ERROR] Failed to load audio track: \(error?.localizedDescription ?? "Unknown")")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            let startTime = CMTime(seconds: start, preferredTimescale: 600)
            let endTime = CMTime(seconds: end, preferredTimescale: 600)
            let range = CMTimeRange(start: startTime, end: endTime)

            do {
                let compTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                try compTrack?.insertTimeRange(range, of: track, at: .zero)
            } catch {
                print("[ERROR] Failed to insert time range: \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            if fileManager.fileExists(atPath: outputURL.path) {
                try? fileManager.removeItem(at: outputURL)
            }

            guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
                print("[ERROR] Failed to create export session")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            exporter.outputURL = outputURL
            exporter.outputFileType = .m4a

            exporter.exportAsynchronously {
                switch exporter.status {
                case .completed:
                    print("[INFO] Exported clip to \(outputURL.path)")
                    DispatchQueue.main.async {
                        completion(outputURL)
                    }
                case .failed, .cancelled:
                    print("[ERROR] Export failed: \(exporter.error?.localizedDescription ?? "Unknown error")")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                default:
                    break
                }
            }
        }
    }

    /// Deletes the saved 5-second clip at given path
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
