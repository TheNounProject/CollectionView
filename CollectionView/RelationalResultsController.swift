//
//  RelationalResultsController.swift
//  CollectionView
//
//  Created by Wesley Byrne on 1/12/17.
//  Copyright © 2017 Noun Project. All rights reserved.
//

import Foundation





fileprivate struct UpdateContext<Section: NSManagedObject, Element:NSManagedObject> : CustomStringConvertible {
    
    typealias SectionWrapper = RelationalResultsControllerSection<Section, Element>

    // Changes from context
    var objectChangeSet = ObjectChangeSet<IndexPath, Element>()
    var sectionChangeSet = ObjectChangeSet<IndexPath, Section>()
    
    // Object changes
    var deleted = IndexedSet<IndexPath,Element>()
    var inserted = IndexedSet<IndexPath, Element>()
    var moved = IndexedSet<IndexPath,Element>()
    var updated = Set<Element>()
    
    // Section Changes
    var insertedSections = IndexedSet<IndexPath, SectionWrapper>()
    var deletedSections = IndexedSet<IndexPath, SectionWrapper>()
    var movedSections = IndexedSet<IndexPath, SectionWrapper>()
    var updatedSections = Set<SectionWrapper>()
    
    
    
    mutating func deleted(_ object: Element, at indexPath: IndexPath) {
        self.deleted.insert(object, for: indexPath)
    }
    
    mutating func inserted(_ object: Element, at indexPath: IndexPath) {
        self.inserted.insert(object, for: indexPath)
    }
    mutating func updated(_ object: Element, at indexPath: IndexPath, to newIndexPath: IndexPath?) {
        if let ip = newIndexPath, ip != indexPath {
            moved.insert(object, for: indexPath)
        }
        else {
            self.updated.insert(object)
        }
    }
    
    
    mutating func deleted(_ section: SectionWrapper, at indexPath: IndexPath) {
        self.deletedSections.insert(section, for: indexPath)
    }
    mutating func inserted(_ section: SectionWrapper, at indexPath: IndexPath) {
        self.insertedSections.insert(section, for: indexPath)
    }
    mutating func updated(_ section: SectionWrapper, at indexPath: IndexPath, to newIndexPath: IndexPath?) {
        if let ip = newIndexPath, ip._section != indexPath._section {
            movedSections.insert(section, for: indexPath)
        }
        else {
            self.updatedSections.insert(section)
        }
    }
    
    
    
//    mutating func add(object: Element, at currentIndex: IndexPath?, for change
//        : ResultsControllerChangeType) {
//        
//        switch change {
//        case .delete:
//            
//            deleted.
//            
//        default:
//            <#code#>
//        }
//        
//        if let i = oldIndex {
//            updated.insert(object, for: i)
//        }
//        
//        else if oldIndex == nil, let i = newIndex {
//            if self.insertedSections.contains(i) { return }
//            inserted.insert(object, for: i)
//        }
//        else if newIndex == nil, let i = oldIndex {
//            deleted.insert(object, for: i)
//        }
//        
//    }
    
    
//    mutating func add(section: SectionWrapper, old oldIndex: IndexPath?, new newIndex: IndexPath?) {
//        
//        if oldIndex == nil, let i = newIndex {
//            insertedSections.insert(section, for: i)
//        }
//        else if newIndex == nil, let i = oldIndex {
//            deletedSections.insert(section, for: i)
//        }
//        else if let i = oldIndex {
//            updatedSections.insert(section, for: i)
//        }
//    }
    
    mutating func reset() {
        self.sectionChangeSet.reset()
        self.objectChangeSet.reset()
        
        inserted.removeAll()
        deleted.removeAll()
        updated.removeAll()
        moved.removeAll()
        insertedSections.removeAll()
        deletedSections.removeAll()
        updatedSections.removeAll()
        movedSections.removeAll()
    }
    
    var description: String {
        return "Context Items: \(deleted.count) Deleted, \(inserted.count) Inserted, \(updated.count) Updated, \(moved.count) Moved\n"
        + "Context Sections: \(insertedSections.count) Inserted, \(deletedSections.count) Deleted \(updatedSections.count) Updated, \(movedSections.count) Moved"
    }
}




class RelationalResultsControllerSection<Section: NSManagedObject, Element: NSManagedObject>: ResultsControllerSection, Hashable {
    
    public var object : Any? { return self._object }
    public var objects: [NSManagedObject] { return _objects }
    
    public var count : Int { return objects.count }
    
    public let _object : Section?
    private(set) public var _objects : [Element] = []
    
    private var _map = [Element:Int]()
    
    fileprivate var needsSort : Bool = false
    
    public var hashValue: Int {
        return _object?.hashValue ?? 0
    }
    
    public static func ==(lhs: RelationalResultsControllerSection, rhs: RelationalResultsControllerSection) -> Bool {
        return lhs._object == rhs._object
    }
    
    internal init(object: Section?, objects: [Element]) {
        self._object = object
        self._objects = objects
        for (idx, obj) in _objects.enumerated() {
            _map[obj] = idx
        }
    }
    
    func index(for object: Element) -> Int? {
        return _map[object]
    }
    
    func insert(_ object: Element, using sortDescriptors: [NSSortDescriptor] = []) -> Int {
        let start = _objects.insert(object, using: sortDescriptors)
        for idx in start..<objects.count {
            _map[_objects[idx]] = idx
        }
//        print(_map)
        return start
    }
    func remove(_ object: Element) -> Int? {
        guard let start = _map.removeValue(forKey: object) else { return nil }
        _objects.remove(at: start)
        for idx in start..<_objects.count {
            _map[_objects[idx]] = idx
        }
        return start
    }
    
    func sortItems(using sortDescriptors: [NSSortDescriptor]) {
        self._objects.sort(using: sortDescriptors)
        self._map.removeAll(keepingCapacity: true)
        for (idx, obj) in self._objects.enumerated() {
            self._map[obj] = idx
        }
    }
}



public class RelationalResultsController<Section: NSManagedObject, Element: NSManagedObject> : NSObject, ResultsController {
    
    typealias SectionWrapper = RelationalResultsControllerSection<Section, Element>
    
    private var _fetched: Bool = false
    
    
    func setNeedsFetch() {
        if _fetched {
            _fetched = false
            NotificationCenter.default.removeObserver(self, name: Notification.Name.NSManagedObjectContextObjectsDidChange, object: self.managedObjectContext)
        }
    }
    
    
    public var sectionFetchRequest : NSFetchRequest<Section>? { didSet { setNeedsFetch() }}
    public var fetchRequest = NSFetchRequest<Element>() { didSet { setNeedsFetch() }}
    
    
    /// Simple way to get the name from the section object
    // Alternative method is to leave nil and conform class to CustomDisplayStringConvertible
    public var sectionNameKeyPath : String?
    
    public var sectionKeyPath: String = "" { didSet { setNeedsFetch() }}
    public let managedObjectContext: NSManagedObjectContext
    
    
    internal var _objectMap = [Element:Int]() // Map between elements and the last group it was known to be in
    internal var _sectionMap = [Int:IndexPath]() // Key is hash value of section object, 0 is ungrouped
    
//    internal var allObjects = Set<Element>()
    
    internal var _fetchedObjects = [Element]()
    internal var _fetchedSections = OrderedSet<Section>()
    
    private var _sections = [SectionWrapper]()
    
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
    public func section(for sectionIndexPath: IndexPath) -> ResultsControllerSection? {
        return self._section(for: sectionIndexPath)
    }
    
    public final func object(for sectionIndexPath: IndexPath) -> Any? {
        return self._object(for: sectionIndexPath)
    }
    public final func object(at indexPath: IndexPath) -> NSManagedObject? {
        return self._object(at: indexPath)
    }
    
    
    // MARK: - Private Item Accessors
    /*-------------------------------------------------------------------------------*/
    private func _section(for sectionIndexPath: IndexPath) -> SectionWrapper? {
        return self._sections.object(at: sectionIndexPath._section)
    }
    
    public func _object(for sectionIndexPath: IndexPath) -> Section? {
        return self._sections.object(at: sectionIndexPath._section)?._object
    }
    
    public func _object(at indexPath: IndexPath) -> Element? {
        return self._sections.object(at: indexPath._section)?._objects.object(at: indexPath._item)
    }
    
    
    // MARK: - Getting IndexPaths
    /*-------------------------------------------------------------------------------*/
    public func indexPath(for object: Element) -> IndexPath? {
        
        if self.sectionKeyPath != nil {
            guard let sHash = self._objectMap[object],
                let sIndex = self._sectionMap[sHash],
                let section = self._section(for: sIndex),
                let idx = section.index(for: object) else { return nil }
            
            return IndexPath.for(item: idx, section: sIndex._section)
        }
        else if let idx = _sections.first?.index(for: object) {
            return IndexPath.for(item: idx, section: 0)
        }
        return nil
    }
    public func indexPath(for sectionObject: Section?) -> IndexPath? {
        return _sectionMap[sectionObject?.hashValue ?? 0]
    }
    
    public func performFetch() throws {
        
        guard self.fetchRequest.entityName != nil else {
            assertionFailure("fetch request must have an entity when performing fetch")
            throw ResultsControllerError.unknown
        }
        
        let _objects = try managedObjectContext.fetch(fetchRequest)
        
        if !_fetched && delegate != nil {
            NotificationCenter.default.addObserver(self, selector: #selector(handleChangeNotification(_:)), name: Notification.Name.NSManagedObjectContextObjectsDidChange, object: self.managedObjectContext)
        }
        _fetched = true
        
        var unordered = [Section : SectionWrapper]()
        var orphans = [Element]()
        
        if let sectionRQ = self.sectionFetchRequest {
            for s in try managedObjectContext.fetch(sectionRQ) {
                if unordered[s] == nil {
                    unordered[s] = SectionWrapper(object: s, objects: [])
                }
            }
        }
        
        for object in _objects {
            
            if let parent = object.value(forKey: sectionKeyPath) as? Section {
                if let existing = unordered[parent] {
                    _ = existing.insert(object)
                }
                else {
                    unordered[parent] = SectionWrapper(object: parent, objects: [object])
                }
                _objectMap[object] = parent.hashValue
            }
            else {
                orphans.append(object)
                _objectMap[object] = 0
            }
            
        }
        
        func printSectionOrder() {
            var keys = [String]()
            for s in self.sectionFetchRequest?.sortDescriptors ?? [] {
                if let k = s.key {
                    keys.append(k)
                }
                
            }
            
            guard keys.count > 0 else {
                print("No sort descriptor keys to print")
                return
            }
            
            var str = "Section Order:\n"
            
            
            for s in self._fetchedSections {
                var oStr = ""
                for k in keys {
                    oStr += "\(k): \(s.value(forKey: k))  "
                }
                str += oStr
            }
        }
        
        self._fetchedSections = OrderedSet<Section>(elements:  unordered.keys)
        self._fetchedSections.sort(using: self.sectionFetchRequest?.sortDescriptors ?? [])
        
        var _tempSections = [SectionWrapper]()
        for (idx, s) in self._fetchedSections.enumerated() {
            let sec = unordered[s]!
            self._sectionMap[s.hashValue] = IndexPath.for(section: idx)
            sec.sortItems(using: fetchRequest.sortDescriptors ?? [])
            _tempSections.append(sec)
        }
        
        if orphans.count > 0 {
            self._sectionMap[0] = IndexPath.for(section: _tempSections.count)
            _tempSections.append(SectionWrapper(object: nil, objects: orphans.sorted(using: fetchRequest.sortDescriptors ?? [])))
        }
        
        self._sections = _tempSections
    }
    
    // MARK: - Helpers
    /*-------------------------------------------------------------------------------*/
    
    private func contains(sectionObject: Section) -> Bool {
        return _sectionMap[sectionObject.hashValue] != nil
    }
    
    private func contains(object: Element) -> Bool {
        return _objectMap[object] != nil
    }
    
    
    // MARK: - Handling Changes
    /*-------------------------------------------------------------------------------*/
    
    fileprivate var context = UpdateContext<Section, Element>()
    
    func handleChangeNotification(_ notification: Notification) {
        
        self.delegate?.controllerWillChangeContent(controller: self)
        
        self.context.reset()
        
        print("•••••••••••••••• Start ••••••••••••••••")
        print("\(_sections.count) Sections (\(_fetchedSections.count) Fetched)")
        for (idx, res) in _sections.enumerated() {
            print("\(idx) - \(res.objects.count) Objects")
        }
        print("---------------------------------------")
        
        
        preprocess(notification: notification)
        
        print(context.sectionChangeSet)
        print(context.objectChangeSet)

        processDeletedSections()
        
        for change in context.deletedSections {
            self.delegate?.controller(self, didChangeSection: change.object, at: change.index, for: .delete)
        }
        processInsertedSections()
        
        for change in context.insertedSections {
            guard let newIP = self.indexPath(for: change.object._object) else { continue }
            self.delegate?.controller(self, didChangeSection: change.object, at: change.index, for: .insert(newIP))
        }
        
        processUpdatedSections()
        
        for change in context.movedSections {
            guard let newIP = self.indexPath(for: change.object._object) else { continue }
            self.delegate?.controller(self, didChangeSection: change.object, at: change.index, for: .move(newIP))
        }
        for object in context.updatedSections {
            guard let newIP = self.indexPath(for: object._object) else { continue }
//            let type : ResultsControllerChangeType = (old == newIP) ? .update : .move(newIP)
            self.delegate?.controller(self, didChangeSection: object, at: newIP, for: .update)
        }
        
        
        processDeletedObjects()
        processInsertedObjects()
        processUpdatedObjects()
        
        for change in context.deleted {
            self.delegate?.controller(self, didChangeObject: change.object, at: change.index, for: .delete)
        }
        for change in context.inserted {
            guard let newIP = self.indexPath(for: change.object) else { continue }
            self.delegate?.controller(self, didChangeObject: change.object, at: change.index, for: .insert(newIP))
        }
        for change in context.moved {
            guard let newIP = self.indexPath(for: change.object) else { continue }
            
            self.delegate?.controller(self, didChangeObject: change.object, at: change.index, for: .insert(newIP))
        }
        for object in context.updated {
            guard let newIP = self.indexPath(for: object) else { continue }
//            let old : IndexPath = change.index
//            let type : ResultsControllerChangeType = (old == newIP) ? .update : .move(newIP)
            self.delegate?.controller(self, didChangeObject: object, at: newIP, for: .update)
        }
        
        self.delegate?.controllerDidChangeContent(controller: self)
        
        print("----------------- AFTER ----------------")
        print(context)
        
        print("\(_sections.count) Sections (\(_fetchedSections.count) Fetched)")
        for (idx, res) in _sections.enumerated() {
            print("\(idx) - \(res.objects.count) Objects")
        }
        print("•••••••••••••••• END •••••••••••••••••••")
    }
    
    
    func preprocess(notification: Notification) {
        
        var sections = ObjectChangeSet<IndexPath, Section>()
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
                sections.add(deleted: o, for: ip)
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
                            if !match { sections.add(deleted: o, for: ip) }
                            else { sections.add(updated: o, for: ip) }
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
                        sections.add(updated: o, for: ip)
                    }
                }
                else if let o = obj as? Element, fetchRequest.entity == o.entity {
                    
                    let _ip = self.indexPath(for: o)
                    let match = fetchRequest.predicate == nil || fetchRequest.predicate?.evaluate(with: o) == true
                    
                    if let ip = _ip, sections.deleted.contains(ip.sectionCopy) == false {
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
            
            let object = change.object
            guard let ip = self.indexPath(for: object) else { continue }
            
            let section = self._sections[ip._section]
            context.deleted(section, at: ip.sectionCopy)
            
            for obj in section._objects {
                _objectMap[obj] = nil
            }
            _removeSection(section._object)
        }
    }
    
    
    private func processInsertedSections() {
        for object in context.sectionChangeSet.inserted {
            
            let index = _fetchedSections.insert(object, using: sectionFetchRequest?.sortDescriptors ?? [])
            
            let ip = IndexPath.for(section: index)
            
            _sectionMap[object.hashValue] = ip
            let s = SectionWrapper(object: object, objects: [])
            _sections.insert(s, at: index)
            
            for idx in index+1..<_sections.count {
                _sectionMap[_sections[idx].hashValue] = IndexPath.for(section: idx)
            }
            context.inserted(s, at: ip)
        }
    }
    
    private func _removeSection(_ section: Section?) {
        
        guard let ip = self.indexPath(for: section) else { return }
        
        _sectionMap[section?.hashValue ?? 0] = nil
        _sections.remove(at: ip._section)
        if section != nil {
            _fetchedSections.remove(at: ip._section)
        }
        
        for idx in ip._section..<_sections.count {
            _sectionMap[_sections[idx].hashValue] = IndexPath.for(section: idx)
        }
    }
    
    
    private func processUpdatedSections() {
        for change in context.sectionChangeSet.updated {
            
            guard let currentIP = self.indexPath(for: change.object),
                let section = _section(for: currentIP) else { continue }
            
            let sort = self.sectionFetchRequest?.sortDescriptors ?? []
            let newIndex = self._fetchedSections.insert(change.object, using: sort)
            
            context.updated(section, at: currentIP, to: IndexPath.for(section: newIndex))
            
//            context.add(section: section, old: change.index, new: currentIP)
            
            //
            //                // Moved to another section
            //            if let newSip = self.indexPath(for: sectionValue),
            //                let newSection = self._section(for: newSip) {
            //                newIP = newIP.copy(item: newSection.insert(object, using: sort))
            //                _objectMap[object] = newSection.hashValue
            //            }
            //
            //                // Move to new section
            //            else {
            //                // The section value doesn't exist yet, the section will be inserted
            //                let sec = SectionWrapper(object: sectionValue, objects: [object])
            //                newIP = newIP.copy(item: self._sections.count)
            //                self._sections.append(sec)
            //                _sectionMap[sectionValue?.hashValue ?? 0] = newIP.sectionCopy
            //                _objectMap[object] = sec.hashValue
            //            }
            //            
            //            context.add(object: object, old: cIP, new: newIP)
        }
    }
    
    
    
    // MARK: - Object Processing
    /*-------------------------------------------------------------------------------*/
    
    func processUpdatedObjects() {
        
        for change in context.objectChangeSet.updated {
            
            let object = change.object
            
            guard let cIP = self.indexPath(for: object),
                let currentSection = _section(for: cIP) else { continue }
            
            let sort = self.fetchRequest.sortDescriptors ?? []
            _ = currentSection.remove(object)
            
            var newIP = cIP
            
            let sectionValue = object.value(forKeyPath: sectionKeyPath) as? Section
            
            // Same group
            if sectionValue == currentSection._object {
                newIP = newIP.copy(item: currentSection.insert(object, using: sort))
                _objectMap[object] = currentSection.hashValue
            }
                
                // Moved to another section
            else if let newSip = self.indexPath(for: sectionValue),
                let newSection = self._section(for: newSip) {
                newIP = newIP.copy(item: newSection.insert(object, using: sort))
                _objectMap[object] = newSection.hashValue
            }
                
                // Move to new section
            else {
                // The section value doesn't exist yet, the section will be inserted
                let sec = SectionWrapper(object: sectionValue, objects: [object])
                newIP = newIP.copy(item: self._sections.count)
                self._sections.append(sec)
                _sectionMap[sectionValue?.hashValue ?? 0] = newIP.sectionCopy
                _objectMap[object] = sec.hashValue
            }
            
            context.updated(object, at: cIP, to: newIP)
        }
    }
    
    func processInsertedObjects() {
        
        for object in context.objectChangeSet.inserted {
            
            guard self.contains(object: object) == false else { continue }
            
            var newIP = IndexPath.Zero
            let sort = self.fetchRequest.sortDescriptors ?? []
            
            let sectionValue = object.value(forKeyPath: self.sectionKeyPath) as? Section
            
            if let existingIP = self.indexPath(for: sectionValue),
                let existingSection = self._section(for: existingIP) {
                
                newIP = existingIP.copy(item: existingSection.insert(object, using: sort))
                _objectMap[object] = existingSection.hashValue
                
                if context.insertedSections.contains(existingSection) {
                    // If the section was just inserted, no need to report items within it
                    continue
                }
            }
            else {
                // The section value doesn't exist yet, the section will be inserted
                let sec = SectionWrapper(object: sectionValue, objects: [object])
                newIP = IndexPath.for(item: 0, section: _sections.count)
                self._sections.append(sec)
                _sectionMap[sectionValue?.hashValue ?? 0] = newIP.sectionCopy
                _objectMap[object] = sec.hashValue
            }
            //            }
            //            else if let section = self._sections.first {
            //                // No key path, just one section
            //                newIP = newIP.copy(item: section.insert(object, using: sort))
            //                _objectMap[object] = section.hashValue
            //            }
            //            else {
            //                let sec = RelationalResultsControllerSection<Section, Element>(object: nil, objects: [object])
            //                self._sections.append(sec)
            //                _sectionMap[sec.hashValue] = newIP.sectionCopy
            //                _objectMap[object] = sec.hashValue
            //            }
            context.inserted(object, at: newIP)
//            context.add(object: object, old: nil, new: newIP)
        }
    }
    
    
    func processDeletedObjects() {
        
        for change in context.objectChangeSet.deleted {
            
            let object = change.object
            
            defer {
                _objectMap[object] = nil
            }
            guard let oldIP = self.indexPath(for: object) else { continue }
            
            // If the section was removed, the index path for the object will not be found.
            // No need to check if the section was deleted, +1
            
            let section = self._sections[oldIP._section]
            _ = section.remove(object)
            context.deleted(object, at: oldIP)

            if section.objects.count == 0 {
                
                // If the section object matches the section predicat, keep it.
                if let req = self.sectionFetchRequest,
                    let obj = section._object {
                    if req.predicate == nil || req.predicate?.evaluate(with: obj) == true { continue }
                }
                
                _removeSection(section._object)
            }
        }
    }
    


}


