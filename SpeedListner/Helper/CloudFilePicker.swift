//
//  CloudFilePicker.swift
//  SpeedListner
//
//  Created by satyam dwivedi on 05/09/24.
//


import UIKit
import MobileCoreServices
//import SwiftyDropbox

class CloudFilePicker: NSObject, UIDocumentPickerDelegate {
    
    // MARK: - Properties
    
    var completion: ((URL?) -> Void)?
    
    // MARK: - Public Method to Browse Local Files
    
    func browseLocalFiles(in viewController: UIViewController, completion: @escaping (URL?) -> Void) {
        self.completion = completion
        
        // Configure the document picker to only allow AAX file types
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.audiovisualContent], asCopy: true)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .formSheet
        
        // Present the document picker
        viewController.present(documentPicker, animated: true, completion: nil)
    }
    
    // MARK: - Dropbox Integration
    
    func browseDropboxFiles(in viewController: UIViewController, completion: @escaping (URL?) -> Void) {
//        self.completion = completion
//        
//        // Check if the user is logged in
//        if DropboxClientsManager.authorizedClient == nil {
//            // Not authorized, start the OAuth flow
//            DropboxClientsManager.authorizeFromController(UIApplication.shared, controller: viewController) { url in
//                UIApplication.shared.open(url, options: [:], completionHandler: nil)
//            }
//        } else {
//            // User is authorized, list files
//            listDropboxFiles { fileURL in
//                if let fileURL = fileURL {
//                    completion(fileURL)
//                } else {
//                    print("No file selected from Dropbox")
//                    completion(nil)
//                }
//            }
//        }
    }
    
    // List files from Dropbox and allow user to pick an AAX file
    private func listDropboxFiles(completion: @escaping (URL?) -> Void) {
//        guard let client = DropboxClientsManager.authorizedClient else {
//            completion(nil)
//            return
//        }
//        
//        client.files.listFolder(path: "").response { response, error in
//            if let result = response {
//                // Display files to user (in a real app, you'd present a UI for this)
//                for entry in result.entries {
//                    print("File: \(entry.name)")
//                    if entry.name.hasSuffix(".aax") {
//                        // Download the AAX file
//                        self.downloadDropboxFile(entry: entry, completion: completion)
//                        return
//                    }
//                }
//            } else if let error = error {
//                print("Dropbox file listing error: \(error)")
//                completion(nil)
//            }
//        }
    }
    
    // Download the selected file from Dropbox
//    private func downloadDropboxFile(entry: Files.Metadata, completion: @escaping (URL?) -> Void) {
//        guard let client = DropboxClientsManager.authorizedClient else {
//            completion(nil)
//            return
//        }
//        
//        // File URL where the file will be downloaded
//        let tempDir = FileManager.default.temporaryDirectory
//        let localURL = tempDir.appendingPathComponent(entry.name)
//        
//        client.files.download(path: entry.pathLower ?? "").response { response, error in
//            if let (metadata, data) = response {
//                do {
//                    try data.write(to: localURL)
//                    print("Downloaded file from Dropbox: \(metadata.name)")
//                    completion(localURL)
//                } catch {
//                    print("Error saving file: \(error)")
//                    completion(nil)
//                }
//            } else if let error = error {
//                print("Dropbox download error: \(error)")
//                completion(nil)
//            }
//        }
//    }
    
    // MARK: - UIDocumentPickerDelegate Methods
    
    // This method is called when the user selects a document
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let pickedFileURL = urls.first else {
            completion?(nil)
            return
        }
        
        // Ensure the file is an AAX file
        if pickedFileURL.pathExtension.lowercased() == "aax" {
            print("Selected AAX file: \(pickedFileURL)")
            completion?(pickedFileURL)
        } else {
            print("Selected file is not an AAX file")
            completion?(nil)
        }
    }
    
    // This method is called when the user cancels the document picker
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Document picker was cancelled")
        completion?(nil)
    }
}
