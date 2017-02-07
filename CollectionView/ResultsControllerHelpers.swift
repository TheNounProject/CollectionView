//
//  ResultsControllerHelpers.swift
//  CollectionView
//
//  Created by Wesley Byrne on 1/12/17.
//  Copyright © 2017 Noun Project. All rights reserved.
//

import Foundation



extension NSManagedObject {
    var idSuffix : String {
        let str = self.objectID.uriRepresentation().lastPathComponent
        if self.objectID.isTemporaryID {
            let from = -3
            let idx = str.index(from >= 0 ? str.startIndex: str.endIndex,
                                 offsetBy: from)
            return str.substring(from: idx)
        }
        return self.objectID.uriRepresentation().lastPathComponent
    }
}


public extension Array where Element:NSSortDescriptor {
    
    func description(of object: AnyObject) -> String {
        guard self.count > 0 else { return "nil" }
        
        var values = [String]()
        
        for sort in self {
            guard let key = sort.key else {
                values.append("??")
                continue
            }
            guard let value = object.value(forKey: key) else {
                values.append("nil")
                continue
            }
            values.append("\(value)")
        }
        
        if values.count > 1 {
            return "[\(values.joined(separator: ", "))]"
        }
        return values.first ?? "nil"
    }
    
    
    func forEachKey<T:Collection>(describing objects: T, do block:(_ key: String, _ object: T.Iterator.Element)->Void) {
        var validKeys = [String]()
        for sort in self {
            if let key = sort.key {
                validKeys.append(key)
            }
        }
        guard validKeys.count > 0 else {
            print("Empty sort descriptor array")
            return
        }
        for obj in objects {
            for k in validKeys {
                block(k, obj)
            }
        }
    }

    
    func compare(_ anObject: AnyObject, to otherObject: AnyObject) -> ComparisonResult {
        guard self.count > 0 else { return .orderedAscending }
        for sortDesc in self {
            
            guard let key = sortDesc.key else { continue }
            let v1 = anObject.value(forKeyPath: key)
            let v2 = otherObject.value(forKeyPath: key)
            if v1 == nil && v2 == nil {
                continue
            }
            let res = sortDesc.compare(anObject, to: otherObject)
            if res == .orderedSame { continue }
            return res
        }
        return .orderedDescending
    }
    
}

extension Sequence where Iterator.Element: NSSortDescriptor {
    
    
}





public extension Sequence where Iterator.Element: AnyObject {
    
    public func sorted(using sortDescriptors: [NSSortDescriptor]) -> [Iterator.Element] {
        guard sortDescriptors.count > 0 else { return Array(self) }
        
        return self.sorted(by: { (o1, o2) -> Bool in
            return sortDescriptors.compare(o1, to: o2) == .orderedAscending
        })
    }
    
}


public extension Array where Element:AnyObject {
    
    mutating public func sort(using sortDescriptors: [NSSortDescriptor]) {
        guard sortDescriptors.count > 0 else { return }
        self.sort { (o1, o2) -> Bool in
            return sortDescriptors.compare(o1, to: o2) == .orderedAscending
        }
    }
    
    public func insertionIndex(of object: Element, using sortDescriptors: [NSSortDescriptor]) -> Int {
        guard sortDescriptors.count > 0 else { return self.count }
        
        for (idx, element) in self.enumerated() {
            if sortDescriptors.compare(object, to: element) == .orderedAscending { return idx }
        }
        return self.count
    }
    
    mutating public func insert(_ object: Element, using sortDescriptors: [NSSortDescriptor]) -> Int {
        if sortDescriptors.count > 0 {
            for (idx, element) in self.enumerated() {
                if sortDescriptors.compare(object, to: element) == .orderedAscending {
                    self.insert(object, at: idx)
                    return idx
                }
            }
        }
        self.append(object)
        return self.count - 1
    }
}

