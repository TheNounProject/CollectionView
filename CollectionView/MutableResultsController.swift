//
//  FetchedResultsController.swift
//  CollectionView
//
//  Created by Wes Byrne on 1/16/17.
//  Copyright © 2017 Noun Project. All rights reserved.
//

import Foundation



/*
fileprivate struct ChangeContext<Element:Hashable> : CustomStringConvertible {
    
    var objectChanges = ObjectChangeSet<IndexPath, Element>()
    var itemsWithSectionChange = Set<Element>()
    
    mutating func reset() {
        self.objectChanges.reset()
    }
    
    var description: String {
        return "Context Items: \(objectChanges.deleted.count) Deleted, \(objectChanges.inserted.count) Inserted, \(objectChanges.updated.count) Updated"
    }
}
*/



public class SectionInfo<Section: SectionType, Element: Hashable>: Hashable {
    
    public let representedObject : Section?
    public var objects: [Element] { return _storage.objects }
    
    public var numberOfObjects : Int { return _storage.count }
    
    private(set) var _storage : OrderedSet<Element>
    private var _storageCopy = OrderedSet<Element>()
    
    internal init(object: Section?, objects: [Element] = []) {
        self.representedObject = object
        _storage = OrderedSet(elements: objects)
    }
    
    
    
    // MARK: - Equatable
    /*-------------------------------------------------------------------------------*/
    public var hashValue: Int {
        return representedObject?.hashValue ?? 0
    }

//    fileprivate override func isEqual(_ object: ManagedSectionInfo?) -> Bool {
//        return self._value == object?.representedObject
//    }
    public static func ==(lhs: SectionInfo, rhs: SectionInfo) -> Bool {
        return lhs.representedObject == rhs.representedObject
    }

//    static func <(lhs: ManagedSectionInfo, rhs: ManagedSectionInfo) -> Bool {
//        if let v1 = lhs._value,
//            let v2 = rhs._value {
//            return v1 < v2
//        }
//        return lhs._value != nil
//    }
    
    
    // MARK: - Objects
    /*-------------------------------------------------------------------------------*/
    
    func index(of object: Element) -> Int? {
        return _storage.index(of: object)
    }
    
    @discardableResult func insert(_ object: Element, using sortDescriptors: [NSSortDescriptor] = []) -> Int {
        self.add(object)
        return self._storage.count - 1
    }
    @discardableResult func remove(_ object: Element) -> Int? {
        return _storage.remove(object)
    }
    
    func append(_ element: Element) {
        self._storage.append(element)
    }
    
    func sort(using sortDescriptors: [SortDescriptor<Element>]) {
        self._storage.sort(using: sortDescriptors)
    }

    
    // MARK: - Editing
    /*-------------------------------------------------------------------------------*/
    
    private(set) var needsSort : Bool = false
    private(set) var isEditing: Bool = false
//    private var _added = Set<Element>() // Tracks added items needing sort, to allow for performance optimizations
    
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
        assert(!needsSort, "endEditing() called but the section still needs to be sorted.")
        isEditing = false
        self.needsSort = false
        let changes = ChangeSet(source: _storageCopy, target: _storage, forceUpdates: forceUpdates)
        self._storageCopy.removeAll()
        return changes
    }
    
    func markNeedsSort() {
        self.needsSort = true
    }
    
    func add(_ element: Element) {
        guard self._storage.contains(element) == false else {
            let _ = _storage.index(of: element)
            return
        }
        self.needsSort = self.needsSort || self._storage.count > 0
        self._storage.append(element)
    }
}





/**
 A results controller not only manages data, it also provides an easy to use, consistent interface for working with CollectionViews. While a typical controller fetches and manages data changes internally, this slimmed down version leaves the manipulation of it's content up to you so you can use the same interface with any type of data.
*/
public class ManagedResultsController<Section: SectionType, Element: Hashable> : NSObject, ResultsController {
    
    fileprivate typealias WrappedSectionInfo = SectionInfo<Section, Element>

    // MARK: - Initialization
    /*-------------------------------------------------------------------------------*/
    
    
    /**
     Controller initializer a given context and fetch request

     - Parameter context: A managed object context
     - Parameter request: A fetch request with an entity name
     - Parameter sectionKeyPath: An optional key path to use for section groupings

    */
    public override init() {
        
    }
    
    deinit {
        self._sections.removeAll()
    }
    

    
    
    
    // MARK: - Configuration
    /*-------------------------------------------------------------------------------*/
    
    /**
     A closuer for providing custom sorting
     */
    public var sortDescriptors : [SortDescriptor<Element>] = []
    public var sectionSortDescriptors : [SortDescriptor<Section>] = []
    
    
    /// A key path of the elements to use for section groupings
    public var sectionKeyPath: KeyPath<Element,Section>?
    
    
    /**
     The delegate to report changes to
     */
    public weak var delegate: ResultsControllerDelegate?
    
    
    
    // MARK: - Controller Contents
    /*-------------------------------------------------------------------------------*/
    
    private var fetchedObjects = Set<Element>()
    private var _objectSectionMap = [Element:WrappedSectionInfo]() // Map between elements and the last group it was known to be in
    private var _fetchedObjects = [Element]()
    private var _sections = OrderedSet<WrappedSectionInfo>()
    
    
    /// The number of sections in the controller
    public var numberOfSections : Int {
        return _sections.count
    }
    
    
    
    /**
     The number of objects in a given section
     
     - Parameter section: A section index
     - Returns: The number of objects in the given section

    */
    public func numberOfObjects(in section: Int) -> Int {
        return self._sections[section].numberOfObjects
    }
    
    
    /**
     A list of all objects in the controller
     
     For performance reasons it is preferred to use object(at:)
     */
    public var allObjects: [Any] { return Array(fetchedObjects) }
    
    
    
    /**
     The list of sections in the controller
     
     For performance reasons accessing the controllers data should be done via the controller getters such as sectionInfo(forSectionAt:) or object(at:)
     */
    public var sections: [SectionInfo<Section,Element>] { return _sections.objects }
    
    
    /**
     The value of sectionKeyPath for the objects in a given section

     - Parameter indexPath: The index path of the section
     
     - Returns: A string value (if any) for the given section
     
     If sectionKeyPath is set, each section is created to represent the value returned for that path by any of the objects contained within it. CustomDisplayStringConvertible is used to create a string from that value.
     
     If the objects have an attribute `category` of type int, and the sectionKeyPath is set to `category`, each category will represent the various Int values. Using CustomDisplayStringConvertible, that int will be returned as a string.
     
     For custom handling of this, use `object(forSectionAt:)`

    */
    public func sectionName(forSectionAt indexPath: IndexPath) -> String {
        return (object(forSectionAt: indexPath) as? CustomDisplayStringConvertible)?.displayDescription ?? ""
    }
    
    
    
    // MARK: - Querying Sections & Objects
    /*-------------------------------------------------------------------------------*/
    
    
    /**
     The info for a given section

     - Parameter sectionIndexPath: An index path with the desired section
     - Returns: The info for the given section (or nil if indexPath.section is out of range)

    */
    public func sectionInfo(forSectionAt sectionIndexPath: IndexPath) -> SectionInfo<Section,Element>? {
        return self._sections._object(at: sectionIndexPath._section)
    }
    
    
    /**
     The object represented by the given section (if sectionKeyPath is not nil)

     - Parameter sectionIndexPath: An index path for the desired section
     
     - Returns: The value for `sectionKeyPath` of each object in the section (or nil)

    */
    public func object(forSectionAt sectionIndexPath: IndexPath) -> Section? {
        return self.sectionInfo(forSectionAt: sectionIndexPath)?.representedObject
    }
    
    
    /**
     The object at a given index path

     - Parameter indexPath: An index path
     
     - Returns: The object at the given indexPath (or nil if it is out of range)

    */
    public func object(at indexPath: IndexPath) -> Element? {
        return self.sectionInfo(at: indexPath)?._storage._object(at: indexPath._item)
    }

    
    
    // MARK: - Getting IndexPaths
    /*-------------------------------------------------------------------------------*/
    
    
    /**
     The index path of the section represented by section info
     
     - Parameter sectionInfo: Info for the section
     
     - Returns: The index path of the section matching the given info (or nil)
     
     */
    public func indexPath(of sectionInfo: SectionInfo<Section,Element>) -> IndexPath? {
        if let idx = _sections.index(of: sectionInfo) {
            return IndexPath.for(section: idx)
        }
        return nil
    }
    
    
    
    /**
     The index path of a given object contained in the controller
     
     - Parameter object: An object contained in the controller
     
     - Returns: The index path for the given object
     */
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
    
    
    /**
     The index path of the section that represents a value
     
     - Parameter sectionValue: The value that the desired section represents
     
     - Returns: The index path of the section (or nil)
     
     Section value refers the the value of `sectionKeyPath` for all objects in a section.
     
     */
    public func indexPathOfSection(representing sectionValue: Section?) -> IndexPath? {
        let _wrap = WrappedSectionInfo(object: sectionValue)
        if let idx =  _sections.index(of: _wrap) {
            return IndexPath.for(section: idx)
        }
        return nil
    }
    
    
    
    
    // MARK: - Private Helpers
    /*-------------------------------------------------------------------------------*/
    public func sectionInfo(at sectionIndexPath: IndexPath) -> SectionInfo<Section,Element>? {
        return self.sectionInfo(at: sectionIndexPath._section)
    }
    
    public func sectionInfo(at sectionIndex: Int) -> SectionInfo<Section,Element>? {
        guard sectionIndex < self.numberOfSections else { return nil }
        return self._sections.object(at: sectionIndex)
    }
    
    public func sectionInfo(representing section: Section?) -> SectionInfo<Section,Element>? {
        guard let ip = self.indexPathOfSection(representing: section) else { return nil }
        return self.sectionInfo(at: ip)
    }
    
    private func contains(object: Element) -> Bool {
        return _fetchedObjects.contains(object)
    }
    
    
    // MARK: - Storage Manipulation
    /*-------------------------------------------------------------------------------*/
    
    public func setContent(_ content: [Element]) {
        self._sections = []
        if let kp = self.sectionKeyPath {
            for element in content {
                let s = getOrCreateSectionInfo(for: element[keyPath: kp])
                s.append(element)
            }
        }
        else {
            let s = WrappedSectionInfo(object: nil, objects: content)
            self._sections = [s]
        }
        self.sortSections()
        self.sortObjects()
    }
    
    /// Clears all data and stops monitoring for changes in the context.
    public func reset() {
        self._sections.removeAll()
        self.fetchedObjects.removeAll()
        self._fetchedObjects.removeAll()
        self._sectionsCopy = nil
        self._fetchedObjects.removeAll()
        self._objectSectionMap.removeAll()
    }
    
    
    func sortObjects() {
        guard !self.sortDescriptors.isEmpty else { return }
        for s in _sections {
            s.sort(using: self.sortDescriptors)
        }
    }
    
    func sortSections() {
        guard !self.sectionSortDescriptors.isEmpty else { return }
        self._sections.sort { (a, b) -> Bool in
            if a.representedObject == nil { return false }
            if b.representedObject == nil { return true }
            return sectionSortDescriptors.compare(a.representedObject!, b.representedObject!) == .ascending
        }
    }
    
    
    private func getOrCreateSectionInfo(for section: Section?) -> WrappedSectionInfo {
        if let s = self.sectionInfo(representing: section) { return s }
        if _sectionsCopy == nil { _sectionsCopy = _sections }
        let s = WrappedSectionInfo(object: section, objects: [])
        _sections.append(s)
        return s
    }
    
    private func _remove(_ section: Section?) {
        guard let ip = self.indexPathOfSection(representing: section) else { return }
        if _sectionsCopy == nil { _sectionsCopy = _sections }
        _sections.remove(at: ip._section)
    }
    

    
    
    
    // MARK: - Handling Changes
    /*-------------------------------------------------------------------------------*/
    
    /// Returns the number of changes processed during an update. Only valid during controllDidChangeContent(_)
    public var pendingChangeCount : Int {
        return pendingItemChangeCount
    }
    
    /// Same as pendingChangeCount. Returns the number of changes processed during an update. Only valid during controllDidChangeContent(_)
    public var pendingItemChangeCount : Int {
        return 0
//        return context.objectChanges.count
    }

    
    /// If true, changes reported to the delegate account for a placeholer cell that is not reported in the controllers data
    public var hasEmptyPlaceholder : Bool = false
    
    /// A special set of changes if hasEmptyPlaceholder is true that can be passed along to a Collection View
    public private(set) var placeholderChanges : ResultsChangeSet?
    
    
    
    
//    private var context = ChangeContext<Element>()
    private var _sectionsCopy : OrderedSet<WrappedSectionInfo>?
    
    private var _editing = 0
    
    func beginEditing() {
        if _editing == 0 {
            // Prepare for editing
        }
        _editing += 1
    }
    func endEditing() {
        precondition(_editing > 0, "Internal ResultsController error. Unbalanced calls to beginEditing/endEditing")
        if _editing > 1 {
            _editing -= 1
            return
        }
        _editing = 0
        
        // Finalize edits
    }
    
    func delete(section: Section) {
        
    }
    
    func deleteSection(at index: Int) {
        
    }
    
    func insert(section: Section) {
        
    }
    
    func move(section: Section, to index: Int) {
        
    }
    
    func deleteObject(at indexPath: IndexPath) {
        
    }
    
    func delete(objects: Set<Element>) {
        
    }
    
    func insert(objects: Set<Element>) {
        
    }
    
    func move(object: Element, to indexPath: IndexPath) {
        
    }
    /*
    @objc func handleChangeNotification(_ notification: Notification) {
        
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
            if s.needsSort {
                if let sorter = self.sort {
                    s.sort(using: sorter)
                }
                else {
                    s.sortItems(using: fetchRequest.sortDescriptors ?? [])
                }
            }
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
            
            if let s = self._sectionsCopy?.object(at: source._section) ?? _sections._object(at: source._section),
                let e = processedSections[s]?.edit(for: object) {
                processedSections[s]?.remove(edit: e)
            }
            
            if targetIP._item != proposedEdit.index {
                let _ = processedSections[targetSection]?.edit(withSource: targetIP._item)
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
        
        _sectionsCopy = nil
        
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
            self._sectionsCopy = nil
        })
        
    }
    
    
    func preprocess(notification: Notification) {
        
        var objects = ObjectChangeSet<IndexPath, Element>()
        
        guard let changes = notification.userInfo?[ResultsControllerCDManager.Dispatch.changeSetKey] as? [NSEntityDescription:ResultsControllerCDManager.EntityChangeSet] else {
            return
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
        self.context.objectChanges = objects
        
    }
    
    
    
    func processDeleted() {
        
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
    
    func processInserted() {
        
        
        
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
                    let sec = SectionInfo(value: sectionValue, objects: [object])
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
                s.insert(object)
                _objectSectionMap[object] = s
            }
        }
    }

    
    
    
    func processUpdated() {
        
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
                    currentSection.markNeedsSort()
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
                    currentSection.remove(object)
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
                
                // Maybe check if the sort keys were actually updated before doing this
                sec.markNeedsSort()
                
                _objectSectionMap[object] = sec
            }
        }
    }
    
    */
    

    
}



