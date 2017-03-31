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
    
    
    public var numberOfObjects : Int { return _storage.count }
    
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
    
    
    
    public func performFetch() throws -> [NSManagedObject] {
        
        guard self.fetchRequest.entityName != nil else {
            assertionFailure("fetch request must have an entity when performing fetch")
            throw ResultsControllerError.unknown
        }
        
        if !_fetched && delegate != nil {
            register()
        }
        _fetched = true
        
        self._storage.removeAll()
        
        let _objects = try managedObjectContext.fetch(self.fetchRequest)
        self._storage = Set(_objects)
        return _objects
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
    
    public var wait: Bool = true
    
    func handleChangeNotification(_ notification: Notification) {
        guard let changes = notification.userInfo?[ResultsControllerCDManager.Dispatch.changeSetKey] as? [NSEntityDescription:ResultsControllerCDManager.EntityChangeSet] else {
            return
        }
        
        if let itemChanges = changes[self.fetchRequest.entity!] {
        func run() {
                var deleted = Set<Element>()
                var inserted = Set<Element>()
                var updated = Set<Element>()
                
                for obj in itemChanges.deleted {
                    guard let removes = self._storage.remove(obj) else { continue }
                    deleted.insert(obj)
                }
                
                for obj in itemChanges.inserted {
                    if self.fetchRequest.predicate == nil || self.fetchRequest.predicate?.evaluate(with: obj) == true {
                        self._storage.insert(obj)
                        inserted.insert(obj)
                    }
                }
                
                for obj in itemChanges.updated {
                    
                    let existed = self.contains(obj)
                    let match = self.fetchRequest.predicate == nil || self.fetchRequest.predicate?.evaluate(with: obj) == true
                    
                    if existed {
                        if !match { deleted.insert(obj) }
                        else { updated.insert(obj) }
                    }
                    else if match {
                        inserted.insert(obj)
                    }
                }
                
                if deleted.count == 0, updated.count == 0, inserted.count == 0 { return }
                
                self._storage.subtract(deleted)
                self._storage.formUnion(inserted)
                
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

            if wait {
                self.managedObjectContext.performAndWait { run() }
            }
            else {
                self.managedObjectContext.perform { run() }
            }
        }
        
        
    }
    
    
    
    // MARK: - Accessing Content
    /*-------------------------------------------------------------------------------*/
    private func contains(_ element: Element) -> Bool {
        return self._storage.contains(element)
    }
    
    
}
