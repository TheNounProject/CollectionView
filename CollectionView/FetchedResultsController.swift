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





public typealias SectionRepresentable = Comparable & Hashable & CustomDisplayStringConvertible

fileprivate class FetchedSectionInfo<ValueType: SectionRepresentable, Element: NSManagedObject>: NSObject, Comparable, ResultsControllerSectionInfo {
    
    public var object : Any? { return self._value }
    public var objects: [Any] { return _storage.objects }
    
    public var numberOfObjects : Int { return _storage.count }
    
    private(set) var _value : ValueType?
    private(set) var _storage = OrderedSet<Element>()
    private(set) var _storageCopy = OrderedSet<Element>()
    
    internal init(value: ValueType?, objects: [Element] = []) {
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
    
    func insert(_ object: Element, using sortDescriptors: [NSSortDescriptor] = []) -> Int {
        
        if self._storage.count == 0  {
            self.add(object)
            return 0
        }
        else if needsSort || sortDescriptors.count == 0 {
            self.add(object)
            return self._storage.count - 1
        }
        else {
            let idx = _storage.insert(object, using: sortDescriptors)
            return idx
        }
    }
    func remove(_ object: Element) -> Int? {
        return _storage.remove(object)
    }
    
    func sortItems(using sortDescriptors: [NSSortDescriptor]) {
        self.needsSort = false
        self._storage.sort(using: sortDescriptors)
    }
    
    
    
    
    // MARK: - Editing
    /*-------------------------------------------------------------------------------*/
    
    private(set) var needsSort : Bool = false
    private(set) var isEditing: Bool = false
//    private var _added = Set<Element>() // Tracks added items needing sort, if one do insert for performance
    
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
            let idx = _storage.index(of: element)!
            return
        }
        self.needsSort = self._storage.count > 0
//        _added.insert(element)
        self._storage.add(element)
    }

    
}



/**
 An item based results controller
*/
public class FetchedResultsController<Section: SectionRepresentable, Element: NSManagedObject> : NSObject, ResultsController {
    
    
    fileprivate typealias SectionInfo = FetchedSectionInfo<Section, Element>
    
    // MARK: - Results Controller Protocol
    /*-------------------------------------------------------------------------------*/
    
    public var allObjects: [Any] { return Array(fetchedObjects) }
    public var sections: [ResultsControllerSectionInfo] { return _sections.objects }
    
    public var hasEmptyPlaceholder : Bool = false
    
    public let fetchRequest : NSFetchRequest<Element>
    public var sortDescriptors: [NSSortDescriptor]? {
        return fetchRequest.sortDescriptors
    }
    public let managedObjectContext: NSManagedObjectContext
    
    public var sectionKeyPath: String?

    
    fileprivate var fetchedObjects = Set<Element>()
    
    fileprivate var _objectSectionMap = [Element:SectionInfo]() // Map between elements and the last group it was known to be in
    
    fileprivate var _fetchedObjects = [Element]()
    private var _sections = OrderedSet<SectionInfo>()
    
    public weak var delegate: ResultsControllerDelegate? {
        didSet {
            if (oldValue == nil) == (delegate == nil) { return }
            if delegate == nil { unregister() }
            else if _fetched { register() }
        }
    }
    
    public init(context: NSManagedObjectContext, request: NSFetchRequest<Element>, sectionKeyPath: String? = nil) {
        
        assert(request.entityName != nil, "request is missing entity name")
        let objectEntity = NSEntityDescription.entity(forEntityName: request.entityName!, in: context)
        assert(objectEntity != nil, "Unable to load entity description for object \(request.entityName!)")
        request.entity = objectEntity
        
        request.returnsObjectsAsFaults = false
        
        self.managedObjectContext = context
        self.fetchRequest = request
        self.sectionKeyPath = sectionKeyPath
    }
    
     
    
    public var numberOfSections : Int {
        return _sections.count
    }
    
    public func numberOfObjects(in section: Int) -> Int {
        return self._sections[section].numberOfObjects
    }
    
    public func sectionName(forSectionAt indexPath: IndexPath) -> String {
        return _sectionInfo(at: indexPath)?._value?.displayDescription ?? ""
    }
    
    
    
    // MARK: - Public Item Accessors
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
        
        if let keyPath = self.sectionKeyPath {
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
        let _wrap = SectionInfo(value: sectionValue)
        if let idx =  _sections.index(of: _wrap) {
            return IndexPath.for(section: idx)
        }
        return nil
    }
    
    
    // MARK: - Private Accessors
    /*-------------------------------------------------------------------------------*/
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
    
    public func _object(forSectionAt sectionIndexPath: IndexPath) -> Section? {
        return self._sectionInfo(at: sectionIndexPath)?._value
    }
    
    public func _object(at indexPath: IndexPath) -> Element? {
        return self._sectionInfo(at: indexPath)?._storage.object(at: indexPath._item)
    }
    public func _indexPathOfSection(representing sectionObject: Section?) -> IndexPath? {
        let _wrap = SectionInfo(value: sectionObject)
        if let idx = _sections.index(of: _wrap) {
            return IndexPath.for(section: idx)
        }
        return nil
    }
    
    
    
    
    
    // MARK: - Helpers
    /*-------------------------------------------------------------------------------*/
    private func contains(object: Element) -> Bool {
        return _fetchedObjects.contains(object)
    }
    
    
    
    
    // MARK: - Logging
    /*-------------------------------------------------------------------------------*/
    private func printSectionOrderKeys() {
//        var str = "Section Ordering Keys:\n"
        
//            s.forEachKey(describing: _sections, do: { (k, o) in
//                str += "\(k): \(o._object?.value(forKey: k) ?? "-- Ungrouped")  "
//            })
//        print(str)
    }
    
    private func logSections() {
//        print("\(_sections.count) Sections")
//        for (idx, res) in _sections.enumerated() {
//            var str = "\(idx) - \(res.description(with: fetchRequest.sortDescriptors ?? []))"
//            print(str)
//        }
    }
    
    
    
    // MARK: - Storage Manipulation
    /*-------------------------------------------------------------------------------*/
    
    fileprivate func _insert(section: Section?) -> SectionInfo {
        if let s = self._sectionInfo(representing: section) { return s }
        if _sectionsCopy == nil { _sectionsCopy = _sections }
        let s = SectionInfo(value: section, objects: [])
        _sections.add(s)
        return s
    }
    
    private func _remove(_ section: Section?) {
        guard let ip = self._indexPathOfSection(representing: section) else { return }
        if _sectionsCopy == nil { _sectionsCopy = _sections }
        _sections.remove(at: ip._section)
    }
    
    func sortSections() {
        self._sections.sort()
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
    
    private var _fetched: Bool = false
    
    public var pendingChangeCount : Int {
        return pendingItemChangeCount
    }
    public var pendingItemChangeCount : Int {
        return context.objectChanges.count
    }
    
    public func performFetch() throws {
        
        guard self.fetchRequest.entityName != nil else {
            assertionFailure("fetch request must have an entity when performing fetch")
            throw ResultsControllerError.unknown
        }
        
        if !_fetched && delegate != nil {
            register()
        }
        _fetched = true
        
        self._sections.removeAll()
        
        let _objects = try managedObjectContext.fetch(self.fetchRequest)
        self.fetchedObjects = Set(_objects)
        if _objects.count == 0 { return }
        
        if let keyPath = self.sectionKeyPath {
            for object in _objects {
                
                let parentValue = object.value(forKey: keyPath) as? Section
                let p = self._insert(section: parentValue)
                p.insert(object)
                _objectSectionMap[object] = p
            }
            sortSections()
        }
        else {
            self._sections = [
                SectionInfo(value: nil, objects: _objects)
            ]
            
        }
    }
    
    
    
    func pause() {
        
    }
    

    
    
    // MARK: - Handling Changes
    /*-------------------------------------------------------------------------------*/
    
    private var context = ChangeContext<Element>()
    private var _sectionsCopy : OrderedSet<SectionInfo>?
    public private(set) var emptySectionChanges : ResultsChangeSet?
    
    func handleChangeNotification(_ notification: Notification) {
        
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
            if s.needsSort {
                s.sortItems(using: fetchRequest.sortDescriptors ?? [])
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
        _sectionsCopy = nil
        
        
        
//        var csrLog = "Performing Cross Section Reduction ------ "
//        var indent = 0
//        
        func appendCSRLog(_ string: String) {
            return;
//            csrLog += "\n"
//            for _ in 0..<indent {
//                csrLog += "\t"
//            }
//            csrLog += string
        }
        func reduceCrossSectional(_ object: Element, targetEdit tEdit: Edit<Element>? = nil) -> Bool {
            
            guard self.context.itemsWithSectionChange.remove(object) != nil else {
                return false
            }
            
//            indent += 1
//            defer {
//                indent -= 1
//            }
            
//            appendCSRLog("Reducing cross section edit for \(object.idSuffix):")
            
            guard let source = self.context.objectChanges.updated.index(of: object),
                let targetIP = self.indexPath(of: object),
                let targetSection = self._sectionInfo(at: targetIP) else {
                    appendCSRLog("No source/target for cross")
                    return true
            }
            
            guard let proposedEdit = tEdit ?? processedSections[targetSection]?.edit(for: object) else {
                appendCSRLog("Target: nil")
                return true
            }
            
            appendCSRLog("Target: \(targetIP) \(proposedEdit)")
            
            let newEdit = Edit(.move(origin: source._item), value: object, index: targetIP._item)
            processedSections[targetSection]?.operationIndex.moves.insert(newEdit, with: targetIP._item)
            appendCSRLog("Added move from \(source) to \(proposedEdit)")
            
            processedSections[targetSection]?.remove(edit: proposedEdit)
            appendCSRLog("Removed proposed edit \(proposedEdit)")
            
            if targetIP._item != proposedEdit.index {
                let old = processedSections[targetSection]?.edit(withSource: targetIP._item)
                appendCSRLog("Old edit at move to position: \(old)")
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
            
            if self.emptySectionChanges == nil {
                self.emptySectionChanges = ResultsChangeSet()
            }
            if old == 0 && _sections.count != 0 {
                self.emptySectionChanges?.addChange(forItemAt: IndexPath.zero, with: .delete)
            }
            else if old != 0 && _sections.count == 0 {
                self.emptySectionChanges?.addChange(forItemAt: nil, with: .insert(IndexPath.zero))
            }
        }
        else {
            self.emptySectionChanges = nil
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
                        
                    case let .move(origin: _):
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
            self.emptySectionChanges = nil
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
    
    
    

    
}



