//
//  RelationalResultsController.swift
//  CollectionView
//
//  Created by Wesley Byrne on 1/12/17.
//  Copyright © 2017 Noun Project. All rights reserved.
//

import Foundation






fileprivate struct ChangeContext<Section: NSManagedObject, Element:NSManagedObject> : CustomStringConvertible {
    var inserted = [Element:IndexPath]()
    var deleted = [Element:IndexPath]()
    var updated = [Element:IndexPath]()
    
    typealias SectionWrapper = RelationalResultsControllerSection<Section, Element>
    
    var insertedSections = [SectionWrapper : IndexPath]()
    var deletedSections = [SectionWrapper : IndexPath]()
    
    
    mutating func add(object: Element, old oldIP: IndexPath?, new newIP: IndexPath?) {
        switch (oldIP, newIP) {
        case (nil, _): // Inserted
            inserted[object] = newIP
        case (let ip , nil): // Deleted
            deleted[object] = ip
        case let (old, new): // Updated
            updated[object] = old ?? new
        }
    }
    
    
    mutating func add(section: SectionWrapper, old oldIP: IndexPath?, new newIP: IndexPath?) {
        switch (oldIP, newIP) {
        case (nil, _): // Inserted
            insertedSections[section] = newIP
        case (let ip , nil): // Deleted
            deletedSections[section] = ip
        case let (old, new): // Updated
//            updated[obj] = old ?? new
            break
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




class RelationalResultsControllerSection<Section: NSManagedObject, Element: NSManagedObject>: ResultsControllerSection, Hashable {
    
    public var object : Any? { return self._object }
    public var objects: [NSManagedObject] { return _objects }
    
    public var count : Int { return objects.count }
    
    private(set) public var _object : Section?
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
        let start = _objects.insert(object, using: [])
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
    internal var _fetchedSections = [Section]()
    
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
    
    public func object(for sectionIndexPath: IndexPath) -> Any? {
        return self._object(for: sectionIndexPath)
    }
    public func object(at indexPath: IndexPath) -> NSManagedObject? {
        return self._item(at: indexPath)
    }
    
    
    // MARK: - Private Item Accessors
    /*-------------------------------------------------------------------------------*/
    private func _section(for sectionIndexPath: IndexPath) -> SectionWrapper? {
        return self._sections.object(at: sectionIndexPath._section)
    }
    
    private func _object(for sectionIndexPath: IndexPath) -> Section? {
        return self._sections.object(at: sectionIndexPath._section)?._object
    }
    
    public func _item(at indexPath: IndexPath) -> Element? {
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
        print(_sectionMap)
        print(sectionObject?.hashValue ?? 0)
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
        
        for object in _objects {
            
            if let parent = object.value(forKey: sectionKeyPath) as? Section {
                if let existing = unordered[parent] {
                    existing.insert(object)
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
        
        if let sectionRQ = self.sectionFetchRequest {
            for s in try managedObjectContext.fetch(sectionRQ) {
                if unordered[s] == nil {
                    unordered[s] = SectionWrapper(object: s, objects: [])
                }
            }
        }
        
        let sorted = unordered.keys.sorted(using: sectionFetchRequest?.sortDescriptors ?? [])
        
        var _tempSections = [SectionWrapper]()
        for (idx, s) in sorted.enumerated() {
            let sec = unordered[s]!
            self._sectionMap[s.hashValue] = IndexPath.for(section: idx)
            sec.sortItems(using: fetchRequest.sortDescriptors ?? [])
            _tempSections.append(sec)
        }
        
        if orphans.count < 0 {
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
    
    fileprivate var context = ChangeContext<Section, Element>()
    
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
        
        
        let relatedChanges = preprocess(notification: notification)
        
        
        
        print(relatedChanges.objects)
        print(relatedChanges.sections)

        processUpdated(sections: relatedChanges.sections.updated)
        processDeleted(sections: relatedChanges.sections.deleted)
        processInserted(sections: relatedChanges.sections.inserted)
        
        processUpdated(objects: relatedChanges.objects.updated)
        processDeleted(objects: relatedChanges.objects.deleted)
        processInserted(objects: relatedChanges.objects.inserted)
        
        
        for obj in context.deletedSections {
            self.delegate?.controller(self, didChangeSection: obj.key, at: obj.value, for: .delete)
        }
        for obj in context.insertedSections {
            guard let newIP = self.indexPath(for: obj.key._object) else { continue }
            self.delegate?.controller(self, didChangeSection: obj.key, at: obj.value, for: .insert(newIP))
        }
        
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
            let type : ResultsControllerChangeType = (old == newIP) ? .update : .move(newIP)
            self.delegate?.controller(self, didChangeObject: obj.key, at: obj.value, for: type)
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
    
    
    func preprocess(notification: Notification) ->
        (sections: ContextChange<Section>, objects: ContextChange<Element>) {
            var sections = ContextChange<Section>()
            var elements = ContextChange<Element>()
            
            guard let info = notification.userInfo else {
                return (sections, elements)
            }
            
            // Updated
            if let updated = info[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
                for obj in updated {
                    if let o = obj as? Section {
                        
                        // If there is a sectionRQ, compare against it
                        if let sectionRQ = self.sectionFetchRequest, o.entity == sectionRQ.entity {
                            
                            let existed = self.contains(sectionObject: o)
                            let matches = sectionRQ.predicate == nil || sectionRQ.predicate?.evaluate(with: o) == true
                            
                            if existed && !matches {
                                sections.deleted.insert(o)
                            }
                            else if !existed && matches {
                                sections.inserted.insert(o)
                            }
                            else if existed && matches {
                                sections.updated.insert(o)
                            }
                        }
                            // No sectionRQ, add it to updated to check order
                        else if _sectionMap[o.hashValue] != nil {
                            sections.updated.insert(o)
                        }
                    }
                    else if let o = obj as? Element, fetchRequest.entity == o.entity {
                        
                        let existed = self.contains(object: o)
                        let matches = fetchRequest.predicate == nil || fetchRequest.predicate?.evaluate(with: o) == true
                        
                        if existed && !matches {
                            elements.deleted.insert(o)
                        }
                        else if !existed && matches {
                            elements.inserted.insert(o)
                        }
                        else if existed && matches {
                            elements.updated.insert(o)
                        }
                        
                    }
                }
            }
            
            // Inserted
            if let inserted = info[NSInsertedObjectsKey] as? Set<NSManagedObject> {
                for obj in inserted {
                    if let o = obj as? Element, o.entity == fetchRequest.entity {
                        if fetchRequest.predicate == nil || fetchRequest.predicate?.evaluate(with: 0) == true {
                            elements.inserted.insert(o)
                        }
                    }
                    else if let o = obj as? Section,
                        let sectionRQ = self.sectionFetchRequest,
                        o.entity == sectionRQ.entity,
                        (sectionRQ.predicate == nil || sectionRQ.predicate?.evaluate(with: o) == true) {
                        sections.inserted.insert(o)
                    }
                }
            }
            
            // Deleted
            var deleted = (info[NSDeletedObjectsKey] as? Set<NSManagedObject>) ?? Set<NSManagedObject>()
            if let invalidated = info[NSInvalidatedObjectsKey] as? Set<NSManagedObject> {
                deleted = deleted.union(invalidated)
            }
            for obj in deleted {
                if let o = obj as? Element, self.contains(object: o) {
                    elements.deleted.insert(o)
                }
                else if let o = obj as? Section, self.contains(sectionObject: o) {
                    sections.deleted.insert(o)
                }
            }
            return (sections, elements)
    }
    
    
    
    // MARK: - Section Processing
    /*-------------------------------------------------------------------------------*/
    
    func processUpdated(sections: Set<Section>) {
        
    }
    
    func processInserted(sections: Set<Section>) {
        
    }
    
    func processDeleted(sections: Set<Section>) {
        for object in sections {
            
            guard let ip = self.indexPath(for: object) else { continue }
            
            let section = self._sections[ip._section]
            _sections.remove(at: ip._section)
            
            context.add(section: section, old: ip, new: nil)
            
            for obj in section._objects {
                _objectMap[obj] = nil
            }
            
            // If the section object matches the section predicat, keep it.
            if let req = self.sectionFetchRequest,
                let obj = section._object {
                if req.predicate == nil || req.predicate?.evaluate(with: obj) == true { continue }
            }
            
            _removeSection(section._object)
        }
    }
    
    func _removeSection(_ section: Section?) {
        
        guard let ip = self.indexPath(for: section) else { return }
        
        _sectionMap[section?.hashValue ?? 0] = nil
        _sections.remove(at: ip._section)
        
        for idx in ip._section..<_sections.count {
            _sectionMap[_sections[idx].hashValue] = IndexPath.for(section: idx)
        }
    }
    
    
    
    // MARK: - Object Processing
    /*-------------------------------------------------------------------------------*/
    
    func processUpdated(objects: Set<Element>) {
        
        for object in objects {
            
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
            
            context.add(object: object, old: cIP, new: newIP)
        }
    }
    
    func processInserted(objects: Set<Element>) {
        
        for object in objects {
            
            guard self.contains(object: object) == false else { continue }
            
            var newIP = IndexPath.Zero
            let sort = self.fetchRequest.sortDescriptors ?? []
            
            
            let sectionValue = object.value(forKeyPath: self.sectionKeyPath) as? Section
            
            if let newSip = self.indexPath(for: sectionValue),
                let newSection = self._section(for: newSip) {
                newIP = newIP.copy(item: newSection.insert(object, using: sort))
                _objectMap[object] = newSection.hashValue
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
            context.add(object: object, old: nil, new: newIP)
        }
    }
    
    
    func processDeleted(objects: Set<Element>) {
        
        for object in objects {
            
            guard let oldIP = self.indexPath(for: object) else { continue }
            let section = self._sections[oldIP._section]
            
            _ = section.remove(object)
            context.add(object: object, old: oldIP, new: nil)
            _objectMap[object] = nil
            
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


