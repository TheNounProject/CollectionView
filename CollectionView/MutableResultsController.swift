
//
//  FetchedResultsController.swift
//  CollectionView
//
//  Created by Wes Byrne on 1/16/17.
//  Copyright © 2017 Noun Project. All rights reserved.
//

import Foundation



fileprivate struct EditingContext<Element:Hashable> : CustomStringConvertible {
    
    var objectChanges = ObjectChangeSet<IndexPath, Element>()
    var itemsWithSectionChange = Set<Element>()
    
    mutating func reset() {
        self.objectChanges.reset()
    }
    
    var description: String {
        return "Context Items: \(objectChanges.deleted.count) Deleted, \(objectChanges.inserted.count) Inserted, \(objectChanges.updated.count) Updated"
    }
}



/**
 A results controller not only manages data, it also provides an easy to use, consistent interface for working with CollectionViews. While a typical controller fetches and manages data changes internally, this slimmed down version leaves the manipulation of it's content up to you so you can use the same interface with any type of data.
*/
public class MutableResultsController<Section: SectionType, Element: ResultType> : ResultsController {
    
    typealias WrappedSectionInfo = SectionInfo<Section, Element>

    // MARK: - Initialization
    /*-------------------------------------------------------------------------------*/
    
    init() {
        
    }
    
    init(sectionKeyPath: KeyPath<Element,Section>? = nil,
         sortDescriptors: [SortDescriptor<Element>] = [],
         sectionSortDescriptors: [SortDescriptor<Section>] = []) {
        self.sectionKeyPath = sectionKeyPath
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
        if let idx = _sections.index(of: _wrap) {
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
    
    func contains(object: Element) -> Bool {
        return _objectSectionMap[object] != nil
    }
    
    func contains(sectionObject: Section) -> Bool {
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
    }
    
    public func setContent(_ content: [Element]) {
        self._sections = []
        if let kp = self.sectionKeyPath {
            for element in content {
                let s = getOrCreateSectionInfo(for: element[keyPath: kp])
                s.append(element)
                self._objectSectionMap[element] = s
            }
        }
        else if !content.isEmpty {
            let s = WrappedSectionInfo(object: nil, objects: content)
            self._sections = [s]
            for o in content {
                self._objectSectionMap[o] = s
            }
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
    
    
    func getOrCreateSectionInfo(for section: Section?) -> WrappedSectionInfo {
        if let s = self.sectionInfo(representing: section) { return s }
        if _sectionsCopy == nil { _sectionsCopy = _sections }
        let s = WrappedSectionInfo(object: section, objects: [])
        _sections.append(s)
        return s
    }
    
    private func _removeSection(representing section: Section?) {
        guard let ip = self.indexPathOfSection(representing: section) else { return }
        if _sectionsCopy == nil { _sectionsCopy = _sections }
        _sections.remove(at: ip._section)
    }
    private func _removeSection(info sectionInfo: WrappedSectionInfo) {
        if _sectionsCopy == nil { _sectionsCopy = _sections }
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
    public var hasEmptyPlaceholder : Bool = false
    
    /// A special set of changes if hasEmptyPlaceholder is true that can be passed along to a Collection View
    public private(set) var placeholderChanges : ResultsChangeSet?
    
    
    private var _sectionsCopy : OrderedSet<WrappedSectionInfo>?
    private var _editingContext = EditingContext<Element>()
    private var _editing = 0
    
    public func beginEditing() {
        if _editing == 0 {
            delegate?.controllerWillChangeContent(controller: self)
            _sectionsCopy = nil
            self._editingContext.reset()
        }
        _editing += 1
    }
    public func endEditing() {
        precondition(_editing > 0, "ResultsController endEditing called before beginEditing")
        if _editing > 1 {
            _editing -= 1
            return
        }
        _editing = 0
        
        var processedSections = [WrappedSectionInfo:ChangeSet<OrderedSet<Element>>]()
        for s in _sections {
            if s.needsSort {
                s.sort(using: self.sortDescriptors)
            }
            if s.isEditing {
                if s.numberOfObjects == 0 && self.shouldRemoveEmptySection(s) {
                    self._removeSection(info: s)
                    continue;
                }
                let set = s.endEditing(forceUpdates: self._editingContext.objectChanges.updated.valuesSet)
                processedSections[s] = set
            }
        }
        
        if self._sections.needsSort {
            self.sortSections()
        }
        
        if let oldSections = _sectionsCopy {
            var sectionChanges = ChangeSet(source: oldSections, target: _sections)
            sectionChanges.reduceEdits()
            
            for change in sectionChanges.edits {
                switch change.operation {
                case .insertion:
                    let ip = IndexPath.for(section: change.index)
                    delegate?.controller(self, didChangeSection: change.value, at: nil, for: .insert(ip))
                case .deletion:
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
        let _previousSectionCount = _sectionsCopy?.count
        
        func reduceCrossSectional(_ object: Element, targetEdit tEdit: Edit<Element>? = nil) -> Bool {
            
            guard self._editingContext.itemsWithSectionChange.remove(object) != nil else {
                return false
            }
            guard let source = self._editingContext.objectChanges.updated.index(of: object),
                let targetIP = self.indexPath(of: object),
                let targetSection = self.sectionInfo(at: targetIP) else {
                    return true
            }
            
            guard let proposedEdit = tEdit ?? processedSections[targetSection]?.edit(for: object) else {
                return true
            }
            
            let newEdit = Edit(.move(origin: source._item), value: object, index: targetIP._item)
            processedSections[targetSection]?.operationIndex.moves.insert(newEdit, for: targetIP._item)
            processedSections[targetSection]?.remove(edit: proposedEdit)
            
            if let s = self._sectionsCopy?.object(at: source._section) ?? _sections._object(at: source._section),
                let e = processedSections[s]?.edit(for: object) {
                processedSections[s]?.remove(edit: e)
            }
            
            if targetIP._item != proposedEdit.index {
                let _ = processedSections[targetSection]?.edit(withSource: targetIP._item)
            }
            else if case .substitution = proposedEdit.operation, let obj = self._editingContext.objectChanges.object(for: targetIP) {
                let insert = Edit(.deletion, value: obj, index: proposedEdit.index)
                processedSections[targetSection]?.operationIndex.deletes.insert(insert, for: targetIP._item)
            }
            return true
        }
        
        while let obj = self._editingContext.itemsWithSectionChange.first {
            _ = reduceCrossSectional(obj)
        }
        
        _sectionsCopy = nil
        
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
                    guard let source = self._editingContext.objectChanges.updated.index(of: edit.value),
                        let dest = self.indexPath(of: edit.value) else {
                            continue
                    }
                    
                    delegate?.controller(self, didChangeObject: edit.value, at: source, for: .move(dest))
                    
                case .substitution:
                    let ip = IndexPath.for(item: edit.index, section: sectionIndex)
                    delegate?.controller(self, didChangeObject: edit.value, at: ip, for: .update)
                    
                case .insertion:
                    guard let ip = self.indexPath(of: edit.value) else {
                        continue
                    }
                    delegate?.controller(self, didChangeObject: edit.value, at: nil, for: .insert(ip))
                    
                case .deletion:
                    let source = IndexPath.for(item: edit.index, section: sectionIndex)
                    delegate?.controller(self, didChangeObject: edit.value, at: source, for: .delete)
                }
            }
        }
        
        delegate?.controllerDidChangeContent(controller: self)
        self.placeholderChanges = nil
        self._sectionsCopy = nil
    }
    
    
    


}


extension MutableResultsController where Section:AnyObject {
    
    // MARK: - Section Manipulation
    /*-------------------------------------------------------------------------------*/
    
    func delete(section: Section) {
        guard let info = self.sectionInfo(representing: section) else { return }
        self.beginEditing()
        for obj in info._storage {
            _objectSectionMap[obj] = nil
        }
        self._removeSection(info: info)
        self.endEditing()
    }
    
    func insert(section: Section) {
        self.beginEditing()
        _ = self.getOrCreateSectionInfo(for: section)
        self.endEditing()
    }
    
    func didUpdate(section: Section) {
        self.beginEditing()
        _sections.needsSort = true
        self.endEditing()
    }
}


extension MutableResultsController where Element:AnyObject {
    
    
    // MARK: - Object Manipulation
    /*-------------------------------------------------------------------------------*/
    
    func delete<C : Collection>(objects deletedObjects: C) where C.Iterator.Element == Element {
        for o in deletedObjects {
            self.delete(object: o)
        }
    }
    
    func delete(object: Element) {
        guard let section = self._objectSectionMap.removeValue(forKey: object) else { return }
        section.ensureEditing()
        section.remove(object)
    }
    
    func insert<C : Collection>(objects newObjects: C) where C.Iterator.Element == Element {
        for o in newObjects {
            self.insert(object: o)
        }
    }
    
    func insert(object: Element) {
        guard self.contains(object: object) == false else { return }
        self.beginEditing()
        if let keyPath = self.sectionKeyPath {
            
            let sectionValue = object[keyPath: keyPath]
            if let existingSection = self.sectionInfo(representing: sectionValue) {
                existingSection.ensureEditing()
                existingSection.add(object)
                _objectSectionMap[object] = existingSection
                
                // Should items in inserted sections be included?
            }
            else {
                // The section value doesn't exist yet, the section will be inserted
                let sec = SectionInfo(object: sectionValue, objects: [object])
                self._sections.append(sec)
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
            s.insert(object)
            _objectSectionMap[object] = s
        }
        self._editingContext.objectChanges.add(inserted: object)
        self.endEditing()
    }
    
    
    func didUpdate(object: Element) {
        
        guard let tempIP = self.indexPath(of: object),
            let currentSection = self.sectionInfo(at: tempIP) else {
                print("Skipping object update")
                return
        }
        beginEditing()
        currentSection.ensureEditing()
        if let keyPath = self.sectionKeyPath {
            let sectionValue = object[keyPath:keyPath]
            
            if sectionValue == currentSection.representedObject {
                // Move within the same section
                currentSection.markNeedsSort()
                _objectSectionMap[object] = currentSection
            }
            else {
                currentSection.remove(object)
                let newSection = self.getOrCreateSectionInfo(for: sectionValue)
                newSection.ensureEditing()
                newSection.add(object)
                // TODO:
                //                self.context.itemsWithSectionChange.insert(object)
                _objectSectionMap[object] = newSection
            }
        }
        else {
            let sec = getOrCreateSectionInfo(for: nil)
            sec.ensureEditing()
            sec.add(object)
            
            // Maybe check if the sort keys were actually updated before doing this
            sec.markNeedsSort()
            
            _objectSectionMap[object] = sec
        }
        self._editingContext.objectChanges.add(updated: object, for: tempIP)
        endEditing()
    }
}



