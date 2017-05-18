//
//  RelationalResultsController.swift
//  CollectionView
//
//  Created by Wesley Byrne on 1/12/17.
//  Copyright © 2017 Noun Project. All rights reserved.
//

import Foundation


//extension OrderedSet where Element



fileprivate class UpdateContext<Section: NSManagedObject, Element:NSManagedObject> : CustomStringConvertible {
    
    typealias SectionInfo = RelationalSectionInfo<Section, Element>

    // Changes from context
    var objectChangeSet = ObjectChangeSet<IndexPath, Element>()
    var sectionChangeSet = ObjectChangeSet<Int, Section>()
    
    var itemsWithSectionChange = Set<Element>()
    
    func reset() {
        self.sectionChangeSet.reset()
        self.objectChangeSet.reset()
    }
    
    var description: String {
        return "Context Items: \(objectChangeSet.deleted.count) Deleted, \(objectChangeSet.inserted.count) Inserted, \(objectChangeSet.updated.count) Updated"
        + "Context Sections: \(sectionChangeSet.inserted.count) Inserted, \(sectionChangeSet.deleted.count) Deleted \(sectionChangeSet.updated.count) Updated"
    }
}


fileprivate class RelationalSectionInfo<Section: NSManagedObject, Element: NSManagedObject>: NSObject, ResultsControllerSectionInfo {
    
    public var object : Any? { return self._object }
    public var objects: [Any] { return _storage.objects  }
    public var numberOfObjects: Int { return _storage.count }
    
    private unowned let controller : RelationalResultsController<Section,Element>
    
    fileprivate let _object : Section?
    
    private(set) var isEditing: Bool = false
    
    private(set) var _storage = OrderedSet<Element>()
    private var _storageCopy = OrderedSet<Element>()
    
    override public var hashValue: Int {
        return _object?.hashValue ?? 0
    }
    
    fileprivate override func isEqual(_ object: Any?) -> Bool {
        return self._object == (object as? RelationalSectionInfo<Section, Element>)?._object
    }
    
    public static func ==(lhs: RelationalSectionInfo, rhs: RelationalSectionInfo) -> Bool {
        return lhs._object == rhs._object
    }
    
    internal init(controller: RelationalResultsController<Section,Element>, object: Section?, objects: [Element] = []) {
        self.controller = controller
        self._object = object
        _storage.add(contentsOf: objects)
    }
    
    func index(of object: Element) -> Int? {
        return _storage.index(of: object)
    }
    
    func appendOrdered(_ object: Element) -> Int {
        self._storage.add(object)
        return self._storage.count - 1
    }
    
    func remove(_ object: Element) -> Int? {
        return _storage.remove(object)
    }
    
    func sortItems(using sortDescriptors: [NSSortDescriptor]) {
        
        if self.isEditing {
            Swift.print("Attempt to call sort items on relations section info while editing.")
            return;
        }
        
//        self.needsSort = false
        self._storage.sort(using: sortDescriptors)
    }
    
    
    func description(with descriptors: [NSSortDescriptor]) -> String {
        var str = "\(_storage.count) Objects"
        
        if descriptors.count > 0 {
            var sortValues = [String]()
            for o in _storage {
                sortValues.append(o.description)
//                sortValues.append(descriptors.description(of: o))
            }
            str += "[\n"
            str += sortValues.joined(separator: "\n")
            str += "]"
        }
        else {
            str += "No sort"
        }
        return str
    }
    override var description: String {
        return description(with: [])
    }
    
    // MARK: - Editing
    /*-------------------------------------------------------------------------------*/
    
//    private(set) var needsSort : Bool = false
    private var _added = Set<Element>() // Tracks added items needing sort, if one do insert for performance
    
    var isEmpty : Bool {
        return self.numberOfObjects == 0 && _added.count == 0
    }
    
    func beginEditing() {
        assert(!isEditing, "Mutiple calls to beginEditing() for RelationalResultsControllerSection")
        isEditing = true
        _storageCopy = _storage
        _added.removeAll()
    }
    
    func ensureEditing() {
        if isEditing { return }
        beginEditing()
    }
    
    func endEditing(forceUpdates: Set<Element>) -> ChangeSet<OrderedSet<Element>> {
        assert(isEditing, "endEditing() called before beginEditing() for RelationalResultsControllerSection")
        
        if self._added.count > 0, let desc = controller.fetchRequest.sortDescriptors {
            let ordered = self._added.sorted(using: desc)
            _storage.insert(contentsOf: ordered, using: desc)
        }
        
        isEditing = false
//        self.needsSort = false
        let changes = ChangeSet(source: _storageCopy, target: _storage, forceUpdates: forceUpdates)
        self._storageCopy.removeAll()
        return changes
    }
    
    func _modified(_ element: Element) {
        assert(self.isEditing, "Attempt to call modified object while NOT editing")
        self._added.insert(element)
    }
    
    func _add(_ element: Element) {
        assert(self.isEditing, "Attempt to call modified object while NOT editing")
//        guard self._storage.contains(element) == false else {
//            return
//        }
//        self.needsSort = self._storage.count > 0
//        _added.insert(element)
//        self._storage.add(element)
        self._added.insert(element)
    }
}


/**
 A ResultsController that manages item and section CoreData objects independently.
*/
public class RelationalResultsController<Section: NSManagedObject, Element: NSManagedObject> : NSObject, ResultsController {
    
    fileprivate typealias SectionInfo = RelationalSectionInfo<Section, Element>
    
    // MARK: - Results Controller Protocol
    /*-------------------------------------------------------------------------------*/
    public var allObjects: [Any] {
        var objects = [Element]()
        for section in _sections {
            objects.append(contentsOf: section._storage)
        }
        return objects
    }
    
    
    /**
     An array of all sections
     
     - Note: accessing the sections here incurs fairly large overhead, avoid if possible. Use `numberOfSections` and sectionInfo(forSectionAt:) when possible.
    */
    public var sections: [ResultsControllerSectionInfo] { return _sections.objects }
    
    
    /**
     A fetch request used to fetch, filter, and sort the section results of the controller.
     
     This is used to validate the section objects. If `fetchSections` is true, section objects will be fetched independent of the child objects.
     
     A parent object that does not match the request here, may still be visible if it has children that match the predicate of fetchRequest.
    */
    public let sectionFetchRequest : NSFetchRequest<Section>
    
    
    /**
     A fetch request used to fetch, filter, and sort the results of the controller.
    */
    public let fetchRequest : NSFetchRequest<Element>
    
    
    /**
     If true, sections will be fetched independent of objects using sectionFetchRequest.
     
     This is useful to populate the controller with section objects that may not have any children.
    */
    public var fetchSections : Bool = true
    
    
    /**
     If the controller should assume that sections with zero objects have a placholder.
     
     # Discussion
     When displaying sections within a CollectionView, it can be helpful to fill empty sections with a placholder cell. This causes an issue when responding to updates from a results controller. For example, when an object is inserted into an empty section, the results controller will report a single insert change. The CollectionView though would need to remove the exisitng cell AND insert the new one. 
     
     Setting hasEmptySectionPlaceholders to true, will report changes as such, making it easy to propagate the reported changes to a CollectionView.
    */
    public var hasEmptySectionPlaceholders : Bool = false
    
    
    private var _fetched: Bool = false
    private func setNeedsFetch() {
        if _fetched {
            _fetched = false
            unregister()
        }
    }
    
    
    /**
     A keyPath of the section objects to get the displayable name
     
     For custom names, leave nil and conform your section objects to CustomDisplayStringConvertible
    */
    public var sectionNameKeyPath : String?
    
    
    /**
     The keyPath of the controllers objects which holds a to-one relationship to the section object
    */
    public var sectionKeyPath: String = "" { didSet { setNeedsFetch() }}
    
    
    /**
     The managed object context to fetch from and observe for changes
    */
    public private(set) var managedObjectContext: NSManagedObjectContext
    
    private var _objectSectionMap = [Element:SectionInfo]() // Map between elements and the last group it was known to be in
    
//    internal var _fetchedObjects = OrderedSet<Element>()
    private var _sections = OrderedSet<SectionInfo>()
    
    
    /**
     An object the report to when content in the controller changes
    */
    public weak var delegate: ResultsControllerDelegate? {
        didSet {
            if (oldValue == nil) == (delegate == nil) { return }
            if delegate == nil { unregister() }
            else if _fetched { register() }
        }
    }
    
    deinit {
        self._sections.removeAll()
        self._objectSectionMap.removeAll()
        self.fetchRequest.predicate = nil
        if _fetched {
            unregister()
        }
    }
    
    
    public init(context: NSManagedObjectContext, request: NSFetchRequest<Element>, sectionRequest: NSFetchRequest<Section>, sectionKeyPath keyPath: String) {
        
        self.managedObjectContext = context
        self.fetchRequest = request
        self.sectionFetchRequest = sectionRequest
        
        request.returnsObjectsAsFaults = false
        sectionRequest.returnsObjectsAsFaults = false
        
        super.init()
        
        validateRequests()
        
        self.sectionKeyPath = keyPath
    }
    
    private func validateRequests() {
        assert(fetchRequest.entityName != nil, "request is missing entity name")
        assert(sectionFetchRequest.entityName != nil, "sectionRequest is missing entity name")
        
        let objectEntity = NSEntityDescription.entity(forEntityName: fetchRequest.entityName!, in: self.managedObjectContext)
        let sectionEntity = NSEntityDescription.entity(forEntityName: sectionFetchRequest.entityName!, in: self.managedObjectContext)
        
        assert(objectEntity != nil, "Unable to load entity description for object \(fetchRequest.entityName!)")
        assert(sectionEntity != nil, "Unable to load entity description for section \(sectionFetchRequest.entityName!)")
        
        fetchRequest.entity = objectEntity
        sectionFetchRequest.entity = sectionEntity
    }
    
    
    
    // MARK: - Counts & Section Names
    /*-------------------------------------------------------------------------------*/
    
    
    /**
     The number of sections in the controller
    */
    public var numberOfSections : Int {
        return _sections.count
    }
    
    
    /**
     The number of objects in a specified section

     - Parameter section: The section to count objects in
     
     - Returns: The number of objects in the specified section

    */
    public func numberOfObjects(in section: Int) -> Int {
        return self._sections[section].numberOfObjects
    }
    
    public func sectionName(forSectionAt indexPath: IndexPath) -> String {
        guard let obj = _sectionInfo(at: indexPath)?._object else {
            return "Ungrouped"
        }
        if let key = self.sectionNameKeyPath,
            let val = obj.value(forKeyPath: key) as? CustomDisplayStringConvertible {
            return val.displayDescription
        }
        return (obj as? CustomDisplayStringConvertible)?.displayDescription ?? ""
    }
    
    
    
    // MARK: - Public Item Accessors
    /*-------------------------------------------------------------------------------*/
    public func sectionInfo(forSectionAt sectionIndexPath: IndexPath) -> ResultsControllerSectionInfo? {
        return self._sectionInfo(at: sectionIndexPath)
    }
    
    public final func object(forSectionAt sectionIndexPath: IndexPath) -> Any? {
        return self._object(forSectionAt: sectionIndexPath)
    }
    public final func object(at indexPath: IndexPath) -> Any? {
        return self._object(at: indexPath)
    }
    
    
    // MARK: - Getting IndexPaths
    /*-------------------------------------------------------------------------------*/
    public func indexPath(of object: Element) -> IndexPath? {
        guard let section = self._objectSectionMap[object],
            let sIdx = self._sections.index(of: section),
            let idx = section.index(of: object) else { return nil }
        
        return IndexPath.for(item: idx, section: sIdx)
    }
    
    public func indexPath(of sectionInfo: ResultsControllerSectionInfo) -> IndexPath? {
        guard let info = sectionInfo as? SectionInfo else { return nil }
        if let idx = _sections.index(of: info) {
            return IndexPath.for(section: idx)
        }
        return nil
    }
    public func indexPathOfSection(representing sectionObject: Section?) -> IndexPath? {
        let _wrap = SectionInfo(controller: self, object: sectionObject)
        if let idx = _sections.index(of: _wrap) {
            return IndexPath.for(section: idx)
        }
        return nil
    }
    
    
    // MARK: - Private Accessors
    /*-------------------------------------------------------------------------------*/
    private func _sectionInfo(at sectionIndexPath: IndexPath) -> SectionInfo? {
        return self._sections._object(at: sectionIndexPath._section)
    }
    private func _sectionInfo(at sectionIndex: Int) -> SectionInfo? {
        return self._sections._object(at: sectionIndex)
    }
    private func _sectionInfo(representing section: Section?) -> SectionInfo? {
        guard let ip = self.indexPathOfSection(representing: section) else { return nil }
        return self._sectionInfo(at: ip)
    }
    
    public func _object(forSectionAt sectionIndexPath: IndexPath) -> Section? {
        return self._sectionInfo(at: sectionIndexPath)?._object
    }
    
    public func _object(at indexPath: IndexPath) -> Element? {
        return self._sectionInfo(at: indexPath)?._storage._object(at: indexPath._item)
    }
    
    
    
    // MARK: - Helpers
    /*-------------------------------------------------------------------------------*/
    
    private func contains(sectionObject: Section) -> Bool {
        let _wrap = SectionInfo(controller: self, object: sectionObject)
        return _sections.contains(_wrap)
    }
    
    private func contains(object: Element) -> Bool {
        return indexPath(of: object) != nil
    }
    
    
    // MARK: - Logging
    /*-------------------------------------------------------------------------------*/
    private func printSectionOrderKeys() {
        var str = "Section Ordering Keys:\n"
        if let s = self.sectionFetchRequest.sortDescriptors {
            s.forEachKey(describing: _sections, do: { (k, o) in
                str += "\(k): \(o._object?.value(forKey: k) ?? "-- Ungrouped")  "
            })
        }
        else {
            print("No section sort descriptors")
        }
        print(str)
    }
    
    private func logSections() {
        print("\(_sections.count) Sections")
        for (idx, res) in _sections.enumerated() {
            let str = "\(idx) - \(res.description(with: fetchRequest.sortDescriptors ?? []))"
            print(str)
        }
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
    
    
    // MARK: - Perform Fetch
    /*-------------------------------------------------------------------------------*/
    
    public func setManagedObjectContext(_ moc: NSManagedObjectContext) throws {
        guard moc != self.managedObjectContext else { return }
        self.setNeedsFetch()
        self.managedObjectContext = moc
        
        validateRequests()
        
        try self.performFetch()
    }
    
    public func performFetch() throws {
        
        guard self.fetchRequest.entityName != nil else {
            assertionFailure("fetch request must have an entity when performing fetch")
            throw ResultsControllerError.unknown
        }
        guard self.sectionFetchRequest.entityName != nil else {
            assertionFailure("fetch request must have an entity when performing fetch")
            throw ResultsControllerError.unknown
        }
        
        let _objects = try managedObjectContext.fetch(fetchRequest)
        
        // Manage notification registration
        if !_fetched && delegate != nil {
            register()
        }
        _fetched = true
        
        self._sections.removeAll()
        
        // Add the queried sections
        if self.fetchSections {
            for s in try managedObjectContext.fetch(self.sectionFetchRequest) {
                _ = self._insert(section: s)
            }
        }
        
        // Add the object into sections
        // No need to sort since they were just fetched with the sort descriptors
        for object in _objects {
            let parent = object.value(forKey: sectionKeyPath) as? Section
            let p = self._insert(section: parent)
            _ = p.appendOrdered(object)
            _objectSectionMap[object] = p
        }
                                                        
        // Sort the sections all at once
        self.sortSections()
    }
    
    

    
    
    
    // MARK: - Storage Manipulation
    /*-------------------------------------------------------------------------------*/
    private func _ensureSectionCopy() {
        if _sectionsCopy == nil { _sectionsCopy = _sections }
    }
    
    fileprivate func _insert(section: Section?) -> SectionInfo {
        if let s = self._sectionInfo(representing: section) { return s }
        _ensureSectionCopy()
        let s = SectionInfo(controller: self, object: section, objects: [])
        _sections.add(s)
        return s
    }
    
    private func _remove(_ section: Section?, ip: IndexPath? = nil) {
        guard let ip = ip ?? self.indexPathOfSection(representing: section) else { return }
        _ensureSectionCopy()
        _sections.remove(at: ip._section)
    }
    
    private func sortSections() {
        if _sectionsCopy == nil { _sectionsCopy = _sections }
        self._sections.needsSort = false
        guard let sort = sectionFetchRequest.sortDescriptors, sort.count > 0 else {
            return
        }
        let s = self._sections.sorted(by: { (s1, s2) -> Bool in
            if let o1 = s1._object,
                let o2 = s2._object {
                return sort.compare(o1, to: o2) == .orderedAscending
            }
            return s1.object != nil
        })
        self._sections = OrderedSet(elements: s)
    }
    
    
    
    
    
    // MARK: - Handling Changes
    /*-------------------------------------------------------------------------------*/
    
    fileprivate var context = UpdateContext<Section, Element>()
    fileprivate var _sectionsCopy : OrderedSet<SectionInfo>?
    
    public private(set) var emptySectionChanges : ResultsChangeSet?
    
    public var pendingChangeCount : Int {
        return pendingItemChangeCount + pendingSectionChangeCount
    }
    public var pendingItemChangeCount : Int {
        return context.objectChangeSet.count
    }
    public var pendingSectionChangeCount : Int {
        return context.sectionChangeSet.count
    }
    
    
    func handleChangeNotification(_ notification: Notification) {
        
        guard let delegate = self.delegate, self._fetched else {
            print("Ignoring context notification because results controller doesn't have a delegate or has not been fetched yet")
            return
        }
        
        managedObjectContext.perform { [unowned self] in
            
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
                processedSections[targetSection]?.operationIndex.moves.insert(newEdit, with: targetIP._item)
                
                processedSections[targetSection]?.remove(edit: proposedEdit)
                
                
                if targetIP._item != proposedEdit.index {
                    // let _ = processedSections[targetSection]?.edit(withSource: targetIP._item)
                }
                else if case .substitution = proposedEdit.operation, let obj = self.context.objectChangeSet.object(for: targetIP) {
                    let insert = Edit(.deletion, value: obj, index: proposedEdit.index)
                    processedSections[targetSection]?.operationIndex.deletes.insert(insert, with: targetIP._item)
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
                        processedSections[sourceInfo]?.operationIndex.inserts.insert(insert, with: insert.index)
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
                            //                    let sectionIndex = self._sections.index(for: s.key),
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
        
    }
    
    
    
    private func preprocess(notification: Notification) {
        
        var sections = ObjectChangeSet<Int, Section>()
        var objects = ObjectChangeSet<IndexPath, Element>()
        
        guard let changes = notification.userInfo?[ResultsControllerCDManager.Dispatch.changeSetKey] as? [NSEntityDescription:ResultsControllerCDManager.EntityChangeSet] else {
            return
        }
        
        if let sectionChanges = changes[sectionFetchRequest.entity!] {
            for obj in sectionChanges.deleted {
                guard let o = obj as? Section, let index = self.indexPathOfSection(representing: o)?._section else { continue }
                sections.add(deleted: o, for: index)
            }
            
            
            for obj in sectionChanges.inserted {
                if let o = obj as? Section {
                    if sectionFetchRequest.predicate == nil || sectionFetchRequest.predicate?.evaluate(with: o) == true {
                        sections.add(inserted: o)
                    }
                }
            }
            
            for obj in sectionChanges.updated {
                if let o = obj as? Section {
                    let _ip = self.indexPathOfSection(representing: o)
                    if fetchSections {
                        let match = sectionFetchRequest.predicate == nil || sectionFetchRequest.predicate?.evaluate(with: o) == true
                        
                        if let ip = _ip {
                            if !match { sections.add(deleted: o, for: ip._section) }
                            else { sections.add(updated: o, for: ip._section) }
                        }
                        else if match {
                            sections.add(inserted: o)
                        }
                    }
                    else if let ip = _ip {
                        sections.add(updated: o, for: ip._section)
                    }
                }
            }
        }
        
        if let itemChanges = changes[fetchRequest.entity!] {
            for obj in itemChanges.deleted {
                guard let o = obj as? Element, let ip = self.indexPath(of: o) else { continue }
                objects.add(deleted: o, for: ip)
            }
            
            
            for obj in itemChanges.inserted {
                if let o = obj as? Element {
                    if fetchRequest.predicate == nil || fetchRequest.predicate?.evaluate(with: o) == true {
                        objects.add(inserted: o)
                    }
                }
            }
            
            for obj in itemChanges.updated {
                if let o = obj as? Element {
                    
                    let _ip = self.indexPath(of: o)
                    let match = fetchRequest.predicate == nil || fetchRequest.predicate?.evaluate(with: o) == true
                    
                    if let ip = _ip, sections.deleted.containsValue(for: ip._section) == false {
                        if !match { objects.add(deleted: o, for: ip) }
                        else { objects.add(updated: o, for: ip) }
                    }
                    else if match {
                        objects.add(inserted: o)
                    }
                }
            }
        }
        self.context.objectChangeSet = objects
        self.context.sectionChangeSet = sections
        
    }
    
    
    
    // MARK: - Section Processing
    /*-------------------------------------------------------------------------------*/
    
    
    
    private func processDeletedSections() {
        for change in context.sectionChangeSet.deleted {
            
            let object = change.value
            guard let ip = self.indexPathOfSection(representing: object) else { continue }
            
            let section = self._sections[ip._section]
            for obj in section._storage {
                _objectSectionMap[obj] = nil
            }
            self._remove(object, ip: ip)
        }
    }
    
    private func processInsertedSections() {
        for object in context.sectionChangeSet.inserted {
            _ = self._insert(section: object)
        }
    }
  
    private func processUpdatedSections() {
        if context.sectionChangeSet.updated.count > 0 {
            _sections.needsSort = true
        }
    }
    
    private func postProcesssSections() {
        if _sections.needsSort {
            _sections.sort(using: sectionFetchRequest.sortDescriptors ?? [])
        }
        
        // Need to do a changeSet on the sections and create section moves
        // Maybe just use sectionChangeSet and create from there
    }
    
    
    
    // MARK: - Object Processing
    /*-------------------------------------------------------------------------------*/
    
    func processDeletedObjects() {
        
        for change in context.objectChangeSet.deleted {
            
            let object = change.value
            defer {
                _objectSectionMap[object] = nil
            }
            
            let oldIP = change.index
            
            // If the section was deleted, ignore the items
            guard self.context.sectionChangeSet.deleted.containsValue(for: oldIP._section) == false else {
                continue
            }
            
            let section = self._sections[oldIP._section]
            section.ensureEditing()
            _ = section.remove(object)
            
//            if section.numberOfObjects == 0 {
//                // If the section object matches the section predicat, keep it.
//                let req = self.sectionFetchRequest
//                if self.fetchSections,
//                    let obj = section._object {
//                    if req.predicate == nil || req.predicate?.evaluate(with: obj) == true { continue }
//                }
//                _remove(section._object)
//            }
        }
    }
    
    func processInsertedObjects() {
        
        for object in context.objectChangeSet.inserted {
            
            guard self.contains(object: object) == false else { continue }
            let sectionValue = object.value(forKeyPath: self.sectionKeyPath) as? Section
            
            if let existingIP = self.indexPathOfSection(representing: sectionValue),
                let existingSection = self._sectionInfo(at: existingIP) {
                existingSection.ensureEditing()
                existingSection._add(object)
                _objectSectionMap[object] = existingSection
                
                // Should items in inserted sections be included?
            }
            else {
                let sec = self._insert(section: sectionValue)
                sec.ensureEditing()
                sec._add(object)
                _objectSectionMap[object] = sec
            }
        }
    }
    
    
    func processUpdatedObjects() {
        
        for change in context.objectChangeSet.updated {
            
            let object = change.value
            
            guard let tempIP = self.indexPath(of: object),
                let currentSection = _sectionInfo(at: tempIP) else {
                    print("Skipping object update")
                    continue
            }
            currentSection.ensureEditing()
            
            let sectionValue = object.value(forKeyPath: sectionKeyPath) as? Section
            
            // Move within the same section
            if sectionValue == currentSection._object {
                currentSection.ensureEditing()
                currentSection._modified(object)
                _objectSectionMap[object] = currentSection
            }
                
                // Moved to another section
            else if let newSip = self.indexPathOfSection(representing: sectionValue),
                let newSection = self._sectionInfo(at: newSip) {
                _ = currentSection.remove(object)
                newSection.ensureEditing()
                newSection._add(object)
                self.context.itemsWithSectionChange.insert(object)
                _objectSectionMap[object] = newSection
            }
                
                // Move to new section
            else {
                // The section value doesn't exist yet, the section will be inserted
                let sec = self._insert(section: sectionValue)
                sec.ensureEditing()
                sec._add(object)
                _objectSectionMap[object] = sec
            }
            
        }
    }
    

}

