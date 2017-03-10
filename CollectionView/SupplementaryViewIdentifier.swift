//
//  SupplementaryViewIdentifier.swift
//  CollectionView
//
//  Created by Wesley Byrne on 3/3/17.
//  Copyright © 2017 Noun Project. All rights reserved.
//

import Foundation




struct SupplementaryViewIdentifier: Hashable, CustomStringConvertible {
    
    var indexPath: IndexPath?
    var kind: String
    var reuseIdentifier : String
    
    var hashValue: Int {
        if let ip = self.indexPath {
            return "\(ip._section)/\(self.kind)".hashValue
        }
        return "\(self.kind)/\(self.reuseIdentifier)".hashValue
    }
    init(kind: String, reuseIdentifier: String, indexPath: IndexPath? = nil) {
        self.kind = kind
        self.reuseIdentifier = reuseIdentifier
        self.indexPath = indexPath
    }
    
    func copy(with indexPath: IndexPath) -> SupplementaryViewIdentifier {
        var s = self
        s.indexPath = indexPath
        return s
    }
    
    static func ==(lhs: SupplementaryViewIdentifier, rhs: SupplementaryViewIdentifier) -> Bool {
        return lhs.indexPath == rhs.indexPath && lhs.kind == rhs.kind && lhs.reuseIdentifier == rhs.reuseIdentifier
    }
    
    var description: String {
        return  "SupplementaryViewIdentifier: Kind \(kind), reuseID: \(reuseIdentifier) indexPath: \(indexPath?.description ?? "nil")"
        
    }
}

extension SupplementaryViewIdentifier : Comparable {
    static func <(lhs: SupplementaryViewIdentifier, rhs: SupplementaryViewIdentifier) -> Bool {
        guard let l = lhs.indexPath, let r = rhs.indexPath else { return true }
        return l < r
    }
}
