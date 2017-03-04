//
//  CollectionViewLayout.swift
//  Lingo
//
//  Created by Wesley Byrne on 1/27/16.
//  Copyright © 2016 The Noun Project. All rights reserved.
//

import Foundation




/**
 
 The CollectionViewLayout class is an abstract base class that you subclass and use to generate layout information for a collection view. The job of a layout object is to determine the placement of cells, supplementary views inside the collection view’s bounds and to report that information to the collection view when asked. The collection view then applies the provided layout information to the corresponding views so that they can be presented onscreen.
 
*/
open class CollectionViewLayout : NSObject {
    
    // This is set internally when the layout is set on the CollectionView
    open internal(set) weak var collectionView: CollectionView?
    
    
    
    // The direction that the collection view should scroll
    open var scrollDirection : CollectionViewScrollDirection { return .vertical }
    
    
    open func invalidateLayout() { }
    
    
    @available(*, unavailable, renamed: "prepare()")
    open func prepareLayout() { }
    
    /**
     Tells the layout object to update the current layout.
     
     ## Discussion
     Layout updates occur the first time the collection view presents its content and whenever the layout is invalidated explicitly or implicitly because of a change to the view. During each layout update, the collection view calls this method first to give your layout object a chance to prepare for the upcoming layout operation.
     The default implementation of this method does nothing. Subclasses can override it and use it to set up data structures or perform any initial computations needed to perform the layout later.

    */
    open func prepare() { }
    
    
    /**
     If supporting views should be pinned to the top of the view
    */
    open var pinHeadersToTop: Bool = true
    
    
    /**
     All the index paths to be displayed by the collection view
     
     Becuase the layout likely needs to process all items in the data, setting this during prepare() can cut out the overhead of the collection view having to do so itself.
    */
    public var allIndexPaths = Set<IndexPath>()
    
    
    open func layoutAttributesForElements(in rect: CGRect) -> [CollectionViewLayoutAttributes]? { return nil } // return an array layout attributes instances for all the views in the given rect
    
    open func layoutAttributesForItem(at indexPath: IndexPath) -> CollectionViewLayoutAttributes? { return nil }
    open func layoutAttributesForSupplementaryView(ofKind elementKind: String, atIndexPath indexPath: IndexPath) -> CollectionViewLayoutAttributes? { return nil }
    open func scrollRectForItem(at indexPath: IndexPath, atPosition: CollectionViewScrollPosition) -> CGRect? {
        return self.layoutAttributesForItem(at: indexPath)?.frame
    }
    open func indexPathsForItems(in rect: CGRect) -> [IndexPath]? { return nil }
    
    open func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool { return true }  // return YES to cause the collection view to requery the layout for geometry information
    
    // Subclasses must override this method and use it to return the width and height of the collection view’s content. These values represent the width and height of all the content, not just the content that is currently visible. The collection view uses this information to configure its own content size to facilitate scrolling.
    open var collectionViewContentSize : CGSize { return CGSize.zero }
    
    open func rectForSection(_ section: Int) -> CGRect { return CGRect.zero }
    
    open func indexPathForNextItem(moving direction: CollectionViewDirection, from currentIndexPath: IndexPath) -> IndexPath? { return currentIndexPath }
}
