//
//  FetchedResultsSet.swift
//  CollectionView
//
//  Created by Wesley Byrne on 3/7/17.
//  Copyright © 2017 Noun Project. All rights reserved.
//

import Foundation


public enum FetchedSetControllerChangeType  {
    case delete
    case update
    case insert
}



public protocol FetchedSetControllerDelegate : class {
    func controllerWillChangeContent(_ controller: FetchedSetController) -> Bool
    func controller(_ controller: FetchedSetController, didChangeObject object: NSManagedObject, for changeType: FetchedSetControllerChangeType)
    func controllerDidChangeContent(_ controller: FetchedSetController)
}

public class FetchedSetController : NSObject {
    
    typealias Element = NSManagedObject
    private var _storage = Set<Element>()
    
    
    convenience public init(context: NSManagedObjectContext, entityName: String) {
        let req = NSFetchRequest<NSManagedObject>(entityName: entityName)
        self.init(context: context, request: req)
    }
    
    public init(context: NSManagedObjectContext, request: NSFetchRequest<NSManagedObject>) {
        self.managedObjectContext = context
        self.fetchRequest = request
        super.init()
        validateRequest()
    }
    
    
    
    public private(set) var managedObjectContext : NSManagedObjectContext
    public weak var delegate: FetchedSetControllerDelegate? {
        didSet {
            if (oldValue == nil) == (delegate == nil) { return }
            if delegate == nil { unregister() }
            else if _fetched { register() }
        }
    }
    
    
    // MARK: - Perform Fetch
    /*-------------------------------------------------------------------------------*/
    
    public let fetchRequest : NSFetchRequest<NSManagedObject>
    private var _fetched: Bool = false
    private func setNeedsFetch() {
        if _fetched {
            _fetched = false
            unregister()
        }
    }
    
    
    public func reset() {
        self._storage.removeAll()
        self.setNeedsFetch()
    }
    
    
    
    public func setManagedObjectContext(_ moc: NSManagedObjectContext) throws {
        guard moc != self.managedObjectContext else { return }
        self.setNeedsFetch()
        self.managedObjectContext = moc
        validateRequest()
        try self.performFetch()
    }
    
    
    private func validateRequest() {
        assert(fetchRequest.entityName != nil, "request is missing entity name")
        let objectEntity = NSEntityDescription.entity(forEntityName: fetchRequest.entityName!, in: self.managedObjectContext)
        assert(objectEntity != nil, "Unable to load entity description for object \(fetchRequest.entityName!)")
        fetchRequest.entity = objectEntity
    }
    
    
    
    public func performFetch() throws {
        
        guard self.fetchRequest.entityName != nil else {
            assertionFailure("fetch request must have an entity when performing fetch")
            throw ResultsControllerError.unknown
        }
        
        fetchRequest.sortDescriptors = nil
        fetchRequest.fetchLimit = 0
        
        if !_fetched && delegate != nil {
            register()
        }
        _fetched = true
        
        self._storage.removeAll()
        
        let _objects = try managedObjectContext.fetch(self.fetchRequest)
        self._storage = Set(_objects)
    }
    
    
    // MARK: - Notification Registration
    /*-------------------------------------------------------------------------------*/
    func register() {
        ResultsControllerCDManager.shared.add(context: self.managedObjectContext)
        NotificationCenter.default.addObserver(self, selector: #selector(handleChangeNotification(_:)), name: ResultsControllerCDManager.Dispatch.name, object: self.managedObjectContext)    }
    
    func unregister() {
        ResultsControllerCDManager.shared.remove(context: self.managedObjectContext)
        NotificationCenter.default.removeObserver(self, name: ResultsControllerCDManager.Dispatch.name, object: self.managedObjectContext)
    }
    
    func handleChangeNotification(_ notification: Notification) {
        
        guard let changes = notification.userInfo?[ResultsControllerCDManager.Dispatch.changeSetKey] as? [NSEntityDescription:ResultsControllerCDManager.EntityChangeSet] else {
            return
        }
        
        self.managedObjectContext.performAndWait {
            
            
            if let itemChanges = changes[self.fetchRequest.entity!] {
                
                var deleted = Set<Element>()
                var inserted = Set<Element>()
                var updated = Set<Element>()
                
                for obj in itemChanges.deleted {
                    guard let o = obj as? Element, let removes = self._storage.remove(o) else { continue }
                    deleted.insert(o)
                }
                
                
                for obj in itemChanges.inserted {
                    if let o = obj as? Element {
                        if self.fetchRequest.predicate == nil || self.fetchRequest.predicate?.evaluate(with: o) == true {
                            self._storage.insert(o)
                            inserted.insert(o)
                        }
                    }
                }
                
                for obj in itemChanges.updated {
                    if let o = obj as? Element {
                        
                        let existed = self.contains(o)
                        let match = self.fetchRequest.predicate == nil || self.fetchRequest.predicate?.evaluate(with: o) == true
                        
                        if existed {
                            if !match { deleted.insert(o) }
                            else { updated.insert(o) }
                        }
                        else if match {
                            inserted.insert(o)
                        }
                    }
                }
                
                if deleted.count == 0, updated.count == 0, inserted.count == 0 { return }
                
                self._storage.subtract(deleted)
                self._storage.union(inserted)
                
                if self.delegate?.controllerWillChangeContent(self) == true {
                
                    for o in deleted {
                        self.delegate?.controller(self, didChangeObject: o, for: .delete)
                    }
                    for o in inserted {
                        self.delegate?.controller(self, didChangeObject: o, for: .insert)
                    }
                    for o in updated {
                        self.delegate?.controller(self, didChangeObject: o, for: .update)
                    }
                }
                
                self.delegate?.controllerDidChangeContent(self)
            }
        }
        
        
        
    }
    
    
    
    // MARK: - Accessing Content
    /*-------------------------------------------------------------------------------*/
    private func contains(_ element: Element) -> Bool {
        return self._storage.contains(element)
    }
    
    
}
