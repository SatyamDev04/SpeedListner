//
//  AudioBookmarkExtractor.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 05/05/25.
//

import AVFoundation


enum BookmarkDisplayItem {
    case bookmark(BookmarksModel)
    case segment(BookmarkSegment)
}

struct BookmarksModel: Codable {
    let indentifier: String
    let bookmarksTxt: String
    let timeStamp: TimeInterval
    let time: String
    let date: String
    let isStar: Bool?
}

struct BookmarkSegment{
    let identifiers: [String]
    let startTime: Double
    let endTime: Double
    let url:URL?
    var transcription:String?
    var summary:String?
}

extension BookmarkDisplayItem {
    var startTime: TimeInterval? {
        switch self {
        case .bookmark(let b): return b.timeStamp
        case .segment(let s): return s.startTime
        }
    }
}
class AudioBookmarkExtractor {
    
    /// Groups adjacent bookmarks within `threshold` seconds (default 5 min = 300s)
    static func groupBookmarks(_ bookmarks: [BookmarksModel], threshold: TimeInterval = 300) -> [BookmarkSegment] {
        let sorted = bookmarks.sorted(by: { $0.timeStamp < $1.timeStamp })
        var segments: [BookmarkSegment] = []
        var currentGroup: [BookmarksModel] = []
        var mergedTimestamps: [Double] = []
        var unmergedTimestamps: [Double] = []

        print("All Timestamps: \(sorted.map { $0.timeStamp })")

        for bookmark in sorted {
            if let last = currentGroup.last, bookmark.timeStamp - last.timeStamp <= threshold {
                currentGroup.append(bookmark)
            } else {
                if currentGroup.count > 1 {
                    mergedTimestamps.append(contentsOf: currentGroup.map { $0.timeStamp })
                } else if let single = currentGroup.first {
                    unmergedTimestamps.append(single.timeStamp)
                }

                if !currentGroup.isEmpty {
                    segments.append(BookmarkSegment(
                        identifiers: currentGroup.map { $0.indentifier },
                        startTime: currentGroup.first!.timeStamp,
                        endTime: currentGroup.last!.timeStamp + 5, url: nil // extra 5 seconds padding
                    ))
                }
                currentGroup = [bookmark]
            }
        }

      
        if !currentGroup.isEmpty {
            if currentGroup.count > 1 {
                mergedTimestamps.append(contentsOf: currentGroup.map { $0.timeStamp })
            } else if let single = currentGroup.first {
                unmergedTimestamps.append(single.timeStamp)
            }

            segments.append(BookmarkSegment(
                identifiers: currentGroup.map { $0.indentifier },
                startTime: currentGroup.first!.timeStamp,
                endTime: currentGroup.last!.timeStamp + 5, url: nil
            ))
        }

        print("\nMerged Timestamps: \(mergedTimestamps)")
        print("Unmerged Timestamps: \(unmergedTimestamps)")
        return segments
    }

    /// Extract audio segments for each grouped segment (returns multiple URLs if needed)
    static func extractGroupedBookmarks(
        from inputURL: URL,
        bookmarks: [BookmarksModel],
        threshold: TimeInterval = 300,
        progressHandler: ((Double) -> Void)? = nil,
        completion: @escaping (Bool, [BookmarkSegment]?, Error?) -> Void
    ) {
        let segments = groupBookmarks(bookmarks, threshold: threshold)
        var outputURLs: [BookmarkSegment] = []
        let totalSegments = segments.count
        var processedSegments = 0

        guard totalSegments > 0 else {
            completion(false, nil, NSError(domain: "No bookmarks found", code: 2))
            return
        }

        for segment in segments {
            // Generate unique temporary URL per segment
            let outputURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("merged_\(Int(segment.startTime))_\(UUID().uuidString).m4a")

            extractSingleSegment(
                from: inputURL,
                startTime: segment.startTime,
                endTime: segment.endTime,
                outputURL: outputURL
            ) { success, url, error in
                processedSegments += 1

                if success, let url = url {
                    outputURLs.append(BookmarkSegment(identifiers: segment.identifiers, startTime: segment.startTime, endTime: segment.endTime, url: url))
                }

                // Report progress overall
                progressHandler?(Double(processedSegments) / Double(totalSegments))

                // Completion when all segments processed
                if processedSegments == totalSegments {
                    if !outputURLs.isEmpty {
                     
                        completion(true, outputURLs, nil)
                    } else {
                        completion(false, nil, error ?? NSError(domain: "Failed to export segments", code: 3))
                    }
                }
            }
        }
    }

    /// Extract a single segment (helper function)
    private static func extractSingleSegment(
        from inputURL: URL,
        startTime: Double,
        endTime: Double,
        outputURL: URL,
        completion: @escaping (Bool, URL?, Error?) -> Void
    ) {
        let asset = AVAsset(url: inputURL)
        let composition = AVMutableComposition()

        asset.loadValuesAsynchronously(forKeys: ["tracks"]) {
            var error: NSError?
            let status = asset.statusOfValue(forKey: "tracks", error: &error)
            guard status == .loaded, let track = asset.tracks(withMediaType: .audio).first else {
                completion(false, nil, error ?? NSError(domain: "No audio track found", code: 0))
                return
            }

            let start = CMTime(seconds: startTime, preferredTimescale: 600)
            let end = CMTime(seconds: endTime, preferredTimescale: 600)
            let timeRange = CMTimeRange(start: start, end: end)

            do {
                let compTrack = composition.addMutableTrack(
                    withMediaType: .audio,
                    preferredTrackID: kCMPersistentTrackID_Invalid
                )
                try compTrack?.insertTimeRange(timeRange, of: track, at: .zero)
            } catch {
                completion(false, nil, error)
                return
            }

            if FileManager.default.fileExists(atPath: outputURL.path) {
                try? FileManager.default.removeItem(at: outputURL)
            }

            guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
                completion(false, nil, NSError(domain: "Export session creation failed", code: 1))
                return
            }

            exporter.outputURL = outputURL
            exporter.outputFileType = .m4a

            exporter.exportAsynchronously {
                switch exporter.status {
                case .completed:
                    completion(true, outputURL, nil)
                case .failed, .cancelled:
                    completion(false, nil, exporter.error)
                default:
                    break
                }
            }
        }
    }
}

class TranscriptionAI{
    static func transcribeLocalAudio(fileURL: URL, completion: @escaping (String?) -> Void) {
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/transcriptions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Secrets.openAIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        
    
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(try! Data(contentsOf: fileURL))
        body.append("\r\n".data(using: .utf8)!)

      
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)

        // End
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        let task = URLSession.shared.uploadTask(with: request, from: body) { data, response, error in
            guard let data = data, error == nil else {
                print("Transcription error:", error?.localizedDescription ?? "Unknown error")
                completion(nil)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let text = json["text"] as? String {
                    completion(text)
                } else {
                    print("Unexpected API response:", String(data: data, encoding: .utf8) ?? "")
                    completion(nil)
                }
            } catch {
                print("Failed to decode transcription response:", error)
                completion(nil)
            }
        }

        task.resume()
    }
    
    static func getSummary(from transcription: String, completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Secrets.openAIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": "You are a summarizer."],
                ["role": "user", "content": "Summarize this: \(transcription)"]
            ],
            "temperature": 0.5
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil,
                  let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = result["choices"] as? [[String: Any]],
                  let message = choices.first?["message"] as? [String: Any],
                  let summary = message["content"] as? String else {
                completion(nil)
                return
            }

            completion(summary)
        }.resume()
    }
}


class Secrets {
    static var openAIKey: String {
        guard
            let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let key = dict["OpenAIKey"] as? String
        else {
            fatalError("Missing OpenAI API Key")
        }
        return key
    }
}
