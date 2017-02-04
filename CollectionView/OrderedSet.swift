//
//  OrderedSet.swift
//  CollectionView
//
//  Created by Wesley Byrne on 1/31/17.
//  Copyright © 2017 Noun Project. All rights reserved.
//

import Foundation

typealias HashValue = Int

struct OrderedSet<Element: Hashable> : ExpressibleByArrayLiteral, Collection {
    
    fileprivate var _map = [HashValue:Int]()
    fileprivate var _data = [Element]()
    
    var objects : [Element] { return _data }
    
    init() { }
    
    init<C : Collection>(elements: C) where C.Iterator.Element == Element {
        for (idx, e) in elements.enumerated() {
            guard _map[e.hashValue] == nil else {
                continue
            }
            Set<Int>()
            _data.append(e)
            _map[e.hashValue] = idx
        }
    }
    
    init(arrayLiteral elements: Element...) {
        for (idx, e) in elements.enumerated() {
            guard _map[e.hashValue] == nil else {
                continue
            }
            _data.append(e)
            _map[e.hashValue] = idx
        }
    }
    
    
    var startIndex: Int { return _data.startIndex }
    var endIndex: Int { return _data.endIndex }
    
    func index(after i: Int) -> Int {
        return _data.index(after: i)
    }
    
    subscript(index: Int) -> Element {
        return _data[index]
    }
    
    var count : Int { return _data.count }
    func contains(_ object: Element) -> Bool{
        return _map[object.hashValue] != nil
    }
    
    func index(for object: Element) -> Int? {
        return _map[object.hashValue]
    }
    
    func object(at index: Int) -> Element {
        return _data[index]
    }
    
    fileprivate mutating func _remap(startingAt index: Int) {
        guard index < _data.count else { return }
        for idx in index..<_data.count {
            self._map[_data[idx].hashValue] = idx
        }
    }
    
    
    // MARK: - Appending
    /*-------------------------------------------------------------------------------*/

    @discardableResult mutating func add(_ object: Element) -> Bool {
        guard !self.contains(object) else { return false }
        self.needsSort = true
        _data.append(object)
        _map[object.hashValue] = _data.count - 1
        return true
    }
    
    public mutating func add<C : Collection>(contentsOf newElements: C) where C.Iterator.Element == Element {
        for e in newElements {
            self.add(e)
        }
    }

    
    // MARK: - Inserting
    /*-------------------------------------------------------------------------------*/
    
    mutating func insert(_ object: Element, at index: Int) -> Bool {
        guard !self.contains(object) else { return false }
        self._data.insert(object, at: index)
        _remap(startingAt: index)
        return true
    }
    
    public mutating func insert<C : Collection>(contentsOf newElements: C, at index: Int) -> Set<Element> where C.Iterator.Element == Element {
        var inserted = Set<Element>()
        for (idx, e) in newElements.enumerated() {
            if !self.contains(e) {
                self._data.insert(e, at: index + idx)
                inserted.insert(e)
            }
        }
        if inserted.count > 0 {
            self._remap(startingAt: index)
        }
        return inserted
    }
    
    
    // MARK: - Removing
    /*-------------------------------------------------------------------------------*/
    @discardableResult mutating func remove(at index: Int) -> Element {
        let e = self._data.remove(at: index)
        _map.removeValue(forKey: e.hashValue)
        _remap(startingAt: index)
        return e
    }
    
    @discardableResult mutating func remove(_ object: Element) -> Int? {
        guard let index = self.index(for: object) else { return nil }
        remove(at: index)
        return index
    }
    
    var needsSort : Bool = false
    mutating func _batchRemove(_ object: Element) {
        self.needsSort = true
        guard let index = self._map.removeValue(forKey: object.hashValue) else { return }
        remove(at: index)
    }
    mutating func _batchRemove(at index: Int) {
        self.needsSort = true
        let e = self._data.remove(at: index)
        _map[e.hashValue] = nil
    }
    
    
    mutating func removeAll(keepingCapacity keep: Bool = false) {
        self.needsSort = false
        _data.removeAll(keepingCapacity: keep)
        _map.removeAll(keepingCapacity: keep)
    }
    
}



extension OrderedSet {
    
    func index(ofHash hash: HashValue) -> Int? {
        return _map[hash]
    }
    
}


extension OrderedSet where Element:Comparable {
    
    mutating func sort() {
        self.needsSort = false
        _data.sort()
        _remap(startingAt: 0)
    }
    
    func sorted() {
        var new = self
        new._data.sort()
        new.needsSort = false
        new._remap(startingAt: 0)
    }
    
    
}

extension OrderedSet where Element:Hashable & AnyObject {
    
    mutating func insert(_ object: Element, using sortDescriptors: [NSSortDescriptor]) -> Int {
        
        _ = self.remove(object)
        
        if sortDescriptors.count > 0 {
            for (idx, element) in self.enumerated() {
                if sortDescriptors.compare(object, to: element) == .orderedAscending {
                    self.insert(object, at: idx)
                    return idx
                }
            }
        }
        self.add(object)
        return self.count - 1
    }
    
    mutating func insert<C : Collection>(contentsOf newElements: C, using sortDescriptors: [NSSortDescriptor]) where C.Iterator.Element == Element {
        
        var _fInsert = -1
        for e in newElements {
            _ = self.remove(e)
            let idx = self._data.insert(e, using: sortDescriptors)
            if idx < _fInsert || _fInsert == -1 {
                _fInsert = idx
            }
        }
        
        if _fInsert > -1 {
            self._remap(startingAt: _fInsert)
        }
    }
    
    
    
    mutating func sort(using sortDescriptors: [NSSortDescriptor]) {
        guard sortDescriptors.count > 0 else { return }
        
        self._data.sort(using: sortDescriptors)
        self._map.removeAll(keepingCapacity: true)
        for (idx, obj) in self._data.enumerated() {
            self._map[obj.hashValue] = idx
        }
    }
    
    func sorting(by sortDescriptors: [NSSortDescriptor]) -> OrderedSet<Element> {
        var new = self
        guard sortDescriptors.count > 0 else { return new }
        new.sort(using: sortDescriptors)
        return new
    }
}

extension Collection where Iterator.Element:AnyObject & Hashable {
    func orderedSet(using sortDescriptors: [NSSortDescriptor]) -> OrderedSet<Iterator.Element> {
        let s = OrderedSet<Iterator.Element>(elements: self)
        return s.sorting(by: sortDescriptors)
        
        let t : AnyObject
        
    }
}


