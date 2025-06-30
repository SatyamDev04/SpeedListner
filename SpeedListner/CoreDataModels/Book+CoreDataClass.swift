//
//  Book+CoreDataClass.swift
//  BookPlayer
//
//  Created by  YesItLabs on 9/23/15.
//  
//
//

import Foundation
import CoreData
import AVFoundation

struct BookURL {
    var original: URL
    var processed: URL
}

public class Book: LibraryItem {
    var fileURL: URL {
        return NewDataMannagerClass.getProcessedFolderURL().appendingPathComponent(self.identifier ?? "unown\(UUID())")
    }

    var currentChapter: Chapter? {
        guard let chapters = self.chapters?.array as? [Chapter], !chapters.isEmpty else {
            return nil
        }

        for chapter in chapters where chapter.start <= self.currentTime && chapter.end > self.currentTime {
            return chapter
        }

        return nil
    }

    var displayTitle: String {
        return self.title ?? "unknow"
    }

    var progress: Double {
        return self.currentTime / self.duration
    }

    var percentage: Double {
        return round(self.progress * 100)
    }

    var hasChapters: Bool {
        return !(self.chapters?.array.isEmpty ?? true)
    }

    func setChapters(from asset: AVAsset, book: Book, context: NSManagedObjectContext) {
        for locale in asset.availableChapterLocales {
            let chaptersMetadata = asset.chapterMetadataGroups(withTitleLocale: locale, containingItemsWithCommonKeys: [AVMetadataKey.commonKeyArtwork])

            for (index, chapterMetadata) in chaptersMetadata.enumerated() {
                let chapterIndex = index + 1
                let chapter = Chapter(from: asset, context: context)

                // Set chapter properties
                chapter.title = AVMetadataItem.metadataItems(
                    from: chapterMetadata.items,
                    withKey: AVMetadataKey.commonKeyTitle,
                    keySpace: AVMetadataKeySpace.common
                ).first?.value?.copy(with: nil) as? String ?? ""
                chapter.start = CMTimeGetSeconds(chapterMetadata.timeRange.start)
                chapter.duration = CMTimeGetSeconds(chapterMetadata.timeRange.duration)
                chapter.index = Int16(chapterIndex)

                // Set the relationship between chapter and book
                chapter.book = book

                // Add chapter to the book
                book.addToChapters(chapter)
            }
        }

        // Save context
        do {
            try context.save()
        } catch {
            print("Failed to save chapters: \(error)")
        }
    }

    convenience init(from bookUrl: BookURL, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "Book", in: context)!
        self.init(entity: entity, insertInto: context)
        let fileURL = bookUrl.processed
        print(fileURL,fileURL.lastPathComponent,"Book identifire")
        self.ext = fileURL.pathExtension
        self.identifier = fileURL.lastPathComponent
        let asset = AVAsset(url: fileURL)

        let titleFromMeta = AVMetadataItem.metadataItems(from: asset.metadata, withKey: AVMetadataKey.commonKeyTitle, keySpace: AVMetadataKeySpace.common).first?.value?.copy(with: nil) as? String
         
        let authorFromMeta = AVMetadataItem.metadataItems(from: asset.metadata, withKey: AVMetadataKey.commonKeyArtist, keySpace: AVMetadataKeySpace.common).first?.value?.copy(with: nil) as? String

        self.title = titleFromMeta ?? bookUrl.original.lastPathComponent.replacingOccurrences(of: "_", with: " ")
        self.author = authorFromMeta ?? "Unknown Author"
        self.duration = CMTimeGetSeconds(asset.duration)
        self.uploadTime = Date()
       // var colors: ArtworkColors!
        if let data = AVMetadataItem.metadataItems(from: asset.metadata, withKey: AVMetadataKey.commonKeyArtwork, keySpace: AVMetadataKeySpace.common).first?.value?.copy(with: nil) as? NSData {
            self.artworkData = data
         //   colors = ArtworkColors(from: self.artwork, context: context)
        } else {
           // colors = ArtworkColors(context: context)
            self.usesDefaultArtwork = true
        }

        //self.artworkColors = colors

        self.setChapters(from: asset, book: self, context: context)

        let legacyIdentifier = bookUrl.original.lastPathComponent
        let storedTime = UserDefaults.standard.double(forKey: legacyIdentifier)
        //migration of time
        if storedTime > 0 {
            self.currentTime = storedTime
            UserDefaults.standard.removeObject(forKey: legacyIdentifier)
        }
    }
}
