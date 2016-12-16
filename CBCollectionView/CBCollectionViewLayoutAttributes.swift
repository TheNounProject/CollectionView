//
//  CBCollectionViewLayoutAttributes.swift
//  CBCollectionView
//
//  Created by Wesley Byrne on 9/1/16.
//  Copyright © 2016 Noun Project. All rights reserved.
//

import Foundation


open class CBCollectionViewLayoutAttributes {
    open var frame: CGRect = CGRect.zero
    open var center: CGPoint {
        get { return CGPoint(x: frame.origin.x + frame.size.width/2, y: frame.origin.y + frame.size.height/2) }
        set { self.frame.origin = CGPoint(x: center.x - frame.size.width/2, y: center.y - frame.size.height/2) }
    }
    open var size: CGSize {
        get { return self.frame.size }
        set { self.frame.size = size }
    }
    open var bounds: CGRect {
        get { return CGRect(origin: CGPoint.zero, size: self.frame.size) }
        set { self.frame.size = bounds.size }
    }
    open var alpha: CGFloat = 1
    open var zIndex: CGFloat = 0
    open var hidden: Bool = false
    open var floating: Bool = false
    
    open let indexPath: IndexPath
    open let representedElementCategory: CBCollectionElementCategory
    open let representedElementKind: String?
    
    public init(forCellWithIndexPath indexPath: IndexPath) {
        self.representedElementCategory = .cell
        self.representedElementKind = nil
        self.zIndex = 1
        self.indexPath = indexPath
    }
    public init(forSupplementaryViewOfKind elementKind: String, withIndexPath indexPath: IndexPath) {
        self.representedElementCategory = .supplementaryView
        self.representedElementKind = elementKind
        self.zIndex = 1000
        self.indexPath = indexPath
    }
    
    open var desciption : String {
        var str = "CBCollectionViewLayoutAttributes-"
        str += " IP: \(self.indexPath._section)-\(self.indexPath._item) "
        str += " Frame: \(self.frame)"
        str += " Alpha: \(self.alpha)"
        str += " Hidden: \(self.hidden)"
        return str
    }
    
    public func copy() -> CBCollectionViewLayoutAttributes {
        var attrs : CBCollectionViewLayoutAttributes!
        if self.representedElementCategory == .cell {
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
    internal func copyWithIndexPath(_ newIndexPath: IndexPath) -> CBCollectionViewLayoutAttributes {
        var attrs : CBCollectionViewLayoutAttributes!
        if self.representedElementCategory == .cell {
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
