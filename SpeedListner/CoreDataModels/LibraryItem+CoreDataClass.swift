//
//  LibraryItem+CoreDataClass.swift
//  BookPlayer
//
//  Created by  YesItLabs on 9/23/15.
// 
//
//

import Foundation
import CoreData
import UIKit

public class LibraryItem: NSManagedObject {
    var artwork: UIImage {
        if let artworkData = self.artworkData {
            return UIImage(data: artworkData as Data)!
        } else {
            return #imageLiteral(resourceName: "1024.png")
        }
    }
}
