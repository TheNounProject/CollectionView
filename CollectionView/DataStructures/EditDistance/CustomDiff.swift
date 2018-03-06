//
//  CustomDiff.swift
//  CollectionView
//
//  Created by Wesley Byrne on 2/26/18.
//  Copyright © 2018 Noun Project. All rights reserved.
//

import Foundation


public final class CVDiff : DiffAware {
    
    public init() { }
    
    public func diff<T>(old: T, new: T) -> [Edit<T.Element>] where T : Collection, T.Element : Hashable, T.Index == Int, T.IndexDistance == Int {
        
        let sourceSet = old.indexedSet
        let targetSet = new.indexedSet
        
        var insertions = IndexSet()
        var deletions = IndexSet()
        
        var _edits = EditOperationIndex<T.Iterator.Element>()
        
        for value in Set(old).union(new) {
            
            let sIdx = sourceSet.index(of: value)
            let tIdx = targetSet.index(of: value)
            
            if let s = sIdx, let t = tIdx {
                if s == t {
                    
                }
                else {
                    let adjust = insertions.count(in: 0...s) - deletions.count(in: 0...s)
                    if s + adjust == t {
                        continue
                    }
                    _edits.delete(value, index: s)
                    _edits.insert(value, index: t)
                    insertions.insert(t)
                    deletions.insert(s)
                }
            }
            else if let idx = sIdx {
                _edits.delete(value, index: idx)
                deletions.insert(idx)
            }
            else if let idx = tIdx {
                _edits.insert(value, index: idx)
                insertions.insert(idx)
            }
        }
        return reduceEdits(_edits)
    }
    
    public func reduceEdits<T>(_ edits: EditOperationIndex<T>) -> [Edit<T>] {
        
        var res = [Edit<T>]()
        var edits = edits
        
        print("inserts: \(edits.inserts.count)")
        print("deletes: \(edits.deletes.count)")
        for target in edits.inserts {
            guard edits.deletes.contains(target.value), let source = edits.deletes.remove(target.value) else {
                res.append(target.value)
                continue
            }
            let newEdit = Edit(.move(origin: source), value: target.value.value, index: target.index)
            res.append(newEdit)
        }
        res.append(contentsOf: edits.deletes.values)
        res.append(contentsOf: edits.moves.values)
        res.append(contentsOf: edits.substitutions.values)
        return res
    }
}
