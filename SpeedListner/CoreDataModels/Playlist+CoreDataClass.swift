//
//  Playlist+CoreDataClass.swift
//  BookPlayer
//
//  Created by  YesItLabs on 9/23/15.
//  
//
//

import Foundation
import CoreData
import UIKit

public class Playlist: LibraryItem {
    override var artwork: UIImage {
     return #imageLiteral(resourceName: "Image")

    }

    func totalProgress() -> Double {
        let allBooks = gatherAllBooks()
      
        guard !allBooks.isEmpty else {
            return 0.0
        }

        var totalDuration = 0.0
        var totalProgress = 0.0

        for book in allBooks {
            totalDuration += book.duration
            totalProgress += book.currentTime
        }

        guard totalDuration > 0 else {
            return 0.0
        }

        return totalProgress / totalDuration
    }

    func getRemainingBooks() -> [Book] {
        
        func gatherBooks(from playlist: Playlist) -> [Book] {
            var books = playlist.books?.array as? [Book] ?? []
            
            if let childPlaylists = playlist.children?.allObjects as? [Playlist] {
                for child in childPlaylists {
                    books.append(contentsOf: gatherBooks(from: child))
                }
            }
            return books
        }
        var allBooks = gatherBooks(from: self)

       
        for book in allBooks {
            print(book.title ?? "No Title", "in upper section")
        }

      
        if let firstUnfinishedBook = allBooks.first(where: { book in
            round(book.currentTime) < round(book.duration)
        }) {
           
            if let index = allBooks.firstIndex(of: firstUnfinishedBook) {
                let remainingBooks = Array(allBooks.dropFirst(index))
                
                for book in remainingBooks {
                    print(book.title ?? "No Title", "Remaining Book")
                }
                
                return remainingBooks
            }
        } else {
            
            allBooks.forEach { $0.currentTime = 0.0 }
        }

        return allBooks
    }

    func getBooks(from index: Int) -> [Book] {
        
        func gatherBooks(from playlist: Playlist) -> [Book] {
            var books = playlist.books?.array as? [Book] ?? []
            
            if let childPlaylists = playlist.children?.allObjects as? [Playlist] {
                for child in childPlaylists {
                    books.append(contentsOf: gatherBooks(from: child))
                }
            }
            return books
        }

       
        let allBooks = gatherBooks(from: self)
        
        
        guard index < allBooks.count else {
            return []
        }
        
        return Array(allBooks.suffix(from: index))
    }

  
    private func gatherAllBooks() -> [Book] {
        var books = self.books?.array as? [Book] ?? []
        
        if let childPlaylists = self.children?.allObjects as? [Playlist] {
            for child in childPlaylists {
                books.append(contentsOf: child.gatherAllBooks())
            }
        }
        return books
    }

    
    func itemIndex(with url: URL) -> Int? {
        let identifier = url.lastPathComponent
        return self.itemIndex(with: identifier)
    }

    
    func itemIndex(with identifier: String) -> Int? {
        let allBooks = gatherAllBooks()

        return allBooks.firstIndex { storedBook in
            return storedBook.identifier == identifier
        }
    }

  
    func getBook(at index: Int) -> Book? {
        let allBooks = gatherAllBooks()
        
        guard index >= 0 && index < allBooks.count else {
            return nil
        }
        
        return allBooks[index]
    }

  
    func getBook(with url: URL) -> Book? {
        guard let index = self.itemIndex(with: url) else {
            return nil
        }
        return self.getBook(at: index)
    }

   
    func getBook(with identifier: String) -> Book? {
        guard let index = self.itemIndex(with: identifier) else {
            return nil
        }
        return self.getBook(at: index)
    }
    func info() -> (String,String) {
        let bookCount = self.books?.array.count ?? 0
        let playlistCount = self.children?.count ?? 0
        
        let k = bookCount + playlistCount
        if k == 0 {
            return ("0","0")
        }else{
            return ("\(bookCount)","\(playlistCount)")
        }
    }

    convenience init(title: String, books: [Book]? = nil, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "Playlist", in: context)!
        self.init(entity: entity, insertInto: context)
        self.identifier = title
        self.title = title
        self.uploadTime = Date()
        self.desc = "\(books?.count ?? 0) Files"
        if let books = books{
            self.addToBooks(NSOrderedSet(array: books ))
        }
    }
}
