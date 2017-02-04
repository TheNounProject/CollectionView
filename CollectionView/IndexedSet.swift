//
//  IndexedSet.swift
//  CollectionView
//
//  Created by Wes Byrne on 1/20/17.
//  Copyright © 2017 Noun Project. All rights reserved.
//

import Foundation



//struct IndexedSetIndex<Index:Hashable, Value: Hashable> {
//    fileprivate let index: DictionaryIndex<Index, Value>
//    fileprivate init(_ dictionaryIndex: DictionaryIndex<Index, Value>) {
//        self.index = dictionaryIndex
//    }
//}


public struct IndexedSet<Index: Hashable, Value: Hashable> : Sequence, CustomStringConvertible {
    
    
    //    var table = MapTab
    fileprivate var byValue = [Int:Index]()
    fileprivate var byIndex = [Index:Value]()
    
    //    fileprivate var _sequenced = OrderedSet<Value>()
    
    public var indexes : [Index] {
        return Array(byIndex.keys)
    }
    public var values : [Value] {
        return Array(byIndex.values)
    }
    
    public var count : Int {
        return byValue.count
    }
    
    public func value(for index: Index) -> Value? {
        return byIndex[index]
    }
    public func index(of value: Value) -> Index? {
        return byValue[value.hashValue]
    }
    
    
    public init() { }
    
    public subscript(index: Index) -> Value? {
        get { return value(for: index) }
        set(newValue) {
            if let v = newValue { insert(v, with: index) }
            else { _ = removeValue(for: index) }
        }
    }
    
    // Collection Protocol
//    typealias Index = IndexedSetIndex<Index, Value>
//    public func index(after i: Index) -> Index {
//        return byValue.index(after: i)
//    }
//    public var startIndex: Index { return byValue.startIndex }
//    public var endIndex: Index { return byValue.endIndex }
    
    
    public var description: String {
        var str = "\(type(of: self)) [\n"
        for i in self {
            str += "\(i.index) : \(i.value)\n"
        }
        str += "]"
        return str
    }
    
    public func contains(_ object: Value) -> Bool {
        return byValue[object.hashValue] != nil
    }
    public func containsValue(for index: Index) -> Bool {
        return byIndex[index] != nil
    }
    
    
    public mutating func update(_ value: Value, with index: Index) {
        if let oldIndex = byValue.updateValue(index, forKey: value.hashValue) {
            byIndex.removeValue(forKey: oldIndex)
        }
        byIndex[index] = value
        assert(byIndex.count == byValue.count)
    }
    
    public mutating func insert(_ value: Value, with index: Index) {
        guard byValue[value.hashValue] == nil else { return }
        if let object = self.byIndex.removeValue(forKey: index) {
            byValue.removeValue(forKey: object.hashValue)
        }
        
        byValue[value.hashValue] = index
        byIndex[index] = value
        assert(byIndex.count == byValue.count)
    }
    
    public mutating func removeValue(for index: Index) -> Value? {
        guard let object = byIndex.removeValue(forKey: index) else {
            return nil
        }
        byValue.removeValue(forKey: object.hashValue)
        assert(byIndex.count == byValue.count)
        return object
    }
    mutating func remove(_ value: Value) -> Index? {
        guard let index = byValue.removeValue(forKey: value.hashValue) else {
            return nil
        }
        byIndex.removeValue(forKey: index)
        assert(byIndex.count == byValue.count)
        return index
    }
    
    public mutating func removeAll() {
        byValue.removeAll()
        byIndex.removeAll()
        
        for i in self {
            
        }
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
    
    func index(ofHash hash: HashValue) -> Index? {
        return byValue[hash]
    }
    func value(withHash hash: HashValue) -> Value? {
        guard let i = byValue[hash] else { return nil }
        return self.value(for: i)
    }
    func containsValue(withHash hash: HashValue) -> Bool {
        return byValue[hash] != nil
    }
    
}


extension IndexedSet where Index:Comparable {
    
    var orderedIndexes : [Index] {
        return self.byIndex.keys.sorted()
    }
    
    func ordered() -> [Iterator.Element] {
        return self.makeIterator().sorted { (a, b) -> Bool in
            return a.index < b.index
        }
    }
    
    var orderedValues : [Value] {
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




