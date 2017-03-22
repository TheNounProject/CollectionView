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
    open internal(set) weak var collectionView: CollectionView? { didSet { invalidate() }}
    
    /**
     The direction that the collection view should scroll
    */
    open var scrollDirection : CollectionViewScrollDirection { return .vertical }
    
    
    
    private func overrideWarning(_ function : String = #function) {
        Swift.print("WARNING: CollectionViewLayout \(function) should be overridden in a subclass. Missing in \(type(of: self)). Make sure super is not called too.")
    }
    
    
    // Subclasses must override this method and use it to return the width and height of the collection view’s content. These values represent the width and height of all the content, not just the content that is currently visible. The collection view uses this information to configure its own content size to facilitate scrolling.
    
    /**
     The size that encapsulates all views within the collection view
     */
    open var collectionViewContentSize : CGSize {
        overrideWarning()
        return CGSize.zero
    }
    
    /**
     If supporting views should be pinned to the top of the view
     */
    open var pinHeadersToTop: Bool = true
    
    // MARK: - Layout Validation
    /*-------------------------------------------------------------------------------*/
    
    /**
     Currently this is only called when the layout is applied to a collection view.
    */
    open func invalidate() { }
    
    
    
    /**
     Asks the layout if it should be invalidated due to a bounds change on the collection view

     - Parameter newBounds: The new bounds of the collection view

     - Returns: If the layout should be invalidated

    */
    open func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        overrideWarning()
        return true // Default to YES to force the layout to update.
    }
    
    @available(*, unavailable, renamed: "prepare()")
    open func prepareLayout() { }
    
    /**
     Tells the layout object to update the current layout.
     
     ## Discussion
     Layout updates occur the first time the collection view presents its content and whenever the layout is invalidated explicitly or implicitly because of a change to the view. During each layout update, the collection view calls this method first to give your layout object a chance to prepare for the upcoming layout operation.
     The default implementation of this method does nothing. Subclasses can override it and use it to set up data structures or perform any initial computations needed to perform the layout later.

    */
    open func prepare() {
        overrideWarning()
    }
    
    
    
    // MARK: - Index Paths
    /*-------------------------------------------------------------------------------*/
    
    /**
     All the index paths to be displayed by the collection view
     
     Becuase the layout likely needs to process all items in the data, setting this during prepare() can cut out the overhead of the collection view having to do so itself.
    */
    public var allIndexPaths = Set<IndexPath>()
    
    open func indexPathsForItems(in rect: CGRect) -> [IndexPath] {
        overrideWarning()
        var indexPaths = [IndexPath]()
        for ip in self.allIndexPaths {
            if let attr = self.layoutAttributesForItem(at: ip), attr.frame.intersects(rect) {
                indexPaths.append(attr.indexPath)
            }
        }
        return indexPaths
    }
    
    
    
    // MARK: - Layout Attributes
    /*-------------------------------------------------------------------------------*/
    
    /**
     Returns the layout attributes for all views in a given rect

     - Parameter rect: The rect in which to look for elements

    */
    open func layoutAttributesForItems(in rect: CGRect) -> [CollectionViewLayoutAttributes] {
        overrideWarning()
        var attrs = [CollectionViewLayoutAttributes]()
        for ip in self.allIndexPaths {
            if let attr = self.layoutAttributesForItem(at: ip), attr.frame.intersects(rect) {
                attrs.append(attr)
            }
        }
        return attrs
    }
    
    
    /**
     Returns the layout attributes for an item at the given index path

     - Parameter indexPath: The index path of the item for which you want the attributes
     
     # Important
     This must be overridden by subclasses

    */
    open func layoutAttributesForItem(at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
        overrideWarning()
        return nil
    }
    
    
    @available(*, unavailable, renamed: "layoutAttributesForSupplementaryView(ofKind:at:)")
    open func layoutAttributesForSupplementaryView(ofKind elementKind: String, atIndexPath indexPath: IndexPath) -> CollectionViewLayoutAttributes? { return nil }
    
    /**
     Returns the layout attributes for the supplementary view of the given kind and the given index path
     
     - Parameter elementKind: The kind of the view
     - Parameter indexPath: The index path of the view
     
     # Important
     This must be override by a subclass

    */
    open func layoutAttributesForSupplementaryView(ofKind kind: String, at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
        overrideWarning()
        return nil
    }
    
    

    
    // MARK: - Section Frames
    /*-------------------------------------------------------------------------------*/
    
    /**
     Returns the frame that encapsulates all the content in the section

     - Parameter section: The section to get the frame for

     - Returns: The rect containing all the views

    */
    open func rectForSection(_ section: Int) -> CGRect {
        overrideWarning()
        var rect = self.contentRectForSection(section)
        guard let cv = self.collectionView else { return rect }
        for identifier in cv._allSupplementaryViewIdentifiers {
            if let attributes = self.layoutAttributesForSupplementaryView(ofKind: identifier.kind, at: IndexPath.for(item:0, section: section)) {
                rect = rect.union(attributes.frame)
            }
        }
        return rect
    }
    
    
    /**
     Returns the rect that encapsulates just the items of a section

     - Parameter section: The section to get the content frame for

     - Returns: The rect containing all the items

    */
    open func contentRectForSection(_ section: Int) -> CGRect {
        overrideWarning()
        var rect = CGRect.null
        guard let cv = self.collectionView else { return rect }
        let itemCount = cv.numberOfItems(in: section)
        
        for itemIndex in 0..<itemCount {
            let indexPath = IndexPath.for(item: itemIndex, section: section)
            allIndexPaths.insert(indexPath)
            if let attributes = self.layoutAttributesForItem(at: indexPath) {
                rect = rect.union(attributes.frame);
            }
        }
        return rect
    }
    
    
    
    // MARK: - Scroll Frames
    /*-------------------------------------------------------------------------------*/
    
    /**
     Provides he layout a chance to adjust the frame to which the collection view should scroll to show an item
     
     - Parameter indexPath: The item to scroll to
     - Parameter atPosition: The position at which to scroll the item to
     
     The default implementation returns the value from layoutAttributesForItem(at:)
     */
    open func scrollRectForItem(at indexPath: IndexPath, atPosition: CollectionViewScrollPosition) -> CGRect? {
        return self.layoutAttributesForItem(at: indexPath)?.frame
    }
    
    
    // MARK: - Item Direction
    /*-------------------------------------------------------------------------------*/
    
    /**
     Returns the index path for the next item in a given direction

     - Parameter direction: The direction in which to look for the next items (up, down, left, right)
     - Parameter currentIndexPath: The current index path to seek from
     
    */
    open func indexPathForNextItem(moving direction: CollectionViewDirection, from currentIndexPath: IndexPath) -> IndexPath? { return currentIndexPath }
}
