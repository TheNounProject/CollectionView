//
//  IndexedSet.swift
//  CollectionView
//
//  Created by Wes Byrne on 1/20/17.
//  Copyright © 2017 Noun Project. All rights reserved.
//

import Foundation

public struct IndexedSet<Index: Hashable, Value: Hashable> : Sequence, CustomDebugStringConvertible, ExpressibleByDictionaryLiteral {
    
    //    var table = MapTab
    fileprivate var byValue = [Value: Index]()
    fileprivate var byIndex = [Index: Value]()
    
    //    fileprivate var _sequenced = OrderedSet<Value>()
    
    public var indexes: [Index] {
        return Array(byIndex.keys)
    }
    public var indexSet: Set<Index> {
        return Set(byIndex.keys)
    }
    
    public var dictionary: [Index: Value] {
        return byIndex
    }
    
    public var values: [Value] {
        return Array(byIndex.values)
    }
    public var valuesSet: Set<Value> {
        return Set(byIndex.values)
    }
    
    public var count: Int {
        return byValue.count
    }
    public var isEmpty: Bool {
        return byValue.isEmpty
    }
    
    public func value(for index: Index) -> Value? {
        return byIndex[index]
    }
    public func index(of value: Value) -> Index? {
        return byValue[value]
    }
    
    public init() { }
    
    public init(dictionaryLiteral elements: (Index, Value)...) {
        for e in elements {
            self.insert(e.1, for: e.0)
        }
    }
    public init(_ dictionary: [Index: Value]) {
        for e in dictionary {
            self.insert(e.1, for: e.0)
        }
    }
    
    public subscript(index: Index) -> Value? {
        get { return value(for: index) }
        set(newValue) {
            if let v = newValue { insert(v, for: index) } else { _ = removeValue(for: index) }
        }
    }
    
    public var debugDescription: String {
        var str = "\(type(of: self)) [\n"
        for i in self {
            str += "\(i.index) : \(i.value)\n"
        }
        str += "]"
        return str
    }
    
    public func contains(_ object: Value) -> Bool {
        return byValue[object] != nil
    }
    public func containsValue(for index: Index) -> Bool {
        return byIndex[index] != nil
    }
    
    /// Set the value-index pair removing any existing entries for either
    ///
    /// - Parameter value: The value
    /// - Parameter index: The index
    public mutating func set(_ value: Value, for index: Index) {
        self.removeValue(for: index)
        self.remove(value)
        byValue[value] = index
        byIndex[index] = value
    }
    
    /// Insert value for the given index if the value does not exist.
    ///
    /// - Parameter value: A value
    /// - Parameter index: An index
    public mutating func insert(_ value: Value, for index: Index) {
        self.set(value, for: index)
    }
    
    @discardableResult public mutating func removeValue(for index: Index) -> Value? {
        guard let value = byIndex.removeValue(forKey: index) else {
            return nil
        }
        byValue.removeValue(forKey: value)
        return value
    }
    @discardableResult public mutating func remove(_ value: Value) -> Index? {
        guard let index = byValue.removeValue(forKey: value) else {
            return nil
        }
        byIndex.removeValue(forKey: index)
        return index
    }
    
    public mutating func removeAll() {
        byValue.removeAll()
        byIndex.removeAll()
    }
    
    public typealias Iterator = AnyIterator<(index: Index, value: Value)>
    public func makeIterator() -> Iterator {
        var it = byIndex.makeIterator()
        return AnyIterator {
            if let val = it.next() {
                return (val.key, val.value)
            }
            return nil
        }
    }
}

extension IndexedSet {
    func union(_ other: IndexedSet) -> IndexedSet {
        var new = self
        for e in other.byIndex {
            new.insert(e.value, for: e.key)
        }
        return new
    }
}

extension Array where Element: Hashable {
    public var indexedSet: IndexedSet<Int, Element> {
        var set = IndexedSet<Int, Element>()
        for (idx, v) in self.enumerated() {
            set.insert(v, for: idx)
        }
        return set
    }
}

extension Collection where Iterator.Element: Hashable {
    public var indexedSet: IndexedSet<Int, Iterator.Element> {
        var set = IndexedSet<Int, Iterator.Element>()
        for (idx, v) in self.enumerated() {
            set.insert(v, for: idx)
        }
        return set
    }
}

extension IndexedSet where Index: Comparable {
    
    var orderedIndexes: [Index] {
        return self.byIndex.keys.sorted()
    }
    
    func ordered() -> [Iterator.Element] {
        return self.makeIterator().sorted { (a, b) -> Bool in
            return a.index < b.index
        }
    }
    
    func orderedLog() -> String {
        var str = "\(type(of: self)) [\n"
        for i in self.ordered() {
            str += "\(i.index) : \(i.value)\n"
        }
        str += "]"
        return str
    }
    
    var orderedValues: [Value] {
        let sorted = self.byIndex.sorted(by: { (v1, v2) -> Bool in
            return v1.key < v2.key
        })
        var res = [Value]()
        for element in sorted {
            res.append(element.value)
        }
        return res
    }
    
}
