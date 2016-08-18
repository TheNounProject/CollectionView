//
//  CBCollectionViewConstants.swift
//  Lingo
//
//  Created by Wesley Byrne on 1/27/16.
//  Copyright © 2016 The Noun Project. All rights reserved.
//

import Foundation





public struct IndexPath : Hashable, Comparable {
    let item : Int
    let section : Int
    public var hashValue: Int { return item.hashValue ^ section.hashValue }
    
    init(section: Int) {
        self.item = 0
        self.section = section
    }
    init(item: Int, section: Int) {
        self.item = item
        self.section = section
    }
}

public func == (lhs: IndexPath, rhs: IndexPath) -> Bool {
    return lhs.section == rhs.section && lhs.item == rhs.section
}
public func <= (lhs: IndexPath, rhs: IndexPath) -> Bool {
    return lhs.section < rhs.section || (lhs.section == rhs.section && lhs.item <= rhs.item)
}
public func < (lhs: IndexPath, rhs: IndexPath) -> Bool {
    return lhs.section < rhs.section || (lhs.section == rhs.section && lhs.item < rhs.item)
}
public func > (lhs: IndexPath, rhs: IndexPath) -> Bool {
    return lhs.section > rhs.section || (lhs.section == rhs.section && lhs.item > rhs.item)
}
public func >= (lhs: IndexPath, rhs: IndexPath) -> Bool {
    return lhs.section > rhs.section || (lhs.section == rhs.section && lhs.item >= rhs.item)
}


extension Set {
    
    mutating func removeAllInSet(set: Set) -> Set {
        var removed = Set(minimumCapacity: self.count)
        for item in set {
            if let r = self.remove(item) {
                removed.insert(r)
            }
        }
        return removed
    }
    
    func setByRemovingSubset(set: Set) -> Set {
        var newSet = Set(minimumCapacity: self.count)
        for item in self {
            if !set.contains(item) {
                newSet.insert(item)
            }
        }
        return newSet
    }
    
}





extension CGRect {
    
    var center : CGPoint {
        get { return CGPoint(x: CGRectGetMidX(self), y: CGRectGetMidY(self)) }
        set {
            self.origin.x = newValue.x - (self.size.width/2)
            self.origin.y = newValue.y - (self.size.height/2)
        }
    }
}



@objc public protocol CBCollectionViewDataSource {
    func numberOfSectionsInCollectionView(collectionView: CBCollectionView) -> Int
    func collectionView(collectionView: CBCollectionView, numberOfItemsInSection section: Int) -> Int
    func collectionView(collectionView: CBCollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> CBCollectionViewCell!
    optional func collectionView(collectionView: CBCollectionView, viewForSupplementaryElementOfKind kind: String, forIndexPath indexPath: NSIndexPath) -> CBCollectionReusableView
    optional func collectionView(collectionView: CBCollectionView, pasteboardWriterForItemAtIndexPath indexPath: NSIndexPath) -> NSPasteboardWriting?
    optional func collectionView(collectionView: CBCollectionView, dragContentsForItemAtIndexPath indexPath: NSIndexPath) -> NSImage?
    optional func collectionView(collectionView: CBCollectionView, dragRectForItemAtIndexPath indexPath: NSIndexPath, withStartingRect rect: UnsafeMutablePointer<CGRect>)
}

public extension NSIndexPath {
    public static func _indexPathForItem(item: Int, inSection section: Int) -> NSIndexPath {
        return NSIndexPath(index: section).indexPathByAddingIndex(item)
    }
    public static var Zero : NSIndexPath { return NSIndexPath._indexPathForItem(0, inSection: 0) }
    public var _item: Int { return self.indexAtPosition(1) }
    public var _section: Int { return self.indexAtPosition(0) }
}

@objc public protocol CBCollectionViewDelegate {
    
    optional func collectionViewDidReloadData(collectionView: CBCollectionView)
    
    optional func collectionView(collectionView: CBCollectionView, mouseMovedToSection indexPath: NSIndexPath?)
    
    optional func collectionView(collectionView: CBCollectionView, mouseDownInItemAtIndexPath indexPath: NSIndexPath?, withEvent: NSEvent)
    optional func collectionView(collectionView: CBCollectionView, mouseUpInItemAtIndexPath indexPath: NSIndexPath?, withEvent: NSEvent)
    optional func collectionView(collectionView: CBCollectionView, didDoubleClickItemAtIndexPath indexPath: NSIndexPath, withEvent: NSEvent)
    
    optional func collectionView(collectionView: CBCollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool
    optional func collectionView(collectionView: CBCollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath, withEvent: NSEvent?) -> Bool
    optional func collectionView(collectionView: CBCollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    optional func collectionView(collectionView: CBCollectionView, shouldDeselectItemAtIndexPath indexPath: NSIndexPath) -> Bool
    optional func collectionView(collectionView: CBCollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath)
    
    optional func collectionView(collectionView: CBCollectionView, didRightClickItemAtIndexPath indexPath: NSIndexPath, withEvent: NSEvent)
    
    optional func collectionView(collectionView: CBCollectionView, shouldScrollToItemAtIndexPath indexPath: NSIndexPath) -> Bool
    optional func collectionViewLayoutAnchor(collectionView: CBCollectionView) -> NSIndexPath?
    optional func collectionView(collectionView: CBCollectionView, didScrollToItemAtIndexPath indexPath: NSIndexPath)
    
    optional func collectionView(collectionView: CBCollectionView, willDisplayCell cell:CBCollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath)
    optional func collectionView(collectionView: CBCollectionView, willDisplaySupplementaryView view:CBCollectionReusableView, forElementKind elementKind: String, atIndexPath indexPath: NSIndexPath)
    optional func collectionView(collectionView: CBCollectionView, didEndDisplayingCell cell: CBCollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath)
    optional func collectionView(collectionView: CBCollectionView, didEndDisplayingSupplementaryView view: CBCollectionReusableView, forElementOfKind elementKind: String, atIndexPath indexPath: NSIndexPath)
    
    optional func collectionViewDidEndLiveResize(collectionView: CBCollectionView)
    
    optional func collectionViewDidScroll(collectionView: CBCollectionView)
    optional func collectionViewWillBeginScrolling(collectionView: CBCollectionView)
    optional func collectionViewDidEndScrolling(collectionView: CBCollectionView, animated: Bool)
}

@objc public protocol CBCollectionViewInteractionDelegate : CBCollectionViewDelegate {
    optional func collectionView(collectionView: CBCollectionView, shouldBeginDraggingAtIndexPath indexPath: NSIndexPath, withEvent event: NSEvent) ->Bool
    optional func collectionView(collectionView: CBCollectionView, draggingSession session: NSDraggingSession, willBeginAtPoint point: NSPoint)
    optional func collectionView(collectionView: CBCollectionView, draggingSession session: NSDraggingSession, enedAtPoint screenPoint: NSPoint, withOperation operation: NSDragOperation, draggedIndexPaths: [NSIndexPath])
    optional func collectionView(collectionView: CBCollectionView, draggingSession session: NSDraggingSession, didMoveToPoint point: NSPoint)
    
    optional func collectionView(collectionView: CBCollectionView, dragEntered dragInfo: NSDraggingInfo) -> NSDragOperation
    optional func collectionView(collectionView: CBCollectionView, dragUpdated dragInfo: NSDraggingInfo) -> NSDragOperation
    optional func collectionView(collectionView: CBCollectionView, dragExited dragInfo: NSDraggingInfo?)
    optional func collectionView(collectionView: CBCollectionView, dragEnded dragInfo: NSDraggingInfo?)
    optional func collectionView(collectionView: CBCollectionView, performDragOperation dragInfo: NSDraggingInfo) -> Bool
}

public enum CBCollectionElementCategory : UInt {
    case Cell
    case SupplementaryView
}

public enum CBCollectionViewScrollPosition {
    case None
    case Nearest
    case Top
    case Centered
    case Bottom
}

enum CBCollectionViewSelectionMethod {
    case Click
    case Extending
    case Multiple
}

internal enum CBCollectionViewSelectionType {
    case Single
    case Extending
    case Multiple
}

/*
    Subtract r2 from r1 along
    -------------
   |\\\\ r1 \\\\\|
   |\\\\\\\\\\\\\|
   |=============|
   !    overlap  !
   !_____________!
   I             I
   I     r2      I
   I=============I
*/

func CGRectSubtract(rect1: CGRect, rect2: CGRect, edge: CGRectEdge) -> CGRect {
    
    if rect2.contains(rect1) { return CGRectZero }
    if rect2.isEmpty { return rect1 }
    if !rect1.intersects(rect2) { return rect1 }
    
    if edge == .MaxXEdge {
        
        
    }
    else if edge == .MinXEdge {
        
    }
    else if edge == .MinYEdge {
        let origin = CGPoint(x: rect1.origin.x, y: CGRectGetMaxY(rect2))
        let size = CGSize(width: rect1.size.width, height: CGRectGetMaxY(rect1) - origin.y)
        return CGRect(origin: origin, size: size)
    }
    else if edge == .MaxYEdge {
         return CGRect(origin: rect1.origin, size: CGSize(width: rect1.size.width, height: rect2.origin.y - rect1.origin.y))
    }
    
    return rect1
}

public class CBCollectionViewLayoutAttributes {
    public var frame: CGRect = CGRectZero
    public var center: CGPoint {
        get { return CGPoint(x: frame.origin.x + frame.size.width/2, y: frame.origin.y + frame.size.height/2) }
        set { self.frame.origin = CGPoint(x: center.x - frame.size.width/2, y: center.y - frame.size.height/2) }
    }
    public var size: CGSize {
        get { return self.frame.size }
        set { self.frame.size = size }
    }
    public var bounds: CGRect {
        get { return CGRect(origin: CGPointZero, size: self.frame.size) }
        set { self.frame.size = bounds.size }
    }
    public var alpha: CGFloat = 1
    public var zIndex: CGFloat = 0
    public var hidden: Bool = false
    public var floating: Bool = false
    
    public let indexPath: NSIndexPath
    public let representedElementCategory: CBCollectionElementCategory
    public let representedElementKind: String?
    
    public init(forCellWithIndexPath indexPath: NSIndexPath) {
        self.representedElementCategory = .Cell
        self.representedElementKind = nil
        self.zIndex = 1
        self.indexPath = indexPath
    }
    public init(forSupplementaryViewOfKind elementKind: String, withIndexPath indexPath: NSIndexPath) {
        self.representedElementCategory = .SupplementaryView
        self.representedElementKind = elementKind
        self.zIndex = 1000
        self.indexPath = indexPath
    }
    
    public var desciption : String {
        var str = "CBCollectionViewLayoutAttributes-"
        str += " IP: \(self.indexPath._section)-\(self.indexPath._item) "
        str += " Frame: \(self.frame)"
        str += " Alpha: \(self.alpha)"
        str += " Hidden: \(self.hidden)"
        return str
    }
    
    func copy() -> CBCollectionViewLayoutAttributes {
        var attrs : CBCollectionViewLayoutAttributes!
        if self.representedElementCategory == .Cell {
            attrs = CBCollectionViewLayoutAttributes(forCellWithIndexPath: self.indexPath)
        }
        else {
            attrs = CBCollectionViewLayoutAttributes(forSupplementaryViewOfKind: self.representedElementKind!, withIndexPath: indexPath)
        }
        attrs.frame = self.frame
        attrs.alpha = self.alpha
        attrs.zIndex = self.zIndex
        attrs.hidden = self.hidden
        return attrs
    }
    internal func copyWithIndexPath(newIndexPath: NSIndexPath) -> CBCollectionViewLayoutAttributes {
        var attrs : CBCollectionViewLayoutAttributes!
        if self.representedElementCategory == .Cell {
            attrs = CBCollectionViewLayoutAttributes(forCellWithIndexPath: newIndexPath)
        }
        else {
            attrs = CBCollectionViewLayoutAttributes(forSupplementaryViewOfKind: self.representedElementKind!, withIndexPath: newIndexPath)
        }
        attrs.frame = self.frame
        attrs.alpha = self.alpha
        attrs.zIndex = self.zIndex
        attrs.hidden = self.hidden
        return attrs
    }
}



public extension NSView {
    
    /**
     Add NSLayoutContraints to the reciever to match it'parent optionally provided insets for each side. If the view does not have a superview, no constraints are added.
     
     - parameter insets: Insets to apply to the constraints for Top, Right, Bottom, and Left.
     - returns: The Top, Right, Bottom, and Top constraint added to the view.
     */
    func addConstraintsToMatchParent(insets: NSEdgeInsets? = nil) -> (top: NSLayoutConstraint, right: NSLayoutConstraint, bottom: NSLayoutConstraint, left: NSLayoutConstraint)? {
        if let sv = self.superview {
            let top = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: sv, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: insets == nil ? 0 : insets!.top)
            let right = NSLayoutConstraint(item: sv, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Right, multiplier: 1, constant: insets?.right ?? 0)
            let bottom = NSLayoutConstraint(item: sv, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: insets?.bottom ?? 0)
            let left = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: sv, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: insets == nil ? 0 : insets!.left)
            sv.addConstraints([top, bottom, right, left])
            self.translatesAutoresizingMaskIntoConstraints = false
            return (top, right, bottom, left)
        }
        else {
            debugPrint("CBToolkit Warning: Attempt to add contraints to match parent but the view had not superview.")
        }
        return nil
    }
}



