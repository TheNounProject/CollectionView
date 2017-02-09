//
//  FetchedResultsController.swift
//  CollectionView
//
//  Created by Wes Byrne on 1/16/17.
//  Copyright © 2017 Noun Project. All rights reserved.
//

import Foundation




fileprivate struct ChangeContext<Element:NSManagedObject> : CustomStringConvertible {
    var inserted = [Element:IndexPath]()
    var deleted = [Element:IndexPath]()
    var updated = [Element:IndexPath]()
    
    
    
    mutating func addObject(_ obj: Element, oldIP: IndexPath?, newIP: IndexPath?) {
        switch (oldIP, newIP) {
        case (nil, _): inserted[obj] = newIP
        case (let ip , nil): deleted[obj] = ip
        case let (old, new): updated[obj] = old ?? new
        }
    }
    
    mutating func reset() {
        inserted.removeAll()
        deleted.removeAll()
        updated.removeAll()
    }
    
    var description: String {
        return "\(updated.count) Updated, \(deleted.count) Deleted, \(inserted.count) Inserted"
    }
}





public typealias SectionRepresentable = Comparable & Hashable & CustomDisplayStringConvertible

fileprivate class SectionInfo<ValueType: SectionRepresentable, Element: NSManagedObject>: ResultsControllerSectionInfo, Hashable {
    
    public var object : Any? { return self._value }
    public var objects: [Any] { return _objects }
    
    public var numberOfObjects : Int { return objects.count }
    
    private(set) var _value : ValueType?
    private(set) var _objects : [Element] = []
    
    private var _map = [Element:Int]()
    
    fileprivate var needsSort : Bool = false
    
    
    public var hashValue: Int {
        return _value?.hashValue ?? 0
    }
    public static func ==(lhs: SectionInfo, rhs: SectionInfo) -> Bool {
        return lhs._value == rhs._value
    }
    
    internal init(value: ValueType?, objects: [Element]) {
        self._value = value
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



public class FetchedResultsController<Section: SectionRepresentable, Element: NSManagedObject> : NSObject, ResultsController {
    
    
    public var fetchRequest : NSFetchRequest<Element>?
    public var sortDescriptors: [NSSortDescriptor]? {
        return fetchRequest?.sortDescriptors
    }
    
    fileprivate typealias SectionWrapper = SectionInfo<Section, Element>
    
    public var sectionKeyPath: String?
    
    public let managedObjectContext: NSManagedObjectContext

    public var sections: [ResultsControllerSectionInfo] { return _sections }
    public var allObjects: [Any] { return Array(fetchedObjects) }
        
        
    internal var fetchedObjects = Set<Element>()
    
    internal var _objectMap = [Element:Int]() // Map between elements and the last group it was known to be in
    internal var _sectionMap = [Int:IndexPath]() // Key is hash value of section object, 0 is ungrouped
    
    internal var _fetchedObjects = [Element]()
    internal var _fetchedSections = OrderedSet<Section>()
    
    private var _sections = [SectionWrapper]()
    
    public var delegate : ResultsControllerDelegate? {
        didSet {
            if (oldValue == nil) == (delegate == nil) { return }
            if delegate == nil {
                NotificationCenter.default.removeObserver(self, name: Notification.Name.NSManagedObjectContextObjectsDidChange, object: self.managedObjectContext)
            }
            else {
                NotificationCenter.default.addObserver(self, selector: #selector(handleChangeNotification(_:)), name: Notification.Name.NSManagedObjectContextObjectsDidChange, object: self.managedObjectContext)
            }
        }
    }
    
    public init(context managedObjectContext: NSManagedObjectContext, request: NSFetchRequest<Element>? = nil, sectionKeyPath: String? = nil) {
        self.managedObjectContext = managedObjectContext
        self.fetchRequest = request
        self.sectionKeyPath = sectionKeyPath
    }
    
    public var numberOfSections : Int {
        return _sections.count
    }
    
    public func numberOfObjects(in section: Int) -> Int {
        return self._sections[section].objects.count
    }
    
    public func sectionName(forSectionAt indexPath: IndexPath) -> String {
        return _section(for: indexPath)?._value?.displayDescription ?? ""
    }
    
    
    
    // MARK: - Public Item Accessors
    /*-------------------------------------------------------------------------------*/
    public func sectionInfo(forSectionAt sectionIndexPath: IndexPath) -> ResultsControllerSectionInfo? {
        return self._section(for: sectionIndexPath)
    }
    
    public func object(forSectionAt sectionIndexPath: IndexPath) -> Any? {
        return self._object(for: sectionIndexPath)
    }
    public func object(at indexPath: IndexPath) -> Any? {
        return self._item(at: indexPath)
    }
    
    
    // MARK: - Private Item Accessors
    /*-------------------------------------------------------------------------------*/
    private func _section(for sectionIndexPath: IndexPath) -> SectionWrapper? {
        return self._sections.object(at: sectionIndexPath._section)
    }
    
    private func _object(for sectionIndexPath: IndexPath) -> Section? {
        return self._sections.object(at: sectionIndexPath._section)?._value
    }
    
    public func _item(at indexPath: IndexPath) -> Element? {
        return self._sections.object(at: indexPath._section)?._objects.object(at: indexPath._item)
    }
    


    
    
    // MARK: - Getting IndexPaths
    /*-------------------------------------------------------------------------------*/
    public func indexPath(for object: Element) -> IndexPath? {
        
        if let keyPath = self.sectionKeyPath {
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
        print(_sectionMap)
        print(sectionObject?.hashValue ?? 0)
        return _sectionMap[sectionObject?.hashValue ?? 0]
    }
    
    
    
    
    public func performFetch() throws {
        
        guard let fetchRQ = self.fetchRequest else {
            throw ResultsControllerError.unknown
        }
        
        self._sections.removeAll()
        self._sectionMap.removeAll()
        self._fetchedSections.removeAll()
        
        let _objects = try managedObjectContext.fetch(fetchRQ)
        self.fetchedObjects = Set(_objects)
        
        if let keyPath = self.sectionKeyPath {
            var unordered = [Section : SectionWrapper]()
            var orphans = [Element]()
            for object in _objects {
                
                if let sec = object.value(forKey: keyPath) as? Section {
                    if let existing = unordered[sec] {
                        _ = existing.insert(object)
                    }
                    else {
                        unordered[sec] = SectionWrapper(value: sec, objects: [object])
                    }
                    _objectMap[object] = sec.hashValue
                }
                else {
                    orphans.append(object)
                    _objectMap[object] = 0
                }
            }
            
            let sortDesc = NSSortDescriptor(key: keyPath, ascending: true)
            var sorted = unordered.values.sorted(by: { (r1, r2) -> Bool in
                let o1 = r1.objects[0]
                let o2 = r2.objects[0]
//                return true
                return sortDesc.compare(o1, to: o2) != .orderedDescending
            })
            
            if orphans.count > 0 {
                sorted.append(SectionWrapper(value: nil, objects: orphans))
            }
            
            for (idx, s) in sorted.enumerated() {
                _sectionMap[s.hashValue] = IndexPath.for(section: idx)
                s.sortItems(using: sortDescriptors ?? [])
            }
            self._sections = sorted
            
        }
        else {
            self._sections = [
                SectionWrapper(value: nil, objects: _objects)
            ]
            
        }
    }
    
    
    
    func pause() {
        
    }
    
    
    
    // MARK: - Handling Changes
    /*-------------------------------------------------------------------------------*/
    
    private var context = ChangeContext<Element>()
    
    func handleChangeNotification(_ notification: Notification) {
        
        self.delegate?.controllerWillChangeContent(controller: self)
        
        guard let info = notification.userInfo else { return }
        self.context.reset()
        
        print("•••••••••••••••• Start ••••••••••••••••")
        print("\(_sections.count) Sections")
        for (idx, res) in _sections.enumerated() {
            print("\(idx) - \(res.objects.count) Objects")
        }
        print("---------------------------------------")
        
        
        
        let updated = info[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? Set<NSManagedObject>()
        let inserted = (info[NSInsertedObjectsKey] as? Set<NSManagedObject>) ?? Set<NSManagedObject>()
        //        let refreshed = info[NSRefreshedObjectsKey] as? Set<NSManagedObject>
        
        var deleted = (info[NSDeletedObjectsKey] as? Set<NSManagedObject>) ?? Set<NSManagedObject>()
        if let invalidated = info[NSInvalidatedObjectsKey] as? Set<NSManagedObject> {
            deleted = deleted.union(invalidated)
        }
        
        var updatedEffects = processUpdated(objects: updated)
        processDeleted(objects: deleted.union(updatedEffects.deleted))
        processInserted(objects: inserted.union(updatedEffects.inserted))
        
        for obj in context.deleted {
            self.delegate?.controller(self, didChangeObject: obj.key, at: obj.value, for: .delete)
        }
        for obj in context.inserted {
            guard let newIP = self.indexPath(for: obj.key) else { continue }
            self.delegate?.controller(self, didChangeObject: obj.key, at: obj.value, for: .insert(newIP))
        }
        for obj in context.updated {
            guard let newIP = self.indexPath(for: obj.key) else { continue }
            let old : IndexPath = obj.value
//            let type : ResultsControllerChangeType = (old == newIP) ? .update : .move(newIP)
//            self.delegate?.controller(self, didChangeObject: obj.key, at: obj.value, for: type)
        }
        
        self.delegate?.controllerDidChangeContent(controller: self)
        
        print("----------------- AFTER ----------------")
        print(context)
        
        print("\(_sections.count) Sections")
        for (idx, res) in _sections.enumerated() {
            print("\(idx) - \(res.objects.count) Objects")
        }
        print("•••••••••••••••• END •••••••••••••••••••")
        
    }
    
    
    
    //    private func _insert(object: Element, inSectionAt indexPath: IndexPath) {
    //
    //    }
    
    
    
    func processUpdated(objects: Set<NSManagedObject>) -> (inserted: Set<NSManagedObject>, deleted: Set<NSManagedObject>) {
        
        var inserted = Set<Element>()
        var deleted = Set<Element>()
        
        for _object in objects {
            guard let object = _object as? Element else { continue }
            
            let existed = self.fetchedObjects.contains(object)
            let matches = self.fetchRequest?.predicate == nil || self.fetchRequest?.predicate?.evaluate(with: object) == true
            
            if existed && !matches {
                deleted.insert(object)
            }
            else if !existed && matches {
                inserted.insert(object)
            }
            else if existed && matches {
                
                guard let cIP = self.indexPath(for: object),
                    let currentSection = _section(for: cIP) else { continue }
                
                let sort = self.fetchRequest?.sortDescriptors ?? []
                _ = currentSection.remove(object)
                
                var newIP = cIP
                
                if let key = sectionKeyPath {
                    let sectionValue = object.value(forKeyPath: key) as? Section
                    
                    // Same group
                    if sectionValue == currentSection._value {
                        newIP = newIP.copy(withItem: currentSection.insert(object, using: sort))
                        _objectMap[object] = currentSection.hashValue
                    }
                        
                        // Moved to another section
                    else if let newSip = self.indexPath(for: sectionValue),
                        let newSection = self._section(for: newSip) {
                        newIP = newIP.copy(withItem: newSection.insert(object, using: sort))
                        _objectMap[object] = newSection.hashValue
                    }
                        
                        // Move to new section
                    else {
                        // The section value doesn't exist yet, the section will be inserted
                        let sec = SectionWrapper(value: sectionValue, objects: [object])
                        newIP = newIP.copy(withItem: self._sections.count)
                        self._sections.append(sec)
                        _sectionMap[sectionValue?.hashValue ?? 0] = newIP.sectionCopy
                        _objectMap[object] = sec.hashValue
                    }
                }
                else {
                    // No key path, just one section
                    newIP = newIP.copy(withItem: currentSection.insert(object, using: sort))
                    _objectMap[object] = currentSection.hashValue
                }
                
                context.addObject(object, oldIP: cIP, newIP: newIP)
            }
        }
        return (inserted, deleted)
    }
    
    
    func processDeleted(objects: Set<NSManagedObject>) {
        
        for _object in objects {
            guard let object = _object as? Element,
                let oldIP = self.indexPath(for: object) else { continue }
            
            let section = self._sections[oldIP._section]
            
            _ = section.remove(object)
            context.addObject(object, oldIP: oldIP, newIP: nil)
            _objectMap[object] = nil
            
            
            if section.objects.count == 0 {
                _sectionMap[section.hashValue] = nil
                _sections.remove(at: oldIP._section)
                
                for idx in oldIP._section..<_sections.count {
                    _sectionMap[_sections[idx].hashValue] = IndexPath.for(section: idx)
                }
            }
        }
        
    }
    
    func processInserted(objects: Set<NSManagedObject>) {
        
        for _object in objects {
            guard let object = _object as? Element,
                self.fetchedObjects.contains(object) == false else { continue }
            
            
            var newIP = IndexPath.Zero
            let sort = self.fetchRequest?.sortDescriptors ?? []
            
            if let key = sectionKeyPath {
                let sectionValue = object.value(forKeyPath: key) as? Section
                
                if let newSip = self.indexPath(for: sectionValue),
                    let newSection = self._section(for: newSip) {
                    newIP = newIP.copy(withItem: newSection.insert(object, using: sort))
                    _objectMap[object] = newSection.hashValue
                }
                else {
                    // The section value doesn't exist yet, the section will be inserted
                    let sec = SectionWrapper(value: sectionValue, objects: [object])
                    newIP = IndexPath.for(item: 0, section: _sections.count)
                    self._sections.append(sec)
                    _sectionMap[sectionValue?.hashValue ?? 0] = newIP.sectionCopy
                    _objectMap[object] = sec.hashValue
                }
            }
            else if let section = self._sections.first {
                // No key path, just one section
                newIP = newIP.copy(withItem: section.insert(object, using: sort))
                _objectMap[object] = section.hashValue
            }
            else {
                let sec = SectionWrapper(value: nil, objects: [object])
                self._sections.append(sec)
                _sectionMap[sec.hashValue] = newIP.sectionCopy
                _objectMap[object] = sec.hashValue
            }
            context.addObject(object, oldIP: nil, newIP: newIP)
        }
    }
    

    
}



