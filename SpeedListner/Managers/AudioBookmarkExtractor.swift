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
    var bookmarkId: String?
    var clipId: String?
    var clipVersion: Int?
    let indentifier: String
    let bookmarksTxt: String
    let timeStamp: TimeInterval
    let time: String
    let date: String
    let isStar: Bool?
    var transcription:String?
    var summary:String?
    var audioClipPath:URL?
    var startTime: Double?
    var endTime: Double?
    
}

struct BookmarkSegment{
    let identifiers: String
    let startTime: Double
    let endTime: Double
    let url:URL?
    var transcription:String?
    var summary:String?
    var bookmarksTxt: String? = nil
    var isStar: Bool? = false
    let date: String
    var isProcessed: Bool {
           return (transcription?.isEmpty == false && summary?.isEmpty == false)
       }
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

    /// Groups adjacent bookmarks within `threshold` seconds (default 20s gap allowed between segments)
    static func groupBookmarks(
        _ bookmarks: [BookmarksModel],
        threshold: TimeInterval = 20
    ) -> [BookmarkSegment] {

        let sorted = bookmarks.sorted { $0.timeStamp < $1.timeStamp }
        var segments: [BookmarkSegment] = []
        var currentGroup: [BookmarksModel] = []

        for bookmark in sorted {

            guard let start = bookmark.startTime,
                  let end = bookmark.endTime else {
                continue
            }

            if let last = currentGroup.last,
               let lastEnd = last.endTime {

                let gap = start - lastEnd

                if gap <= threshold {
                    currentGroup.append(bookmark)
                } else {
                    appendSegment(from: currentGroup, to: &segments)
                    currentGroup = [bookmark]
                }

            } else {
                currentGroup = [bookmark]
            }
        }

        appendSegment(from: currentGroup, to: &segments)

        return segments
    }

    private static func appendSegment(
        from group: [BookmarksModel],
        to segments: inout [BookmarkSegment]
    ) {
        guard group.count > 1,
              let firstStart = group.first?.startTime,
              let lastEnd = group.last?.endTime else { return }

        segments.append(
            BookmarkSegment(
                identifiers: "\(firstStart)-\(lastEnd)",
                startTime: firstStart,
                endTime: lastEnd,
                url: nil,
                date: group.last?.date ?? ""
            )
        )
    }

    /// Extract audio segments for each grouped segment (returns multiple URLs if needed)
    static func extractGroupedBookmarks(
        from inputURL: URL,
        bookmarks: [BookmarksModel],
        threshold: TimeInterval = 20,
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
                    outputURLs.append(
                        BookmarkSegment(
                            identifiers: "\(segment.startTime)-\(segment.endTime)",
                            startTime: segment.startTime,
                            endTime: segment.endTime,
                            url: url,
                            date: segment.date
                        )
                    )
                }

                progressHandler?(Double(processedSegments) / Double(totalSegments))

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
        AudioClipUtils.extractClip(
            from: inputURL,
            startTime: startTime,
            endTime: endTime,
            outputURL: outputURL
        ) { url in
            if let url {
                completion(true, url, nil)
            } else {
                completion(
                    false,
                    nil,
                    NSError(
                        domain: "AudioBookmarkExtractor",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to extract bookmark segment"]
                    )
                )
            }
        }
    }
}


struct AITranscriptionResult {
    let transcription: String
    let summary: String
}

struct OpenAIRequestError: LocalizedError {
    let message: String

    var errorDescription: String? {
        message
    }
}

class TranscriptionAI {
    
    static func processAudio(
        fileURL: URL,
        completion: @escaping (Result<AITranscriptionResult, Error>) -> Void
    ) {
        transcribeLocalAudio(fileURL: fileURL) { transcriptionResult in
            switch transcriptionResult {
            case .success(let transcription):
                getSummary(from: transcription) { summaryResult in
                    switch summaryResult {
                    case .success(let summary):
                        completion(.success(
                            AITranscriptionResult(
                                transcription: transcription,
                                summary: summary
                            )
                        ))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    static func transcribeLocalAudio(
        fileURL: URL,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/transcriptions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Secrets.openAIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        
    
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        do {
            body.append(try Data(contentsOf: fileURL))
        } catch {
            completion(.failure(error))
            return
        }
        body.append("\r\n".data(using: .utf8)!)

      
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)

        // End
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        let task = URLSession.shared.uploadTask(with: request, from: body) { data, response, error in
            if let error {
                print("Transcription error:", error.localizedDescription)
                completion(.failure(error))
                return
            }

            guard let data else {
                completion(.failure(OpenAIRequestError(message: "OpenAI returned an empty response.")))
                return
            }

            if let responseError = openAIError(from: data, response: response) {
                completion(.failure(responseError))
                return
            }

            guard
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let text = json["text"] as? String
            else {
                completion(.failure(
                    OpenAIRequestError(message: "OpenAI returned an unexpected transcription response.")
                ))
                return
            }

            completion(.success(text))
        }

        task.resume()
    }
    
    static func getSummary(
        from transcription: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
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

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let data else {
                completion(.failure(OpenAIRequestError(message: "OpenAI returned an empty response.")))
                return
            }

            if let responseError = openAIError(from: data, response: response) {
                completion(.failure(responseError))
                return
            }

            guard
                let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let choices = result["choices"] as? [[String: Any]],
                let message = choices.first?["message"] as? [String: Any],
                let summary = message["content"] as? String
            else {
                completion(.failure(
                    OpenAIRequestError(message: "OpenAI returned an unexpected summary response.")
                ))
                return
            }

            completion(.success(summary))
        }.resume()
    }

    static func openAIError(from data: Data, response: URLResponse?) -> Error? {
        let statusCode = (response as? HTTPURLResponse)?.statusCode
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        let errorObject = json?["error"] as? [String: Any]
        let apiMessage = errorObject?["message"] as? String

        if let apiMessage, !apiMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return OpenAIRequestError(message: apiMessage)
        }

        if let statusCode, !(200...299).contains(statusCode) {
            return OpenAIRequestError(message: "OpenAI request failed with status \(statusCode).")
        }

        return nil
    }
}


class Secrets {
    static var openAIKey: String {
        guard
            let url = Bundle.main.url(forResource: "Info", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let key = dict["OpenAIKey"] as? String
        else {
            fatalError("Missing OpenAI API Key")
        }
        return key
    }
}
struct BookmarkCacheManager {
    static let transcriptionKeyPrefix = "transcription_"
    static let summaryKeyPrefix = "summary_"
    static let isStarKeyPrefix = "isStar_"
    static let isNotesKeyPrefix = "isNotes_"
    
    
    static func saveIsStar(_ bool: Bool, for identifier: String) {
        UserDefaults.standard.set(bool, forKey: isStarKeyPrefix + identifier )
    }
    static func getIsStar(for identifier: String) -> Bool? {
        return UserDefaults.standard.bool(forKey: isStarKeyPrefix + identifier)
    }
    
    static func saveNotes(_ text: String, for identifier: String) {
        UserDefaults.standard.set(text, forKey: isNotesKeyPrefix + identifier)
    }
    
    static func getNotes(for identifier: String) -> String? {
        return UserDefaults.standard.string(forKey: isNotesKeyPrefix + identifier)
    }
    
    static func saveTranscription(_ text: String, for identifier: String) {
        UserDefaults.standard.set(text, forKey: transcriptionKeyPrefix + identifier)
    }
    
    static func getTranscription(for identifier: String) -> String? {
        return UserDefaults.standard.string(forKey: transcriptionKeyPrefix + identifier)
    }
    
    static func saveSummary(_ text: String, for identifier: String) {
        UserDefaults.standard.set(text, forKey: summaryKeyPrefix + identifier)
    }
    
    static func getSummary(for identifier: String) -> String? {
        return UserDefaults.standard.string(forKey: summaryKeyPrefix + identifier)
    }
    
    static func clearCache(for identifier: String) {
        UserDefaults.standard.removeObject(forKey: transcriptionKeyPrefix + identifier)
        UserDefaults.standard.removeObject(forKey: summaryKeyPrefix + identifier)
        UserDefaults.standard.removeObject(forKey: isStarKeyPrefix + identifier)
        UserDefaults.standard.removeObject(forKey: isNotesKeyPrefix + identifier)
    }
}
