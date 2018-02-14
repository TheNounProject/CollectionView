//
//  CollectionViewConstants.swift
//  Lingo
//
//  Created by Wesley Byrne on 1/27/16.
//  Copyright © 2016 The Noun Project. All rights reserved.
//

import Foundation



func delay(_ delay: TimeInterval, block: @escaping (()->Void)) {
    let mDelay = DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
    DispatchQueue.main.asyncAfter(deadline: mDelay, execute: {
        block()
    })
}

struct Logger {

    static let logFiles = Set<String>([
//        "CollectionView",
//        "CollectionViewDocumentView",
//        "CollectionReusableView"
        ])
    
    static func verbose(_ message: Any, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, type: "Verbose", file: file, funtion: function, line: line)
    }
    static func debug(_ message: Any, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, type: "Debug", file: file, funtion: function, line: line)
    }
    static func error(_ message: Any, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, type: "Error", file: file, funtion: function, line: line)
    }
    
    private static func log(_ message: Any, type: String, file: String, funtion: String, line: Int) {
        let fileName = file.components(separatedBy: "/").last!.components(separatedBy: ".").first!
        guard logFiles.count == 0 || logFiles.contains(fileName) else {
            return;
        }
        print("\(fileName) @ \(line) \(type): \(message)")
    }
}

typealias log = Logger





/**
 Provides support for OSX < 10.11 and provides some helpful additions
*/
public extension IndexPath {

    
    /**
     Create an index path with a given item and section
     
     - Parameter item: An item
     - Parameter section: A section

     - Returns: An initialized index path with the item and section
     
     - Note: item and section must be >= 0

    */
    public static func `for`(item: Int = 0, section: Int) -> IndexPath {
        precondition(item >= 0, "Attempt to create an indexPath with negative item")
        precondition(section >= 0, "Attempt to create an indexPath with negative section")
        return IndexPath(indexes: [section, item])
    }

    
    public static var zero : IndexPath { return IndexPath.for(item: 0, section: 0) }
    
    
    /**
     Returns the item of the index path
    */
    public var _item: Int { return self[1] }
    
    /**
     Returns the section of the index path
     */
    public var _section: Int { return self[0] }
    public static func inRange(_ range: CountableRange<Int>, section: Int) -> [IndexPath] {
        var ips = [IndexPath]()
        for idx in range {
            ips.append(IndexPath.for(item: idx, section: section))
        }
        return ips
    }
    
    public var previous : IndexPath? {
        guard self._item >= 1 else { return nil }
        return IndexPath.for(item: self._item - 1, section: self._section)
    }
    public var next : IndexPath {
        return IndexPath.for(item: self._item + 1, section: self._section)
    }
    public var nextSection : IndexPath {
        return IndexPath.for(item: 0, section: self._section + 1)
    }
    
    var sectionCopy : IndexPath {
        return IndexPath.for(item: 0, section: self._section)
    }
    
    func with(item: Int) -> IndexPath {
        return IndexPath.for(item: item, section: self._section)
    }
    func with(section: Int) -> IndexPath {
        return IndexPath.for(item: self._item, section: section)
    }
    
    func adjustingItem(by: Int) -> IndexPath {
        return IndexPath.for(item: self._item + by, section: section)
    }
    func adjustingSection(by: Int) -> IndexPath {
        return IndexPath.for(item: self._item, section: section + by)
    }
    
    func isBetween(_ start: IndexPath, end:IndexPath) -> Bool {
        if self == start { return true }
        if self == end { return true }
        let _start = Swift.min(start, end)
        let _end = Swift.max(start, end)
        return (_start..<_end).contains(self)
    }
}



/// :nodoc:
extension Comparable {
    func compare(_ other: Self) -> ComparisonResult {
        if self == other { return .orderedSame }
        if self < other { return .orderedAscending }
        return .orderedDescending
    }
}



extension Dictionary {
    
    
    func union(_ other: Dictionary<Key, Value>, overwrite: Bool = true) -> Dictionary<Key, Value> {
        var new = self
        for element in other {
            if overwrite || new[element.key] == nil {
                new[element.key] = element.value
            }
        }
        return new
    }
    
}


extension Set {
    
    
    mutating func removeOne() -> Element? {
        guard self.count > 0 else { return nil }
        return self.removeFirst()
    }
    
    /**
     Remove elements shared by both sets, returning the removed items
     
     - parameter set: The set of elements to remove from the receiver
     - returns: A new set of removed elements
     */
     @discardableResult mutating func remove<C : Collection>(_ set: C) -> Set<Element> where C.Iterator.Element == Element {
        var removed = Set(minimumCapacity: self.count)
        for item in set {
            if let r = self.remove(item) {
                removed.insert(r)
            }
        }
        return removed
    }
    
    /**
     Create a new set by removing the elements shared by both sets
     
     - parameter set: The set of elements to remove from the receiver
     - returns: A new set with the shared elements removed
     */
    func removing<C : Collection>(_ set: C) -> Set<Element> where C.Iterator.Element == Element {
        var copy = self
        copy.remove(set)
        return copy
    }
}

extension CGPoint {
    
    var integral : CGPoint {
        return CGPoint(x: round(self.x), y: round(self.y))
    }
    
    public var maxAbsVelocity : CGFloat {
        return max(abs(self.x), abs(self.y))
    }
    
    func maxVelocity(_ other: CGPoint) -> CGPoint {
        let _x = abs(self.x) > abs(other.x) ? self.x : other.x
        let _y = abs(self.y) > abs(other.y) ? self.y : other.y
        return CGPoint(x: _x, y: _y)
    }
    
    func maxXY(_ other: CGPoint) -> CGPoint {
        return CGPoint(x: max(self.x, other.x), y: max(self.y, other.y))
    }
    func maxX(_ other: CGPoint) -> CGPoint {
        return CGPoint(x: max(self.x, other.x), y: self.y)
    }
    func maxY(_ other: CGPoint) -> CGPoint {
        return CGPoint(x: self.x, y: max(self.y, other.y))
    }
    
        func distance(to other: CGPoint) -> CGFloat {
            let xDist = self.x - other.x
            let yDist = self.y - other.y
            return CGFloat(sqrt((xDist * xDist) + (yDist * yDist)))
        }
}

extension CGRect {
    var center : CGPoint {
        get { return CGPoint(x: self.midX, y: self.midY) }
        set {
            self.origin.x = newValue.x - (self.size.width/2)
            self.origin.y = newValue.y - (self.size.height/2)
        }
    }
    
    
    func sharedArea(with other: CGRect) -> CGFloat {
        let intersect = self.intersection(other)
        if intersect.isEmpty { return 0 }
        return intersect.height * intersect.width
    }
    
    func scaled(by scale: CGFloat) -> CGRect {
        var rect = CGRect()
        rect.origin.x = self.origin.x * scale
        rect.origin.y = self.origin.y * scale
        rect.size.width = self.size.width * scale
        rect.size.height = self.size.height * scale
        return rect
    }
}




/*
    Subtract r2 from r1 along
    -------------
   |\\\\ r1 \\\\\|
   |\\\\\\\\\\\\\|
   |-------------|
   !   overlap   !
   !_____________!
   I/////////////I
   I//// r2 /////I
   I-------------I
*/

func CGRectSubtract(_ rect1: CGRect, rect2: CGRect, edge: CGRectEdge) -> CGRect {
    
    if rect2.contains(rect1) { return CGRect.zero }
    if rect2.isEmpty { return rect1 }
    if !rect1.intersects(rect2) { return rect1 }
    
    switch edge {
    case .minXEdge:
        let origin = CGPoint(x: rect2.maxX, y: rect1.origin.y)
        let size = CGSize(width: rect1.maxX - origin.x , height: rect1.size.height)
        return CGRect(origin: origin, size: size)
        
    case .maxXEdge:
        return CGRect(origin: rect1.origin, size: CGSize(width: rect2.origin.x - rect1.origin.x, height: rect1.size.height))
        
    case .minYEdge:
        let origin = CGPoint(x: rect1.origin.x, y: rect2.maxY)
        let size = CGSize(width: rect1.size.width, height: rect1.maxY - origin.y)
        return CGRect(origin: origin, size: size)
        
    case .maxYEdge:
        return CGRect(origin: rect1.origin, size: CGSize(width: rect1.size.width, height: rect2.origin.y - rect1.origin.y))
    }
}



public extension NSView {
    
    /**
     Add NSLayoutContraints to the reciever to match it'parent optionally provided insets for each side. If the view does not have a superview, no constraints are added.
     
     - parameter insets: Insets to apply to the constraints for Top, Right, Bottom, and Left.
     - returns: The Top, Right, Bottom, and Top constraint added to the view.
     */
    @discardableResult func addConstraintsToMatchParent(_ insets: NSEdgeInsets? = nil) -> (top: NSLayoutConstraint, right: NSLayoutConstraint, bottom: NSLayoutConstraint, left: NSLayoutConstraint)? {
        if let sv = self.superview {
            let top = NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: sv, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: insets == nil ? 0 : insets!.top)
            let right = NSLayoutConstraint(item: sv, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1, constant: insets?.right ?? 0)
            let bottom = NSLayoutConstraint(item: sv, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: insets?.bottom ?? 0)
            let left = NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: sv, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: insets == nil ? 0 : insets!.left)
            sv.addConstraints([top, bottom, right, left])
            self.translatesAutoresizingMaskIntoConstraints = false
            return (top, right, bottom, left)
        }
        else {
            debugPrint("Toolkit Warning: Attempt to add contraints to match parent but the view had not superview.")
        }
        return nil
    }
}




/*
 struct IOSet : CustomStringConvertible {
 var _open = IndexSet()
 var _locked = IndexSet()
 
 var _union : IndexSet {
 return _open.union(_locked)
 }
 var _lastIndex : Int? { return _locked.last }
 var _firstIndex : Int? {
 if let o = _open.first, let l = _locked.first {
 return min(o, l)
 }
 if let o = _open.first { return o }
 return _locked.first
 }
 var _deleteCount = 0
 var _insertCount = 0
 
 init() { }
 init(d index: Int) { self.deleted(at: index) }
 init(i index: Int) { self.inserted(at: index) }
 
 mutating func moved(_ source: Int, to destination: Int) {
 self.deleted(at: source)
 self.inserted(at: destination)
 }
 
 mutating func lock(upTo index: Int) {
 guard index > 0 else { return }
 var idx = index - 1
 guard let start = self._firstIndex else {
 _locked.insert(integersIn: 0...idx)
 return
 }
 guard start < idx else {
 return
 }
 var idxSet = IndexSet(integersIn: start...idx)
 idxSet.subtract(_open)
 self._locked = _locked.union(idxSet)
 }
 
 
 mutating func nextOpening(for index: Int) -> Int {
 var all = self._union
 var idx = all.startIndex
 var last = self._open[idx]
 var proposed = index
 
 if proposed >= last {
 proposed = last
 
 if self._locked.contains(last) {
 
 while idx < all.endIndex {
 let check = all[idx]
 var prop = last + 1
 let isGap = prop < check
 if isGap || (self._open.contains(prop) && !self._locked.contains(prop)) {
 proposed = prop
 break;
 }
 proposed = check + 1
 idx = all.index(after: idx)
 last = check
 }
 }
 }
 self.inserted(at: proposed, auto: true)
 return proposed
 }
 
 // Auto is set to true when inserting  as the result of an adjustment
 // This keeps it from being counted when adjusting IP out of the edit area
 mutating func deleted(at index: Int, auto: Bool = false) -> IOSet {
 if !auto {
 _deleteCount += 1
 }
 if _locked.contains(index) {
 return self
 }
 _open.insert(index)
 return self
 }
 
 // Auto is set to true when inserting  as the result of an adjustment
 // This keeps it from being counted when adjusting IP out of the edit area
 mutating func inserted(at index: Int, auto: Bool = false) -> IOSet {
 _locked.insert(index)
 if !auto {
 _insertCount += 1
 }
 return self
 }
 
 var description: String {
 var str = "Section Ops\n"
 
 var open = [Int]()
 var locked = [Int]()
 
 let union = _open.union(_locked)
 
 str += "Union \(union.indices)\n"
 if union.count > 0 {
 for idx in union {
 open.append(_open.contains(idx) ? 1 : 0)
 locked.append(_locked.contains(idx) ? 1 : 0)
 }
 }
 str += "Open: \(open)\n"
 str += "Lock: \(locked)"
 return str
 }
 }
 
 
 mutating func lockSections(upTo index: Int) {
 _sectionOperations.lock(upTo: index)
 }
 
 mutating func lock(upTo indexPath: IndexPath) {
 _operations[indexPath._section]?.lock(upTo: indexPath._item)
 }
 
 
 mutating func deletedSections(at indexSet: IndexSet) {
 _sectionDeletions.formUnion(indexSet)
 for idx in indexSet {
 _sectionOperations.deleted(at: idx)
 }
 }
 mutating func insertedSections(at indexSet: IndexSet) {
 _sectionInsertions.formUnion(indexSet)
 //            for idx in indexSet {
 //                _sectionOperations.inserted(at: idx)
 //            }
 }
 mutating func movedSection(from source: Int, to destination: Int) {
 //            _sectionDeletions.insert(source)
 //            _sectionInsertions.insert(destination)
 _sectionMoves[source] = destination
 //            _sectionOperations.inserted(at: destination)
 //            _sectionOperations.deleted(at: source)
 }
 
 mutating func deletedItem(at indexPath: IndexPath) {
 //            let s = indexPath._section, i = indexPath._item
 //            if _operations[s]?.deleted(at: i) == nil {
 //                _operations[s] = IOSet(d: i)
 //            }
 }
 mutating func insertedItem(at indexPath: IndexPath) {
 let s = indexPath._section, i = indexPath._item
 if _operations[s]?.inserted(at: i) == nil {
 _operations[s] = IOSet(i: i)
 }
 }
 
 mutating func movedItem(from source: IndexPath, to destination: IndexPath) {
 deletedItem(at: source)
 insertedItem(at: destination)
 }
 
 
 var _itemSectionCopy : IOSet?
 
 mutating func adjust(_ indexPath: IndexPath) -> IndexPath {
 
 if _itemSectionCopy == nil {
 _itemSectionCopy = _sectionOperations
 }
 guard let prop = _operations[indexPath._section]?.nextOpening(for: indexPath._item) else {
 return indexPath
 }
 // Open up this space to be filled by another item
 // If it has already been locked, this does nothing
 _operations[indexPath._section]?.deleted(at: indexPath._item, auto: true)
 
 let new = indexPath.with(item: prop)
 //            log.debug("Adjusted \(indexPath)  to: \(new)")
 return new
 }
 
 mutating func adjust(section index: Int) -> Int {
 return _sectionOperations.nextOpening(for: index)
 }
 
 var description: String {
 return  ""// "Insertions : \(_insertions)  \n Deletions: \(_deletions)
 }
 */




