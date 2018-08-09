//
//  FetchedResultsObserver.swift
//  CollectionView
//
//  Created by Wesley Byrne on 2/9/17.
//  Copyright © 2017 Noun Project. All rights reserved.
//

import Foundation

fileprivate let nilKeyHash = UUID().hashValue

fileprivate struct RefKeyTable<Key:Hashable & AnyObject, Value:Any> : Sequence, ExpressibleByDictionaryLiteral {
    
    
    
    private struct KeyRef : Hashable {
        
        weak var key: Key?
        var keyHash : Int
        
        init(val: Key) {
            self.key = val
            self.keyHash = val.hashValue
        }
        
        var hashValue: Int {
            return keyHash
        }
        static func ==(lhs: KeyRef, rhs: KeyRef) -> Bool {
            return lhs.key == rhs.key
        }
    }
    
    private var storage = [KeyRef:Value]()
    
    subscript(key: Key) -> Value? {
        get {
            let k = KeyRef(val: key)
            return self.storage[k]
        }
        set {
            let k = KeyRef(val: key)
            if let val = newValue {
                self.storage[k] = val
            } else {
                self.storage.removeValue(forKey: k)
            }
        }
    }
    
    init(dictionaryLiteral elements: (Key, Value)...) {
        for e in elements {
            self.storage[KeyRef(val: e.0)] = e.1
        }
    }
    
    mutating func removeValue(forKey key: Key) -> Value? {
        return self.storage.removeValue(forKey: KeyRef(val: key))
    }
    
    public typealias Iterator = AnyIterator<(index: Key?, value: Value)>
    public func makeIterator() -> Iterator {
        var it = storage.makeIterator()
        return AnyIterator {
            if let val = it.next() {
                return (val.key.key, val.value)
            }
            return nil
        }
    }
    
}



class ManagedObjectContextObservationCoordinator {
    
    struct Notification {
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

        var isEmpty : Bool {
            return inserted.isEmpty && deleted.isEmpty && updated.isEmpty
        }
        
        @discardableResult mutating func inserted(_ object: NSManagedObject) -> Bool {
            return inserted.insert(object).inserted
        }
        @discardableResult mutating func deleted(_ object: NSManagedObject) -> Bool {
            return deleted.insert(object).inserted
        }
        @discardableResult mutating func updated(_ object: NSManagedObject) -> Bool {
            return updated.insert(object).inserted
        }
        
        var description: String {
            return "EntityChangeSet for \(self.entity.name!): "
                + "\(self.inserted.count) Inserted, "
            + "\(self.deleted.count) Deleted, "
            + "\(self.updated.count) Updated, "
            
        }
    }

    private var contexts = RefKeyTable<NSManagedObjectContext,Int>()
    class var shared : ManagedObjectContextObservationCoordinator {
        struct Static { static let instance = ManagedObjectContextObservationCoordinator() }
        return Static.instance
    }
    
    init() {
        
    }
    
    func add(context: NSManagedObjectContext) {
        let count = contexts[context] ?? 0
        if count == 0 {
            NotificationCenter.default.addObserver(self, selector: #selector(handleChangeNotification(_:)), name: Foundation.Notification.Name.NSManagedObjectContextObjectsDidChange, object: context)
        }
        contexts[context] = count + 1
    }
    
    
    func remove(context: NSManagedObjectContext) {
        let count = contexts[context] ?? 0
        if count <= 1 {
            NotificationCenter.default.removeObserver(self, name: Foundation.Notification.Name.NSManagedObjectContextObjectsDidChange, object: context)
            _ = contexts.removeValue(forKey: context)
        }
        else {
            contexts[context] = count - 1
        }
    }
    
    
    @objc func handleChangeNotification(_ notification: Foundation.Notification) {
        var changeSets = [NSEntityDescription:EntityChangeSet]()
        guard let info = notification.userInfo else {
            return
        }
        
        if info[NSInvalidatedAllObjectsKey] != nil {
            if let moc = notification.object as? NSManagedObjectContext {
                self.remove(context: moc)
            }
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
        
        NotificationCenter.default.post(name: Notification.name, object: notification.object, userInfo: [
            ManagedObjectContextObservationCoordinator.Notification.changeSetKey : changeSets
            ])
    }   
}
