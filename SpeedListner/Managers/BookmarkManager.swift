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
    
    // MARK: - Save Bookmark Without Note
    func saveWithoutNote(book: Book, starStatus: Bool = false, completion: ((Bool) -> Void)? = nil) {
        guard book.identifier != nil else {
            completion?(false)
            return
        }
        
        var arrBookmarksNotes = loadBookmarks(for: book)
        let t = book.currentTime
        let time = formatTime(Int(book.currentTime))
        let date = Date.getCurrentDate()
       
        let start = max(0, t - 5.0)
        let end = min(book.duration, t + 15.0)
        
        AudioClipUtils.extractClip(
            from: book.fileURL,
            startTime: start,
            endTime: end,
            identifier: "\(Int(t))"
        ) { url in
            if let clipURL = url {
                arrBookmarksNotes.append(BookmarksModel(
                    indentifier: book.identifier ?? "",
                    bookmarksTxt: "",
                    timeStamp: t,
                    time: time,
                    date: date,
                    isStar: starStatus,
                    audioClipPath: clipURL
                ))
                print("Audio clip saved: \(clipURL)")
            } else {
                arrBookmarksNotes.append(BookmarksModel(
                    indentifier: book.identifier ?? "",
                    bookmarksTxt: "",
                    timeStamp: t,
                    time: time,
                    date: date,
                    isStar: starStatus
                ))
            }
            
            self.saveBookmarks(arrBookmarksNotes, for: book)
            AudioMonitorManager.shared.startTranscribeAllBookmarksInBackground(book: book)
            completion?(true)
        }
    }
    
    // MARK: - Save Bookmark With Note
    func saveBookmarkWithNote(book: Book, note: String, starStatus: Bool = false, completion: ((Bool) -> Void)? = nil) {
        guard book.identifier != nil else {
            completion?(false)
            return
        }
        
        var arrBookmarksNotes = loadBookmarks(for: book)
        let t = book.currentTime
        let time = formatTime(Int(book.currentTime))
        let date = Date.getCurrentDate()
        let start = max(0, t - 5.0)
        let end = min(book.duration, t + 15.0)
        AudioClipUtils.extractClip(
            from: book.fileURL,
            startTime: start,
            endTime: end,
            identifier: "\(Int(t))"
        ){ url in
            if let clipURL = url {
                arrBookmarksNotes.append(BookmarksModel(
                    indentifier: book.identifier ?? "",
                    bookmarksTxt: note,
                    timeStamp: t,
                    time: time,
                    date: date,
                    isStar: starStatus,
                    audioClipPath: clipURL
                ))
            } else {
                arrBookmarksNotes.append(BookmarksModel(
                    indentifier: book.identifier ?? "",
                    bookmarksTxt: note,
                    timeStamp: t,
                    time: time,
                    date: date,
                    isStar: starStatus
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
        
        let start = max(0, t - 5.0)
        let end = min(book.duration, t + 15.0)
        
        AudioClipUtils.extractClip(
            from: book.fileURL,
            startTime: start,
            endTime: end,
            identifier: "\(Int(t))"
        ){ url in
            if let clipURL = url {
                arrBookmarksNotes[index] = BookmarksModel(
                    indentifier: book.identifier ?? "",
                    bookmarksTxt: note,
                    timeStamp: t,
                    time: time,
                    date: date,
                    isStar: starStatus,
                    audioClipPath: clipURL
                )
            } else {
                arrBookmarksNotes[index] = BookmarksModel(
                    indentifier: book.identifier ?? "",
                    bookmarksTxt: note,
                    timeStamp: t,
                    time: time,
                    date: date,
                    isStar: starStatus
                )
            }
            
            self.saveBookmarks(arrBookmarksNotes, for: book)
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
            return try JSONDecoder().decode([BookmarksModel].self, from: savedData)
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
