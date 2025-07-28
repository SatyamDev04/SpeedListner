import Foundation
import AVFoundation

final class AudioMonitorManager: NSObject {
    
    static let shared = AudioMonitorManager()
    private override init() {}
    private var currentBook: Book?
    
    var isAutoEnabled: Bool {
        UserDefaults.standard.bool(forKey: "autoTranscribeWhileListening")
    }

    // MARK: - Public API
    
    func startTranscribeAllBookmarksInBackground(book: Book?) {
        guard isAutoEnabled, let book = book else { return }
        
        currentBook = book
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.fetchAndTranscribeBookmarks()
        }
    }
    
    // MARK: - Bookmark Handling
    
    private func fetchAndTranscribeBookmarks() {
        guard let book = currentBook else { return }
        
        let key = (book.identifier ?? "") + "_bookmarks"
        guard let savedData = UserDefaults.standard.data(forKey: key) else {
            print("No bookmarks found for book:", book.title ?? "")
            return
        }
        
        do {
            let savedBookmarks = try JSONDecoder().decode([BookmarksModel].self, from: savedData)
            let validBookmarks = savedBookmarks.filter { bookmark in
                if let url = AudioClipUtils.getClipURL(for: bookmark.timeStamp) {
                    return FileManager.default.fileExists(atPath: url.path)
                }
                return false
            }
            guard !validBookmarks.isEmpty else { return }
            
            mergeAdjacentBookmarks(bookmarks: validBookmarks, book: book)
            
        } catch {
            print("Failed to decode bookmarks:", error)
        }
    }
    
    private func mergeAdjacentBookmarks(bookmarks: [BookmarksModel], book: Book) {
        AudioBookmarkExtractor.extractGroupedBookmarks(
            from: book.fileURL,
            bookmarks: bookmarks,
            progressHandler: { progress in
                print("Merging Progress: \(Int(progress * 100))%")
            },
            completion: { [weak self] success, segments, error in
                DispatchQueue.main.async {
                    guard success, let segments = segments else {
                        print("Merge failed:", error?.localizedDescription ?? "Unknown error")
                        return
                    }
                    
                    print("Merge completed with \(segments.count) segment(s).")
                    
                    Task {
                        await self?.transcribeMissingBookmark(bookmarks)
                        await self?.transcribeMissingSegments(segments)
                    }
                }
            }
        )
    }
    
    // MARK: - Transcription
    private func transcribeMissingBookmark(_ bookmarks: [BookmarksModel]) async{
   
        let unprocessed = bookmarks.filter { bookmark in
                let hasTranscript = BookmarkCacheManager.getTranscription(for: "\(Int(bookmark.timeStamp))")?.isEmpty == false
                let hasSummary = BookmarkCacheManager.getSummary(for: "\(Int(bookmark.timeStamp))")?.isEmpty == false
                return !hasTranscript || !hasSummary
            }

        
        guard !unprocessed.isEmpty else {
            print("All segments already transcribed and summarized.")
            return
        }
        
        print("Transcribing \(unprocessed.count) unprocessed segment(s)...")
        
        let group = DispatchGroup()
        
        for var bookmark in unprocessed {
            let identifier = "\(Int(bookmark.timeStamp))"
            guard let url = AudioClipUtils.getClipURL(for: bookmark.timeStamp) else { continue }
            
            group.enter()
            
            TranscriptionAI.processAudio(fileURL: url) { result in
                if let result = result {
                    bookmark.transcription = result.transcription
                    bookmark.summary = result.summary
                    
                    BookmarkCacheManager.saveTranscription(result.transcription, for: identifier)
                    BookmarkCacheManager.saveSummary(result.summary, for: identifier)
                    
                    print("Transcribed segment:", identifier)
                } else {
                    print("Failed transcription for:", identifier)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self, let bookTitle = self.currentBook?.title else { return }
            print("All indiudual bookmarks processed for transcription and summary in: \(bookTitle)")
          //  self.showCompletionToast(for: bookTitle)
        }
    }
    private func transcribeMissingSegments(_ segments: [BookmarkSegment])async {
   
        let unprocessed = segments.filter { segment in
                let hasTranscript = BookmarkCacheManager.getTranscription(for: segment.identifiers)?.isEmpty == false
                let hasSummary = BookmarkCacheManager.getSummary(for: segment.identifiers)?.isEmpty == false
                return !hasTranscript || !hasSummary
            }

        
        guard !unprocessed.isEmpty else {
            print("All segments already transcribed and summarized.")
            return
        }
        
        print("Transcribing \(unprocessed.count) unprocessed segment(s)...")
        
        let group = DispatchGroup()
        
        for var segment in unprocessed {
            let identifier = segment.identifiers
            guard let url = segment.url else { continue }
            
            group.enter()
            
            TranscriptionAI.processAudio(fileURL: url) { result in
                if let result = result {
                    segment.transcription = result.transcription
                    segment.summary = result.summary
                    
                    BookmarkCacheManager.saveTranscription(result.transcription, for: identifier)
                    BookmarkCacheManager.saveSummary(result.summary, for: identifier)
                    
                    print("Transcribed segment:", identifier)
                } else {
                    print("Failed transcription for:", identifier)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self, let bookTitle = self.currentBook?.title else { return }
            print("All bookmarks processed for transcription and summary in: \(bookTitle)")
        }
    }
    
    // MARK: - Alert / Toast
    
    private func showCompletionToast(for bookTitle: String) {
        self.showAlert1(for: "All bookmarks processed for transcription and summary in: \(bookTitle)")
        print("All bookmarks processed for transcription and summary in: \(bookTitle)")
     
       
    }
}
