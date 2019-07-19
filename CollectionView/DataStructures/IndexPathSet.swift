//
//  IndexPathSet.swift
//  CollectionView
//
//  Created by Wesley Byrne on 2/27/18.
//  Copyright © 2018 Noun Project. All rights reserved.
//

import Foundation

struct IndexPathSet: Sequence {
    
    typealias Element = IndexPath
    
    private var storage = [Int: IndexSet]()
    
    typealias Iterator = AnyIterator<IndexPath>
    func makeIterator() -> Iterator {
        var s: Int = 0
        var data = storage.sorted { (a, b) -> Bool in
            return a.key < b.key
        }
        
        return AnyIterator {
            if s >= data.count - 1 { return nil }
            if let v = data[s].value.
            if let v = data
            guard let c = self.storage[s] else { return nil }
            if let e = c.last
            return IndexPath()
        }
    }
    
    mutating func insert(_ indexPath: IndexPath) {
        if self.storage[indexPath._section] == nil {
            self.storage[indexPath._item] = IndexSet(integer: indexPath._item)
        } else {
            self.storage[indexPath._section]!.insert(indexPath._item)
        }
    }
    
    func contains(_ indexPath: IndexPath) -> Bool {
        return storage[indexPath._section]?.contains(indexPath._item) == true
    }
    
}
