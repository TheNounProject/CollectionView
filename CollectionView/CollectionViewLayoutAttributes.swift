//
//  CollectionViewLayoutAttributes.swift
//  CollectionView
//
//  Created by Wesley Byrne on 9/1/16.
//  Copyright © 2016 Noun Project. All rights reserved.
//

import Foundation


/**
 An UICollectionViewLayoutAttributes object manages the layout-related attributes for a given item in a collection view. Layout objects create instances of this class when asked to do so by the collection view. In turn, the collection view uses the layout information to position cells and supplementary views inside its bounds.
*/
public class CollectionViewLayoutAttributes: CustomStringConvertible {
    
    
    // MARK: - Identifying the Referenced Item
    /*-------------------------------------------------------------------------------*/
    
    /// The index path of the item in the collection view.
    public let indexPath: IndexPath
    /// The type of the item.
    public let representedElementCategory: CollectionElementCategory
    /// The layout-specific identifier for the target view.
    public let representedElementKind: String?
    
    // MARK: - Accessing the Layout Attributes
    /*-------------------------------------------------------------------------------*/
    
    /// The frame rectangle of the item.
    public var frame: CGRect = CGRect.zero

    
    /// The center point of the item.
    public var center: CGPoint {
        get { return CGPoint(x: frame.origin.x + frame.size.width/2, y: frame.origin.y + frame.size.height/2) }
        set { self.frame.origin = CGPoint(x: center.x - frame.size.width/2, y: center.y - frame.size.height/2) }
    }
    
    
    /// The size of the item
    public var size: CGSize {
        get { return self.frame.size }
        set { self.frame.size = size }
    }
    
    /// The bounds of the item
    public var bounds: CGRect {
        get { return CGRect(origin: CGPoint.zero, size: self.frame.size) }
        set { self.frame.size = bounds.size }
    }
    
    /// The transparency of the item.
    public var alpha: CGFloat = 1
    
    /// Specifies the item’s position on the z axis.
    public var zIndex: CGFloat = 0
    
    /// Determines whether the item is currently displayed.
    public var hidden: Bool = false
    
    /// Specifies if the item it detached from the scroll view (SupplementaryViews only)
    public var floating: Bool = false

    
    
    // MARK: - Creating Layout Attributes
    /*-------------------------------------------------------------------------------*/
    
    
    /**
     Creates and returns a layout attributes object that represents a cell with the specified index path.

     - Parameter indexPath: The index path of the cell.

    */
    
    public init(forCellWith indexPath: IndexPath) {
        self.representedElementCategory = .cell
        self.representedElementKind = nil
        self.zIndex = 1
        self.indexPath = indexPath
    }
    
    
    
    /**
     Creates and returns a layout attributes object that represents the specified supplementary view.

     - Parameter elementKind: A string that identifies the type of supplementary view.
     - Parameter indexPath: The index path of the view.

    */
    public init(forSupplementaryViewOfKind elementKind: String, with indexPath: IndexPath) {
        self.representedElementCategory = .supplementaryView
        self.representedElementKind = elementKind
        self.zIndex = 1000
        self.indexPath = indexPath
    }
    
    public var description: String {
        var str = "CollectionViewLayoutAttributes-"
        str += " IP: \(self.indexPath._section)-\(self.indexPath._item) "
        str += " Frame: \(self.frame)"
        str += " Floating: \(self.floating) "
        str += " Alpha: \(self.alpha)"
        str += " Hidden: \(self.hidden)"
        return str
    }
    
    /**
     Create a copy of the layout attributes

     - Returns: An initialized object with the same attributes
     
     - Note: A CollectionViewLayout should copy attributes when returning them
    */
    public func copy() -> CollectionViewLayoutAttributes {
        var attrs : CollectionViewLayoutAttributes!
        if self.representedElementCategory == .cell {
            attrs = CollectionViewLayoutAttributes(forCellWith: self.indexPath)
        }
        else {
            attrs = CollectionViewLayoutAttributes(forSupplementaryViewOfKind: self.representedElementKind!, with: indexPath)
        }
        attrs.frame = self.frame
        attrs.alpha = self.alpha
        attrs.zIndex = self.zIndex
        attrs.hidden = self.hidden
        attrs.floating = self.floating
        return attrs
    }
    internal func copyWithIndexPath(_ newIndexPath: IndexPath) -> CollectionViewLayoutAttributes {
        var attrs : CollectionViewLayoutAttributes!
        if self.representedElementCategory == .cell {
            attrs = CollectionViewLayoutAttributes(forCellWith: newIndexPath)
        }
        else {
            attrs = CollectionViewLayoutAttributes(forSupplementaryViewOfKind: self.representedElementKind!, with: newIndexPath)
        }
        attrs.frame = self.frame
        attrs.alpha = self.alpha
        attrs.zIndex = self.zIndex
        attrs.hidden = self.hidden
        return attrs
    }
}
