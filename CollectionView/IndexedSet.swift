//
//  IndexedSet.swift
//  CollectionView
//
//  Created by Wes Byrne on 1/20/17.
//  Copyright © 2017 Noun Project. All rights reserved.
//

import Foundation




struct IndexedSet<Index: Hashable, Object: Hashable> : Sequence {
    
    private var byObject = [Object:Index]()
    private var byIndex = [Index:Object]()
    
    fileprivate var _sequenced = OrderedSet<Object>()
    
    var objects : [Object] {
        return _sequenced.objects
    }
    
    func object(for indexPath: Index) -> Object? {
        return byIndex[indexPath]
    }
    func index(for object: Object) -> Index? {
        return byObject[object]
    }
    
    var count : Int {
        return byObject.count
    }
    
    
    func contains(_ object: Object) -> Bool {
        return byObject[object] != nil
    }
    func contains(_ index: Index) -> Bool {
        return byIndex[index] != nil
    }
    
    
    mutating func insert(_ object: Object, for index: Index) {
        
        if let idx = byObject.removeValue(forKey: object) {
            byIndex.removeValue(forKey: idx)
            _sequenced.remove(object)
        }
        
        byObject[object] = index
        byIndex[index] = object
        _sequenced.append(object)
    }
    
    mutating func remove(_ index: Index) -> Object? {
        guard let object = byIndex.removeValue(forKey: index) else {
            return nil
        }
        byObject.removeValue(forKey: object)
        _sequenced.remove(object)
        return object
    }
    mutating func remove(_ object: Object) -> Index? {
        guard let index = byObject.removeValue(forKey: object) else {
            return nil
        }
        byIndex.removeValue(forKey: index)
        _sequenced.remove(object)
        return index
    }
    
    mutating func removeAll() {
        byObject.removeAll()
        byIndex.removeAll()
        _sequenced.removeAll()
    }
    
    typealias Iterator = AnyIterator<(index: Index, object: Object)>
    func makeIterator() -> Iterator {
        
        var it = _sequenced.makeIterator()
        return AnyIterator {
            if let val = it.next() {
                return (self.byObject[val]!, val)
            }
            return nil
        }
    }
}


extension IndexedSet where Index:Comparable {
    
    
    
    mutating func sort() {
        _sequenced.sorted { (o1, o2) -> Bool in
            guard let i1 = index(for: o1),
                let i2 = index(for: o2) else {
                    return true
            }
            return i1 < i2
        }
    
    }
    
    mutating func sorted() {
        _sequenced.sorted { (o1, o2) -> Bool in
            guard let i1 = index(for: o1),
                let i2 = index(for: o2) else {
                    return true
            }
            return i1 < i2
        }
        
    }
    
    
}









