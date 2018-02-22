//
//  RelationalResultsController.swift
//  CollectionView
//
//  Created by Wesley Byrne on 1/12/17.
//  Copyright © 2017 Noun Project. All rights reserved.
//

import Foundation







/**
 A FetchedResultsController provides the same data store and change reporting as a MutableResultsController but sources it's contents from a CoreData context.
 
 Given an NSFetchRequest, the results from the provided context are fetched and analyzed to provide the data necessary to populate a CollectionView.
 
 The controller can also be sorted, grouped into sections and automatically updated when changes are made in the managed obejct context.
 */
class FetchedResultsController<Section: SectionType, Element: NSManagedObject> : MutableResultsController<Section, Element> {
    
    
    // MARK: - Initialization
    /*-------------------------------------------------------------------------------*/
    
    /**
     Controller initializer a given context and fetch request
     
     - Parameter context: A managed object context
     - Parameter request: A fetch request with an entity name
     - Parameter sectionKeyPath: An optional key path to use for section groupings
     
     */
    public init(context: NSManagedObjectContext, request: NSFetchRequest<Element>, sectionKeyPath: KeyPath<Element,Section>? = nil) {
        
        
        assert(request.entityName != nil, "request is missing entity name")
        let objectEntity = NSEntityDescription.entity(forEntityName: request.entityName!, in: context)
        assert(objectEntity != nil, "Unable to load entity description for object \(request.entityName!)")
        request.entity = objectEntity
        
        request.returnsObjectsAsFaults = false
        
        self._managedObjectContext = context
        self.fetchRequest = request
        
        super.init()
        self.sectionKeyPath = sectionKeyPath
    }
    
    deinit {
        self.fetchRequest.predicate = nil
        unregister()
    }
    
    
    
    // MARK: - Configuration
    /*-------------------------------------------------------------------------------*/
    
    /**
     An object the report to when content in the controller changes
     */
    public override weak var delegate: ResultsControllerDelegate? {
        didSet {
            if (oldValue == nil) == (delegate == nil) { return }
            if delegate == nil { unregister() }
            else if _fetched { register() }
        }
    }
    
    ///The fetch request for the controller
    public let fetchRequest : NSFetchRequest<Element>
    
    public override var sectionKeyPath: KeyPath<Element, Section>? {
        didSet {
            self.setNeedsFetch()
        }
    }
    
    fileprivate weak var _managedObjectContext: NSManagedObjectContext?
    
    /// The managed object context to fetch from
    public var managedObjectContext: NSManagedObjectContext {
        return self._managedObjectContext!
    }
    
    /**
     Update the managed object context used by the controller
     
     - Parameter moc: The new context to use
     
     - Returns: This implicitly calls performFetch which can throw
     
     */
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
    var _fetched: Bool = false
    private var _registered = false
    
    
    func setNeedsFetch() {
        _fetched = false
        unregister()
    }
    
    func register() {
        guard let moc = self._managedObjectContext, !_registered, self.delegate != nil else { return }
        _registered = true
        ManagedObjectContextObservationCoordinator.shared.add(context: self.managedObjectContext)
        NotificationCenter.default.addObserver(self, selector: #selector(handleChangeNotification(_:)), name: ManagedObjectContextObservationCoordinator.Notification.name, object: moc)    }
    
    func unregister() {
        guard let moc = self._managedObjectContext, _registered else { return }
        _registered = false
        ManagedObjectContextObservationCoordinator.shared.remove(context: moc)
        NotificationCenter.default.removeObserver(self, name: ManagedObjectContextObservationCoordinator.Notification.name, object: moc)
    }
    
    
    /**
     Performs the provided fetch request to populate the controller. Calling again resets the controller.
     
     - Throws: If the fetch request is invalid or the fetch fails
     */
    
    public func performFetch() throws {
        validateRequests()
        
        register()
        _fetched = true
        
        let _objects = try managedObjectContext.fetch(self.fetchRequest)
        self.setContent(_objects)
    }
    
    
    /// Clears all data and stops monitoring for changes in the context.
    public override func reset() {
        self.setNeedsFetch()
        super.reset()
    }
    
    override func shouldRemoveEmptySection(_ section: SectionInfo<Section, Element>) -> Bool {
        return true
    }
    
    
    @objc func handleChangeNotification(_ notification: Notification) {
        guard let delegate = self.delegate, self._fetched else {
            print("Ignoring context notification because results controller doesn't have a delegate or has not been fetched yet")
            return
        }
        guard let changes = notification.userInfo?[ManagedObjectContextObservationCoordinator.Notification.changeSetKey] as? [NSEntityDescription:ManagedObjectContextObservationCoordinator.EntityChangeSet] else {
            return
        }
        
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
                    if !match { self.delete(object: o) }
                    else { self.didUpdate(object: o) }
                }
                else if match {
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
public class RelationalResultsController<Section: NSManagedObject, Element: NSManagedObject> : FetchedResultsController<Section, Element> {
    
    // MARK: - Initialization
    /*-------------------------------------------------------------------------------*/
    
    public init(context: NSManagedObjectContext, request: NSFetchRequest<Element>, sectionRequest: NSFetchRequest<Section>, sectionKeyPath keyPath: KeyPath<Element, Section>) {
        
        self.sectionFetchRequest = sectionRequest
        sectionRequest.returnsObjectsAsFaults = false
        
        super.init(context: context, request: request, sectionKeyPath: keyPath)
        
        validateRequests()
        
        self.sectionKeyPath = keyPath
    }
    
    deinit {
        self.sectionFetchRequest.predicate = nil
    }
    
    
    override func validateRequests() {
        super.validateRequests()
        assert(sectionFetchRequest.entityName != nil, "sectionRequest is missing entity name")
        let sectionEntity = NSEntityDescription.entity(forEntityName: sectionFetchRequest.entityName!, in: self.managedObjectContext)
        assert(sectionEntity != nil, "Unable to load entity description for section \(sectionFetchRequest.entityName!)")
        sectionFetchRequest.entity = sectionEntity
    }
    
    
    func evaluate(section: Section) -> Bool {
        guard let p = self.fetchRequest.predicate else { return true }
        return p.evaluate(with: section)
    }
    
    /// Executes a fetch to populate the controller
    override public func performFetch() throws {
        // Validation
        validateRequests()
        precondition(sectionKeyPath != nil, "RelationalResultsController must have a sectionKeyPath")
        
        // Manage notification registration
        register()
        _fetched = true
        
        // Add the queried sections if desired
        if self.fetchSections {
            for section in try managedObjectContext.fetch(self.sectionFetchRequest) {
                _ = self.getOrCreateSectionInfo(for: section)
            }
        }
        try super.performFetch()
    }

    
    // MARK: - Configuration
    /*-------------------------------------------------------------------------------*/
    
    /**
     A fetch request used to fetch, filter, and sort the section results of the controller.
     
     This is used to validate the section objects. If `fetchSections` is true, section objects will be fetched independent of the child objects.
     
     A parent object that does not match the request here, may still be visible if it has children that match the predicate of fetchRequest.
     */
    public let sectionFetchRequest : NSFetchRequest<Section>
    
    /**
     A keyPath of the section objects to get the displayable name
     
     For custom names, leave nil and conform your section objects to CustomDisplayStringConvertible
     */
    public var sectionNameKeyPath : String?
    
    
    /**
     If true, sections will be fetched independent of objects using sectionFetchRequest.
     
     This is useful to populate the controller with section objects that may not have any children.
     */
    public var fetchSections : Bool = true
    
    
    override func shouldRemoveEmptySection(_ section: SectionInfo<Section, Element>) -> Bool {
        guard fetchSections, let s = section.representedObject else { return true }
        return !self.evaluate(section: s)
    }
    
    
    // MARK: - Controller Contents
    /*-------------------------------------------------------------------------------*/
    
    /**
     An array of all sections
     
     - Note: accessing the sections here incurs fairly large overhead, avoid if possible. Use `numberOfSections` and sectionInfo(forSectionAt:) when possible.
     */
//    public var sections: [SectionInfo] { return _sections.objects }
    
    
//    private var _objectSectionMap = [Element:SectionInfo]() // Map between elements and the last group it was known to be in
//    private var _sections = OrderedSet<SectionInfo>()
    

    
    
    // MARK: - Section Names
    /*-------------------------------------------------------------------------------*/
    
    public override func sectionName(forSectionAt indexPath: IndexPath) -> String {
        guard let obj = sectionInfo(at: indexPath)?.representedObject else {
            return "Ungrouped"
        }
        if let key = self.sectionNameKeyPath,
            let val = obj.value(forKeyPath: key) as? CustomDisplayStringConvertible {
            return val.displayDescription
        }
        return (obj as? CustomDisplayStringConvertible)?.displayDescription ?? ""
    }
    
    
    // MARK: - Storage Manipulation
    /*-------------------------------------------------------------------------------*/
//    private func _ensureSectionCopy() {
//        if _sectionsCopy == nil { _sectionsCopy = _sections }
//    }
    
    
    // MARK: - Empty Sections
    /*-------------------------------------------------------------------------------*/
    
    
    /**
     If the controller should assume that sections with zero objects have a placholder.
     
     # Discussion
     When displaying sections within a CollectionView, it can be helpful to fill empty sections with a placholder cell. This causes an issue when responding to updates from a results controller. For example, when an object is inserted into an empty section, the results controller will report a single insert change. The CollectionView though would need to remove the exisitng cell AND insert the new one.
     
     Setting hasEmptySectionPlaceholders to true, will report changes as such, making it easy to propagate the reported changes to a CollectionView.
     */
    public var hasEmptySectionPlaceholders : Bool = false
    
    
    
    /// A special set of changes if empty sections are enabled that can be passed along to a Collection View
    public private(set) var emptySectionChanges : ResultsChangeSet?
    
    
    
    
    // MARK: - Handling Changes
    /*-------------------------------------------------------------------------------*/
    
//    fileprivate var context = UpdateContext<Section, Element>()
//    fileprivate var _sectionsCopy : OrderedSet<SectionInfo>?
    
    
    /// Returns the number of item & section changes processed during an update. Only valid during controllDidChangeContent(_)
//    public var pendingChangeCount : Int {
//        return pendingItemChangeCount + pendingSectionChangeCount
//    }
//    /// Returns the number of item changes processed during an update. Only valid during controllDidChangeContent(_)
//    public var pendingItemChangeCount : Int {
//        return context.objectChangeSet.count
//    }
    
    /// Returns the number of section changes processed during an update. Only valid during controllDidChangeContent(_)
//    public var pendingSectionChangeCount : Int {
//        return context.sectionChangeSet.count
//    }
    
    
    @objc override func handleChangeNotification(_ notification: Notification) {
        
        guard let delegate = self.delegate, self._fetched else {
            print("Ignoring context notification because results controller doesn't have a delegate or has not been fetched yet")
            return
        }
        guard let changes = notification.userInfo?[ManagedObjectContextObservationCoordinator.Notification.changeSetKey] as? [NSEntityDescription:ManagedObjectContextObservationCoordinator.EntityChangeSet] else {
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
                        if !match { self.delete(section: section) }
                        else { self.didUpdate(section: section) }
                    }
                    else if match {
                        self.insert(section: section)
                    }
                }
                else if self.contains(sectionObject: section) {
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
        
        super.handleChangeNotification(notification)
        endEditing()

            
            
            /*
            self.emptySectionChanges = nil
            self._sectionsCopy = nil
            self.context.reset()
            
            self.preprocess(notification: notification)
            
            if self.context.sectionChangeSet.count == 0 && self.context.objectChangeSet.count == 0 {
                return
            }
            
            self.delegate?.controllerWillChangeContent(controller: self)
            
            self.processDeletedSections()
            self.processInsertedSections()
            self.processUpdatedSections()
            
            self.processDeletedObjects()
            self.processInsertedObjects()
            self.processUpdatedObjects()
            
            if self._sections.needsSort {
                self.sortSections()
            }
            
            // Hang on to the changes for each section to lookup sources for items
            // that were move to a new section
            var processedSections = [SectionInfo:ChangeSet<OrderedSet<Element>>]()
            
            for s in self._sections {
//                if s.needsSort {
//                    s.sortItems(using: self.fetchRequest.sortDescriptors ?? [])
//                }
                if s.isEditing {
                    
                    if s.isEmpty {
                        // If the section object matches the section predicat, keep it.
                        let req = self.sectionFetchRequest
                        if self.fetchSections,
                            let obj = s._object,
                             req.predicate == nil || req.predicate?.evaluate(with: obj) == true {
                            // Do  nothing
                        }
                        else {
                            self._remove(s._object)
                            continue;
                        }
                    }
                    let set = s.endEditing(forceUpdates: self.context.objectChangeSet.updated.valuesSet)
                    processedSections[s] = set
                }
            }
            
            if let oldSections = self._sectionsCopy {
                var sectionChanges = ChangeSet(source: oldSections, target: self._sections)
                sectionChanges.reduceEdits()
                for change in sectionChanges.edits {
                    switch change.operation {
                    case .insertion:
                        let ip = IndexPath.for(section: change.index)
                        self.delegate?.controller(self, didChangeSection: change.value, at: nil, for: .insert(ip))
                    case .deletion:
                        let ip = IndexPath.for(section: change.index)
                        self.delegate?.controller(self, didChangeSection: change.value, at: ip, for: .delete)
                    case .substitution:
                        let ip = IndexPath.for(section: change.index)
                        self.delegate?.controller(self, didChangeSection: change.value, at: ip, for: .update)
                    case let .move(origin):
                        let ip = IndexPath.for(section: origin)
                        self.delegate?.controller(self, didChangeSection: change.value, at: ip, for: .move(IndexPath.for(section: change.index)))
                    }
                }
            }
            
            
            func reduceCrossSectional(_ object: Element, targetEdit tEdit: Edit<Element>? = nil) -> Bool {
                
                guard self.context.itemsWithSectionChange.remove(object) != nil else {
                    return false
                }
                
                guard let source = self.context.objectChangeSet.updated.index(of: object),
                    let targetIP = self.indexPath(of: object),
                    let targetSection = self._sectionInfo(at: targetIP) else {
                        return true
                }
                
                guard let proposedEdit = tEdit ?? processedSections[targetSection]?.edit(for: object) else {
                    return true
                }
                
                let newEdit = Edit(.move(origin: source._item), value: object, index: targetIP._item)
                processedSections[targetSection]?.operationIndex.moves.insert(newEdit, for: targetIP._item)
                
                processedSections[targetSection]?.remove(edit: proposedEdit)
                
                
                if targetIP._item != proposedEdit.index {
                    // let _ = processedSections[targetSection]?.edit(withSource: targetIP._item)
                }
                else if case .substitution = proposedEdit.operation, let obj = self.context.objectChangeSet.object(for: targetIP) {
                    let insert = Edit(.deletion, value: obj, index: proposedEdit.index)
                    processedSections[targetSection]?.operationIndex.deletes.insert(insert, for: targetIP._item)
                }
                
                
                /*
                 // sourceSection will be nil if it was deleted (ObjectChangeSet can only lookup by index for inserted/updated)
                 //
                 // If so, complete the move and handle the old target operation
                 //
                 // Note: since the old section was removed, no operations will be processed for it
                 // there is no need then to handle updating/removing the source edit
                 */
                
                guard let sourceSection = self.context.sectionChangeSet.object(for: source._section),
                    let sourceInfo = self._sectionInfo(representing: sourceSection),
                    let sourceEdit = processedSections[sourceInfo]?.edit(withSource: source._item) else {
                        return true
                }
                processedSections[sourceInfo]?.operationIndex.deletes.remove(sourceEdit)
                if case .substitution = sourceEdit.operation {
                    if let ip = self.indexPath(of: sourceEdit.value) {
                        let insert = Edit(.insertion, value: sourceEdit.value, index: ip._item)
                        processedSections[sourceInfo]?.operationIndex.inserts.insert(insert, for: insert.index)
                    }
                    _ = reduceCrossSectional(sourceEdit.value, targetEdit: sourceEdit)
                }
                return true
            }
            
            while let obj = self.context.itemsWithSectionChange.first {
                _ = reduceCrossSectional(obj)
            }
            
            if self.emptySectionChanges == nil {
                self.emptySectionChanges = ResultsChangeSet()
            }
            for s in processedSections {
                var changes = s.value
                changes.reduceEdits()
                processedSections[s.key] = changes
                
                guard let sectionIndex = self.indexPath(of: s.key)?._section else { continue }
                
                
                let start = changes.origin.count
                let end = changes.destination.count
//                log.debug("SECTION: \(sectionIndex) START: \(start) END: \(end)")
                if start != end {
                    if start == 0 {
                        let ip = IndexPath.for(section: sectionIndex)
                        self.emptySectionChanges?.addChange(forItemAt: ip, with: .delete)
                    }
                    else if end == 0 {
                        let ip = IndexPath.for(section: sectionIndex)
                        self.emptySectionChanges?.addChange(forItemAt: nil, with: .insert(ip))
                    }
                }
                
                // Could merge all the edits together to dispatch the delegate calls in order of operation
                // but there is no apparent reason why order is important.
                
                for edit in changes.edits {
                    switch edit.operation {
                        
                    case .move(origin: _):
                        guard let source = self.context.objectChangeSet.updated.index(of: edit.value),
                            let dest = self.indexPath(of: edit.value) else {
                                continue // I don't think this should happen
                        }
                        
                        self.delegate?.controller(self, didChangeObject: edit.value, at: source, for: .move(dest))
                        
                    case .substitution:
                        let ip = IndexPath.for(item: edit.index, section: sectionIndex)
                        self.delegate?.controller(self, didChangeObject: edit.value, at: ip, for: .update)
                        
                    case .insertion:
                        guard let ip = self.indexPath(of: edit.value) else {
                            continue
                        }
                        self.delegate?.controller(self, didChangeObject: edit.value, at: nil, for: .insert(ip))
                        
                    case .deletion:
                        let source = IndexPath.for(item: edit.index, section: sectionIndex)
                        self.delegate?.controller(self, didChangeObject: edit.value, at: source, for: .delete)
                    }
                }
            }
            
            
            self.delegate?.controllerDidChangeContent(controller: self)
            self.emptySectionChanges = nil
            self._sectionsCopy = nil
        }
 */
        
    }

}

