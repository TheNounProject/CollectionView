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

/**
 A results controller that does not concern itself with the order of objects, but only their membership to the supplied fetch request.
*/
public class FetchedSetController: ContextObserver {
    
    typealias Element = NSManagedObject
    
    
    // MARK: - Initialization
    /*-------------------------------------------------------------------------------*/
    
    /// A convenience initializer that takes an entity name and creates a fetch request
    /// - Parameter context: A managed object context to fetch from
    /// - Parameter entityName: An entity name to fetch
    convenience public init(context: NSManagedObjectContext, entityName: String) {
        let req = NSFetchRequest<Element>(entityName: entityName)
        self.init(context: context, request: req)
    }
    
    
    /// Initialize a controller with a context and request
    ///
    /// - Parameter context: A managed object context to fetch from
    /// - Parameter request: A request for an entity
    public init(context: NSManagedObjectContext, request: NSFetchRequest<NSManagedObject>) {
        self.fetchRequest = request
        super.init(context: context)
        self.validateRequest()
    }
    
    deinit {
        unregister()
    }
    
    private var _fetched: Bool = false
    
    private func setNeedsFetch() {
        _fetched = false
        unregister()
    }
    
    /// Fetches the object and begins monitoring the context for changes
    ///
    /// - Returns: The initial contents of the controller
    /// - Throws: A fetch error if one occurs
    @discardableResult public func performFetch() throws -> [NSManagedObject] {
        
        guard self.fetchRequest.entityName != nil else {
            assertionFailure("fetch request must have an entity when performing fetch")
            throw ResultsControllerError.unknown
        }
        
        register()
        _fetched = true
        
        self._storage.removeAll()
        
        let _objects = try managedObjectContext.fetch(self.fetchRequest)
        self._storage = Set(_objects)
        return _objects
    }
    
    /// Clears all data and stops monitoring for changes in the context.
    public func reset() {
        self._storage.removeAll()
        self.setNeedsFetch()
    }
    
    
    private func validateRequest() {
        assert(fetchRequest.entityName != nil, "request is missing entity name")
        let objectEntity = NSEntityDescription.entity(forEntityName: fetchRequest.entityName!, in: self.managedObjectContext)
        assert(objectEntity != nil, "Unable to load entity description for object \(fetchRequest.entityName!)")
        fetchRequest.entity = objectEntity
    }

    
    // MARK: - Configuration
    /*-------------------------------------------------------------------------------*/
    
    /// The managed object context to fetch from
//    public private(set) var managedObjectContext : NSManagedObjectContext
    
    
    /**
     Update the context and perform a fetch

     - Parameter moc: The new managed object context
     
     - Returns: A fetch error if one occurs
    */
    public func setManagedObjectContext(_ moc: NSManagedObjectContext) throws {
        guard moc != self.managedObjectContext else { return }
        self.setNeedsFetch()
        self.managedObjectContext = moc
        validateRequest()
        try self.performFetch()
    }
    
    
    /// A fetch request (including a predicate if needed) for the entity to fetch
    public let fetchRequest : NSFetchRequest<NSManagedObject>
    
    /// The delegate of the controller
    public weak var delegate: FetchedSetControllerDelegate? {
        didSet {
            if (oldValue == nil) == (delegate == nil) { return }
            if delegate == nil { unregister() }
            else if _fetched { register() }
        }
    }
    

    // MARK: - Contents
    /*-------------------------------------------------------------------------------*/
    
    private var _storage = Set<Element>()
    
    
    /// The number of objects in the set
    public var numberOfObjects : Int { return _storage.count }
    
    /// Check if the set contains a given element
    ///
    /// - Parameter element: The element in query
    /// - Returns: True if the object exists in the set
    private func contains(_ element: Element) -> Bool {
        return self._storage.contains(element)
    }
    
    
    
    
    // MARK: - Notification Registration
    /*-------------------------------------------------------------------------------*/
    public override func shouldRegister() -> Bool {
        return self.delegate != nil
    }
    
    public override func process(_ changes: [NSEntityDescription : (inserted: Set<NSManagedObject>, deleted: Set<NSManagedObject>, updated: Set<NSManagedObject>)]) {
        
        guard let changes = changes[self.fetchRequest.entity!] else { return }
        
        var deleted = Set<Element>()
        var inserted = Set<Element>()
        var updated = Set<Element>()
        
        for obj in changes.deleted {
            guard let _ = self._storage.remove(obj) else { continue }
            deleted.insert(obj)
        }
        
        for obj in changes.inserted {
            if self.fetchRequest.predicate == nil || self.fetchRequest.predicate?.evaluate(with: obj) == true {
                self._storage.insert(obj)
                inserted.insert(obj)
            }
        }
        
        for obj in changes.updated {
            
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

}
