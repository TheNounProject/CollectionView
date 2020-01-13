//
//  RelationalResultsController.swift
//  CollectionView
//
//  Created by Wesley Byrne on 1/12/17.
//  Copyright © 2017 Noun Project. All rights reserved.
//

import Foundation

/// A FetchedResultsController provides the same data store and change reporting as a MutableResultsController but sources it's contents from a CoreData context.
///
/// Given an NSFetchRequest, the results from the provided context are fetched and analyzed to provide the data necessary to populate a CollectionView.
///
/// The controller can also be sorted, grouped into sections and automatically updated when changes are made in the managed obejct context.
public class FetchedResultsController<Section: SectionType, Element: NSManagedObject>: MutableResultsController<Section, Element> {
    
    // MARK: - Initialization
    /*-------------------------------------------------------------------------------*/
    
    /// Controller initializer a given context and fetch request
    ///
    /// - Parameter context: A managed object context
    /// - Parameter request: A fetch request with an entity name
    /// - Parameter sectionKeyPath: An optional key path to use for section groupings
    public init(context: NSManagedObjectContext, request: NSFetchRequest<Element>, sectionKeyPath: KeyPath<Element, Section>? = nil) {
        
        assert(request.entityName != nil, "request is missing entity name")
        let objectEntity = NSEntityDescription.entity(forEntityName: request.entityName!, in: context)
        assert(objectEntity != nil, "Unable to load entity description for object \(request.entityName!)")
        request.entity = objectEntity
        
        request.returnsObjectsAsFaults = false
        
        self._managedObjectContext = context
        self.fetchRequest = request
        
        super.init(sectionKeyPath: sectionKeyPath)
    }
    
    deinit {
        self.fetchRequest.predicate = nil
        unregister()
    }
    
    // MARK: - Configuration
    /*-------------------------------------------------------------------------------*/
    
    /// An object the report to when content in the controller changes
    public override weak var delegate: ResultsControllerDelegate? {
        didSet {
            if (oldValue == nil) == (delegate == nil) { return }
            if delegate == nil { unregister() } else if _fetched { register() }
        }
    }
    
    ///The fetch request for the controller
    public let fetchRequest: NSFetchRequest<Element>
    
    override var sectionGetter: SectionAccessor? {
        didSet {
            self.setNeedsFetch()
        }
    }
    
    fileprivate weak var _managedObjectContext: NSManagedObjectContext?
    
    /// The managed object context to fetch from
    public var managedObjectContext: NSManagedObjectContext {
        return self._managedObjectContext!
    }
    
    /// Update the managed object context used by the controller
    ///
    /// - Parameter moc: The new context to use
    ///
    /// - Returns: This implicitly calls performFetch which can throw
    public func setManagedObjectContext(_ moc: NSManagedObjectContext) throws {
        guard moc != self.managedObjectContext else { return }
        self.setNeedsFetch()
        self._managedObjectContext = moc
        validateRequests()
        
        try self.performFetch()
    }
    
    func validateRequests() {
        assert(fetchRequest.entityName != nil, "request is missing entity name")
        let objectEntity = NSEntityDescription.entity(forEntityName: fetchRequest.entityName!, in: self.managedObjectContext)
        assert(objectEntity != nil, "Unable to load entity description for object \(fetchRequest.entityName!)")
        fetchRequest.entity = objectEntity
    }
    
    func evaluate(object: Element) -> Bool {
        guard let p = self.fetchRequest.predicate else { return true }
        return p.evaluate(with: object)
    }
    
    // MARK: - Status
    /*-------------------------------------------------------------------------------*/
    fileprivate var _fetched: Bool = false
    private var _registered = false
    
    func setNeedsFetch() {
        _fetched = false
        unregister()
    }
    
    fileprivate func register() {
        guard let moc = self._managedObjectContext, !_registered, self.delegate != nil else { return }
        _registered = true
        ManagedObjectContextObservationCoordinator.shared.add(context: self.managedObjectContext)
        NotificationCenter.default.addObserver(self, selector: #selector(handleChangeNotification(_:)),
                                               name: ManagedObjectContextObservationCoordinator.Notification.name,
                                               object: moc)    }
    
    fileprivate func unregister() {
        guard let moc = self._managedObjectContext, _registered else { return }
        _registered = false
        ManagedObjectContextObservationCoordinator.shared.remove(context: moc)
        NotificationCenter.default.removeObserver(self, name: ManagedObjectContextObservationCoordinator.Notification.name, object: moc)
    }
    
    /// Performs the provided fetch request to populate the controller. Calling again resets the controller.
    ///
    /// - Throws: If the fetch request is invalid or the fetch fails
    public func performFetch() throws {
        validateRequests()
        
        register()
        _fetched = true
        
        let _objects = try managedObjectContext.fetch(self.fetchRequest)
        self.setContent(objects: _objects)
    }
    
    /// Clears all data and stops monitoring for changes in the context.
    public override func reset() {
        self.setNeedsFetch()
        super.reset()
    }
    
    override func shouldRemoveEmptySection(_ section: SectionInfo<Section, Element>) -> Bool {
        return true
    }
    
    func processChanges(_ changes: [NSEntityDescription: ManagedObjectContextObservationCoordinator.EntityChangeSet]) {
        if let itemChanges = changes[fetchRequest.entity!] {
            self.beginEditing()
            for obj in itemChanges.deleted {
                if let o = obj as? Element {
                    self.delete(object: o)
                }
            }
            
            func _updatedObject(_ o: Element) {
                let match = evaluate(object: o)
                
                if self.contains(object: o) {
                    if !match { self.delete(object: o) } else { self.didUpdate(object: o) }
                } else if match {
                    self.insert(object: o)
                }
            }
            
            for obj in itemChanges.inserted {
                if let o = obj as? Element {
                    _updatedObject(o)
                }
            }
            
            for obj in itemChanges.updated {
                if let o = obj as? Element {
                    _updatedObject(o)
                }
            }
            self.endEditing()
        }
    }
    
    @objc func handleChangeNotification(_ notification: Notification) {
        guard self.delegate != nil, self._fetched else {
            print("Ignoring context notification because results controller doesn't have a delegate or has not been fetched yet")
            return
        }
        guard let changes = notification.userInfo?[ManagedObjectContextObservationCoordinator.Notification.changeSetKey]
            as? [NSEntityDescription: ManagedObjectContextObservationCoordinator.EntityChangeSet] else {
            return
        }
        self.processChanges(changes)
    }
}

/**
 
 Extending on FetchedResultsController and it's section grouping, this controller allows for sections to be created from a parent ententy.- 
 
 In a FetchedResultsController (and NSFetchedResultsController) you would use sectionKeyPath to achieve the following:
 
 ```
 Things
    { sectionKeyPath : "Things" }
    { sectionKeyPath : "Things" }
 
 Not Things
    { sectionKeyPath : "Not Things" }
    { sectionKeyPath : "Not Things" }
 ```
 
 While this is great, it does not work well for the common Parent-Child data model. In a Department - Employee model for example we woul want:
 
 ```
 Sales {}
    Jim {}
    Samantha {}
 
 Managment {}
    Sarah {}
    Howard {}

 
 Delivery {}
    <No employees>
 ```
 
 In this case, both the parent and child are NSManagedObjects joined by a relationship. Also, notice the Delivery department has no employees. With a standard FetchedResultsController where sections consist of the available values in the fetched objects, the "Delivery" would not be included. With a RelationalResultsController though you can opt to fetch both the sections and object independently (see `fetchSections`).
*/
public class RelationalResultsController<Section: NSManagedObject, Element: NSManagedObject>: FetchedResultsController<Section, Element> {
    
    // MARK: - Initialization
    /*-------------------------------------------------------------------------------*/
    
    public init(context: NSManagedObjectContext, request: NSFetchRequest<Element>, sectionRequest: NSFetchRequest<Section>, sectionKeyPath keyPath: KeyPath<Element, Section>) {
        
        self.sectionFetchRequest = sectionRequest
        sectionRequest.returnsObjectsAsFaults = false
        
        super.init(context: context, request: request, sectionKeyPath: keyPath)
        
        validateRequests()
    }
    
    /// Intialize a controller
    ///
    /// - Parameters:
    ///   - context: A managed object context
    ///   - request: A request for fetching objects
    ///   - sectionRequest: A request for fetching sections (if fetchSections is true)
    ///   - keyPath: The key path on the controllers objects that references the sections
    public init(context: NSManagedObjectContext, request: NSFetchRequest<Element>, sectionRequest: NSFetchRequest<Section>, sectionKeyPath keyPath: KeyPath<Element, Section?>) {
        
        self.sectionFetchRequest = sectionRequest
        sectionRequest.returnsObjectsAsFaults = false
        
        super.init(context: context, request: request)
        setSectionKeyPath(keyPath)
        validateRequests()
    }
    
    deinit {
        self.sectionFetchRequest.predicate = nil
    }
    
    /// Executes a fetch to populate the controller
    override public func performFetch() throws {
        // Validation
        validateRequests()
        precondition(isSectioned, "RelationalResultsController must have a sectionKeyPath")
        
        var sections: [Section]?
        if self.fetchSections { // Add the queried sections if desired
            sections = try managedObjectContext.fetch(self.sectionFetchRequest)
        }
        
        let _objects = try managedObjectContext.fetch(self.fetchRequest)
        self.setContent(sections: sections ?? [], objects: _objects)
        register() // Manage notification registration
        _fetched = true
    }
    
    override func validateRequests() {
        super.validateRequests()
        assert(sectionFetchRequest.entityName != nil, "sectionRequest is missing entity name")
        let sectionEntity = NSEntityDescription.entity(forEntityName: sectionFetchRequest.entityName!, in: self.managedObjectContext)
        assert(sectionEntity != nil, "Unable to load entity description for section \(sectionFetchRequest.entityName!)")
        sectionFetchRequest.entity = sectionEntity
    }
    
    func evaluate(section: Section) -> Bool {
        guard let p = self.sectionFetchRequest.predicate else { return true }
        return p.evaluate(with: section)
    }
    
    // MARK: - Configuration
    /*-------------------------------------------------------------------------------*/
    
    /// A fetch request used to fetch, filter, and sort the section results of the controller.
    ///
    /// This is used to validate the section objects. If `fetchSections` is true, section objects will be fetched independent of the child objects.
    ///
    /// A parent object that does not match the request here, may still be visible if it has children that match the predicate of fetchRequest.
    public let sectionFetchRequest: NSFetchRequest<Section>
    
    /// A keyPath of the section objects to get the displayable name
    ///
    /// For custom names, leave nil and conform your section objects to CustomDisplayStringConvertible
    public var sectionNameKeyPath: KeyPath<Section, String>?
    
    /// If true, sections will be fetched independent of objects using sectionFetchRequest.
    ///
    /// This is useful to populate the controller with section objects that may not have any children.
    public var fetchSections: Bool = true
    
    override func shouldRemoveEmptySection(_ section: SectionInfo<Section, Element>) -> Bool {
        guard fetchSections, let s = section.representedObject else { return true }
        return !self.evaluate(section: s)
    }
    
    // MARK: - Section Names
    /*-------------------------------------------------------------------------------*/
    public override func sectionName(forSectionAt indexPath: IndexPath) -> String {
        guard let obj = sectionInfo(at: indexPath)?.representedObject else {
            return "Ungrouped"
        }
        if let key = self.sectionNameKeyPath {
            let val = obj[keyPath: key]
            return val
        }
        return (obj as? CustomDisplayStringConvertible)?.displayDescription ?? ""
    }
    
    // MARK: - Handling Changes
    /*-------------------------------------------------------------------------------*/
    override func processChanges(_ changes: [NSEntityDescription: ManagedObjectContextObservationCoordinator.EntityChangeSet]) {
        guard let delegate = self.delegate, self._fetched else {
            print("Ignoring context notification because results controller doesn't have a delegate or has not been fetched yet")
            return
        }
        
        self.beginEditing()
        if let sectionChanges = changes[sectionFetchRequest.entity!] {
            
            for obj in sectionChanges.deleted {
                if let section = obj as? Section, self.contains(sectionObject: section) {
                    self.delete(section: section)
                }
            }
            
            func _updated(section: Section) {
                let match = self.evaluate(section: section)
                if self.fetchSections {
                    if self.contains(sectionObject: section) {
                        if !match { self.delete(section: section) } else { self.didUpdate(section: section) }
                    } else if match {
                        self.insert(section: section)
                    }
                } else if self.contains(sectionObject: section) {
                    self.didUpdate(section: section)
                }
            }
            
            for obj in sectionChanges.inserted {
                if let section = obj as? Section {
                    _updated(section: section)
                }
            }
            
            for obj in sectionChanges.updated {
                if let section = obj as? Section {
                    _updated(section: section)
                }
            }
        }
        super.processChanges(changes)
        endEditing()
    }
}
