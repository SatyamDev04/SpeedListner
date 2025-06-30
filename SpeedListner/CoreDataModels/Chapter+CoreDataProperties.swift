//
//  Chapter+CoreDataProperties.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 17/09/24.
//
//

import Foundation
import CoreData


extension Chapter {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Chapter> {
        return NSFetchRequest<Chapter>(entityName: "Chapter")
    }

    @NSManaged public var duration: Double
    @NSManaged public var index: Int16
    @NSManaged public var start: Double
    @NSManaged public var title: String?
    @NSManaged public var book: Book?

}

extension Chapter : Identifiable {

}
