//
//  CBCollectionViewConstants.swift
//  Lingo
//
//  Created by Wesley Byrne on 1/27/16.
//  Copyright © 2016 The Noun Project. All rights reserved.
//

import Foundation





public extension NSIndexPath {
    public static func _indexPathForItem(item: Int, inSection section: Int) -> NSIndexPath {
        return NSIndexPath(index: section).indexPathByAddingIndex(item)
    }
    public static func _indexPathForSection(section: Int) -> NSIndexPath {
        return NSIndexPath(index: section).indexPathByAddingIndex(0)
    }
    public static var Zero : NSIndexPath { return NSIndexPath._indexPathForItem(0, inSection: 0) }
    public var _item: Int { return self.indexAtPosition(1) }
    public var _section: Int { return self.indexAtPosition(0) }
    
    
    public static func inRange(range: Range<Int>, section: Int) -> [NSIndexPath] {
        var ips = [NSIndexPath]()
        for idx in range {
            ips.append(NSIndexPath._indexPathForItem(idx, inSection: section))
        }
        return ips
    }
}


struct SupplementaryViewIdentifier: Hashable {
    var indexPath: NSIndexPath?
    var kind: String!
    var reuseIdentifier : String!
    
    var hashValue: Int {
        if let ip = self.indexPath {
            return "\(ip._section)/\(self.kind)".hashValue
        }
        return "\(self.kind)/\(self.reuseIdentifier)".hashValue
    }
    init(kind: String, reuseIdentifier: String, indexPath: NSIndexPath? = nil) {
        self.kind = kind
        self.reuseIdentifier = reuseIdentifier
        self.indexPath = indexPath
    }
}

func ==(lhs: SupplementaryViewIdentifier, rhs: SupplementaryViewIdentifier) -> Bool {
    return lhs.indexPath == rhs.indexPath && lhs.kind == rhs.kind && lhs.reuseIdentifier == rhs.reuseIdentifier
}


extension Set {
    
    /**
     Remove elements shared by both sets, returning the removed items
     
     - parameter set: The set of elements to remove from the receiver
     - returns: A new set of removed elements
     */
    mutating func removeSet(set: Set) -> Set {
        var removed = Set(minimumCapacity: self.count)
        for item in set {
            if let r = self.remove(item) {
                removed.insert(r)
            }
        }
        return removed
    }
    
    func removingSet(set: Set) -> Set {
        var newSet = Set(minimumCapacity: self.count)
        for item in self {
            if !set.contains(item) {
                newSet.insert(item)
            }
        }
        return newSet
    }
}

extension CGPoint {
    
    var integral : CGPoint {
        return CGPoint(x: round(self.x), y: round(self.y))
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



