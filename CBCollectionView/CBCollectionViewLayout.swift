//
//  CBCollectionViewLayout.swift
//  Lingo
//
//  Created by Wesley Byrne on 1/27/16.
//  Copyright © 2016 The Noun Project. All rights reserved.
//

import Foundation


public enum CBCollectionViewScrollDirection {
    case Vertical
    case Horizontal
    
}

public enum CBCollectionViewDirection {
    case Left
    case Right
    case Up
    case Down
}

public class CBCollectionViewLayout : NSObject {
    
    public internal(set) weak var collectionView: CBCollectionView?
    public var scrollDirection : CBCollectionViewScrollDirection { return .Vertical }
    
    public func invalidateLayout() { }
    public func prepareLayout() { }
    public var pinHeadersToTop: Bool = true
    var allIndexPaths = Set<NSIndexPath>()
    
    public func layoutAttributesForElementsInRect(rect: CGRect) -> [CBCollectionViewLayoutAttributes]? { return nil } // return an array layout attributes instances for all the views in the given rect
    public func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> CBCollectionViewLayoutAttributes? { return nil }
    public func layoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> CBCollectionViewLayoutAttributes? { return nil }
    public func scrollRectForItemAtIndexPath(indexPath: NSIndexPath, atPosition: CBCollectionViewScrollPosition) -> CGRect? { return nil }
    public func indexPathsForItemsInRect(rect: CGRect) -> Set<NSIndexPath>? { return nil }
    
    public func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool { return true }  // return YES to cause the collection view to requery the layout for geometry information
    
    // Subclasses must override this method and use it to return the width and height of the collection view’s content. These values represent the width and height of all the content, not just the content that is currently visible. The collection view uses this information to configure its own content size to facilitate scrolling.
    public func collectionViewContentSize() -> CGSize { return CGSizeZero }
    
    public func rectForSection(section: Int) -> CGRect { return CGRectZero }
    
    public func indexPathForNextItemInDirection(direction: CBCollectionViewDirection, afterItemAtIndexPath currentIndexPath: NSIndexPath) -> NSIndexPath? { return currentIndexPath }
}