//
//  OrderedSet.swift
//  CollectionView
//
//  Created by Wesley Byrne on 1/31/17.
//  Copyright © 2017 Noun Project. All rights reserved.
//

import Foundation

//typealias HashValue = Int

/// An implementation of an ordered set that favors lookup performance. Insertions and deletions 
// incur the penalty of updating an index map for all elements beyond the insertion/deletion index.

// There must be an implementation that could improve this but this works for now

public struct OrderedSet<Element: Hashable> : ExpressibleByArrayLiteral, Collection, CustomStringConvertible {
    
    fileprivate var _map = [Element:Int]()
    fileprivate var _data = [Element]()
    
    public var objects : [Element] { return _data }
    
    public init() { }
    
    public init<C : Collection>(elements: C) where C.Iterator.Element == Element {
        for (idx, e) in elements.enumerated() {
            guard _map[e] == nil else {
                continue
            }
            _data.append(e)
            _map[e] = idx
        }
    }
    
    public init(arrayLiteral elements: Element...) {
        for (idx, e) in elements.enumerated() {
            guard _map[e] == nil else {
                continue
            }
            _data.append(e)
            _map[e] = idx
        }
    }
    
    public var description: String {
        var str = "\(type(of: self)) [\n"
        for i in self.enumerated() {
            str += "\(i.offset) : \(i.element) \(i.element.hashValue)\n"
        }
        str += "]"
        return str
    }
    
    
    
    
    public var startIndex: Int { return _data.startIndex }
    public var endIndex: Int { return _data.endIndex }
    
    public func index(after i: Int) -> Int {
        return _data.index(after: i)
    }
    
    public subscript(index: Int) -> Element {
        return _data[index]
    }
    
    public var count : Int { return _data.count }
    public func contains(_ object: Element) -> Bool{
        return _map[object] != nil
    }
    
    public func index(of object: Element) -> Int? {
        return _map[object]
    }
    
    public func object(at index: Int) -> Element {
        return _data[index]
    }
    public func _object(at index: Int) -> Element? {
        guard index < self.count && index >= 0 else { return nil }
        return _data[index]
    }
    
    fileprivate mutating func _remap(startingAt index: Int = 0) {
        guard index < _data.count else { return }
        for idx in index..<_data.count {
            self._map[_data[idx]] = idx
        }
    }
    
    public func object(before other: Element) -> Element? {
        guard let idx = self.index(of: other) else { return nil }
        return self._object(at: idx - 1)
    }
    public func object(after other: Element) -> Element? {
        guard let idx = self.index(of: other) else { return nil }
        return self._object(at: idx + 1)
    }
    
    
    // MARK: - Appending
    /*-------------------------------------------------------------------------------*/

    @discardableResult public mutating func append(_ object: Element) -> Bool {
        guard !self.contains(object) else { return false }
        self.needsSort = true
        _data.append(object)
        _map[object] = _data.count - 1
        return true
    }
    
    public mutating func append<C : Collection>(contentsOf newElements: C) where C.Iterator.Element == Element {
        for e in newElements {
            self.append(e)
        }
    }

    
    // MARK: - Inserting
    /*-------------------------------------------------------------------------------*/
    
    @discardableResult mutating public func insert(_ object: Element, at index: Int) -> Bool {
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
    @discardableResult public mutating func remove(at index: Int) -> Element {
        let e = self._data.remove(at: index)
        _map.removeValue(forKey: e)
        _remap(startingAt: index)
        return e
    }
    
    @discardableResult public mutating func remove(_ object: Element) -> Int? {
        guard let index = self.index(of: object) else { return nil }
        remove(at: index)
        return index
    }
    
    var needsSort : Bool = false
    mutating func _batchRemove(_ object: Element) {
        self.needsSort = true
        guard let index = self._map.removeValue(forKey: object) else { return }
        remove(at: index)
    }
    mutating func _batchRemove(at index: Int) {
        self.needsSort = true
        let e = self._data.remove(at: index)
        _map[e] = nil
    }
    
    
    public mutating func removeAll(keepingCapacity keep: Bool = false) {
        self.needsSort = false
        _data.removeAll(keepingCapacity: keep)
        _map.removeAll(keepingCapacity: keep)
    }
    
}


extension OrderedSet where Element:Comparable {
    
    public mutating func sort() {
        self.needsSort = false
        _data.sort()
        _remap(startingAt: 0)
    }
    
    public func sorted() {
        var new = self
        new._data.sort()
        new.needsSort = false
        new._remap(startingAt: 0)
    }

}

extension OrderedSet {
    
    public mutating func insert(_ object: Element, using sortDescriptors: [SortDescriptor<Element>]) -> Int {
        _ = self.remove(object)
        let idx = self._data.insert(object, using: sortDescriptors)
        _remap(startingAt: idx)
        return idx
    }
    
    public mutating func insert<C : Collection>(contentsOf newElements: C, using sortDescriptors: [SortDescriptor<Element>]) where C.Iterator.Element == Element {
        
        // TODO:
        for e in newElements {
            _ = self.insert(e, using: sortDescriptors)
        }
        /*
        var new = newElements.sorted(using: sortDescriptors)
        var fMatch = self._data.count
        
        var remove = IndexSet()
        
        for obj in new.reversed() {
            if let index = self.index(of: obj) {
                remove.insert(index)
            }
        }
        
        fMatch = remove.first ?? self._data.count
        for idx in remove.reversed() {
            _data.remove(at: idx)
        }
        
        var checkIdx = 0
        while new.count > 0, checkIdx < _data.count {
            let check = _data[checkIdx]
            if sortDescriptors.compare(new[0], to: check) == .orderedAscending {
                if checkIdx < fMatch { fMatch = checkIdx }
                _data.insert(new[0], at: checkIdx)
                new.removeFirst()
            }
            checkIdx += 1
        }
        
        for n in new {
            _data.append(n)
        }
        self._remap(startingAt: fMatch)
 */
    }
    
    public mutating func sort(using sortDescriptor: SortDescriptor<Element>) {
        self._data.sort(using: sortDescriptor)
        self._map.removeAll(keepingCapacity: true)
        self._remap()
    }
    
    public mutating func sort(using sortDescriptors: [SortDescriptor<Element>]) {
        guard sortDescriptors.count > 0 else { return }
        self._data.sort(using: sortDescriptors)
        self._map.removeAll(keepingCapacity: true)
        self._remap()
    }
    
    public func sorted(using sortDescriptors: [SortDescriptor<Element>]) -> OrderedSet<Element> {
        var new = self
        new.sort(using: sortDescriptors)
        return new
    }
    
    public mutating func sort(by sort: ((Element, Element)-> Bool)) {
        self._data = self._data.sorted(by: sort)
        self._map.removeAll(keepingCapacity: true)
        self._remap()
    }
    
    public func sorted(by sort: ((Element, Element)-> Bool)) -> OrderedSet<Element> {
        let data = self._data.sorted(by: sort)
        return OrderedSet(elements: data)
    }
}

extension Collection where Iterator.Element:Hashable {
    public func orderedSet(using sortDescriptors: [SortDescriptor<Iterator.Element>]) -> OrderedSet<Iterator.Element> {
        let s = OrderedSet<Iterator.Element>(elements: self)
        return s.sorted(using: sortDescriptors)
    }
}


