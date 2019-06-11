//
//  SectionInfo.swift
//  CollectionView
//
//  Created by Wesley Byrne on 2/20/18.
//  Copyright © 2018 Noun Project. All rights reserved.
//

import Foundation

public class SectionInfo<Section: SectionType, Element: Hashable>: Hashable {
    
    public let representedObject: Section?
    public var objects: [Element] { return _storage.objects }
    
    public var numberOfObjects: Int { return _storage.count }
    
    private(set) var _storage: OrderedSet<Element>
    private var _storageCopy = OrderedSet<Element>()
    
    internal init(object: Section?, objects: [Element] = []) {
        self.representedObject = object
        _storage = OrderedSet(elements: objects)
    }
    
    // MARK: - Equatable
    /*-------------------------------------------------------------------------------*/
    public func hash(into hasher: inout Hasher) {
        hasher.combine(representedObject)
    }
    
    public static func ==(lhs: SectionInfo, rhs: SectionInfo) -> Bool {
        return lhs.representedObject == rhs.representedObject
    }
    
    // MARK: - Objects
    /*-------------------------------------------------------------------------------*/
    
    func index(of object: Element) -> Int? {
        return _storage.index(of: object)
    }
    
//    @discardableResult func insert(_ object: Element, using sortDescriptors: [SortDescriptor<Element>] = []) -> Int {
//        return self._storage.insert(object, using: sortDescriptors)
//    }
    func remove(_ object: Element) {
        if self.isEditing {
            self._removed.insert(object)
        }
        else {
            _storage.remove(object)
        }
    }
    func add(_ element: Element) {
        if self.isEditing {
            self._updated.insert(element)
        }
        else {
            self._storage.append(element)
        }
    }

    func replace(_ element: Element, at index: Int) {
        self._storage.replace(object: element, at: index)
    }
    
    func sort(using sortDescriptors: [SortDescriptor<Element>]) {
        self._storage.sort(using: sortDescriptors)
    }
    
    // MARK: - Editing
    /*-------------------------------------------------------------------------------*/
    
    private(set) var isEditing: Bool = false
    private var _removed = Set<Element>() // Tracks removed items needing sort, to allow for performance optimizations
    private var _updated = Set<Element>() // Tracks added items needing sort, to allow for performance optimizations
    
    func beginEditing() {
        assert(!isEditing, "Mutiple calls to beginEditing() for RelationalResultsControllerSection")
        isEditing = true
        self._updated.removeAll()
        self._removed.removeAll()
    }
    
    func ensureEditing() {
        if isEditing { return }
        beginEditing()
    }
    
    func endEditing(sorting: [SortDescriptor<Element>], forceUpdates: Set<Element>) -> EditDistance<OrderedSet<Element>>? {
        defer {
            isEditing = false
        }
        guard isEditing, (!self._updated.isEmpty || !self._removed.isEmpty) else {
            return nil
        }
        let source = self._storage
        
        self._storage.remove(contentsOf: _removed)
        self._storage.insert(contentsOf: _updated, using: sorting)
       
        let changes = EditDistance(source: source, target: _storage)
        self._storageCopy.removeAll()
        self._removed.removeAll()
        self._updated.removeAll()
        return changes
    }
}

extension SectionInfo: CustomStringConvertible {
    
    public var description: String {
        if let o = self.representedObject {
            return "SectionInfo representing \(o)"
        }
        return "SectionInfo representing nil"
    }
}
