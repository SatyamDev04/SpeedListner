//
//  LibraryCoreDataClass.swift
//  BookPlayer
//
//  Created by  YesItLabs on 9/23/15.
//  
//
//

import Foundation
import CoreData

public class Library: NSManagedObject {

    func itemIndex(with identifier: String) -> Int? {
        
        guard let items = self.items?.array as? [LibraryItem] else {
            return nil
        }

        for (index, item) in items.enumerated() {
            
            print(item.title,"checking title")
            if let storedBook = item as? Book,
                storedBook.identifier == identifier {
                return index
            }
            //check if playlist
            if let playlist = item as? Playlist{
                print(playlist.title,"jaiii")
//                var k:[Book] = []
//                let b = playlist.splaylist?.array as? [SubPlaylist] ?? []
//                for p in b {
//                    let books = p.books?.array as? [Book] ?? []
//                    for b in books {
//                        k.append(b)
//                    }
//                }
                let pBook = playlist.books?.array as? [Book] ?? []
                let tBooks = pBook /*+ k*/
                
                
            let rk = tBooks.contains(where: { (storedBook) -> Bool in
                       return storedBook.identifier == identifier
                })
                if rk {
                    return index
                }else{
                  //  return nil
                }
                
                //check playlist books
                
            }

        }

        return nil
    }

    func itemIndex(with url: URL) -> Int? {
        let hash = url.lastPathComponent
        return self.itemIndex(with: hash)
    }

    func getItem(at index: Int) -> LibraryItem? {
        guard let items = self.items?.array as? [LibraryItem] else {
            return nil
        }

        return items[index]
    }

    func getItem(with url: URL) -> LibraryItem? {
        guard let index = self.itemIndex(with: url) else {
            return nil
        }
        return self.getItem(at: index)
    }

    func getItem(with identifier: String) -> LibraryItem? {
        guard let index = self.itemIndex(with: identifier) else {
            return nil
        }
        return self.getItem(at: index)
    }
}
