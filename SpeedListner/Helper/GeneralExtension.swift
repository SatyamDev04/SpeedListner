//
//  GeneralExtension.swift
//  SpeedListners
//
//  Created by ravi on 20/12/22.
//

import Foundation

// MARK: - Dictionary Extensions >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

extension Dictionary {
    mutating func unionInPlace(_ dictionary: Dictionary<Key, Value>) {
        for (key, value) in dictionary {
            self[key] = value
        }
    }
    
    mutating func unionInPlace<S: Sequence>(_ sequence: S) where S.Iterator.Element == (Key, Value) {
        for (key, value) in sequence {
            self[key] = value
        }
    }
    
    func validatedValue(_ key: Key, expected: AnyObject) -> AnyObject {
        // checking if in case object is nil
        
        if let object = self[key] as? AnyObject {
            // added helper to check if in case we are getting number from server but we want a string from it
            if object is NSNumber, expected is String {
                return "\(object)" as AnyObject
            } else if object is NSNumber, expected is Float {
                return object.floatValue as AnyObject
            } else if object is NSNumber, expected is Double {
                return object.doubleValue as AnyObject
            } else if object.isKind(of: expected.classForCoder) == false {
                return expected
            } else if object is String {
                if (object as! String == "null") || (object as! String == "<null>") || (object as! String == "(null)") {
                    return "" as AnyObject
                }
            }
            return object
        } else {
            if expected is String || expected as! String == "" {
                return "" as AnyObject
            }
            
            return expected
        }
    }
}

