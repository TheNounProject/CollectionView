//
//  CollectionViewLayout.swift
//  Lingo
//
//  Created by Wesley Byrne on 1/27/16.
//  Copyright © 2016 The Noun Project. All rights reserved.
//

import Foundation


open class CollectionViewLayout : NSObject {
    
    // This is set internally when the layout is set on the CollectionView
    public internal(set) weak var collectionView: CollectionView? { didSet { prepare() }}
    open var scrollDirection : CollectionViewScrollDirection { return .vertical }
    
    /// Called when the collection view is set to do any initialization setup
    open func prepare() { }
    
    open func invalidateLayout() { }
    open func prepareLayout() { }
    open var pinHeadersToTop: Bool = true
    public var allIndexPaths = Set<IndexPath>()
    
    open func layoutAttributesForElements(in rect: CGRect) -> [CollectionViewLayoutAttributes]? { return nil } // return an array layout attributes instances for all the views in the given rect
    
    open func layoutAttributesForItem(at indexPath: IndexPath) -> CollectionViewLayoutAttributes? { return nil }
    open func layoutAttributesForSupplementaryView(ofKind elementKind: String, atIndexPath indexPath: IndexPath) -> CollectionViewLayoutAttributes? { return nil }
    open func scrollRectForItem(at indexPath: IndexPath, atPosition: CollectionViewScrollPosition) -> CGRect? {
        return self.layoutAttributesForItem(at: indexPath)?.frame
    }
    open func indexPathsForItems(in rect: CGRect) -> Set<IndexPath>? { return nil }
    
    open func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool { return true }  // return YES to cause the collection view to requery the layout for geometry information
    
    // Subclasses must override this method and use it to return the width and height of the collection view’s content. These values represent the width and height of all the content, not just the content that is currently visible. The collection view uses this information to configure its own content size to facilitate scrolling.
    open var collectionViewContentSize : CGSize { return CGSize.zero }
    
    open func rectForSection(_ section: Int) -> CGRect { return CGRect.zero }
    
    open func indexPathForNextItem(moving direction: CollectionViewDirection, from currentIndexPath: IndexPath) -> IndexPath? { return currentIndexPath }
}
