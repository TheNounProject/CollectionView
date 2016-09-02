//
//  CBCollectionViewLayoutAttributes.swift
//  CBCollectionView
//
//  Created by Wesley Byrne on 9/1/16.
//  Copyright © 2016 Noun Project. All rights reserved.
//

import Foundation


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
