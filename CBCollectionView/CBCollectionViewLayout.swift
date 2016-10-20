//
//  CBCollectionViewLayout.swift
//  Lingo
//
//  Created by Wesley Byrne on 1/27/16.
//  Copyright © 2016 The Noun Project. All rights reserved.
//

import Foundation


open class CBCollectionViewLayout : NSObject {
    
    // This is set internally when the layout is set on the CollectionView
    open internal(set) weak var collectionView: CBCollectionView?
    open var scrollDirection : CBCollectionViewScrollDirection { return .vertical }
    
    open func invalidateLayout() { }
    open func prepareLayout() { }
    open var pinHeadersToTop: Bool = true
    var allIndexPaths = Set<IndexPath>()
    
    open func layoutAttributesForElementsInRect(_ rect: CGRect) -> [CBCollectionViewLayoutAttributes]? { return nil } // return an array layout attributes instances for all the views in the given rect
    open func layoutAttributesForItemAtIndexPath(_ indexPath: IndexPath) -> CBCollectionViewLayoutAttributes? { return nil }
    open func layoutAttributesForSupplementaryViewOfKind(_ elementKind: String, atIndexPath indexPath: IndexPath) -> CBCollectionViewLayoutAttributes? { return nil }
    open func scrollRectForItemAtIndexPath(_ indexPath: IndexPath, atPosition: CBCollectionViewScrollPosition) -> CGRect? { return nil }
    open func indexPathsForItemsInRect(_ rect: CGRect) -> Set<IndexPath>? { return nil }
    
    open func shouldInvalidateLayoutForBoundsChange(_ newBounds: CGRect) -> Bool { return true }  // return YES to cause the collection view to requery the layout for geometry information
    
    // Subclasses must override this method and use it to return the width and height of the collection view’s content. These values represent the width and height of all the content, not just the content that is currently visible. The collection view uses this information to configure its own content size to facilitate scrolling.
    open func collectionViewContentSize() -> CGSize { return CGSize.zero }
    
    open func rectForSection(_ section: Int) -> CGRect { return CGRect.zero }
    
    open func indexPathForNextItemInDirection(_ direction: CBCollectionViewDirection, afterItemAtIndexPath currentIndexPath: IndexPath) -> IndexPath? { return currentIndexPath }
}
