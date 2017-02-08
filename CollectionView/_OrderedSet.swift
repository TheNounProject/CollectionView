//
//  _OrderedSet.swift
//  CollectionView
//
//  Created by Wesley Byrne on 2/6/17.
//  Copyright © 2017 Noun Project. All rights reserved.
//

import Foundation


class OrderedSet<Element: Hashable> : ExpressibleByArrayLiteral, Collection, CustomStringConvertible {
    
    fileprivate var _storage = NSMutableOrderedSet()
    
    init<C : Collection>(elements: C) where C.Iterator.Element == Element {
        _storage = NSMutableOrderedSet(array: Array(elements))
    }
    
    required init(arrayLiteral elements: Element...) {
        _storage = NSMutableOrderedSet(array: elements)
    }
    
    
    public var description: String {
        var str = "\(type(of: self)) [\n"
        for i in self.enumerated() {
            str += "\(i.offset) : \(i.element) \(i.element.hashValue)\n"
        }
        str += "]"
        return str
    }
    
    var objects : [Element] {
        return _storage.array as! [Element]
    }
    
    var startIndex: Int { return 0 }
    var endIndex: Int { return _storage.count }
    
    func index(after i: Int) -> Int {
        return i + 1
    }
    
    subscript(index: Int) -> Element {
        return self.object(at: index) as! Element
    }
    
    var count : Int { return _storage.count }
    func contains(_ object: Element) -> Bool{
        return _storage.contains(object)
    }
    
    func index(of object: Element) -> Int? {
        let i = _storage.index(of: object)
        return i == NSNotFound ? nil : i
    }
    
    func object(at index: Int) -> Element {
        return _storage.object(at: index) as! Element
    }
    
    
    
    
    
    
    // MARK: - Appending
    /*-------------------------------------------------------------------------------*/
    
    @discardableResult func add(_ object: Element) -> Bool {
        guard self._storage.contains(object) == false else { return false }
        self._storage.add(object)
        return true
    }
    
    public func add<C : Collection>(contentsOf newElements: C) where C.Iterator.Element == Element {
        self._storage.addObjects(from: Array(newElements))
        
    }
    
    
    // MARK: - Inserting
    /*-------------------------------------------------------------------------------*/
    
    func insert(_ object: Element, at index: Int) -> Bool {
        guard !self.contains(object) else { return false }
        self._storage.insert(object, at: index)
        return true
    }
    
    public func insert<C : Collection>(contentsOf newElements: C, at index: Int) where C.Iterator.Element == Element {
        let arr = Array(newElements)
        let range = IndexSet(integersIn: index...arr.count - 1)
        self._storage.insert(arr, at: range)
    }
    
    
    // MARK: - Removing
    /*-------------------------------------------------------------------------------*/
    @discardableResult func remove(at index: Int) -> Element {
        let o = self._storage.object(at: index) as! Element
        self._storage.removeObject(at: index)
        return o
    }
    
    @discardableResult func remove(_ object: Element) -> Int? {
        let i = self._storage.index(of: object)
        guard i != NSNotFound else { return nil }
        self._storage.remove(object)
        return i
    }
    
    var needsSort : Bool = false
    //    mutating func _batchRemove(_ object: Element) {
    //        self.needsSort = true
    //        self._storage.removeObject(at: object)
    //    }
    //    mutating func _batchRemove(at index: Int) {
    //        self.needsSort = true
    //        let e = self._data.remove(at: index)
    //        _map[e.hashValue] = nil
    //    }
    
    
    func removeAll() {
        self._storage.removeAllObjects()
        self.needsSort = false
    }
}




extension OrderedSet where Element:Hashable & AnyObject {
    
    func insert(_ object: Element, using sortDescriptors: [NSSortDescriptor]) -> Int {
        
        if sortDescriptors.count == 0 {
            self._storage.add(object)
            return _storage.count - 1
        }
        
        var idx = 0
        while idx <= self._storage.count {
            let check = self.object(at: idx)
            if sortDescriptors.compare(object, to: check) == .orderedDescending {
                self._storage.insert(object, at: idx)
                return idx
            }
            idx += 1
        }
        
        self._storage.add(object)
        return self._storage.count - 1
    }
    
    func insert<C : Collection>(contentsOf newElements: C, using sortDescriptors: [NSSortDescriptor]) where C.Iterator.Element == Element {
        
        if sortDescriptors.count == 0 {
            self._storage.addObjects(from: Array(newElements))
            return
        }
        
        var idx = 0
        
        var inserts = newElements.sorted(using: sortDescriptors)
        
        //        var insert = inserts.first
        
        while idx <= self._storage.count {
            guard let insert = inserts.first else { break }
            let check = self.object(at: idx)
            if sortDescriptors.compare(insert, to: check) == .orderedDescending {
                self._storage.insert(object, at: idx)
                self._storage.removeObject(at: 0)
            }
            idx += 1
        }
        
        if inserts.count > 0 {
            self._storage.addObjects(from: inserts)
        }
    }
    
    
    
    func sort(using sortDescriptors: [NSSortDescriptor]) {
        self._storage.sort(using: sortDescriptors)
    }
    
    func sorting(by sortDescriptors: [NSSortDescriptor]) -> OrderedSet<Element> {
        var new = self.copy()
        guard sortDescriptors.count > 0 else { return new }
        new.sort(using: sortDescriptors)
        return new
    }
}



extension OrderedSet {
    
    //    func copy() -> OrderedSet {
    //        let new = OrderedSet()
    //        new._storage = self._storage.mutableCopy() as! NSMutableOrderedSet
    //        return new
    //    }
    
}

