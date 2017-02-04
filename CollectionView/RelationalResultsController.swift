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


fileprivate class RelationalSectionInfo<Section: NSManagedObject, Element: NSManagedObject>: ResultsControllerSectionInfo, Hashable, CustomStringConvertible {
    
    public var object : Any? { return self._object }
    public var objects: [Any] { return _storage.objects  }
    public var numberOfObjects: Int { return objects.count }
    
    fileprivate let _object : Section?
    
    private(set) var isEditing: Bool = false
    
    private(set) var _storage = OrderedSet<Element>()
    private var _storageCopy = OrderedSet<Element>()
    
    public var hashValue: Int {
        return _object?.hashValue ?? 0
    }
    
    public static func ==(lhs: RelationalSectionInfo, rhs: RelationalSectionInfo) -> Bool {
        return lhs._object == rhs._object
    }
    
    internal init(object: Section?, objects: [Element]) {
        self._object = object
        _storage.add(contentsOf: objects)
    }
    
    func index(for object: Element) -> Int? {
        return _storage.index(for: object)
    }
    
    func insert(_ object: Element, using sortDescriptors: [NSSortDescriptor] = []) -> Int {
        if self._storage.count == 0 {
            self._storage.add(object)
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
    var description: String {
        return description(with: [])
    }
    
    // MARK: - Editing
    /*-------------------------------------------------------------------------------*/
    
    private(set) var needsSort : Bool = false
    private var _added = Set<Element>() // Tracks added items needing sort, if one do insert for performance
    
    
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
    
    func endEditing() -> ChangeSet<OrderedSet<Element>> {
        assert(isEditing, "endEditing() called before beginEditing() for RelationalResultsControllerSection")
        assert(!needsSort, "endEditing() called but the section still needs to be sorted.")
        isEditing = false
        self.needsSort = false
        let changes = ChangeSet(source: _storageCopy, target: _storage)
        self._storageCopy.removeAll()
        return changes
    }
    
    func markNeedsSort() {
        self.needsSort = true
    }
    
    func add(_ element: Element) {
        guard self._storage.contains(element) == false else { return }
        self.needsSort = self._storage.count > 0
        _added.insert(element)
        self._storage.add(element)
    }
}


public class RelationalResultsController<Section: NSManagedObject, Element: NSManagedObject> : NSObject, ResultsController {
    
    
    fileprivate typealias SectionInfo = RelationalSectionInfo<Section, Element>
    
    
    
    
    // MARK: - Results Controller Protocol
    /*-------------------------------------------------------------------------------*/
    public var allObjects: [Any] { return _fetchedObjects.objects }
    public var sections: [ResultsControllerSectionInfo] { return _sections.objects }
    
    public var sectionFetchRequest : NSFetchRequest<Section>? { didSet { setNeedsFetch() }}
    public var fetchRequest = NSFetchRequest<Element>() { didSet { setNeedsFetch() }}
    
    
    private var _fetched: Bool = false
    
    func setNeedsFetch() {
        if _fetched {
            _fetched = false
            NotificationCenter.default.removeObserver(self, name: Notification.Name.NSManagedObjectContextObjectsDidChange, object: self.managedObjectContext)
        }
    }
    
    
    /// Simple way to get the name from the section object
    // Alternative method is to leave nil and conform class to CustomDisplayStringConvertible
    public var sectionNameKeyPath : String?
    
    public var sectionKeyPath: String = "" { didSet { setNeedsFetch() }}
    public let managedObjectContext: NSManagedObjectContext
    
    internal var _objectSectionMap = [Element:Int]() // Map between elements and the last group it was known to be in
    
    internal var _fetchedObjects = OrderedSet<Element>()
    private var _sections = OrderedSet<SectionInfo>()
    
    public var delegate: ResultsControllerDelegate? {
        didSet {
            if (oldValue == nil) == (delegate == nil) { return }
            if delegate == nil {
                NotificationCenter.default.removeObserver(self, name: Notification.Name.NSManagedObjectContextObjectsDidChange, object: self.managedObjectContext)
            }
            else if _fetched {
                NotificationCenter.default.addObserver(self, selector: #selector(handleChangeNotification(_:)), name: Notification.Name.NSManagedObjectContextObjectsDidChange, object: self.managedObjectContext)
            }
        }
    }
    
    public init(context: NSManagedObjectContext, request: NSFetchRequest<Element> = NSFetchRequest<Element>(), sectionRequest: NSFetchRequest<Section>? = nil, sectionKeyPath keyPath: String) {
        
        self.managedObjectContext = context
        super.init()
        
        self.fetchRequest = request
        self.sectionFetchRequest = sectionRequest
        self.sectionKeyPath = keyPath
    }
    
    
    
    // MARK: - Counts & Section Names
    /*-------------------------------------------------------------------------------*/
    
    public func numberOfSections() -> Int {
        return _sections.count
    }
    
    public func numberOfObjects(in section: Int) -> Int {
        return self._sections[section].objects.count
    }
    
    public func sectionName(forSectionAt indexPath: IndexPath) -> String {
        guard let obj = _section(for: indexPath)?._object else {
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
    public func section(for sectionIndexPath: IndexPath) -> ResultsControllerSectionInfo? {
        return self._section(for: sectionIndexPath)
    }
    
    public final func object(for sectionIndexPath: IndexPath) -> Any? {
        return self._object(for: sectionIndexPath)
    }
    public final func object(at indexPath: IndexPath) -> Any? {
        return self._object(at: indexPath)
    }
    
    
    // MARK: - Private Item Accessors
    /*-------------------------------------------------------------------------------*/
    private func _section(for sectionIndexPath: IndexPath) -> SectionInfo? {
        return self._section(at: sectionIndexPath._section)
    }
    private func _section(at sectionIndex: Int) -> SectionInfo? {
        return self._sections.object(at: sectionIndex)
    }
    
    private func _sectionWrapper(for section: Section?) -> SectionInfo? {
        guard let ip = self.indexPath(for: section) else { return nil }
        return self._section(for: ip)
    }
    
    public func _object(for sectionIndexPath: IndexPath) -> Section? {
        return self._sections.object(at: sectionIndexPath._section)._object
    }
    
    public func _object(at indexPath: IndexPath) -> Element? {
        return self._section(for: indexPath)?._storage.object(at: indexPath._item)
    }
    
    
    // MARK: - Getting IndexPaths
    /*-------------------------------------------------------------------------------*/
    public func indexPath(for object: Element) -> IndexPath? {
        
        if self.sectionKeyPath != nil {
            guard let sHash = self._objectSectionMap[object],
                let sIndex = self._sections.index(ofHash: sHash),
                let section = self._section(at: sIndex),
                let idx = section.index(for: object) else { return nil }
            
            return IndexPath.for(item: idx, section: sIndex)
        }
        else if let idx = _sections.first?.index(for: object) {
            return IndexPath.for(item: idx, section: 0)
        }
        return nil
    }
    public func indexPath(for sectionObject: Section?) -> IndexPath? {
        if let idx = _sections.index(ofHash: sectionObject?.hashValue ?? 0) {
            return IndexPath.for(section: idx)
        }
        return nil
    }
    
    
    // MARK: - Helpers
    /*-------------------------------------------------------------------------------*/
    
    private func contains(sectionObject: Section) -> Bool {
        let o = _sections[sectionObject.hashValue]
        return true
    }
    
    private func contains(object: Element) -> Bool {
        return _fetchedObjects.contains(object)
    }
    
    
    // MARK: - Logging
    /*-------------------------------------------------------------------------------*/
    private func printSectionOrderKeys() {
        var str = "Section Ordering Keys:\n"
        if let s = self.sectionFetchRequest?.sortDescriptors {
            s.forEachKey(describing: _sections, do: { (k, o) in
                str += "\(k): \(o._object?.value(forKey: k) ?? "-- Ungrouped")  "
            })
        }
        else {
            print("No section sort descriptors")
        }
        print(str)
    }
    
    
    
    // MARK: - Perform Fetch
    /*-------------------------------------------------------------------------------*/
    
    public func performFetch() throws {
        
        guard self.fetchRequest.entityName != nil else {
            assertionFailure("fetch request must have an entity when performing fetch")
            throw ResultsControllerError.unknown
        }
        
        let _objects = try managedObjectContext.fetch(fetchRequest)
        
        // Manage notification registration
        if !_fetched && delegate != nil {
            NotificationCenter.default.addObserver(self, selector: #selector(handleChangeNotification(_:)), name: Notification.Name.NSManagedObjectContextObjectsDidChange, object: self.managedObjectContext)
        }
        _fetched = true
        
        self._sections.removeAll()
        
        // Add the queried sections
        if let sectionRQ = self.sectionFetchRequest {
            for s in try managedObjectContext.fetch(sectionRQ) {
                self._insert(section: s)
            }
        }
        
        // Add the object into sections
        // No need to sort since they were just fetched with the sort descriptors
        for object in _objects {
            if let parent = object.value(forKey: sectionKeyPath) as? Section {
                var p = self._insert(section: parent)
                p.insert(object)
                _objectSectionMap[object] = parent.hashValue
            }
            else {
                let s = self._insert(section: nil)
                s.insert(object)
                _objectSectionMap[object] = 0
            }
        }
        
        // Sort the sections all at once
        self.sortSections()
    }
    
    

    
    
    
    // MARK: - Storage Manipulation
    /*-------------------------------------------------------------------------------*/
    
    fileprivate func _insert(section: Section?) -> SectionInfo {
        if let s = self._sectionWrapper(for: section) { return s }
        let s = SectionInfo(object: section, objects: [])
        _sections.add(s)
        return s
    }
    
    private func _remove(_ section: Section?) {
        guard let ip = self.indexPath(for: section) else { return }
        _sections.remove(at: ip._section)
    }
    
    func sortSections() {
        guard let sort = sectionFetchRequest?.sortDescriptors, sort.count > 0 else {
            return
        }
        
        let s = self._sections.sorted(by: { (s1, s2) -> Bool in
            
            // Always put ungroued at the bottom, maybe this should be an option
            if s1.object == nil || s2.object == nil {
                return s1.object != nil
            }
            
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
    
    func handleChangeNotification(_ notification: Notification) {
        
        self.delegate?.controllerWillChangeContent(controller: self)
        
        self.context.reset()
        
        print("•••••••••••••••• Start ••••••••••••••••")
        logSections()
        print("---------------------------------------")
        
        
        preprocess(notification: notification)
        
        print(context.sectionChangeSet)
        print(context.objectChangeSet)

        processDeletedSections()
        processInsertedSections()
        processUpdatedSections()
        
        processDeletedObjects()
        processInsertedObjects()
        processUpdatedObjects()
        
        // Hang on to the changes for each section to lookup sources for items
        // that were move to a new section
        var processedSections = [SectionInfo:ChangeSet<OrderedSet<Element>>]()
        var convertedIO = Set<Element>()
        
        
        print("BEFORE cross sectional reduction")
        for s in _sections {
            if s.needsSort {
                s.sortItems(using: fetchRequest.sortDescriptors ?? [])
            }
            if s.isEditing {
                let set = s.endEditing()
                processedSections[s] = set
                print(set)
            }
        }
        
        
        
        func reduceCrossSectional(_ object: Element) {
            
            guard self.context.itemsWithSectionChange.remove(object) != nil else {
                return
            }
            
            guard let source = self.context.objectChangeSet.updated.index(of: object),
                let target = self.indexPath(for: object),
                let targetSection = self._section(for: target) else {
                    return
            }
            
            guard let targetEdit = processedSections[targetSection]?.edit(for: object) else { return }
            
            let newEdit = Edit(.move(origin: source._item), value: object, destination: target._section)
            processedSections[targetSection]?.operationIndex.moves.insert(newEdit, with: newEdit)
            
            switch targetEdit.operation {
            case .insertion:
                // Adding the new edit above should overwrite the old one
                processedSections[targetSection]?.operationIndex.inserts.remove(targetEdit)
                break;
                
            case .substitution:
                processedSections[targetSection]?.operationIndex.substitutions.remove(targetEdit)
                
                guard let oldObj = self.context.objectChangeSet.object(for: target) else { return }
                let delete = Edit(.deletion, value: oldObj, destination: source._item)
                processedSections[targetSection]?.operationIndex.deletes.insert(delete, with: delete)
                
            case .deletion:
                // Not sure if this actually happens or not
                 processedSections[targetSection]?.operationIndex.inserts.remove(targetEdit)
                 print("Deletion edit available at target index")
                break;
                 
            case .move(_):
            // I don't think this sould be ablet to happen
                break;
            }
            
            /*
             // sourceSection will be nil if if was deleted (ObjectChangeSet can only lookup by index for inserted/updated)
             //
             // If so, complete the move and handle the old target operation
             //
             // Note: since the old section was removed, no operations will be processed for it
             // there is no need then to handle updating/removing the source edit
             */
            guard let sourceSection = self.context.sectionChangeSet.object(for: source._section),
                let sourceWrap = _sectionWrapper(for: sourceSection),
                let sourceEdit = processedSections[sourceWrap]?.edit(for: object) else {
                    return
            }
            
            switch sourceEdit.operation {
            case .deletion:
                processedSections[sourceWrap]?.operationIndex.deletes.remove(sourceEdit)
                break;
                
            case .substitution:
                guard let obj = self._object(at: source) else {
                    processedSections[sourceWrap]?.operationIndex.substitutions.remove(sourceEdit)
                    return
                }
                reduceCrossSectional(obj)
//                processedSections[sourceWrap]?.operationIndex.substitutions.remove(sourceEdit)
                //                let insert = sourceEdit.copy(with: .insertion)
                
//                let insert = Edit(.insertion, value: obj, destination: source._item)
//                processedSections[sourceWrap]?.operationIndex.inserts.insert(insert, with: insert)
                
            case .insertion, .move(_):
                // The target edit can't be a insert/move if it didn't contain the object to begin
                break;
            }
        }
        
        
        while let obj = self.context.itemsWithSectionChange.first {
            reduceCrossSectional(obj)
        }
        
        print("\nAFTER cross sectional reduction")
        for s in processedSections {
            print("\(self.indexPath(for: s.key._object)) \(s.value)")
        }
        
        
        for s in processedSections {
            var changes = s.value
            changes.reduceEdits()
            
            // Could merge all the edits together to dispatch the delegate calls in order of operation
            // but there is no apparent reason why order is important.
            
            for edit in changes.edits {
                switch edit.operation {
                    
                case let .move(origin: from):
                    guard let source = self.context.objectChangeSet.updated.index(of: edit.value),
                    let sectionIndex = self._sections.index(for: s.key),
                    let dest = self.indexPath(for: edit.value) else { continue }
                    
                    self.delegate?.controller(self, didChangeObject: edit.value, at: source, for: .move(dest))
                    
                case .substitution:
                    guard let source = self.context.objectChangeSet.updated.index(of: edit.value),
                        let destination = self.indexPath(for: edit.value) else { continue }
                    self.delegate?.controller(self, didChangeObject: edit.value, at: source, for: .update(destination))
                    
                case .insertion:
                    guard let ip = self.indexPath(for: edit.value) else { continue  }
                    self.delegate?.controller(self, didChangeObject: edit.value, at: nil, for: .insert(ip))
                    
                case .deletion:
                    guard let source = self.context.objectChangeSet.deleted.index(of: edit.value) else { continue }
                    self.delegate?.controller(self, didChangeObject: edit.value, at: source, for: .delete)
                }
            }
        }
        
        print("\nAFTER final reduction")
        for s in processedSections {
            print("\(self.indexPath(for: s.key._object)) \(s.value)")
        }
        
        
        /*
        func endEditing(for section: SectionInfo) -> ChangeSet<OrderedSet<Element>>? {
            if let s = processedSections[section] {
                return s
            }
            if !section.isEditing { return nil }
            
            guard let sectionIndex = self.indexPath(for: section._object)?._section else {
                print("IndexPath not found for section containing updated objects")
                return nil
            }
            if section.needsSort {
                section.sortItems(using: fetchRequest.sortDescriptors ?? [])
            }
            
            let changeSet = section.endEditing()
            processedSections[section] = changeSet
            
            
            for edit in changeSet.edits {
                switch edit.operation {
                    
                case let .move(origin: from):
                    
                    guard let source = self.context.objectChangeSet.updated.index(of: edit.value) else { continue }
                    let dest = IndexPath.for(item: edit.destination, section: sectionIndex)
                    
                    self.delegate?.controller(self, didChangeObject: edit.value, at: source, for: .move(dest))
                    
                case .substitution:
                    guard let source = self.context.objectChangeSet.updated.index(of: edit.value),
                        let destination = self.indexPath(for: edit.value)
                        else { continue }
                    self.delegate?.controller(self, didChangeObject: edit.value, at: source, for: .update(destination))
                    
                case .insertion:
                    
                    guard let ip = self.indexPath(for: edit.value) else { continue  }
                    
                    // If the item existed, it muse have come from a different sectio, convert to move
                    if let oldIP = context.objectChangeSet.updated.index(of: edit.value) {
                        if convertedIO.contains(edit.value) { continue }
                        
                        let oldSection = self.context.sectionChangeSet
                        
                        self.delegate?.controller(self, didChangeObject: edit.value, at: oldIP, for: .move(ip))
                        continue
                    }
                    self.delegate?.controller(self, didChangeObject: edit.value, at: nil, for: .insert(ip))
                    
                case .deletion:
                    
                    // If the item still exists, it muse have moved to a different section
                    // The complimentary is converted to a above, ignore it here
                    if let newIP = self.indexPath(for: edit.value) {
                        continue
                    }

                    if let source = self.context.objectChangeSet.deleted.index(of: edit.value) {
                        self.delegate?.controller(self, didChangeObject: edit.value, at: source, for: .delete)
                        continue
                    }
                }
            }
            return changeSet
        }
        
        
        for s in _sections {
            endEditing(for: s)
        }
 */
        
        
        self.delegate?.controllerDidChangeContent(controller: self)
        
        print("----------------- AFTER ----------------")
        print(context)
        logSections()
        print("•••••••••••••••• END •••••••••••••••••••")
    }
    
    private func logSections() {
        print("\(_sections.count) Sections")
        for (idx, res) in _sections.enumerated() {
            var str = "\(idx) - \(res.description(with: fetchRequest.sortDescriptors ?? []))"
            print(str)
        }
    }
    
    func preprocess(notification: Notification) {
        
        var sections = ObjectChangeSet<Int, Section>()
        var objects = ObjectChangeSet<IndexPath, Element>()
        
        guard let info = notification.userInfo else {
            return
        }
        
        
        // Deleted
        var deleted = (info[NSDeletedObjectsKey] as? Set<NSManagedObject>) ?? Set<NSManagedObject>()
        if let invalidated = info[NSInvalidatedObjectsKey] as? Set<NSManagedObject> {
            deleted = deleted.union(invalidated)
        }
        for obj in deleted {
            if let o = obj as? Element, let ip = self.indexPath(for: o) {
                objects.add(deleted: o, for: ip)
            }
            else if let o = obj as? Section, let ip = self.indexPath(for: o) {
                sections.add(deleted: o, for: ip._section)
            }
        }
        
        
        // Inserted
        if let inserted = info[NSInsertedObjectsKey] as? Set<NSManagedObject> {
            for obj in inserted {
                if let o = obj as? Element, o.entity == fetchRequest.entity {
                    if fetchRequest.predicate == nil || fetchRequest.predicate?.evaluate(with: 0) == true {
                        objects.add(inserted: o)
                    }
                }
                else if let o = obj as? Section,
                    let sectionRQ = self.sectionFetchRequest,
                    o.entity == sectionRQ.entity,
                    (sectionRQ.predicate == nil || sectionRQ.predicate?.evaluate(with: o) == true) {
                    sections.add(inserted: o)
                }
            }
        }

        
        // Updated
        if let updated = info[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
            for obj in updated {
                if let o = obj as? Section {
                    
                    let _ip = self.indexPath(for: o)
                    // If there is a sectionRQ, compare against it
                    if let sectionRQ = self.sectionFetchRequest, o.entity == sectionRQ.entity {
                        
                        let match = sectionRQ.predicate == nil || sectionRQ.predicate?.evaluate(with: o) == true
                        
                        if let ip = _ip {
                            if !match { sections.add(deleted: o, for: ip._section) }
                            else { sections.add(updated: o, for: ip._section) }
                        }
                        else if match {
                            sections.add(inserted: o)
                        }
                        
//                        print(o.changedValuesForCurrentEvent())
//                        print(o.changedValues())
//                        print(o.committedValues(forKeys: []))
                        
                    }
                        // No sectionRQ, add it to updated to check order
                    else if let ip = _ip {
                        sections.add(updated: o, for: ip._section)
                    }
                }
                else if let o = obj as? Element, fetchRequest.entity == o.entity {
                    
                    let _ip = self.indexPath(for: o)
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
            guard let ip = self.indexPath(for: object) else { continue }
            
            let section = self._sections[ip._section]
            for obj in section._storage {
                _objectSectionMap[obj] = nil
            }
            
            _sections._batchRemove(at: ip._section)
        }
    }
    
    private func processInsertedSections() {
        for object in context.sectionChangeSet.inserted {
            self._insert(section: object)
        }
    }
  
    private func processUpdatedSections() {
        for change in context.sectionChangeSet.updated {
            // Check ordering ??
            _sections.needsSort = true
            
            // Not sure what else to do here for now.
        }
    }
    
    private func postProcesssSections() {
        if _sections.needsSort {
            _sections.sort(using: sectionFetchRequest?.sortDescriptors ?? [])
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
            
            if section.objects.count == 0 {
                // If the section object matches the section predicat, keep it.
                if let req = self.sectionFetchRequest,
                    let obj = section._object {
                    if req.predicate == nil || req.predicate?.evaluate(with: obj) == true { continue }
                }
                _remove(section._object)
            }
        }
    }
    
    func processInsertedObjects() {
        
        for object in context.objectChangeSet.inserted {
            
            guard self.contains(object: object) == false else { continue }
            
//            var newIP = IndexPath.Zero
            let sort = self.fetchRequest.sortDescriptors ?? []
            
            let sectionValue = object.value(forKeyPath: self.sectionKeyPath) as? Section
            
            if let existingIP = self.indexPath(for: sectionValue),
                let existingSection = self._section(for: existingIP) {
                
                existingSection.ensureEditing()
                existingSection.add(object)
                _objectSectionMap[object] = existingSection.hashValue
                
                // Should items in inserted sections be included?
            }
            else {
                // The section value doesn't exist yet, the section will be inserted
                let sec = SectionInfo(object: sectionValue, objects: [object])
//                newIP = IndexPath.for(item: 0, section: _sections.count)
                self._sections.add(sec)
                _objectSectionMap[object] = sec.hashValue
            }

//            context.inserted(object, at: newIP)
        }
    }
    
    
    func processUpdatedObjects() {
        
        var updatedSections = Set<SectionInfo>()
        
        for change in context.objectChangeSet.updated {
            
            let object = change.value
            let sourceIP = change.index
            
            guard let tempIP = self.indexPath(for: object),
                let currentSection = _section(for: tempIP) else {
                    print("Skipping object update")
                    continue
            }
            currentSection.ensureEditing()
            
            let sort = self.fetchRequest.sortDescriptors ?? []
            var destinationIP = tempIP
            
            let sectionValue = object.value(forKeyPath: sectionKeyPath) as? Section
            
            // Move within the same section
            if sectionValue == currentSection._object {
                currentSection.markNeedsSort()
                _objectSectionMap[object] = currentSection.hashValue
            }
                
                // Moved to another section
            else if let newSip = self.indexPath(for: sectionValue),
                let newSection = self._section(for: newSip) {
                currentSection.remove(object)
                newSection.ensureEditing()
                newSection.add(object)
                self.context.itemsWithSectionChange.insert(object)
                _objectSectionMap[object] = newSection.hashValue
            }
                
                // Move to new section
            else {
                // The section value doesn't exist yet, the section will be inserted
                let sec = self._insert(section: sectionValue)
                sec.ensureEditing()
                sec.add(object)
                _objectSectionMap[object] = sec.hashValue
            }
            
        }
    }
    

}

