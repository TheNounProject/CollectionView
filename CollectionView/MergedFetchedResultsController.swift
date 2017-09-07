//
//  FetchedResultsController.swift
//  CollectionView
//
//  Created by Wes Byrne on 1/16/17.
//  Copyright © 2017 Noun Project. All rights reserved.
//

import Foundation




fileprivate struct ChangeContext<Element:NSManagedObject> : CustomStringConvertible {
    
    var objectChanges = ObjectChangeSet<IndexPath, Element>()
    var itemsWithSectionChange = Set<Element>()
    
    mutating func reset() {
        self.objectChanges.reset()
    }
    
    var description: String {
        return "Context Items: \(objectChanges.deleted.count) Deleted, \(objectChanges.inserted.count) Inserted, \(objectChanges.updated.count) Updated"
    }
}





fileprivate class FetchedSectionInfo<ValueType: SectionRepresentable, Element: NSManagedObject>: NSObject, Comparable, ResultsControllerSectionInfo {
    
    public var object : Any? { return self._value }
    public var objects: [Any] { return _storage.objects }
    
    public var numberOfObjects : Int { return _storage.count }
    
    private(set) var _value : ValueType?
    fileprivate(set) var _storage = OrderedSet<Element>()
    private(set) var _storageCopy = OrderedSet<Element>()
    
    private unowned var controller : MergedFetchedResultsController<ValueType, Element>
    
    internal init(controller: MergedFetchedResultsController<ValueType, Element>, value: ValueType?, objects: [Element] = []) {
        self.controller = controller
        self._value = value
        _storage.add(contentsOf: objects)
    }
    
    
    // MARK: - Equatable
    /*-------------------------------------------------------------------------------*/
    override public var hashValue: Int {
        return _value?.hashValue ?? 0
    }
    fileprivate override func isEqual(_ object: Any?) -> Bool {
        return self._value == (object as? FetchedSectionInfo<ValueType, Element>)?._value
    }
    public static func ==(lhs: FetchedSectionInfo, rhs: FetchedSectionInfo) -> Bool {
        return lhs._value == rhs._value
    }
    static func <(lhs: FetchedSectionInfo, rhs: FetchedSectionInfo) -> Bool {
        if let v1 = lhs._value,
            let v2 = rhs._value {
            return v1 < v2
        }
        return lhs._value != nil
    }
    
    
    // MARK: - Objects
    /*-------------------------------------------------------------------------------*/
    
    func index(of object: Element) -> Int? {
        return _storage.index(of: object)
    }
    
    @discardableResult func appendOrdered(_ object: Element) -> Int {
        self._storage.add(object)
        return self._storage.count - 1
    }
    @discardableResult func remove(_ object: Element) -> Int? {
        return _storage.remove(object)
    }
    
//    func sortItems(using sortDescriptors: [NSSortDescriptor]) {
//        self.needsSort = false
//        self._storage.sort(using: sortDescriptors)
//    }
    
    
    // MARK: - Editing
    /*-------------------------------------------------------------------------------*/
    
    private(set) var isEditing: Bool = false
    private var _added = Set<Element>() // Tracks added items needing sort, if one do insert for performance
    
    func beginEditing() {
        assert(!isEditing, "Mutiple calls to beginEditing() for RelationalResultsControllerSection")
        isEditing = true
        _storageCopy = _storage
//        _added.removeAll()
    }
    
    func ensureEditing() {
        if isEditing { return }
        beginEditing()
    }
    
    func endEditing(forceUpdates: Set<Element>) -> ChangeSet<OrderedSet<Element>> {
        assert(isEditing, "endEditing() called before beginEditing() for RelationalResultsControllerSection")
        
        if self._added.count > 0 {
            let ordered = self._added.sorted(using: controller.sortDescriptors)
            _storage.insert(contentsOf: ordered, using: controller.sortDescriptors)
        }
        
        isEditing = false
        let changes = ChangeSet(source: _storageCopy, target: _storage, forceUpdates: forceUpdates)
        self._storageCopy.removeAll()
        return changes
    }
    
    func _modified(_ element: Element) {
        assert(self.isEditing, "Attempt to call modified object while NOT editing")
        self._added.insert(element)
    }
    
    func add(_ element: Element) {
        assert(self.isEditing, "Attempt tot call add while not editing")
        self._added.insert(element)
    }

    
}



/**
 An item based results controller that merges NSManagedObjects that have shared properties.
 
 A fetch request is supplied for each entity type but they are sorted and managed as the same type. Each entity included must share properties used for sorting.
*/
public class MergedFetchedResultsController<Section: SectionRepresentable, Element: NSManagedObject> : NSObject, ResultsController {
    
    
    fileprivate typealias SectionInfo = FetchedSectionInfo<Section, Element>

    
    
    
    // MARK: - Initialization
    /*-------------------------------------------------------------------------------*/
    
    public init(context: NSManagedObjectContext, sortDescriptors: [NSSortDescriptor] = [], sectionKeyPath: String? = nil) {
        
        self.managedObjectContext = context
        self.sectionKeyPath = sectionKeyPath
        self.sortDescriptors = sortDescriptors
    }
    
    
    
    private var _fetched: Bool = false
    
    
    /**
     Performs the provided fetch request to populate the controller. Calling again resets the controller.
     
     - Throws: If the fetch request is invalid or the fetch fails
     */
    public func performFetch() throws {
        
        self._sections.removeAll()
        self.fetchedObjects.removeAll()
        
        if !_fetched && delegate != nil {
            register()
        }
        _fetched = true
        
        var additional = [Section:[Element]]()
        var orphaned = [Element]()
        
        for request in fetchRequests {
            
            guard request.entityName != nil else {
                assertionFailure("fetch request must have an entity when performing fetch")
                throw ResultsControllerError.unknown
            }
            request.sortDescriptors = sortDescriptors
            let _objects = try managedObjectContext.fetch(request)
            
            if _objects.count == 0 { continue }
            
            func _insert(section: Section?, objects: [Element]) -> SectionInfo {
                if let s = self._sectionInfo(representing: section) {
                    
                    if let _sec = section {
                        if additional[_sec] == nil { additional[_sec] = objects }
                        else { additional[_sec]?.append(contentsOf: objects) }
                    }
                    else {
                        orphaned.append(contentsOf: objects)
                    }
                    return s
                }
                let s = SectionInfo(controller: self, value: section, objects: objects)
                _sections.add(s)
                return s
            }
            
            self.fetchedObjects.formUnion(_objects)
            if let keyPath = self.sectionKeyPath {
                for object in _objects {
                    let parentValue = object.value(forKey: keyPath) as? Section
                    _objectSectionMap[object] = _insert(section: parentValue, objects: [object])
                }
            }
            else {
                _ = _insert(section: nil, objects: _objects)
            }
        }
        
        if _sections.count > 0 {
            self.sortSections()
        }
        for add in additional {
            _sectionInfo(representing: add.key)?._storage.insert(contentsOf: add.value, using: self.sortDescriptors)
        }
        _sectionInfo(representing: nil)?._storage.insert(contentsOf: orphaned, using: self.sortDescriptors)
    }
    
    
    /// Clears all data and stops monitoring for changes in the context.
    public func reset() {
        self.unregister()
        self._fetched = false
        self._sections.removeAll()
        self._objectSectionMap.removeAll()
        self._fetchedObjects.removeAll()
        self.fetchedObjects.removeAll()
    }
    
    
    public func addRequest(_ request: NSFetchRequest<Element>) {
        assert(request.entityName != nil, "request is missing entity name")
        let objectEntity = NSEntityDescription.entity(forEntityName: request.entityName!, in: self.managedObjectContext)
        assert(objectEntity != nil, "Unable to load entity description for object \(request.entityName!)")
        request.entity = objectEntity
        request.returnsObjectsAsFaults = false
        fetchRequests.append(request)
    }
    
    
    // MARK: - Configuration
    /*-------------------------------------------------------------------------------*/
    
    public let managedObjectContext: NSManagedObjectContext
    
    public var fetchRequests = [NSFetchRequest<Element>]()
    public var sortDescriptors = [NSSortDescriptor]()
    public var sectionKeyPath: String?
    
    
    public weak var delegate: ResultsControllerDelegate? {
        didSet {
            if (oldValue == nil) == (delegate == nil) { return }
            if delegate == nil { unregister() }
            else if _fetched { register() }
        }
    }
    
    
    
    // MARK: - Controller Contents
    /*-------------------------------------------------------------------------------*/
    
    private var fetchedObjects = Set<Element>()
    
    private var _objectSectionMap = [Element:SectionInfo]() // Map between elements and the last group it was known to be in
    
    private var _fetchedObjects = [Element]()
    private var _sections = OrderedSet<SectionInfo>()

    
    
    public var numberOfSections : Int {
        return _sections.count
    }
    
    public func numberOfObjects(in section: Int) -> Int {
        return self._sections[section].numberOfObjects
    }
    
    public func sectionName(forSectionAt indexPath: IndexPath) -> String {
        return _sectionInfo(at: indexPath)?._value?.displayDescription ?? ""
    }
    
    
    public var allObjects: [Any] { return Array(fetchedObjects) }
    
    public var sections: [ResultsControllerSectionInfo] { return _sections.objects }
    
    
    // MARK: - Querying Sections & Objects
    /*-------------------------------------------------------------------------------*/
    public func sectionInfo(forSectionAt sectionIndexPath: IndexPath) -> ResultsControllerSectionInfo? {
        return self._sectionInfo(at: sectionIndexPath)
    }
    
    public func object(forSectionAt sectionIndexPath: IndexPath) -> Any? {
        return self._object(forSectionAt: sectionIndexPath)
    }
    
    public func object(at indexPath: IndexPath) -> Any? {
        return self._object(at: indexPath)
    }
    

    
    // MARK: - Typed Getters
    /*-------------------------------------------------------------------------------*/
    
    public func _object(forSectionAt sectionIndexPath: IndexPath) -> Section? {
        return self._sectionInfo(at: sectionIndexPath)?._value
    }
    
    public func _object(at indexPath: IndexPath) -> Element? {
        return self._sectionInfo(at: indexPath)?._storage.object(at: indexPath._item)
    }
    
    public func _indexPathOfSection(representing sectionObject: Section?) -> IndexPath? {
        let _wrap = SectionInfo(controller: self, value: sectionObject)
        if let idx = _sections.index(of: _wrap) {
            return IndexPath.for(section: idx)
        }
        return nil
    }
    
    

    
    // MARK: - Getting IndexPaths
    /*-------------------------------------------------------------------------------*/
    
    public func indexPath(of sectionInfo: ResultsControllerSectionInfo) -> IndexPath? {
        guard let info = sectionInfo as? SectionInfo else { return nil }
        if let idx = _sections.index(of: info) {
            return IndexPath.for(section: idx)
        }
        return nil
    }
    
    public func indexPath(of object: Element) -> IndexPath? {
        
        if self.sectionKeyPath != nil {
            guard let section = self._objectSectionMap[object],
                let sIndex = self._sections.index(of: section),
                let idx = section.index(of: object) else { return nil }
            return IndexPath.for(item: idx, section: sIndex)
        }
        else if let idx = _sections.first?.index(of: object) {
            return IndexPath.for(item: idx, section: 0)
        }
        return nil
    }
    
    public func indexPathOfSection(representing sectionValue: Section?) -> IndexPath? {
        let _wrap = SectionInfo(controller: self, value: sectionValue)
        if let idx =  _sections.index(of: _wrap) {
            return IndexPath.for(section: idx)
        }
        return nil
    }
    
    
    
    
    // MARK: - Helpers
    /*-------------------------------------------------------------------------------*/
    private func contains(object: Element) -> Bool {
        return _fetchedObjects.contains(object)
    }
    
    private func _sectionInfo(at sectionIndexPath: IndexPath) -> SectionInfo? {
        return self._sectionInfo(at: sectionIndexPath._section)
    }
    
    private func _sectionInfo(at sectionIndex: Int) -> SectionInfo? {
        guard sectionIndex < self.numberOfSections else { return nil }
        return self._sections.object(at: sectionIndex)
    }
    
    private func _sectionInfo(representing section: Section?) -> SectionInfo? {
        guard let ip = self._indexPathOfSection(representing: section) else { return nil }
        return self._sectionInfo(at: ip)
    }

    
    
    // MARK: - Storage Manipulation
    /*-------------------------------------------------------------------------------*/
    
    private  func _insert(section: Section?) -> SectionInfo {
        if let s = self._sectionInfo(representing: section) { return s }
        if _sectionsCopy == nil { _sectionsCopy = _sections }
        let s = SectionInfo(controller: self, value: section, objects: [])
        _sections.add(s)
        return s
    }
    
    private func _remove(_ section: Section?) {
        guard let ip = self._indexPathOfSection(representing: section) else { return }
        if _sectionsCopy == nil { _sectionsCopy = _sections }
        _sections.remove(at: ip._section)
    }
    
    private func sortSections() {
        self._sections.sort()
    }
    
    
    
    
    // MARK: - Notification Registration
    /*-------------------------------------------------------------------------------*/
    private func register() {
        ResultsControllerCDManager.shared.add(context: self.managedObjectContext)
        NotificationCenter.default.addObserver(self, selector: #selector(handleChangeNotification(_:)), name: ResultsControllerCDManager.Dispatch.name, object: self.managedObjectContext)    }
    
    private func unregister() {
        ResultsControllerCDManager.shared.remove(context: self.managedObjectContext)
        NotificationCenter.default.removeObserver(self, name: ResultsControllerCDManager.Dispatch.name, object: self.managedObjectContext)
    }



    
    
    // MARK: - Empty Sections
    /*-------------------------------------------------------------------------------*/
    
    /// If true, changes reported to the delegate account for a placeholer cell that is not reported in the controllers data
    public var hasEmptyPlaceholder : Bool = false
    
    /// A special set of changes if hasEmptyPlaceholder is true that can be passed along to a Collection View
    public private(set) var placeholderChanges : ResultsChangeSet?
    
    
    
    
    // MARK: - Handling Changes
    /*-------------------------------------------------------------------------------*/
    
    /// Returns the number of changes processed during an update. Only valid during controllDidChangeContent(_)
    public var pendingChangeCount : Int {
        return pendingItemChangeCount
    }
    
    /// Same as pendingChangeCount. Returns the number of changes processed during an update. Only valid during controllDidChangeContent(_)
    public var pendingItemChangeCount : Int {
        return context.objectChanges.count
    }
    
    
    private var context = ChangeContext<Element>()
    private var _sectionsCopy : OrderedSet<SectionInfo>?
    
    
    @objc func handleChangeNotification(_ notification: Notification) {
        
        guard let delegate = self.delegate, self._fetched else {
            print("Ignoring context notification because results controller doesn't have a delegate or has not been fetched yet")
            return
        }
        _sectionsCopy = nil
        
        guard let info = notification.userInfo else { return }
        self.context.reset()
        
        preprocess(notification: notification)
        
        if context.objectChanges.count == 0 {
            return
        }
        delegate.controllerWillChangeContent(controller: self)
        
        processDeleted()
        processInserted()
        processUpdated()
        
        
        var processedSections = [SectionInfo:ChangeSet<OrderedSet<Element>>]()
        for s in _sections {
            if s.isEditing {
                if s.numberOfObjects == 0 {
                    self._remove(s._value)
                    continue;
                }
                let set = s.endEditing(forceUpdates: self.context.objectChanges.updated.valuesSet)
                processedSections[s] = set
            }
        }
        
        
        if let oldSections = _sectionsCopy {
            var sectionChanges = ChangeSet(source: oldSections, target: _sections)
            sectionChanges.reduceEdits()
            
            for change in sectionChanges.edits {
                switch change.operation {
                case .insertion:
                    let ip = IndexPath.for(section: change.index)
                    delegate.controller(self, didChangeSection: change.value, at: nil, for: .insert(ip))
                case .deletion:
                    let ip = IndexPath.for(section: change.index)
                    delegate.controller(self, didChangeSection: change.value, at: ip, for: .delete)
                case .substitution:
                    let ip = IndexPath.for(section: change.index)
                    delegate.controller(self, didChangeSection: change.value, at: ip, for: .update)
                case let .move(origin):
                    let ip = IndexPath.for(section: origin)
                    delegate.controller(self, didChangeSection: change.value, at: ip, for: .move(IndexPath.for(section: change.index)))
                }
            }
        }
        let _previousSectionCount = _sectionsCopy?.count
        _sectionsCopy = nil
        

        func reduceCrossSectional(_ object: Element, targetEdit tEdit: Edit<Element>? = nil) -> Bool {
            
            guard self.context.itemsWithSectionChange.remove(object) != nil else {
                return false
            }
            
            guard let source = self.context.objectChanges.updated.index(of: object),
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
                let _ = processedSections[targetSection]?.edit(withSource: targetIP._item)
                // Nothing to do
            }
            else if case .substitution = proposedEdit.operation, let obj = self.context.objectChanges.object(for: targetIP) {
                let insert = Edit(.deletion, value: obj, index: proposedEdit.index)
                processedSections[targetSection]?.operationIndex.deletes.insert(insert, with: targetIP._item)
            }
            return true
        }
        
        while let obj = self.context.itemsWithSectionChange.first {
            _ = reduceCrossSectional(obj)
        }
        
        if hasEmptyPlaceholder, let old = _previousSectionCount {
            
            if self.placeholderChanges == nil {
                self.placeholderChanges = ResultsChangeSet()
            }
            if old == 0 && _sections.count != 0 {
                self.placeholderChanges?.addChange(forItemAt: IndexPath.zero, with: .delete)
            }
            else if old != 0 && _sections.count == 0 {
                self.placeholderChanges?.addChange(forItemAt: nil, with: .insert(IndexPath.zero))
            }
        }
        else {
            self.placeholderChanges = nil
        }
        
        
        
        self.managedObjectContext.perform({
            for s in processedSections {
                var changes = s.value
                changes.reduceEdits()
                processedSections[s.key] = changes
                
                guard let sectionIndex = self.indexPath(of: s.key)?._section else { continue }
                
                // Could merge all the edits together to dispatch the delegate calls in order of operation
                // but there is no apparent reason why order is important.
                
                for edit in changes.edits {
                    switch edit.operation {
                        
                    case .move(origin: _):
                        guard let source = self.context.objectChanges.updated.index(of: edit.value),
                            let dest = self.indexPath(of: edit.value) else {
                                continue
                        }
                        
                        delegate.controller(self, didChangeObject: edit.value, at: source, for: .move(dest))
                        
                    case .substitution:
                        let ip = IndexPath.for(item: edit.index, section: sectionIndex)
                        delegate.controller(self, didChangeObject: edit.value, at: ip, for: .update)
                        
                    case .insertion:
                        guard let ip = self.indexPath(of: edit.value) else {
                            continue
                        }
                        delegate.controller(self, didChangeObject: edit.value, at: nil, for: .insert(ip))
                        
                    case .deletion:
                        let source = IndexPath.for(item: edit.index, section: sectionIndex)
                        delegate.controller(self, didChangeObject: edit.value, at: source, for: .delete)
                    }
                }
            }

            delegate.controllerDidChangeContent(controller: self)
            self.placeholderChanges = nil
        })
    }
    
    
    private func preprocess(notification: Notification) {
        
        var objects = ObjectChangeSet<IndexPath, Element>()
        
        guard let changes = notification.userInfo?[ResultsControllerCDManager.Dispatch.changeSetKey] as? [NSEntityDescription:ResultsControllerCDManager.EntityChangeSet] else {
            return
        }
        
        
        
        for request in self.fetchRequests {
            if let itemChanges = changes[request.entity!] {
                for obj in itemChanges.deleted {
                    guard let o = obj as? Element, let ip = self.indexPath(of: o) else { continue }
                    objects.add(deleted: o, for: ip)
                }
                
                for obj in itemChanges.inserted {
                    if let o = obj as? Element {
                        if request.predicate == nil || request.predicate?.evaluate(with: o) == true {
                            objects.add(inserted: o)
                        }
                    }
                }
                
                for obj in itemChanges.updated {
                    if let o = obj as? Element {
                        
                        let _ip = self.indexPath(of: o)
                        let match = request.predicate == nil || request.predicate?.evaluate(with: o) == true
                        
                        if let ip = _ip {
                            if !match { objects.add(deleted: o, for: ip) }
                            else { objects.add(updated: o, for: ip) }
                        }
                        else if match {
                            objects.add(inserted: o)
                        }
                    }
                }
            }
        }
        self.context.objectChanges = objects
        
    }
    
    private func processDeleted() {
        
        for change in self.context.objectChanges.deleted {
            let object = change.value
            defer {
                _objectSectionMap[object] = nil
            }
            
            let oldIP = change.index
            let section = self._sections[oldIP._section]
            
            section.ensureEditing()
            _ = section.remove(object)
        }
    }
    
    private func processInserted() {
        
        for object in context.objectChanges.inserted {
            
            guard self.contains(object: object) == false else { continue }
            if let keyPath = self.sectionKeyPath {
                
                let sectionValue = object.value(forKeyPath: keyPath) as? Section
                if let existingIP = self._indexPathOfSection(representing: sectionValue),
                    let existingSection = self._sectionInfo(at: existingIP) {
                    
                    existingSection.ensureEditing()
                    existingSection.add(object)
                    _objectSectionMap[object] = existingSection
                    
                    // Should items in inserted sections be included?
                }
                else {
                    // The section value doesn't exist yet, the section will be inserted
                    let sec = SectionInfo(controller: self, value: sectionValue, objects: [object])
                    self._sections.add(sec)
                    _objectSectionMap[object] = sec
                }
            }
            else if let section = self._sections.first {
                // No key path, just one section
                section.ensureEditing()
                section.add(object)
                _objectSectionMap[object] = section
            }
            else {
                let s = self._insert(section: nil)
                _ = s.appendOrdered(object)
                _objectSectionMap[object] = s
            }
        }
    }

    
    
    
    private func processUpdated() {
        
        for change in context.objectChanges.updated {
            
            let object = change.value
//            let sourceIP = change.index
            
            guard let tempIP = self.indexPath(of: object),
                let currentSection = _sectionInfo(at: tempIP) else {
                    print("Skipping object update")
                    continue
            }
            currentSection.ensureEditing()
            if let keyPath = self.sectionKeyPath {
                let sectionValue = object.value(forKeyPath: keyPath) as? Section
                
                // Move within the same section
                if sectionValue == currentSection._value {
                    currentSection._modified(object)
                    _objectSectionMap[object] = currentSection
                }
                    
                    // Moved to another section
                else if let newSip = self._indexPathOfSection(representing: sectionValue),
                    let newSection = self._sectionInfo(at: newSip) {
                    currentSection.remove(object)
                    newSection.ensureEditing()
                    newSection.add(object)
                    self.context.itemsWithSectionChange.insert(object)
                    _objectSectionMap[object] = newSection
                }
                    
                    // Move to new section
                else {
                    // The section value doesn't exist yet, the section will be inserted
                    let sec = self._insert(section: sectionValue)
                    sec.ensureEditing()
                    sec.add(object)
                    _objectSectionMap[object] = sec
                }
            }
            else {
                
                let sec = _insert(section: nil)
                sec.ensureEditing()
                sec.add(object)
                _objectSectionMap[object] = sec
            }
        }
    }
    
    
    

    
}



