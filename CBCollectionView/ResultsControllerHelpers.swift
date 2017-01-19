//
//  ResultsControllerHelpers.swift
//  CBCollectionView
//
//  Created by Wesley Byrne on 1/12/17.
//  Copyright © 2017 Noun Project. All rights reserved.
//

import Foundation




public extension Sequence where Iterator.Element: AnyObject {
    
    public func sorted(using sortDescriptors: [NSSortDescriptor]) -> [Iterator.Element] {
        guard sortDescriptors.count > 0 else { return Array(self) }
        
        return self.sorted(by: { (o1, o2) -> Bool in
            return sortDescriptors.compare(o1, to: o2) == .orderedAscending
        })
    }
}



public extension Array where Element: AnyObject {
    
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




public extension Array where Element:NSSortDescriptor {
    
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
