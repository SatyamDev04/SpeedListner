//
//  BookmarkManager.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 26/08/25.
//


import Foundation
import MediaPlayer

class BookmarkManager {
    
    static let shared = BookmarkManager()
    
    private init() {}
    
    let COMMENTS_LIMIT = 255
    private let clipVersion = 3
    private let migrationVersion = 3
    private let migrationQueue = DispatchQueue(label: "bookmark.migration.queue", qos: .utility)
    
    // MARK: - Save Bookmark Without Note
    func saveWithoutNote(
        book: Book,
        starStatus: Bool = false,
        timestamp: TimeInterval? = nil,
        completion: ((Bool) -> Void)? = nil
    ) {
        guard book.identifier != nil else {
            completion?(false)
            return
        }
        
        var arrBookmarksNotes = loadBookmarks(for: book)
        let t = resolvedTimestamp(for: book, requestedTimestamp: timestamp)
        let time = formatTime(Int(t))
        let date = Date.getCurrentDate()
        let range = AudioClipUtils.clipRange(around: t, duration: book.duration)
        let start = range.start
        let end = range.end
        let bookmarkId = UUID().uuidString
        let clipId = AudioClipUtils.makeClipId(bookIdentifier: book.identifier ?? "book", timestamp: t)
        
        AudioClipUtils.extractClip(
            from: book.fileURL,
            startTime: start,
            endTime: end,
            clipId: clipId
        ) { url in
            if let clipURL = url {
                print("[Bookmark] saveWithoutNote ts=\(t) start=\(start) end=\(end) clipId=\(clipId) path=\(clipURL.path)")
                arrBookmarksNotes.append(self.makeBookmarkModel(
                    bookmarkId: bookmarkId,
                    clipId: clipId,
                    indentifier: book.identifier ?? "",
                    bookmarksTxt: "",
                    timeStamp: t,
                    time: time,
                    date: date,
                    isStar: starStatus,
                    audioClipPath: clipURL,
                    startTime: start,
                    endTime: end
                ))
                print("Audio clip saved: \(clipURL)")
            } else {
                arrBookmarksNotes.append(self.makeBookmarkModel(
                    bookmarkId: bookmarkId,
                    clipId: clipId,
                    indentifier: book.identifier ?? "",
                    bookmarksTxt: "",
                    timeStamp: t,
                    time: time,
                    date: date,
                    isStar: starStatus,
                    audioClipPath: nil,
                    startTime: start,
                    endTime: end
                ))
            }
            
            self.saveBookmarks(arrBookmarksNotes, for: book)
            AudioMonitorManager.shared.startTranscribeAllBookmarksInBackground(book: book)
            completion?(true)
        }
    }
    
    // MARK: - Save Bookmark With Note
    func saveBookmarkWithNote(
        book: Book,
        note: String,
        starStatus: Bool = false,
        timestamp: TimeInterval? = nil,
        completion: ((Bool) -> Void)? = nil
    ) {
        guard book.identifier != nil else {
            completion?(false)
            return
        }
        
        var arrBookmarksNotes = loadBookmarks(for: book)
        let t = resolvedTimestamp(for: book, requestedTimestamp: timestamp)
        let time = formatTime(Int(t))
        let date = Date.getCurrentDate()
        let range = AudioClipUtils.clipRange(around: t, duration: book.duration)
        let start = range.start
        let end = range.end
        let bookmarkId = UUID().uuidString
        let clipId = AudioClipUtils.makeClipId(bookIdentifier: book.identifier ?? "book", timestamp: t)
        AudioClipUtils.extractClip(
            from: book.fileURL,
            startTime: start,
            endTime: end,
            clipId: clipId
        ){ url in
            if let clipURL = url {
                print("[Bookmark] saveWithNote ts=\(t) start=\(start) end=\(end) clipId=\(clipId) path=\(clipURL.path)")
                arrBookmarksNotes.append(self.makeBookmarkModel(
                    bookmarkId: bookmarkId,
                    clipId: clipId,
                    indentifier: book.identifier ?? "",
                    bookmarksTxt: note,
                    timeStamp: t,
                    time: time,
                    date: date,
                    isStar: starStatus,
                    audioClipPath: clipURL,
                    startTime: start,
                    endTime: end
                ))
            } else {
                arrBookmarksNotes.append(self.makeBookmarkModel(
                    bookmarkId: bookmarkId,
                    clipId: clipId,
                    indentifier: book.identifier ?? "",
                    bookmarksTxt: note,
                    timeStamp: t,
                    time: time,
                    date: date,
                    isStar: starStatus,
                    audioClipPath: nil,
                    startTime: start,
                    endTime: end
                ))
            }
            
            self.saveBookmarks(arrBookmarksNotes, for: book)
            AudioMonitorManager.shared.startTranscribeAllBookmarksInBackground(book: book)
            completion?(true)
        }
    }
    
    // MARK: - Update Existing Bookmark
    func updateBookmark(book: Book, index: Int, note: String, starStatus: Bool, completion: ((Bool) -> Void)? = nil) {
        var arrBookmarksNotes = loadBookmarks(for: book)
        
        guard index < arrBookmarksNotes.count else {
            completion?(false)
            return
        }
        
        let t = arrBookmarksNotes[index].timeStamp
        let time = arrBookmarksNotes[index].time
        let date = arrBookmarksNotes[index].date
        
        let range = AudioClipUtils.clipRange(around: t, duration: book.duration)
        let start = range.start
        let end = range.end
        let existing = arrBookmarksNotes[index]
        let clipId = existing.clipId ?? AudioClipUtils.makeClipId(bookIdentifier: book.identifier ?? "book", timestamp: t)
        let bookmarkId = existing.bookmarkId ?? UUID().uuidString
        
        AudioClipUtils.extractClip(
            from: book.fileURL,
            startTime: start,
            endTime: end,
            clipId: clipId
        ){ url in
            if let clipURL = url {
                print("[Bookmark] update ts=\(t) start=\(start) end=\(end) clipId=\(clipId) path=\(clipURL.path)")
                arrBookmarksNotes[index] = self.makeBookmarkModel(
                    bookmarkId: bookmarkId,
                    clipId: clipId,
                    indentifier: book.identifier ?? "",
                    bookmarksTxt: note,
                    timeStamp: t,
                    time: time,
                    date: date,
                    isStar: starStatus,
                    audioClipPath: clipURL,
                    startTime: start,
                    endTime: end
                )
            } else {
                arrBookmarksNotes[index] = self.makeBookmarkModel(
                    bookmarkId: bookmarkId,
                    clipId: clipId,
                    indentifier: book.identifier ?? "",
                    bookmarksTxt: note,
                    timeStamp: t,
                    time: time,
                    date: date,
                    isStar: starStatus,
                    audioClipPath: existing.audioClipPath,
                    startTime: start,
                    endTime: end
                )
            }
            
            self.saveBookmarks(arrBookmarksNotes, for: book)
            AudioMonitorManager.shared.startTranscribeAllBookmarksInBackground(book: book)
            completion?(true)
        }
    }
    
    // MARK: - Load Bookmarks
    func loadBookmarks(for book: Book) -> [BookmarksModel] {
        let userDefaults = UserDefaults.standard
        guard let bookIdentifier = book.identifier,
              let savedData = userDefaults.object(forKey: "\(bookIdentifier)_bookmarks") as? Data else {
            return []
        }
        
        do {
            let decoded = try JSONDecoder().decode([BookmarksModel].self, from: savedData)
            let normalized = decoded.map { normalizeBookmark($0, book: book) }

            // Persist only if normalization updated legacy rows.
            if let encodedNormalized = try? JSONEncoder().encode(normalized), encodedNormalized != savedData {
                userDefaults.set(encodedNormalized, forKey: "\(bookIdentifier)_bookmarks")
            }
            return normalized
        } catch {
            print("Error loading bookmarks: \(error)")
            return []
        }
    }
    
    // MARK: - Save Bookmarks
    private func saveBookmarks(_ bookmarks: [BookmarksModel], for book: Book) {
        guard let bookIdentifier = book.identifier else { return }
        
        do {
            let encodedData = try JSONEncoder().encode(bookmarks)
            UserDefaults.standard.set(encodedData, forKey: "\(bookIdentifier)_bookmarks")
        } catch {
            print("Error saving bookmarks: \(error)")
        }
    }
    
    // MARK: - Delete Bookmark
    func deleteBookmark(book: Book, at index: Int, completion: ((Bool) -> Void)? = nil) {
        var arrBookmarksNotes = loadBookmarks(for: book)
        
        guard index < arrBookmarksNotes.count else {
            completion?(false)
            return
        }
        
        arrBookmarksNotes.remove(at: index)
        saveBookmarks(arrBookmarksNotes, for: book)
        completion?(true)
    }

    func migrateLegacyBookmarksIfNeeded(
        for book: Book,
        forceReclip: Bool = false,
        completion: (([BookmarksModel]) -> Void)? = nil
    ) {
        guard let bookIdentifier = book.identifier else {
            completion?([])
            return
        }

        let migrationKey = "bookmarkMigrationV\(migrationVersion)_\(bookIdentifier)"
        if !forceReclip && UserDefaults.standard.bool(forKey: migrationKey) {
            completion?(loadBookmarks(for: book))
            return
        }

        migrationQueue.async {
            let bookmarks = self.loadBookmarks(for: book)
            guard !bookmarks.isEmpty else {
                UserDefaults.standard.set(true, forKey: migrationKey)
                DispatchQueue.main.async { completion?([]) }
                return
            }

            self.migrateBookmarksSequentially(
                bookmarks,
                book: book,
                index: 0,
                forceReclip: forceReclip,
                migrated: []
            ) { migrated in
                self.saveBookmarks(migrated, for: book)
                let migrationCompleted = migrated.allSatisfy { bookmark in
                    (bookmark.clipVersion ?? 0) >= self.clipVersion
                        && AudioClipUtils.resolveClipURL(for: bookmark) != nil
                }
                UserDefaults.standard.set(migrationCompleted, forKey: migrationKey)
                DispatchQueue.main.async {
                    completion?(migrated)
                }
            }
        }
    }
    
    // MARK: - Format Time
    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let seconds = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    private func makeBookmarkModel(
        bookmarkId: String,
        clipId: String,
        indentifier: String,
        bookmarksTxt: String,
        timeStamp: TimeInterval,
        time: String,
        date: String,
        isStar: Bool,
        audioClipPath: URL?,
        startTime: Double,
        endTime: Double
    ) -> BookmarksModel {
        BookmarksModel(
            bookmarkId: bookmarkId,
            clipId: clipId,
            clipVersion: clipVersion,
            indentifier: indentifier,
            bookmarksTxt: bookmarksTxt,
            timeStamp: timeStamp,
            time: time,
            date: date,
            isStar: isStar,
            transcription: nil,
            summary: nil,
            audioClipPath: audioClipPath,
            startTime: startTime,
            endTime: endTime
        )
    }

    private func normalizeBookmark(_ bookmark: BookmarksModel, book: Book) -> BookmarksModel {
        var normalized = bookmark
        let range = AudioClipUtils.clipRange(around: bookmark.timeStamp, duration: book.duration)
        let start = range.start
        let end = range.end

        if normalized.bookmarkId == nil {
            normalized.bookmarkId = UUID().uuidString
        }
        if normalized.startTime == nil {
            normalized.startTime = start
        }
        if normalized.endTime == nil {
            normalized.endTime = end
        }
        if normalized.clipId == nil, let path = normalized.audioClipPath?.lastPathComponent {
            if path.hasPrefix("clip_") && path.hasSuffix(".m4a") {
                normalized.clipId = String(path.dropFirst("clip_".count).dropLast(".m4a".count))
            }
        }
        return normalized
    }

    private func migrateBookmarksSequentially(
        _ bookmarks: [BookmarksModel],
        book: Book,
        index: Int,
        forceReclip: Bool,
        migrated: [BookmarksModel],
        completion: @escaping ([BookmarksModel]) -> Void
    ) {
        if index >= bookmarks.count {
            completion(migrated)
            return
        }

        var normalized = normalizeBookmark(bookmarks[index], book: book)
        let range = AudioClipUtils.clipRange(around: normalized.timeStamp, duration: book.duration)
        let start = range.start
        let end = range.end

        if normalized.clipId == nil {
            normalized.clipId = AudioClipUtils.makeClipId(bookIdentifier: normalized.indentifier, timestamp: normalized.timeStamp)
        }
        if normalized.bookmarkId == nil {
            normalized.bookmarkId = UUID().uuidString
        }

        let hasValidClip = AudioClipUtils.resolveClipURL(for: normalized).map { FileManager.default.fileExists(atPath: $0.path) } ?? false
        let needsReclip = forceReclip || !hasValidClip || (normalized.clipVersion ?? 0) < clipVersion

        if !needsReclip {
            var next = normalized
            next.clipVersion = clipVersion
            var result = migrated
            result.append(next)
            migrateBookmarksSequentially(bookmarks, book: book, index: index + 1, forceReclip: forceReclip, migrated: result, completion: completion)
            return
        }

        let clipId = normalized.clipId ?? AudioClipUtils.makeClipId(bookIdentifier: normalized.indentifier, timestamp: normalized.timeStamp)
        AudioClipUtils.extractClip(
            from: book.fileURL,
            startTime: start,
            endTime: end,
            clipId: clipId
        ) { url in
            var recoded = normalized
            recoded.clipId = clipId
            recoded.startTime = start
            recoded.endTime = end
            if let url = url {
                recoded.audioClipPath = url
                recoded.clipVersion = self.clipVersion
                print("[BookmarkMigration] ts=\(recoded.timeStamp) start=\(start) end=\(end) clipId=\(clipId) path=\(url.path)")
            }

            var result = migrated
            result.append(recoded)
            self.migrateBookmarksSequentially(bookmarks, book: book, index: index + 1, forceReclip: forceReclip, migrated: result, completion: completion)
        }
    }

    private func resolvedTimestamp(
        for book: Book,
        requestedTimestamp: TimeInterval?
    ) -> TimeInterval {
        let timestamp: TimeInterval
        if let requestedTimestamp {
            timestamp = requestedTimestamp
        } else if PlayerManager.shared.currentBook?.identifier == book.identifier {
            timestamp = PlayerManager.shared.currentTime
        } else {
            timestamp = book.currentTime
        }

        return min(max(timestamp, 0), max(0, book.duration))
    }
    
    // MARK: - Setup Remote Command Center
    func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.bookmarkCommand.isEnabled = true
        commandCenter.likeCommand.localizedTitle = "Bookmark"
        commandCenter.likeCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            print("🔖 Bookmark button pressed from lock screen")
            // You can add logic here to save bookmark when triggered from lock screen
            return .success
        }
    }
}

// Extension for Date formatting
