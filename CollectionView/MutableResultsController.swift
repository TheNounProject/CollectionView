
//
//  FetchedResultsController.swift
//  CollectionView
//
//  Created by Wes Byrne on 1/16/17.
//  Copyright © 2017 Noun Project. All rights reserved.
//

import Foundation


/// A set of changes for an entity with with mappings to original Indexes
fileprivate struct ChangeIndex<Index: Hashable, Object:Hashable>: CustomStringConvertible {
    
    var inserted = Set<Object>()
    var updated = IndexedSet<Index, Object>()
    var deleted = IndexedSet<Index, Object>()
    
    var count : Int {
        return inserted.count + updated.count + deleted.count
    }
    
    var description: String {
        let str = "Change Set \(Object.self):"
            + " \(updated.count) Updated, "
            + " \(inserted.count) Inserted, "
            + " \(deleted.count) Deleted"
        return str
    }
    
    init() { }
    
    mutating func inserted(_ object: Object) {
        inserted.insert(object)
    }
    
    mutating func updated(_ object: Object, at index: Index) {
        self.updated.insert(object, for: index)
    }
    
    mutating func deleted(_ object: Object, at index: Index) {
        self.deleted.insert(object, for: index)
    }
    
    func object(for index: Index) -> Object? {
        return updated[index] ?? deleted[index]
    }
    
    func index(for object: Object) -> Index? {
        return updated.index(of: object) ?? deleted.index(of: object)
    }
    
    mutating func reset() {
        self.inserted.removeAll()
        self.deleted.removeAll()
        self.updated.removeAll()
    }
}



/**
 A results controller not only manages data, it also provides an easy to use, consistent interface for working with CollectionViews. While a typical controller fetches and manages data changes internally, this slimmed down version leaves the manipulation of it's content up to you so you can use the same interface with any type of data.
*/
public class MutableResultsController<Section: SectionType, Element: ResultType> : ResultsController {
    
    typealias WrappedSectionInfo = SectionInfo<Section, Element>
    
    typealias SectionAccessor = (Element) -> Section?
    
    
    private struct EditingContext: CustomStringConvertible {
        
        var objectChanges = ChangeIndex<IndexPath, Element>()
        var sectionChanges = ChangeIndex<Int, Section>()
        var itemsWithSectionChange = Set<Element>()
        
        mutating func reset() {
            self.objectChanges.reset()
        }
        
        var description: String {
            return "Context Items: \(objectChanges.deleted.count) Deleted, \(objectChanges.inserted.count) Inserted, \(objectChanges.updated.count) Updated"
        }
    }
    
    

    // MARK: - Initialization
    /*-------------------------------------------------------------------------------*/
    
    public init() {
        
    }
    
    public init(sectionKeyPath: KeyPath<Element,Section>? = nil,
         sortDescriptors: [SortDescriptor<Element>] = [],
         sectionSortDescriptors: [SortDescriptor<Section>] = []) {
        self.setSectionKeyPath(sectionKeyPath)
        self.sortDescriptors = sortDescriptors
        self.sectionSortDescriptors = sectionSortDescriptors
    }
    
    deinit {
        self._sections.removeAll()
    }
    
    // MARK: - Configuration
    /*-------------------------------------------------------------------------------*/
    
    public var sortDescriptors : [SortDescriptor<Element>] = []
    public var sectionSortDescriptors : [SortDescriptor<Section>] = []
    
    var sectionGetter : SectionAccessor?
    /// Returns true if a sectionKeyPath has been set
    public var isSectioned: Bool {
        return sectionGetter != nil
    }
    private func section(for element: Element) -> Section? {
        return sectionGetter?(element)
    }
    
    /// A key path of the elements to use for section groupings
    public func setSectionKeyPath(_ keyPath: KeyPath<Element, Section>?) {
        guard let kp = keyPath else {
            sectionGetter = nil
            return
        }
        sectionGetter = {
            $0[keyPath: kp]
        }
    }
    /// A key path of the elements to use for section groupings
    public func setSectionKeyPath(_ keyPath: KeyPath<Element, Section?>) {
        sectionGetter = {
            return $0[keyPath: keyPath]
        }
    }
    
    
    /**
     The delegate to report changes to
     */
    public weak var delegate: ResultsControllerDelegate?
    
    
    
    // MARK: - Controller Contents
    /*-------------------------------------------------------------------------------*/
    
    private var _objectSectionMap = [Element:WrappedSectionInfo]() // Map between elements and the last group it was known to be in
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
    public var allObjects: [Element] {
        return self._sections.reduce(into: [Element]()) { (res, sec) in
            res.append(contentsOf: sec._storage)
        }
    }
    
    
    
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
        if self.sectionGetter != nil {
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
        if let idx = _sections.index(of: _wrap) {
            return IndexPath.for(section: idx)
        }
        return nil
    }
    
    
    
    
    // MARK: - Private Helpers
    /*-------------------------------------------------------------------------------*/
    
    
    /// Section info for a given index path
    ///
    /// - Parameter sectionIndexPath: A index path (item is not used)
    /// - Returns: The section info if available
    public func sectionInfo(at sectionIndexPath: IndexPath) -> SectionInfo<Section,Element>? {
        return self.sectionInfo(at: sectionIndexPath._section)
    }
    
    
    /// Section info for a given section
    ///
    /// - Parameter sectionIndex: A section index
    /// - Returns: The section info if available
    public func sectionInfo(at sectionIndex: Int) -> SectionInfo<Section,Element>? {
        guard sectionIndex < self.numberOfSections else { return nil }
        return self._sections.object(at: sectionIndex)
    }
    
    
    /// Section info representing a given section value (or nil)
    ///
    /// - Parameter section: A value that is represented by a section in the controller
    /// - Returns: The section info if available
    public func sectionInfo(representing section: Section?) -> SectionInfo<Section,Element>? {
        guard let ip = self.indexPathOfSection(representing: section) else { return nil }
        return self.sectionInfo(at: ip)
    }
    
    /// Check if an object exists in the controller
    ///
    /// - Parameter object: An object
    /// - Returns: True if the object is currently in the controller's data
    public func contains(object: Element) -> Bool {
        return _objectSectionMap[object] != nil
    }
    
    /// Check if a section value exists in the controller
    ///
    /// - Parameter sectionObject: A section value
    /// - Returns: True if a section representing the value exists in the controller's data
    public func contains(sectionObject: Section) -> Bool {
        let _wrap = WrappedSectionInfo(object: sectionObject, objects: [])
        return _sections.contains(_wrap)
    }
    
    
    // MARK: - Storage Manipulation
    /*-------------------------------------------------------------------------------*/
    
    
    /**
     Set pre-grouped content on the controller

     - Parameter content: A list of section, [Element] tuples to set as the content
    */
    public func setContent(_ content: [(Section,[Element])]) {
        self._sections = []
        for s in content {
            let section = WrappedSectionInfo(object: s.0, objects: s.1)
            self._sections.append(section)
            for o in s.1 {
                self._objectSectionMap[o] = section
            }
        }
        self.sortSections()
        self.sortObjects()
        self.delegate?.controllerDidLoadContent(controller: self)
    }
    
    
    /// Set the content of the controller to be sorted and grouped according to options
    ///
    /// - Parameter content: An array of elements
    public func setContent(sections: [Section] = [], objects: [Element]) {
        self._sections = []
        if let sectionAccessor = self.sectionGetter {
            for section in sections {
                _ = getOrCreateSectionInfo(for: section)
            }
            for element in objects {
                let s = getOrCreateSectionInfo(for: sectionAccessor(element))
                s.add(element)
                self._objectSectionMap[element] = s
            }
        }
        else if !objects.isEmpty {
            if !sections.isEmpty {
                print("ResultsController Warning: sections provided but no sectionKeyPath has been set")
            }
            let s = WrappedSectionInfo(object: nil, objects: objects)
            self._sections = [s]
            for o in objects {
                self._objectSectionMap[o] = s
            }
        }
        self.sortSections()
        self.sortObjects()
        self.delegate?.controllerDidLoadContent(controller: self)
    }
    
    /// Clears all data and stops monitoring for changes in the context.
    public func reset() {
        self._sections.removeAll()
        self._sectionsCopy = nil
        self._objectSectionMap.removeAll()
        self.delegate?.controllerDidLoadContent(controller: self)
    }
    
    
    private func sortObjects() {
        guard !self.sortDescriptors.isEmpty else { return }
        for s in _sections {
            s.sort(using: self.sortDescriptors)
        }
    }
    
    private func sortSections() {
        guard !self.sectionSortDescriptors.isEmpty else { return }
        self._sections.sort { (a, b) -> Bool in
            if a.representedObject == nil { return false }
            if b.representedObject == nil { return true }
            return sectionSortDescriptors.compare(a.representedObject!, b.representedObject!) == .ascending
        }
    }
    
    private func ensureSectionCopy() {
        if _sectionsCopy == nil { _sectionsCopy = _sections }
    }
    
    
    func getOrCreateSectionInfo(for section: Section?) -> WrappedSectionInfo {
        if let s = self.sectionInfo(representing: section) { return s }
        self.ensureSectionCopy()
        let s = WrappedSectionInfo(object: section, objects: [])
        _sections.append(s)
        return s
    }
    
    private func _removeSection(representing section: Section?) {
        guard let ip = self.indexPathOfSection(representing: section) else { return }
        self.ensureSectionCopy()
        _sections.remove(at: ip._section)
    }
    private func _removeSection(info sectionInfo: WrappedSectionInfo) {
        self.ensureSectionCopy()
        self._sections.remove(sectionInfo)
    }
    
    
    func shouldRemoveEmptySection(_ section: SectionInfo<Section, Element>)-> Bool {
        return true
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
    @available(*, unavailable, message: "This functionality has been deprecated and will be replaced soon.")
    public var hasEmptyPlaceholder : Bool = false
    
    /// A special set of changes if hasEmptyPlaceholder is true that can be passed along to a Collection View
    @available(*, unavailable, message: "This functionality has been deprecated and will be replaced soon.")
    public private(set) var placeholderChanges : CollectionViewProvider?
    
    
    private var _sectionsCopy : OrderedSet<WrappedSectionInfo>?
    private var _editingContext = EditingContext()
    private var _editing = 0
    
    func logContents(prefix: String) {
        print("\(prefix) -----------")
        for section in _sections.enumerated() {
            print("  Section \(section.offset) - \(section.element)")
            debugPrint(section.element._storage)
        }
    }
    
    
    /// Begin an esiting session to group multiple changes (see `endEditing()`)
    public func beginEditing() {
        if _editing == 0 {
            delegate?.controllerWillChangeContent(controller: self)
            _sectionsCopy = nil
            self._editingContext.reset()
        }
        _editing += 1
    }
    
    /// End an esiting session to commit changes (see `beginEditing()`)
    public func endEditing() {
        precondition(_editing > 0, "ResultsController endEditing called before beginEditing")
        if _editing > 1 {
            _editing -= 1
            return
        }
        _editing = 0
        
        if self._sections.needsSort {
            self.ensureSectionCopy()
            self.sortSections()
        }
        
        var processedSections = [Int:EditDistance<OrderedSet<Element>>]()
        for (idx, s) in _sections.enumerated() {
            if let changeSet = s.endEditing(sorting: sortDescriptors, forceUpdates: Set()) {
                if s.numberOfObjects == 0 && self.shouldRemoveEmptySection(s) {
                    self._removeSection(info: s)
                    continue;
                }
                processedSections[idx] = changeSet
            }
        }
        
        var insertedSections = IndexSet()
        var deletedSections = IndexSet()
        
        if let oldSections = _sectionsCopy {
            var sectionChanges = EditDistance(source: oldSections, target: _sections)
            
            for change in sectionChanges.edits {
                switch change.operation {
                case .insertion:
                    insertedSections.insert(change.index)
                    let ip = IndexPath.for(section: change.index)
                    delegate?.controller(self, didChangeSection: change.value, at: nil, for: .insert(ip))
                case .deletion:
                    deletedSections.insert(change.index)
                    let ip = IndexPath.for(section: change.index)
                    delegate?.controller(self, didChangeSection: change.value, at: ip, for: .delete)
                case .substitution:
                    let ip = IndexPath.for(section: change.index)
                    delegate?.controller(self, didChangeSection: change.value, at: ip, for: .update)
                case let .move(origin):
                    let ip = IndexPath.for(section: origin)
                    delegate?.controller(self, didChangeSection: change.value, at: ip, for: .move(IndexPath.for(section: change.index)))
                }
            }
        }
        
        
        
        func reduceCrossSectional(_ object: Element) {
            
            // Get the sourceIP, targetIP and section info of the target
            guard let sourceIP = self._editingContext.objectChanges.updated.index(of: object),
                let targetIP = self.indexPath(of: object) else {
                    return
            }
            
            guard let targetEdits = processedSections[targetIP._section]?.operationIndex.edits(for: object), !targetEdits.isEmpty else {
                print("Couldn't find insert for cross section souce: \(sourceIP) target \(targetIP)")
                return
            }
            
            // Add the new move edit
            let newEdit = Edit(.move(origin: sourceIP._item), value: object, index: targetIP._item)
            processedSections[targetIP._section]?.operationIndex.moves.insert(newEdit, for: targetIP._item)
            
            

            // Remove the original edits
            // With Heckel multiple edits can be made on the same object (Move and Update)
//            var targetReplaced : (Element, Int)? = nil
            var affected : (Element, Int)? = nil
            for e in targetEdits {
                switch e.operation {
                case .substitution: affected = affected ?? (e.value, e.index)
                case let .move(origin: from): affected = (e.value, from)
                default: break
                }
                processedSections[targetIP._section]!.operationIndex.remove(edit: e)
            }
            if let m = affected {
                processedSections[targetIP._section]!.operationIndex.delete(m.0, index: m.1)
            }
            
            // Get the new index for the section this object came from (more work to do if sections have changed)
            var sourceSectionIndex = sourceIP._section
            if let originalSections = self._sectionsCopy {
                // If the original section has been removed, nothing to do
                guard let s = self._sections.index(of: originalSections.object(at: sourceSectionIndex)) else { return }
                sourceSectionIndex = s
            }
            
            // There should always be a source edit (delete or replace)
            guard let sourceEdits = processedSections[sourceSectionIndex]?.operationIndex.edits(for: object), !sourceEdits.isEmpty else { return }
            
            // Remove the old edits and replace them with an insert if it was going to remain
            var _affected : (Element, Int)? = nil
            for e in sourceEdits {
                switch e.operation {
                case .substitution: _affected = _affected ?? (e.value, e.index)
                case .move(origin: _): _affected = (e.value, e.index)
                default: break
                }
                processedSections[sourceSectionIndex]!.operationIndex.remove(edit: e)
            }
            if let m = _affected {
                processedSections[sourceSectionIndex]!.operationIndex.insert(m.0, index: m.1)
            }
        }
        
        while let obj = self._editingContext.itemsWithSectionChange.removeOne() {
            reduceCrossSectional(obj)
        }
        
        _sectionsCopy = nil
        
        for sectionIndex in processedSections.keys {
            let changes = processedSections[sectionIndex]!.operationIndex.allEdits
            
            // Could merge all the edits together to dispatch the delegate calls in order of operation
            // but there is no apparent reason why order is important.
            
            for edit in changes {
                switch edit.operation {
                    
                case .move(origin: _):
                    // Get the source and target
                    guard let source = self._editingContext.objectChanges.updated.index(of: edit.value),
                        let dest = self.indexPath(of: edit.value) else {
                            continue
                    }
                    delegate?.controller(self, didChangeObject: edit.value, at: source, for: .move(dest))
                    
                case .substitution:
                    // TODO: Should this be the source IP?
                    let ip = IndexPath.for(item: edit.index, section: sectionIndex)
                    delegate?.controller(self, didChangeObject: edit.value, at: ip, for: .update)
                    
                case .insertion:
                    // Get the new IP – if the section was inserted we can skip
                    guard let ip = self.indexPath(of: edit.value), !insertedSections.contains(ip._section) else {
                        continue
                    }
                    delegate?.controller(self, didChangeObject: edit.value, at: nil, for: .insert(ip))
                    
                case .deletion:
                    // Get the original IP – if the section was removed, we can skip
                    guard let source = self._editingContext.objectChanges.index(for: edit.value),
                        !deletedSections.contains(source._section) else {
                        continue
                    }
                    delegate?.controller(self, didChangeObject: edit.value, at: source, for: .delete)
                }
            }
        }
        
        delegate?.controllerDidChangeContent(controller: self)
//        self.placeholderChanges = nil
        self._sectionsCopy = nil
    }
}


extension MutableResultsController where Section:AnyObject {
    
    // MARK: - Section Manipulation
    /*-------------------------------------------------------------------------------*/
    
    
    /// Remove the section representing the given value
    ///
    /// - Parameter section: A Section value represented by a section in the controller
    public func delete(section: Section) {
        guard let info = self.sectionInfo(representing: section) else { return }
        self.beginEditing()
        defer { self.endEditing() }
        for obj in info._storage {
            _objectSectionMap[obj] = nil
        }
        self._removeSection(info: info)
    }
    
    /**
     Insert a section representing the provided value

     - Parameter section: A Section value representing a section in the controller

    */
    public func insert(section: Section) {
        self.beginEditing()
        defer { self.endEditing() }
        _sections.needsSort = true
        _ = self.getOrCreateSectionInfo(for: section)
    }
    
    
    /**
     Notify the controller that a section value has changed
     
     After an object is changed in a way that affects its representation as a section in the controller (i.e. sorting), the controller must be notified to process the change.

     - Parameter section: A section existing in the controller

    */
    public func didUpdate(section: Section) {
        self.beginEditing()
        defer { self.endEditing() }
        _sections.needsSort = true
    }
}


extension MutableResultsController where Element:AnyObject {
    
    
    // MARK: - Object Manipulation
    /*-------------------------------------------------------------------------------*/
    
    /// Delete objects from the controller
    ///
    /// - Parameter deletedObjects: A collection objects in the controller
    public func delete<C : Collection>(objects deletedObjects: C) where C.Iterator.Element == Element {
        self.beginEditing()
        defer { self.endEditing() }
        
        for o in deletedObjects {
            self.delete(object: o)
        }
    }
    
    /// Delete an object from the controller
    ///
    /// - Parameter object: An object in the controller
    public func delete(object: Element) {
        self.beginEditing()
        defer { self.endEditing() }
        guard let ip = self.indexPath(of: object),
            let section = self._objectSectionMap.removeValue(forKey: object) else { return }
        self._editingContext.objectChanges.deleted(object, at: ip)
        
        section.ensureEditing()
        section.remove(object)
    }
    
    
    /// Insert multiple objects into the controller
    ///
    /// - Parameter newObjects: A collection of objects
    public func insert<C : Collection>(objects newObjects: C) where C.Iterator.Element == Element {
        self.beginEditing()
        defer { self.endEditing() }
        for o in newObjects {
            self.insert(object: o)
        }
    }

    
    /// Insert an object into the controller
    ///
    /// - Parameter object: An object
    public func insert(object: Element) {
        guard self.contains(object: object) == false else { return }
        self.beginEditing()
        defer { self.endEditing() }
        if let sectionAccessor = self.sectionGetter {
            
            let sectionValue = sectionAccessor(object)
            if let existingSection = self.sectionInfo(representing: sectionValue) {
                existingSection.ensureEditing()
                existingSection.add(object)
                _objectSectionMap[object] = existingSection
            }
            else {
                // The section value doesn't exist yet, the section will be inserted
                let sec = getOrCreateSectionInfo(for: sectionValue)
                sec.add(object)
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
            let s = self.getOrCreateSectionInfo(for: nil)
            s.add(object)
            _objectSectionMap[object] = s
        }
        self._editingContext.objectChanges.inserted(object)
    }
    
    
    
    /**
     Notify the controller that an existing object has been updated
     
     After an object is changed in a way that affects its section or sorting, the controller must be notified to process the change.

     - Parameter object: An existing object in the controller
     
    */
    public func didUpdate(object: Element) {
        
        guard let tempIP = self.indexPath(of: object),
            let currentSection = self.sectionInfo(at: tempIP) else {
                print("Skipping object update \(object)")
                return
        }
        self.beginEditing()
        defer { self.endEditing() }
        currentSection.ensureEditing()
        if let sectionAccessor = self.sectionGetter {
            let sectionValue = sectionAccessor(object)
            
            if sectionValue == currentSection.representedObject {
                // Move within the same section
                currentSection.add(object)
                _objectSectionMap[object] = currentSection
            }
            else {
                currentSection.remove(object)
                let newSection = self.getOrCreateSectionInfo(for: sectionValue)
                newSection.ensureEditing()
                newSection.add(object)
                self._editingContext.itemsWithSectionChange.insert(object)
                _objectSectionMap[object] = newSection
            }
        }
        else {
            let sec = getOrCreateSectionInfo(for: nil)
            sec.ensureEditing()
            sec.add(object)
            
            // Maybe check if the sort keys were actually updated before doing this
            _objectSectionMap[object] = sec
        }
        self._editingContext.objectChanges.updated(object, at: tempIP)
    }
}



