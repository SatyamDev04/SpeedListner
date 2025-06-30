//
//  Chapter+CoreDataClass.swift
//  BookPlayer
//
//  Created by  YesItLabs on 9/23/15.
//  
//
//

import Foundation
import CoreData
import AVFoundation

public class Chapter: NSManagedObject {
    var end: TimeInterval {
        return start + duration
    }
    convenience init(from asset: AVAsset, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "Chapter", in: context)!
        self.init(entity: entity, insertInto: context)

    }
}
