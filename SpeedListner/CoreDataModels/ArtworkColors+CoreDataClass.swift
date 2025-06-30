//
//  ArtworkColors+CoreDataClass.swift
//  BookPlayer
//
//  Created by  YesItLabs on 9/23/15.
//  
//
//

import Foundation
import CoreData
import UIKit
//import ColorCube

public class ArtworkColors: NSManagedObject {
    var background: UIColor {
        return UIColor(hex: self.backgroundHex)
    }
    var primary: UIColor {
        return UIColor(hex: self.primaryHex)
    }
    var secondary: UIColor {
        return UIColor(hex: self.secondaryHex)
    }
    var tertiary: UIColor {
        return UIColor(hex: self.tertiaryHex)
    }
    
    // W3C recommends contrast values larger than 4 or 7 (strict), but 3.0 should be fine for our use case
    convenience init(from image: UIImage,
                     context: NSManagedObjectContext,
                     darknessThreshold: CGFloat = 0.2,
                     minimumContrastRatio: CGFloat = 3.0) {
        let entity = NSEntityDescription.entity(forEntityName: "ArtworkColors", in: context)!
        self.init(entity: entity, insertInto: context)

        // Safeguard against empty or unprocessed image data
        var colors: [UIColor] = [.red, .blue] // Provide some initial colors if extraction fails

        // Extract average color for luminance check
        let averageColor = image.averageColor()
        let displayOnDark = averageColor.luminance > darknessThreshold

        // Sort colors based on luminance
        colors.sort { color1, color2 in
            if displayOnDark {
                return color1.isDarker(than: color2)
            } else {
                return color1.isLighter(than: color2)
            }
        }

        // Set background color
        let backgroundColor: UIColor = colors.first ?? UIColor.white
        
        // Adjust contrast and ensure proper visibility for the other colors
        colors = colors.map { color in
            let contrastRatio = color.contrastRatio(with: backgroundColor)
            
            if contrastRatio > minimumContrastRatio || color == backgroundColor {
                return color
            } else {
                return displayOnDark ? color.overlayWhite : color.overlayBlack
            }
        }

        // Set the colors in the Core Data object
        self.setColorsFromArray(colors, displayOnDark: displayOnDark)
    }

    // Set the hex color values in Core Data from an array of UIColor
    func setColorsFromArray(_ colors: [UIColor] = [], displayOnDark: Bool = false) {
        var colorsToSet = colors

        // Ensure at least 4 colors are present
        if colorsToSet.isEmpty {
            colorsToSet.append(UIColor(hex: "#FFFFFF")) // background
            colorsToSet.append(UIColor(hex: "#37454E")) // primary
            colorsToSet.append(UIColor(hex: "#3488D1")) // secondary
            colorsToSet.append(UIColor(hex: "#7685B3")) // tertiary
        } else if colorsToSet.count < 4 {
            let placeholder = displayOnDark ? UIColor.white : UIColor.black
            while colorsToSet.count < 4 {
                colorsToSet.append(placeholder)
            }
        }

        // Store the hex values in Core Data
        self.backgroundHex = colorsToSet[0].cssHex
        self.primaryHex = colorsToSet[1].cssHex
        self.secondaryHex = colorsToSet[2].cssHex
        self.tertiaryHex = colorsToSet[3].cssHex

        self.displayOnDark = displayOnDark
    }

    // Default initializer: Assigns default colors if no image is available
    convenience init(context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "ArtworkColors", in: context)!
        self.init(entity: entity, insertInto: context)

        self.setColorsFromArray() // Assign default colors
    }
}
