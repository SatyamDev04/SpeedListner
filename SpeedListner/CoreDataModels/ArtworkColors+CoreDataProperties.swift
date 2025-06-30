//
//  ArtworkColors+CoreDataProperties.swift
//  BookPlayer
//
//  Created by  YesItLabs on 9/23/15.
//  
//
//

import Foundation
import CoreData

extension ArtworkColors {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ArtworkColors> {
        return NSFetchRequest<ArtworkColors>(entityName: "ArtworkColors")
    }

    @NSManaged public var backgroundHex: String!
    @NSManaged public var primaryHex: String!
    @NSManaged public var secondaryHex: String!
    @NSManaged public var tertiaryHex: String!
    @NSManaged public var displayOnDark: Bool
}
