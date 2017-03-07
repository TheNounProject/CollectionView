//
//  FetchedResultsObserver.swift
//  CollectionView
//
//  Created by Wesley Byrne on 2/9/17.
//  Copyright © 2017 Noun Project. All rights reserved.
//

import Foundation


class ResultsControllerCDManager {
    
    
    struct Dispatch {
        static let name = Foundation.Notification.Name(rawValue: "CDResultsControllerNotification")
        static let changeSetKey : String = "EntityChangeSet"
    }
    
    
    struct EntityChangeSet : CustomStringConvertible {
        var entity: NSEntityDescription
        var inserted = Set<NSManagedObject>()
        var deleted = Set<NSManagedObject>()
        var updated = Set<NSManagedObject>()
        
        init(deleted obj: NSManagedObject) {
            self.entity = obj.entity
            self.deleted(obj)
        }
        init(inserted obj: NSManagedObject) {
            self.entity = obj.entity
            self.inserted(obj)
        }
        init(updated obj: NSManagedObject) {
            self.entity = obj.entity
            self.updated(obj)
        }
        
        mutating func inserted(_ object: NSManagedObject) -> Bool {
            return inserted.insert(object).inserted
        }
        mutating func deleted(_ object: NSManagedObject) -> Bool {
            return deleted.insert(object).inserted
        }
        mutating func updated(_ object: NSManagedObject) -> Bool {
            return updated.insert(object).inserted
        }
        
        var description: String {
            return "EntityChangeSet for \(self.entity.name!): "
                + "\(self.inserted.count) Inserted, "
            + "\(self.deleted.count) Deleted, "
            + "\(self.updated.count) Updated, "
            
        }
        
    }

    
    var contexts = [NSManagedObjectContext:Int]()
    
    class var shared : ResultsControllerCDManager {
        struct Static { static let instance = ResultsControllerCDManager() }
        return Static.instance
    }
    
    
    init() {
        
    }
    
    
    func add(context: NSManagedObjectContext) {
        let count = contexts[context] ?? 0
        if count == 0 {
            NotificationCenter.default.addObserver(self, selector: #selector(handleChangeNotification(_:)), name: Notification.Name.NSManagedObjectContextObjectsDidChange, object: context)
        }
        contexts[context] = count + 1
    }
    
    
    func remove(context: NSManagedObjectContext) {
        let count = contexts[context] ?? 0
        
        if count <= 1 {
            NotificationCenter.default.removeObserver(self, name: Notification.Name.NSManagedObjectContextObjectsDidChange, object: context)
            contexts.removeValue(forKey: context)
        }
        else {
            contexts[context] = count - 1
        }
    }
    
    
    @objc func handleChangeNotification(_ notification: Notification) {
        var changeSets = [NSEntityDescription:EntityChangeSet]()
        guard let info = notification.userInfo else {
            return
        }
        
        var deleted = (info[NSDeletedObjectsKey] as? Set<NSManagedObject>) ?? Set<NSManagedObject>()
        if let invalidated = info[NSInvalidatedObjectsKey] as? Set<NSManagedObject> {
            deleted = deleted.union(invalidated)
        }
        for obj in deleted {
            if changeSets[obj.entity]?.deleted(obj) == nil {
                changeSets[obj.entity] = EntityChangeSet(deleted: obj)
            }
        }
        
        if let inserted = info[NSInsertedObjectsKey] as? Set<NSManagedObject> {
            for obj in inserted {
                if changeSets[obj.entity]?.inserted(obj) == nil {
                    changeSets[obj.entity] = EntityChangeSet(inserted: obj)
                }
            }
        }
        
        
        var updated = info[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? Set<NSManagedObject>()
        if let invalidated = info[NSRefreshedObjectsKey] as? Set<NSManagedObject> {
            updated = updated.union(invalidated)
        }
        for obj in updated {
            if changeSets[obj.entity]?.updated(obj) == nil {
                changeSets[obj.entity] = EntityChangeSet(updated: obj)
            }
        }
        
//        print("CD Results Controller Dispatch")
//        for set in changeSets {
//            print(set.value)
//        }
        
        NotificationCenter.default.post(name: Dispatch.name, object: notification.object, userInfo: [
            ResultsControllerCDManager.Dispatch.changeSetKey : changeSets
            ])
    }
    
    
    
    
    
}





class FetchedResultsObserver {
    
    
    
    
    
}
