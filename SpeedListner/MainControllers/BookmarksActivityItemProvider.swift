//
//  BookmarksActivityItemProvider.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 03/07/25.
//

import UIKit


final class BookmarksActivityItemProvider: UIActivityItemProvider {
    
    let currentItem: Book
    let bookmarks: [BookmarksModel]
    
    init(currentItem: Book, bookmarks: [BookmarksModel]) {
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
            
            let contentsData = parseBookmarksData()
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
    func parseBookmarksData() -> Data? {
        var fileContents = ""
        
        for bookmark in bookmarks {
            
            let chapterTime = bookmark.time
            let chapterdate = bookmark.date
            let formattedTime = self.formatTime(Int(currentItem.duration))
            fileContents += "\("Bookmark".localized): \(chapterTime)\n"
            fileContents += "\("Date".localized): \(chapterdate)\n"
            fileContents += "\("Book Length".localized): \(formattedTime)\n"
            if bookmark.isStar ?? false {
                fileContents += "\("Starred?".localized): \("******************************")\n"
            }else{
                fileContents += "\("Starred?".localized): \("")\n"
            }
            let note = bookmark.bookmarksTxt
            fileContents += "\("Note".localized): \(note)\n"
            
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
