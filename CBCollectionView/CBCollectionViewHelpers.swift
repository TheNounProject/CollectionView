//
//  CBCollectionViewConstants.swift
//  Lingo
//
//  Created by Wesley Byrne on 1/27/16.
//  Copyright © 2016 The Noun Project. All rights reserved.
//

import Foundation



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
    optional func collectionView(collectionView: CBCollectionView, mouseDownInItemAtIndexPath indexPath: NSIndexPath?, withEvent: NSEvent)
    optional func collectionView(collectionView: CBCollectionView, mouseUpInItemAtIndexPath indexPath: NSIndexPath?, withEvent: NSEvent)
    optional func collectionView(collectionView: CBCollectionView, didDoubleClickItemAtIndexPath indexPath: NSIndexPath, withEvent: NSEvent)
    
    optional func collectionView(collectionView: CBCollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath, withKey: Bool) -> Bool
    optional func collectionView(collectionView: CBCollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    optional func collectionView(collectionView: CBCollectionView, shouldDeselectItemAtIndexPath indexPath: NSIndexPath) -> Bool
    optional func collectionView(collectionView: CBCollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath)
    
    optional func collectionView(collectionView: CBCollectionView, didRightClickItemAtIndexPath indexPath: NSIndexPath, withEvent: NSEvent)
    optional func collectionView(collectionView: CBCollectionView, shouldScrollToItemAtIndexPath indexPath: NSIndexPath) -> Bool
    optional func collectionView(collectionView: CBCollectionView, didScrollToItemAtIndexPath indexPath: NSIndexPath)
    
    optional func collectionView(collectionView: CBCollectionView, willDisplayCell cell:CBCollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath)
    optional func collectionView(collectionView: CBCollectionView, willDisplaySupplementaryView view:CBCollectionReusableView, forElementKind elementKind: String, atIndexPath indexPath: NSIndexPath)
    optional func collectionView(collectionView: CBCollectionView, didEndDisplayingCell cell: CBCollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath)
    optional func collectionView(collectionView: CBCollectionView, didEndDisplayingSupplementaryView view: CBCollectionReusableView, forElementOfKind elementKind: String, atIndexPath indexPath: NSIndexPath)
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

internal enum CBCollectionViewSelectionType {
    case Single
    case Extending
    case Multiple
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
}





