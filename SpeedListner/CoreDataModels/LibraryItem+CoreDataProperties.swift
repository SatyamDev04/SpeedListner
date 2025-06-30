//
//  LibraryItem+CoreDataProperties.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 17/09/24.
//
//

import Foundation
import CoreData


extension LibraryItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LibraryItem> {
        return NSFetchRequest<LibraryItem>(entityName: "LibraryItem")
    }

    @NSManaged public var artworkData: NSData?
    @NSManaged public var currentTime: Double
    @NSManaged public var duration: Double
    @NSManaged public var identifier: String?
    @NSManaged public var percentCompleted: Double
    @NSManaged public var recentPlayTime: Date?
    @NSManaged public var title: String?
    @NSManaged public var uploadTime: Date?
    @NSManaged public var library: Library?

}

extension LibraryItem : Identifiable {

}
