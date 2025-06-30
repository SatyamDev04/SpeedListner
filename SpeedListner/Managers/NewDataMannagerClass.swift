//
//  NewDataMannagerClass.swift
//  SpeedListner
//
//  Created by satyam dwivedi on 05/09/24.
//  
//

import Foundation
import AVFoundation
import CoreData
import CryptoKit

class NewDataMannagerClass {
    
    static let processedFolderName = "AllFiles"
    static let mergeFolderName = "MergeBookMark"
    
    // MARK: - Folder URLs
    
    class func getDocumentsFolderURL() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    class func getProcessedFolderURL() -> URL {
        let documentsURL = self.getDocumentsFolderURL()
        let processedFolderURL = documentsURL.appendingPathComponent(self.processedFolderName)
        
        if !FileManager.default.fileExists(atPath: processedFolderURL.path) {
            do {
                try FileManager.default.createDirectory(at: processedFolderURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                fatalError("Couldn't create Processed folder")
            }
        }
        
        return processedFolderURL
    }
    class func getMergedBookmarkFolderURL() -> URL {
        let documentsURL = self.getDocumentsFolderURL()
        let mergedFolderURL = documentsURL.appendingPathComponent(self.mergeFolderName)
        
        if !FileManager.default.fileExists(atPath: mergedFolderURL.path) {
            do {
                try FileManager.default.createDirectory(at: mergedFolderURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                fatalError("Couldn't create MergeBookMark folder")
            }
        }
        
        return mergedFolderURL
    }
    
    
    class func notifyPendingFiles() {
           let documentsFolder = self.getDocumentsFolderURL()
          
           guard let urls = self.getFiles(from: documentsFolder) else {
               return
           }
           
           for url in urls {
               let userInfo = ["fileURL": url]
               NotificationCenter.default.post(name: Notification.Name.AudiobookPlayer.libraryOpenURL, object: nil, userInfo: userInfo)
           }
       }
    
    // MARK: - Core Data stack
    
    public static var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "SpeedListner")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    class func saveContext () {
        let context = self.persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
              
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - File processing
    
    internal class func getFiles(from folder: URL) -> [URL]? {
        guard let urls = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants) else {
            return nil
        }
        return filterFiles(urls)
    }
    
    internal class func filterFiles(_ urls: [URL]) -> [URL] {
        return urls.filter({ !$0.hasDirectoryPath })
    }
    
    class func processFile(at origin: URL, destinationFolder: URL, completion: @escaping (URL?) -> Void) {
        let originalFileName = origin.lastPathComponent
        let newFileURL = destinationFolder.appendingPathComponent(originalFileName)
        
        do {
            if !FileManager.default.fileExists(atPath: newFileURL.path) {
                try FileManager.default.copyItem(at: origin, to: newFileURL)
            }
        } catch {
            print("File processed unsuccessfully. Could not copy to: \(newFileURL.path)", error.localizedDescription)
            completion(nil)
            return
        }
        
        completion(newFileURL)
        print("File processed successfully. Copied to: \(newFileURL.path)")
    }
    
    // MARK: - Models handler
    
    class func getLibrary() -> Library {
        var library: Library!
        let context = self.persistentContainer.viewContext
        let fetch: NSFetchRequest<Library> = Library.fetchRequest()
        do {
            library = try context.fetch(fetch).first ?? Library.create(in: context)
        } catch {
            fatalError("Failed to fetch library")
        }
        return library
    }
    
    class func getBook(with identifier: String, from library: Library) -> Book? {
        guard let item = library.getItem(with: identifier) else {
            return nil
        }
        
        if let playlist = item as? Playlist {
            return playlist.getBook(with: identifier)
        }
        return item as? Book
    }
    
    class func insertBooks(from bookUrls: [BookURL], into playlist: Playlist?, or library: Library, completion:@escaping () -> Void) {
        let context = self.persistentContainer.viewContext
        
        // Ensure context is saved before processing new books
        if context.hasChanges {
            self.saveContext()
        }

        for bookUrl in bookUrls {
            let url = bookUrl.processed
            guard let item = library.getItem(with: url) else {
                let book = Book(from: bookUrl, context: context)

                if let playlist = playlist {
                    playlist.addToBooks(book)
                } else {
                    library.addToItems(book)
                }
                continue
            }
            
            if let storedPlaylist = item as? Playlist, let storedBook = storedPlaylist.getBook(with: url) {
                storedPlaylist.removeFromBooks(storedBook)

                if let newPlaylist = playlist {
                    newPlaylist.addToBooks(storedBook)
                } else {
                    library.addToItems(storedBook)
                }
            }
        }
        
        self.saveContext()
        DispatchQueue.main.async { completion() }
    }
    
    class func insertPlaylists(title: String, into parentPlaylist: Playlist?, or library: Library?, completion: @escaping (Playlist) -> Void) {
        let context = self.persistentContainer.viewContext
        if context.hasChanges {
            self.saveContext()
        }
        let newPlaylist = Playlist(title: title, context: context)
        
        if let parent = parentPlaylist {
            parent.addToChildren(newPlaylist)
        } else {
            library?.addToItems(newPlaylist)
        }

        self.saveContext()  // Ensure playlist is saved after creation
        DispatchQueue.main.async { completion(newPlaylist) }
    }
    
    class func moveBook(_ book: Book, from oldPlaylist: Playlist?,or library:Library?, to newPlaylist: Playlist, completion: @escaping () -> Void) {
        if let playlist = oldPlaylist {
            playlist.removeFromBooks(book)
        }else{
            library?.removeFromItems(book)
        }
        newPlaylist.addToBooks(book)
        self.saveContext()
        DispatchQueue.main.async { completion() }
    }
    
    class func movePlaylist(_ playlist: Playlist,or library:Library?, from oldParent: Playlist?, to newParent: Playlist,completion: @escaping () -> Void) {
        if let oldParent = oldParent {
            oldParent.removeFromChildren(playlist)
        }else{
            library?.removeFromItems(playlist)
        }
        
        newParent.addToChildren(playlist)
        self.saveContext()
        DispatchQueue.main.async { completion() }
    }
    
    class func createPlaylist(title: String, books: [Book]) -> Playlist {
        return Playlist(title: title, books: books, context: self.persistentContainer.viewContext)
    }
    
    class func createBook(from bookUrl: BookURL) -> Book {
        return Book(from: bookUrl, context: self.persistentContainer.viewContext)
    }
    
    internal class func insert(_ playlist: Playlist, into library: Library) {
        library.addToItems(playlist)
        self.saveContext()
    }
    
    internal class func delete(_ item: NSManagedObject) {
        self.persistentContainer.viewContext.delete(item)
        self.saveContext()
    }
    
    class func exists(_ book: Book) -> Bool {
        return FileManager.default.fileExists(atPath: book.fileURL.path)
    }
    
    class func playerItem(from book: Book) -> AVPlayerItem {
        let asset = AVAsset(url: book.fileURL)
        return AVPlayerItem(asset: asset)
    }
    
    class func delete(book: Book, from library: Library, or playlist: Playlist?, deleteFile: Bool = true) {
        let context = self.persistentContainer.viewContext
        
        if let playlist = playlist {
            playlist.removeFromBooks(book)
        } else {
            library.removeFromItems(book)
        }
        
        if deleteFile {
            do {
                if FileManager.default.fileExists(atPath: book.fileURL.path) {
                    try FileManager.default.removeItem(at: book.fileURL)
                    print("Book file deleted successfully: \(book.fileURL.path)")
                } else {
                    print("Book file not found: \(book.fileURL.path)")
                }
            } catch {
                print("Error deleting book file: \(error.localizedDescription)")
            }
        }
        
        self.saveContext()
    }
    
    class func delete(playlist: Playlist, from library: Library, or parentPlaylist: Playlist?, deleteBooks: Bool = true) {
        let context = self.persistentContainer.viewContext
        
        if let parentPlaylist = parentPlaylist {
            parentPlaylist.removeFromChildren(playlist)
        } else {
            library.removeFromItems(playlist)
        }
        
        if deleteBooks {
            if let books = playlist.books?.array as? [Book] {
                for book in books {
                    do {
                        if FileManager.default.fileExists(atPath: book.fileURL.path) {
                            try FileManager.default.removeItem(at: book.fileURL)
                            print("Book file deleted successfully: \(book.fileURL.path)")
                        } else {
                            print("Book file not found: \(book.fileURL.path)")
                        }
                    } catch {
                        print("Error deleting book file: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        context.delete(playlist)
        self.saveContext()
    }
    
    
    
// MARK: - Folder Directory Related methods
    
    
    
    class func createNestedFolders(inParent parentFolder: URL, nestedFolderNames: [String]) -> URL {
        var currentFolderURL = parentFolder
        
        // Loop through the list of folder names and create each folder inside the previous one
        for folderName in nestedFolderNames {
            currentFolderURL = currentFolderURL.appendingPathComponent(folderName)
            
            // Create the folder if it doesn't exist
            if !FileManager.default.fileExists(atPath: currentFolderURL.path) {
                do {
                    try FileManager.default.createDirectory(at: currentFolderURL, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    fatalError("Couldn't create folder: \(folderName)")
                }
            }
        }
        
        return currentFolderURL
    }

    // MARK: - Playlist Folder Deletion

    class func deleteFolderForPlaylist(named playlistName: String, inside parentFolderURL: URL?) {
        let parentURL = parentFolderURL ?? self.getDocumentsFolderURL()
        let playlistFolderURL = parentURL.appendingPathComponent(playlistName)
        
        do {
            if FileManager.default.fileExists(atPath: playlistFolderURL.path) {
                try FileManager.default.removeItem(at: playlistFolderURL)
                print("Deleted folder for playlist: \(playlistFolderURL.path)")
            }
        } catch {
            print("Failed to delete folder for playlist: \(error.localizedDescription)")
        }
    }

    // MARK: - Models Handler

    class func insertPlaylistsWithDirectory(title:String,plarents: [String], into parentPlaylist: Playlist?, or library: Library?, completion: @escaping () -> Void) {
        let context = self.persistentContainer.viewContext
        var parents = [String]()
        parents = plarents
        parents.append(title)
        if context.hasChanges {
            self.saveContext()
        }
        
        let newPlaylist = Playlist(title: title, context: context)
        let parentFolderURL: URL?
        
        if let parentPlaylist = parentPlaylist {
            
             parentFolderURL =  self.createNestedFolders(inParent: self.getProcessedFolderURL(), nestedFolderNames:plarents)
            
            parentPlaylist.addToChildren(newPlaylist)
        } else {
            
            parentFolderURL = self.createNestedFolders(inParent: self.getProcessedFolderURL(), nestedFolderNames: plarents)
            library?.addToItems(newPlaylist)
        }
        
        if let playlistFolderURL = parentFolderURL {
            print("Playlist folder created at: \(playlistFolderURL)")
        }
        
        self.saveContext()
        DispatchQueue.main.async {
            completion()
        }
    }

    class func insertBooksWithDirectory(from bookUrls: [BookURL], into playlist: Playlist?, or library: Library, completion: @escaping () -> Void) {
        let context = self.persistentContainer.viewContext

        if context.hasChanges {
            self.saveContext()
        }

        let playlistFolderURL: URL?
        if let playlist = playlist {
            playlistFolderURL = self.createNestedFolders(inParent: self.getDocumentsFolderURL(), nestedFolderNames: [playlist.title ?? "unkown"])
        } else {
            playlistFolderURL = self.getProcessedFolderURL()
        }

        for bookUrl in bookUrls {
            let url = bookUrl.processed

            if let destinationFolderURL = playlistFolderURL {
                self.processFile(at: url, destinationFolder: destinationFolderURL) { newFileURL in
                    guard let newFileURL = newFileURL else {
                        print("Failed to process file: \(url)")
                        return
                    }
                    
                    guard let item = library.getItem(with: newFileURL) else {
                        let book = Book(from: bookUrl, context: context)

                        if let playlist = playlist {
                            playlist.addToBooks(book)
                        } else {
                            library.addToItems(book)
                        }
                        return
                    }
                    
                    if let storedPlaylist = item as? Playlist, let storedBook = storedPlaylist.getBook(with: newFileURL) {
                        storedPlaylist.removeFromBooks(storedBook)

                        if let newPlaylist = playlist {
                            newPlaylist.addToBooks(storedBook)
                        } else {
                            library.addToItems(storedBook)
                        }
                    }
                }
            }
        }

        self.saveContext()
        DispatchQueue.main.async {completion()}
    }

    class func deleteWithDirectory(playlist: Playlist, from library: Library, or parentPlaylist: Playlist?, deleteBooks: Bool = true) {
        let context = self.persistentContainer.viewContext
        
        if let parentPlaylist = parentPlaylist {
            parentPlaylist.removeFromChildren(playlist)
        } else {
            library.removeFromItems(playlist)
        }
        
        if deleteBooks {
            if let books = playlist.books?.array as? [Book] {
                for book in books {
                    do {
                        if FileManager.default.fileExists(atPath: book.fileURL.path) {
                            try FileManager.default.removeItem(at: book.fileURL)
                            print("Book file deleted successfully: \(book.fileURL.path)")
                        } else {
                            print("Book file not found: \(book.fileURL.path)")
                        }
                    } catch {
                        print("Error deleting book file: \(error.localizedDescription)")
                    }
                }
            }
        }

        let parentFolder = parentPlaylist?.title != nil ? [parentPlaylist!.title ?? "unknown", playlist.title ?? "unknown"] : [playlist.title ?? "unknown"]
        let folderURL = self.createNestedFolders(inParent: self.getDocumentsFolderURL(), nestedFolderNames: parentFolder )
        
        if let parent = parentPlaylist {
            self.deleteFolderForPlaylist(named: playlist.title ?? "unknown", inside: folderURL)
        } else {
            self.deleteFolderForPlaylist(named: playlist.title ?? "unknown", inside: self.getDocumentsFolderURL())
        }
        
        context.delete(playlist)
        self.saveContext()
    }
}

 
