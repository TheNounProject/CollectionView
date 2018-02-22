//
//  SectionInfo.swift
//  CollectionView
//
//  Created by Wesley Byrne on 2/20/18.
//  Copyright © 2018 Noun Project. All rights reserved.
//

import Foundation



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
    
    public static func ==(lhs: SectionInfo, rhs: SectionInfo) -> Bool {
        return lhs.representedObject == rhs.representedObject
    }
    
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
        self.needsSort = false
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


