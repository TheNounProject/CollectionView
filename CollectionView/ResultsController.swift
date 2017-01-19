
//  ResultsController.swift
//  Lingo
//
//  Created by Wesley Byrne on 1/11/17.
//  Copyright © 2017 The Noun Project. All rights reserved.
//

import Foundation
import CoreData

// Test 2

public extension Array where Element:Any {
    public func object(at index: Int) -> Element? {
        if index >= 0 && index < self.count {
            return self[index]
        }
        return nil
    }
}

public enum ResultsControllerError: Error {
    case unknown
}


public protocol CustomDisplayStringConvertible  {
    var displayDescription : String { get }
}

extension String : CustomDisplayStringConvertible {
    public var displayDescription: String { return self }
}

extension NSNumber : CustomDisplayStringConvertible {
    public var displayDescription: String { return "\(self)" }
}


public protocol ResultsController {
    
    var delegate : ResultsControllerDelegate? { get set }
    
    func numberOfSections() -> Int
    func numberOfObjects(in section: Int) -> Int
    
    // MARK: - Getting Items
    /*-------------------------------------------------------------------------------*/
    func section(for sectionIndexPath: IndexPath) -> ResultsControllerSection?
    func object(for sectionIndexPath: IndexPath) -> Any?
    func object(at indexPath: IndexPath) -> NSManagedObject?
    
    func sectionName(forSectionAt indexPath :IndexPath) -> String
    
    func performFetch() throws
    
}


public protocol ResultsControllerDelegate {
    func controllerWillChangeContent(controller: ResultsController)
    func controller(_ controller: ResultsController, didChangeObject object: NSManagedObject, at indexPath: IndexPath?, for changeType: ResultsControllerChangeType)
    func controller(_ controller: ResultsController, didChangeSection section: ResultsControllerSection, at indexPath: IndexPath?, for changeType: ResultsControllerChangeType)
    func controllerDidChangeContent(controller: ResultsController)
}

public protocol ResultsControllerSection {
    var object : Any? { get }
    var objects : [NSManagedObject] { get }
    var count : Int { get }
}


public enum ResultsControllerChangeType {
    case delete
    case update
    case insert(IndexPath)
    case move(IndexPath)
}


struct ContextChange<Object:NSManagedObject>: CustomStringConvertible {
    
    var inserted = Set<Object>()
    var updated = Set<Object>()
    var deleted = Set<Object>()
    
    var description: String {
        var str = "Context changes for \(Object.className())\n "
        + "updated: \(updated.count)\n"
        + "Inserted: \(inserted.count)\n"
        + "deleted: \(deleted.count)"
        return str
    }
    
    
    init() { }
    
    init(notification: Notification) {
        guard let info = notification.userInfo else {
            return
        }
        
        if let updated = info[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
            for obj in updated {
                if let o = obj as? Object {
                    self.updated.insert(o)
                }
            }
        }
        if let inserted = info[NSInsertedObjectsKey] as? Set<NSManagedObject> {
            for obj in inserted {
                if let o = obj as? Object {
                    self.inserted.insert(o)
                }
            }
        }
        
        var deleted = (info[NSDeletedObjectsKey] as? Set<NSManagedObject>) ?? Set<NSManagedObject>()
        if let invalidated = info[NSInvalidatedObjectsKey] as? Set<NSManagedObject> {
            deleted = deleted.union(invalidated)
        }
        for obj in deleted {
            if let o = obj as? Object {
                self.deleted.insert(o)
            }
        }
    }
    
//    static func allFrom(_ notification: Notification) -> [String:ContextChange<NSManagedObject>] {
//        
//        var result = [String: ContextChange<NSManagedObject>]()
//        guard let info = notification.userInfo else {
//            return result
//        }
//        
//        if let updated = info[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
//            for obj in updated {
//                if result[obj.className] == nil {
//                    result[obj.className] = ContextChange<NSManagedObject>(updated: obj)
//                }
//                else {
//                    result[obj.className]?.updated.insert(obj)
//                }
//            }
//        }
//        if let inserted = info[NSInsertedObjectsKey] as? Set<NSManagedObject> {
//            for obj in inserted {
//                if result[obj.className] == nil {
//                    result[obj.className] = ContextChange<NSManagedObject>(inserted: obj)
//                }
//                else {
//                    result[obj.className]?.inserted.insert(obj)
//                }
//            }
//        }
//        //        let refreshed = info[NSRefreshedObjectsKey] as? Set<NSManagedObject>
//        
//        var deleted = (info[NSDeletedObjectsKey] as? Set<NSManagedObject>) ?? Set<NSManagedObject>()
//        if let invalidated = info[NSInvalidatedObjectsKey] as? Set<NSManagedObject> {
//            deleted = deleted.union(invalidated)
//        }
//        for obj in deleted {
//            if result[obj.className] == nil {
//                result[obj.className] = ContextChange<NSManagedObject>(deleted: obj)
//            }
//            else {
//                result[obj.className]?.deleted.insert(obj)
//            }
//        }
//        
//        return result
//    }
    
    


    
}



