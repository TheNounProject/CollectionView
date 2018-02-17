
//
//  SortDescriptor.swift
//  CollectionView
//
//  Created by Wesley Byrne on 2/16/18.
//  Copyright © 2018 Noun Project. All rights reserved.
//

import Foundation


public enum SortDescriptorResult {
    case same
    case ascending
    case descending
}

public struct SortDescriptor<T> {
    
    public let ascending : Bool
    private let comparator : (T, T) -> SortDescriptorResult
    
    public init<V:Comparable>(_ keyPath: KeyPath<T,V>, ascending:Bool = true) {
        self.comparator = {
            let v1 = $0[keyPath: keyPath]
            let v2 = $1[keyPath: keyPath]
            if v1 == v2 { return .same }
            if v1 > v2 { return .descending }
            return .ascending
        }
        self.ascending = ascending
    }
    public init(_ comparator: @escaping ((T,T)->SortDescriptorResult), ascending: Bool = true) {
        self.comparator = comparator
        self.ascending = ascending
    }
    public func compare(_ a:T, to b:T) -> SortDescriptorResult {
        return comparator(a, b)
    }
}

protocol Comparer {
    associatedtype Compared
    var ascending: Bool { get }
    func compare(_ a: Compared, to b: Compared) -> SortDescriptorResult
}
extension SortDescriptor : Comparer { }

extension Sequence where Element: Comparer {
    func compare(_ element: Element.Compared, _ other: Element.Compared) -> SortDescriptorResult {
        for comparer in self {
            switch comparer.compare(element, to: other) {
            case .same: break
            case .descending: return comparer.ascending ? .descending : .ascending
            case .ascending: return comparer.ascending ? .ascending : .descending
            }
        }
        return .same
    }
}


public extension Array {
    public mutating func sort(using sortDescriptor: SortDescriptor<Element>) {
        self.sort(using: [sortDescriptor])
    }
    
    public mutating func sort(using sortDescriptors: [SortDescriptor<Element>]) {
        guard sortDescriptors.count > 0 else { return }
        self.sort { (a, b) -> Bool in
            return sortDescriptors.compare(a, b) == .ascending
        }
    }
    
    public mutating func insert(_ element: Element, using sortDescriptors: [SortDescriptor<Element>]) -> Int {
        if sortDescriptors.count > 0 {
            for (idx, existing) in self.enumerated() {
                if sortDescriptors.compare(element, existing) != .ascending {
                    self.insert(element, at: idx)
                    return idx
                }
            }
        }
        self.append(element)
        return self.count - 1
    }
}
    
extension Sequence {
    public func sorted(using sortDescriptor: SortDescriptor<Element>) -> [Element] {
        return self.sorted(using: [sortDescriptor])
    }
    
    public func sorted(using sortDescriptors: [SortDescriptor<Element>]) -> [Element] {
        guard sortDescriptors.count > 0 else { return Array(self) }
        return self.sorted { (a, b) -> Bool in
            return sortDescriptors.compare(a, b) == .ascending
        }
    }
}

