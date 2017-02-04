//
//  ChangeSet.swift
//  CollectionView
//
//  Created by Wesley Byrne on 2/1/17.
//  Copyright © 2017 Noun Project. All rights reserved.
//

import Foundation



public struct Matrix2D<T> : CustomStringConvertible {
    var _storage = [[T]]()
    
    public var rows: Int {
        return _storage.count
    }
    public var columns : Int {
        return _storage.first?.count ?? 0
    }
    
    public init(rows: Int, columns: Int, default value: T) {
        var sub = [T](repeating: value, count: rows)
        _storage = [[T]](repeating: sub, count: columns)
    }
    
    public subscript(row: Int, column: Int) -> T {
        get {
            // This could validate arguments.
            return _storage[row][column]
        }
        set {
            // This could also validate.
            _storage[row][column] = newValue
        }
    }
    
    public func value(at row: Int, column: Int) -> T {
        return self[row, column]
    }
    
    public var description: String {
        return dump({ (v) -> Any in
            return "\(v)"
        })
    }
    
    public func dump(_ describe : (T)->Any) -> String {
        var str = ""
        for r in 0..<rows {
            for c in 0..<columns {
                let desc = describe(self[r, c])
                str += "\(desc)  "
            }
            str += "\n"
        }
        return str
    }
}


public struct Edit<T: Hashable> : CustomStringConvertible, Hashable {
    public let operation: EditOperation
    public let value: T
    public let destination: Int
    
    // Define initializer so that we don't have to add the `operation` label.
    public init(_ operation: EditOperation, value: T, destination: Int) {
        self.operation = operation
        self.value = value
        self.destination = destination
    }
    
    public var description: String {
        return "Edit: \(operation) Destination: \(self.destination)  \(value)"
    }

    public var hashValue: Int { return value.hashValue }
    public static func ==(lhs: Edit<T>, rhs: Edit<T>) -> Bool {
        return lhs.value == rhs.value
    }
    
    func copy(with operation: EditOperation) -> Edit<T> {
        return Edit(operation, value: self.value, destination: self.destination)
    }
}

/** Defines the type of an `Edit`.
 - note: I would have liked to make it an `Edit.Operation` subtype, but that's currently not allowed inside a generic type.
 */
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

public struct ChangeSetOptions :OptionSet {
    
    public let rawValue: Int
    public static let minimumOperations = ChangeSetOptions(rawValue: 1 << 0)
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
//    static let secondDay  = ChangeSetOptions(rawValue: 1 << 1)
//    static let priority   = ChangeSetOptions(rawValue: 1 << 2)
//    static let standard   = ChangeSetOptions(rawValue: 1 << 3)
    
    
}

public typealias HashedIndexedSet<T:Hashable> = IndexedSet<T,T>


public struct EditOperationIndex<T:Hashable> {
    
        public var inserts = HashedIndexedSet<Edit<T>>()
        public var deletes = HashedIndexedSet<Edit<T>>()
        public var substitutions = HashedIndexedSet<Edit<T>>()
        public var moves = HashedIndexedSet<Edit<T>>()
    
    init(edits: [Edit<T>]) {
        for e in edits {
            switch e.operation {
            case .insertion:
                inserts.insert(e, with: e)
            case .deletion:
                deletes.insert(e, with: e)
            case .substitution:
                substitutions.insert(e, with: e)
            case .move(origin: _):
                moves.insert(e, with: e)
            }
        }
    }
    
    var allEdits : [Edit<T>] {
       var edits = [Edit<T>]()
        edits.append(contentsOf: inserts.values)
        edits.append(contentsOf: deletes.values)
        edits.append(contentsOf: moves.values)
        edits.append(contentsOf: substitutions.values)
        return edits
    }
}

public struct ChangeSet<T: Collection> where T.Iterator.Element: Hashable, T.IndexDistance == Int {
    
    public typealias Element = T.Iterator.Element
    
    /// The starting-point collection.
    public let origin: T
    
    /// The ending-point collection.
    public let destination: T
    public let matrix : Matrix2D<[Edit<Element>]>

    public lazy var operationIndex : EditOperationIndex<Element> = {
        return EditOperationIndex<Element>(edits: self.edits)
    }()
    
    public var edits: [Edit<Element>]
    
    public mutating func edit(for value: Element) -> Edit<Element>? {
        return self.operationIndex.inserts.value(withHash: value.hashValue)
            ?? self.operationIndex.deletes.value(withHash: value.hashValue)
            ?? self.operationIndex.substitutions.value(withHash: value.hashValue)
            ?? self.operationIndex.moves.value(withHash: value.hashValue)
    }
    
    
    public init(source s: T, target t: T, options: ChangeSetOptions = []) {
        self.origin = s
        self.destination = t
        
        
        
        let m = s.count
        let n = t.count
        
        let shared = Set(s).intersection(t)
        // Fill first row and column of insertions and deletions.
        
        var _matrix = Matrix2D(rows: n+1, columns: m+1, default: [Edit<Element>]())
        
        var edits = [Edit<Element>]()
        for (row, element) in s.enumerated() {
            let deletion = Edit(.deletion, value: element, destination: row)
            edits.append(deletion)
            _matrix[row + 1, 0] = edits
        }
        
        edits.removeAll()
        for (col, element) in t.enumerated() {
            let insertion = Edit(.insertion, value: element, destination: col)
            edits.append(insertion)
            _matrix[0, col + 1] = edits
        }
        
        guard m > 0 && n > 0 else {
            self.edits = _matrix[m, n]
            self.matrix = _matrix
            return
        }
        
        // Indexes into the two collections.
        var sx: T.Index
        var tx = t.startIndex
        
        var _inserted = Set<Element>()
        var _deleted = Set<Element>()

        
        // Fill body of _matrix.
        
        for j in 1...n {
            sx = s.startIndex
            
            for i in 1...m {
                if s[sx] == t[tx] {
                    _matrix[i, j] = _matrix[i - 1, j - 1] // no operation
                } else {
                    
                    var del = _matrix[i - 1, j] // a deletion
                    var ins = _matrix[i, j - 1] // an insertion
                    var sub = _matrix[i - 1, j - 1] // a substitution
                    
                    // Record operation.
                    
                    let src = s[sx]
                    let trg = t[tx]
                    
                    var forceDelete = false
                    var forceInsert = false
                    
                    if options.contains(.minimumOperations) == false {
                        if shared.contains(src) {
                            forceDelete = _deleted.contains(src) != nil
                            forceInsert = !forceDelete
                        }
                        else if shared.contains(trg) {
                            forceDelete = _deleted.contains(trg) != nil
                            forceInsert = !forceDelete
                        }
                    }
                    
                    let minimumCount = min(del.count, ins.count, sub.count)
                    if forceDelete || del.count == minimumCount {
                        let deletion = Edit(.deletion, value: src, destination: i - 1)
                        del.append(deletion)
                        _deleted.insert(src)
                        _matrix[i, j] = del
                    }
                    else if forceInsert || ins.count == minimumCount {
                        let insertion = Edit(.insertion, value: trg, destination: j - 1)
                        _inserted.insert(trg)
                        ins.append(insertion)
                        _matrix[i, j] = ins
                    }
                    else {
                        let substitution = Edit(.substitution, value: trg, destination: i - 1)
                        sub.append(substitution)
                        _matrix[i, j] = sub
                    }
                }
                
                sx = s.index(sx, offsetBy: 1)
            }
            
            tx = t.index(tx, offsetBy: 1)
        }
        self.edits = _matrix[m, n]
        self.matrix = _matrix
        
        print(self.matrixLog)

    }
    
    
    
    
    
    public mutating func reduceEdits() {
        
        
        for d in self.operationIndex.deletes {
            if let i = self.operationIndex.inserts.remove(d.value) {
                
                self.operationIndex.deletes.removeValue(for: d.value)
                let newEdit = Edit(.move(origin: d.index.destination), value: d.value.value, destination: i.destination)
                self.operationIndex.moves.insert(newEdit, with: newEdit)
            }
            
            
            
        }
        
        self.edits = self.operationIndex.allEdits
        
        /*
        edits.reduce([Edit<Element>]()) { (edits, edit) in
            var reducedEdits = edits
            if let (move, index) = move(from: edit, in: reducedEdits), case let .move(origin) = move.operation {
                reducedEdits.remove(at: index)
                if move.destination == origin {
                    let n = Edit(.substitution, value: edit.value, destination: origin)
                    reducedEdits.append(n)
                }
                else {
                    reducedEdits.append(move)
                }
            } else {
                reducedEdits.append(edit)
            }
            return reducedEdits
        }
        */
    }
    
    
    public var matrixLog : String {
        return matrix.dump({ (v) -> Any in
            return v.count
        })
    }
    
    
    /** Returns the edit steps required to go from one collection to another.
     
     The number of steps is the `count` of elements.
     
     - note: Indexes in the returned `Edit` elements are into the `from` source collection (just like how `UITableView` expects changes in the `beginUpdates`/`endUpdates` block.)
     
     - seealso:
	    - [Edit distance and edit steps](http://davedelong.tumblr.com/post/134367865668/edit-distance-and-edit-steps) by [Dave DeLong](https://twitter.com/davedelong).
	    - [Explanation of and Pseudo-code for the Wagner-Fischer algorithm](https://en.wikipedia.org/wiki/Wagner–Fischer_algorithm).
     
     - parameters:
	    - from: The starting-point collection.
	    - to: The ending-point collection.
     
     - returns: An array of `Edit` elements.
     */
//    static private func editOperations(from source: T, to target: T, options: ChangeSetOptions = []) -> (matrix: Matrix2D<[Edit<Element>]>,  edits: [Edit<Element>]) {
//        
//        var s = source
//        var t = target
//        
//        let m = s.count
//        let n = t.count
//        
//        let shared = Set(s).intersection(t)
//        var _inserted = Set<Element>()
//        var _deleted = Set<Element>()
//        
//        // Fill first row and column of insertions and deletions.
//        
//        var matrix = Matrix2D(rows: n+1, columns: m+2, default: [Edit<Element>]())
//        
////        var d: [[[Edit<T.Iterator.Element>]]] = Array(repeating: Array(repeating: [], count: n + 1), count: m + 1)
//        
//        var edits = [Edit<Element>]()
//        for (row, element) in s.enumerated() {
//            let deletion = Edit(.deletion, value: element, destination: row)
//            edits.append(deletion)
//            matrix[row + 1, 0] = edits
//        }
//        
//        edits.removeAll()
//        for (col, element) in t.enumerated() {
//            let insertion = Edit(.insertion, value: element, destination: col)
//            edits.append(insertion)
//            matrix[0, col + 1] = edits
//        }
//        
//        guard m > 0 && n > 0 else { return (matrix, matrix[m, n]) }
//        
//        // Indexes into the two collections.
//        var sx: T.Index
//        var tx = t.startIndex
//        
//        // Fill body of matrix.
//        
//        let preferMoves = options.contains(.minimumOperations) == false
//        
//        for j in 1...n {
//            sx = s.startIndex
//            
//            for i in 1...m {
//                if s[sx] == t[tx] {
//                    matrix[i, j] = matrix[i - 1, j - 1] // no operation
//                } else {
//                    
//                    var del = matrix[i - 1, j] // a deletion
//                    var ins = matrix[i, j - 1] // an insertion
//                    var sub = matrix[i - 1, j - 1] // a substitution
//                    
//                    // Record operation.
//                    
//                    let src = s[sx]
//                    let trg = t[tx]
//                    
//                    var forceDelete = false
//                    var forceInsert = false
//                    
//                    if preferMoves {
//                        if shared.contains(src) {
//                            forceDelete = _deleted.contains(src)
//                            forceInsert = !forceDelete
//                        }
//                        else if shared.contains(trg) {
//                            forceDelete = _deleted.contains(trg)
//                            forceInsert = !forceDelete
//                        }
//                    }
//                    
//                    let minimumCount = min(del.count, ins.count, sub.count)
//                    if forceDelete || del.count == minimumCount {
//                        let deletion = Edit(.deletion, value: s[sx], destination: i - 1)
//                        del.append(deletion)
//                        matrix[i, j] = del
//                    }
//                    else if forceInsert || ins.count == minimumCount {
//                        let insertion = Edit(.insertion, value: t[tx], destination: j - 1)
//                        ins.append(insertion)
//                        matrix[i, j] = ins
//                    }
//                    else {
//                        let substitution = Edit(.substitution, value: t[tx], destination: i - 1)
//                        sub.append(substitution)
//                        matrix[i, j] = sub
//                    }
//                }
//                
//                sx = s.index(sx, offsetBy: 1)
//            }
//            
//            tx = t.index(tx, offsetBy: 1)
//        }
//        
//        let allEdits = matrix[m, n]
//        
//        // Convert deletion/insertion pairs of same element into moves.
//        return (matrix, reducedEdits(matrix[m, n]))
//    }
    

    
    /** Returns an array where deletion/insertion pairs of the same element are replaced by `.move` edits.
     
     - parameter edits: An array of `Edit` elements to be reduced.
     - returns: An array of `Edit` elements.
     */
    private static func reducedEdits<T: Equatable>(_ edits: [Edit<T>]) -> [Edit<T>] {
        return edits.reduce([Edit<T>]()) { (edits, edit) in
            var reducedEdits = edits
            if let (move, index) = move(from: edit, in: reducedEdits), case let .move(origin) = move.operation {
                reducedEdits.remove(at: index)
                if move.destination == origin {
                    let n = Edit(.substitution, value: edit.value, destination: origin)
                    reducedEdits.append(n)
                }
                else {
                    reducedEdits.append(move)
                }
            } else {
                reducedEdits.append(edit)
            }
            return reducedEdits
        }
    }
    
    
}


/** Returns a potential `.move` edit based on an array of `Edit` elements and an edit to match up against.
 
 If `edit` is a deletion or an insertion, and there is a matching opposite insertion/deletion with the same value in the array, a corresponding `.move` edit is returned.
 
 - parameters:
 - deletionOrInsertion: A `.deletion` or `.insertion` edit there will be searched an opposite match for.
 - edits: The array of `Edit` elements to search for a match in.
 
 - returns: An optional tuple consisting of the `.move` `Edit` that corresponds to the given deletion or insertion and an opposite match in `edits`, and the index of the match – if one was found.
 */
private func move<T: Equatable>(from deletionOrInsertion: Edit<T>, `in` edits: [Edit<T>]) -> (move: Edit<T>, index: Int)? {
    
    switch deletionOrInsertion.operation {
        
    case .deletion:
        if let insertionIndex = edits.index(where: { (earlierEdit) -> Bool in
            if case .insertion = earlierEdit.operation, earlierEdit.value == deletionOrInsertion.value {
                return true
            }
            else { return false }
        }) {
            return (Edit(.move(origin: deletionOrInsertion.destination), value: deletionOrInsertion.value, destination: edits[insertionIndex].destination), insertionIndex)
        }
        
    case .insertion:
        if let deletionIndex = edits.index(where: { (earlierEdit) -> Bool in
            if case .deletion = earlierEdit.operation, earlierEdit.value == deletionOrInsertion.value { return true } else { return false }
        }) {
            return (Edit(.move(origin: edits[deletionIndex].destination), value: deletionOrInsertion.value, destination: deletionOrInsertion.destination), deletionIndex)
        }
        
    default:
        break
    }
    
    return nil
}

extension ChangeSet : CustomStringConvertible {
    
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

extension Edit: Equatable {}
public func ==<T: Equatable>(lhs: Edit<T>, rhs: Edit<T>) -> Bool {
    guard lhs.destination == rhs.destination && lhs.value == rhs.value else { return false }
    switch (lhs.operation, rhs.operation) {
    case (.insertion, .insertion), (.deletion, .deletion), (.substitution, .substitution):
        return true
    case (.move(let lhsOrigin), .move(let rhsOrigin)):
        return lhsOrigin == rhsOrigin
    default:
        return false
    }
}
