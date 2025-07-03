//
//  BookmarksActivityItemProvider.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 03/07/25.
//

import UIKit
import MessageUI

final class BookmarksActivityItemProvider: UIActivityItemProvider {
    
    let currentItem: Book
    let bookmarks: [BookmarkDisplayItem]
    
    init(currentItem: Book, bookmarks: [BookmarkDisplayItem]) {
        self.currentItem = currentItem
        self.bookmarks = bookmarks
        super.init(placeholderItem: URL(fileURLWithPath: "placeholder.txt"))
    }
    
    public override func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        let t = currentItem.title
        
        let fileTitle = "bookmarks-" + " \(t ?? "").txt"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileTitle)
        
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
            
            let contentsData = parseBookmarksData(for: bookmarks)
            FileManager.default.createFile(atPath: fileURL.path, contents: contentsData)
        } catch {
            return nil
        }
        
        return fileURL
    }
    func formatTime(_ time:Int) -> String {
        let hours = Int(time / 3600)
        
        let remaining = Float(time - (hours * 3600))
        
        let minutes = Int(remaining / 60)
        
        let seconds = Int(remaining - Float(minutes * 60))
        
        var formattedTime = String(format:"%02d:%02d", minutes, seconds)
        if hours > 0 {
            formattedTime = String(format:"%02d:"+formattedTime, hours)
        }
        
        return formattedTime
    }
    func parseBookmarksData(for displayItems: [BookmarkDisplayItem]) -> Data? {
        var fileContents = ""

        // Header
        if let bookTitle = currentItem.title {
            fileContents += "Bookmarks For - \(bookTitle)\n\n"
        }

        let formattedBookDuration = formatTime(Int(currentItem.duration)) + " (1x)"

        for item in displayItems {
            switch item {
            case .bookmark(let bookmark):
                fileContents += "Bookmark: \(bookmark.time) (1x)\n"
                fileContents += "Date: \(bookmark.date)\n"
                fileContents += "Book Length: \(formattedBookDuration)\n"

                if bookmark.isStar == true {
                    fileContents += "Starred?: ******************************\n"
                } else {
                    fileContents += "Starred?:\n"
                }

                fileContents += "Note: \(bookmark.bookmarksTxt)\n\n"

//                if let summary = BookmarkCacheManager.getSummary(for: [bookmark.indentifier]), !summary.isEmpty {
//                    fileContents += "AI Summary:\n"
//                    fileContents += summary + "\n\n"
//                }
//
//                if let transcription = BookmarkCacheManager.getTranscription(for: [bookmark.indentifier]), !transcription.isEmpty {
//                    fileContents += "Transcription:\n"
//                    fileContents += transcription + "\n\n"
//                }

            case .segment(let segment):
                let formattedStartTime = formatTime(Int(segment.startTime))
                fileContents += "Bookmark: \(formattedStartTime) (1x)\n"
                fileContents += "Date: \(Date().toString("MM/dd/yyyy"))\n" // fallback or use segment date if available
                fileContents += "Book Length: \(formattedBookDuration)\n"

                if segment.isStar == true {
                    fileContents += "Starred?: ******************************\n"
                } else {
                    fileContents += "Starred?:\n"
                }

                fileContents += "Note: \(segment.bookmarksTxt ?? "")\n\n"

                if let summary = segment.summary, !summary.isEmpty {
                    fileContents += "AI Summary:\n"
                    fileContents += summary + "\n\n"
                }

                if let transcription = segment.transcription, !transcription.isEmpty {
                    fileContents += "Transcription:\n"
                    fileContents += transcription + "\n\n"
                }
            }

            fileContents += "------------------\n"
        }

        return fileContents.data(using: .utf8)
    }
    
    public override func activityViewControllerPlaceholderItem(
        _ activityViewController: UIActivityViewController
    ) -> Any {
        return URL(fileURLWithPath: "placeholder.txt")
    }
}



extension BookMarkVC: MFMailComposeViewControllerDelegate {
    
    func showEmailExport(book: Book, displayItems: [BookmarkDisplayItem]) {
        guard MFMailComposeViewController.canSendMail() else {
            self.showAlert(for: "Mail services are not available.")
            return
        }

        let subject = "\(book.title ?? "") - Bookmarks, Notes, Transcriptions & Summaries"
        let textData = parseBookmarksData(for: displayItems)
        let body = textData.flatMap { String(data: $0, encoding: .utf8) } ?? ""

        let mailVC = MFMailComposeViewController()
        mailVC.mailComposeDelegate = self
        mailVC.setSubject(subject)
        mailVC.setMessageBody(body, isHTML: false)

        // Attach the .txt file
        if let data = textData {
            let filename = "Bookmarks-\(book.title ?? "book").txt"
            mailVC.addAttachmentData(data, mimeType: "text/plain", fileName: filename)
        }

        self.present(mailVC, animated: true, completion: nil)
    }

    // MARK: - Mail Delegate
    public func mailComposeController(_ controller: MFMailComposeViewController,
                                      didFinishWith result: MFMailComposeResult,
                                      error: Error?) {
        controller.dismiss(animated: true)
    }
    func parseBookmarksData(for displayItems: [BookmarkDisplayItem]) -> Data? {
        var fileContents = ""

        // Header
        if let bookTitle = currentItem.title {
            fileContents += "Bookmarks For - \(bookTitle)\n\n"
        }

        let formattedBookDuration = formatTime(Int(currentItem.duration)) + " (1x)"

        for item in displayItems {
            switch item {
            case .bookmark(let bookmark):
                fileContents += "Bookmark: \(bookmark.time) (1x)\n"
                fileContents += "Date: \(bookmark.date)\n"
                fileContents += "Book Length: \(formattedBookDuration)\n"

                if bookmark.isStar == true {
                    fileContents += "Starred?: ******************************\n"
                } else {
                    fileContents += "Starred?:\n"
                }

                fileContents += "Note: \(bookmark.bookmarksTxt)\n\n"



            case .segment(let segment):
                let formattedStartTime = formatTime(Int(segment.startTime))
                fileContents += "Bookmark: \(formattedStartTime) (1x)\n"
                fileContents += "Date: \(Date().toString("MM/dd/yyyy"))\n" // fallback or use segment date if available
                fileContents += "Book Length: \(formattedBookDuration)\n"

                if segment.isStar == true {
                    fileContents += "Starred?: ******************************\n"
                } else {
                    fileContents += "Starred?:\n"
                }

                fileContents += "Note: \(segment.bookmarksTxt ?? "")\n\n"

                 if let summary = BookmarkCacheManager.getSummary(for: segment.identifiers), !summary.isEmpty {
                                    fileContents += "AI Summary:\n"
                                    fileContents += summary + "\n\n"
                                }
                if let transcription = BookmarkCacheManager.getTranscription(for: segment.identifiers), !transcription.isEmpty {
                                    fileContents += "Transcription:\n"
                                    fileContents += transcription + "\n\n"
                                }
            }

            fileContents += "------------------\n"
        }

        return fileContents.data(using: .utf8)
    }
}
extension Date {
    func toString(_ format: String = "MM/dd/yyyy") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}
