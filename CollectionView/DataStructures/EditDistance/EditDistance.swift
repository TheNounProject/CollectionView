//
//  ChangeSet.swift
//  CollectionView
//
//  Created by Wesley Byrne on 2/1/17.
//  Copyright © 2017 Noun Project. All rights reserved.
//

import Foundation



public enum EditOperation {
    case insertion
    case deletion
    case substitution
    case move(origin: Int)
    
    var isDeletion : Bool {
        switch self {
        case .deletion: return true
        default: return false
        }
    }
    
    var isInsertion : Bool {
        switch self {
        case .insertion: return true
        default: return false
        }
    }
}






public struct Edit<T: Hashable> : CustomStringConvertible, Hashable {
    
    public let operation: EditOperation
    public let value: T
    public let index: Int
    
    // Define initializer so that we don't have to add the `operation` label.
    public init(_ operation: EditOperation, value: T, index: Int) {
        self.operation = operation
        self.value = value
        self.index = index
    }
    
    static func insert(_ value: T, index: Int) -> Edit<T> {
        return Edit(.insertion, value: value, index: index)
    }
    static func replace(_ value: T, index: Int) -> Edit<T> {
        return Edit(.substitution, value: value, index: index)
    }
    static func delete(_ value: T, index: Int) -> Edit<T> {
        return Edit(.deletion, value: value, index: index)
    }
    static func move(_ value: T, from: Int, to: Int) -> Edit<T> {
        return Edit(.move(origin: from), value: value, index: to)
    }
    
    public var description: String {
        switch self.operation {
        case let .move(origin):
            return "Edit: Move \(self.value) from \(origin) to \(self.index)"
        case .substitution:
            return "Edit: Replace \(self.value) at \(self.index)"
        case .insertion:
            return "Edit: Insert \(self.value) at \(self.index)"
        case .deletion:
            return "Edit: Delete \(self.value) at \(self.index)"
        }
    }

    public var hashValue: Int { return value.hashValue }
    public static func ==(lhs: Edit<T>, rhs: Edit<T>) -> Bool {
        return lhs.value == rhs.value
    }
    
    func copy(with operation: EditOperation) -> Edit<T> {
        return Edit(operation, value: self.value, index: self.index)
    }
}



public struct ChangeSetOptions :OptionSet {
    
    public let rawValue: Int
    public static let minimumOperations = ChangeSetOptions(rawValue: 1 << 0)
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public typealias HashedIndexedSet<T:Hashable> = IndexedSet<T,T>


public struct EditOperationIndex<T:Hashable> {
    
    public var inserts = IndexedSet<Int, Edit<T>>()
    public var deletes = IndexedSet<Int, Edit<T>>()
    public var substitutions = IndexedSet<Int, Edit<T>>()
    public var moves = IndexedSet<Int, Edit<T>>()
    
    init(edits: [Edit<T>] = []) {
        for e in edits {
            switch e.operation {
            case .insertion:
                inserts.insert(e, for: e.index)
            case .deletion:
                deletes.insert(e, for: e.index)
            case .substitution:
                substitutions.insert(e, for: e.index)
            case .move(origin: _):
                moves.insert(e, for: e.index)
            }
        }
    }
    
    mutating func insert(_ value: T, index: Int) {
        inserts.insert(Edit(.insertion, value: value, index: index), for: index)
    }
    mutating func replace(_ value: T, index: Int) {
        substitutions.insert(Edit(.substitution, value: value, index: index), for: index)
    }
    mutating func delete(_ value: T, index: Int) {
        deletes.insert(Edit(.deletion, value: value, index: index), for: index)
    }
    
    var allEdits : [Edit<T>] {
       var edits = [Edit<T>]()
        edits.append(contentsOf: inserts.values)
        edits.append(contentsOf: deletes.values)
        edits.append(contentsOf: moves.values)
        edits.append(contentsOf: substitutions.values)
        return edits
    }
    
    public func edits(for value: T) -> [Edit<T>] {
        let mock = Edit(.insertion, value: value, index: 0)
        var edits = [Edit<T>]()
        if let i = self.inserts.index(of: mock),
            let e = self.inserts.value(for: i) {
            edits.append(e)
        }
        if let i = self.deletes.index(of: mock),
            let e = self.deletes.value(for: i) {
            edits.append(e)
        }
        if let i = self.substitutions.index(of: mock),
            let e = self.substitutions.value(for: i) {
            edits.append(e)
        }
        if let i = self.moves.index(of: mock),
            let e = self.moves.value(for: i) {
            edits.append(e)
        }
        return edits
    }
    
    public mutating func remove(edit: Edit<T>) {
        switch edit.operation {
        case .deletion: self.deletes.remove(edit)
        case .insertion: self.inserts.remove(edit)
        case .substitution: self.substitutions.remove(edit)
        case .move(origin: _): self.moves.remove(edit)
        }
    }
    
    public mutating func edit(withSource index: Int) -> Edit<T>? {
        return self.deletes.value(for: index)
            ?? self.substitutions.value(for: index)
            ?? self.moves.value(for: index)
    }
}




public struct EditDistance<T: Collection> where T.Iterator.Element: Hashable, T.Index == Int {
    
    public typealias Element = T.Iterator.Element
    
    /// The starting-point collection.
    public let origin: T
    
    /// The ending-point collection.
    public let destination: T

    lazy var operationIndex : EditOperationIndex<Element> = {
        return EditOperationIndex<Element>(edits: self.edits)
    }()
    
    public var edits: [Edit<Element>]
    
    
    
    public init(source s: T, target t: T, forceUpdates: Set<Element>? = nil, algorithm: DiffAware = Heckel()) {
        self.origin = s
        self.destination = t
        self.edits = algorithm.preprocess(old: s, new: t) ?? algorithm.diff(old: s, new: t)
    }
}



extension EditDistance : CustomStringConvertible {
    
    // TODO: This is really not performant, take out after dev
    public var description: String {
        var str = "ChangeSet<\(Element.self)> ["
        var other = self
        for e in other.operationIndex.allEdits {
            str += "\n\(e)"
        }
        str += "\n]"
        return str
    }
}

