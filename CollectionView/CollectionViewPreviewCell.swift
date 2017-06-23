//
//  PreviewCell.swift
//  Lingo
//
//  Created by Wesley Byrne on 3/22/17.
//  Copyright © 2017 The Noun Project. All rights reserved.
//

import Foundation



/**
A protocol for CollectionViewCells that need to customize their transition when used in CollectionViewPreviewController.
 
 If you adopt this protocol in a custom CollectionViewCell subclass, see the source code for CollectionViewPreviewCell for an example implementation.
 */
public protocol CollectionViewPreviewTransitionCell : class {
    
    
    // MARK: - Transitioning From Source
    /*-------------------------------------------------------------------------------*/
    /**
     Called just before the transition animation to prepare the cell
     
     Update the cell to prepare for transition from the item at indexPath in collectionView. Typically this will include fetching the layout attributes and/or cell using the provided index path and collection view, then applying the frame to self.
     
     - Parameter indexPath: The indexPath of the source cell
     - Parameter collectionView: The source collection view
     - Parameter layoutAttributes: The final layout attributes for the receiver
     
     */
    func prepareForTransition(fromItemAt indexPath: IndexPath, in collectionView: CollectionView, to layoutAttributes: CollectionViewLayoutAttributes)
    
    /**
     Called within the animation block in which the cell should moved from the source position to the destination position
     
     Update the cell to position and style as needed to transition from it's source. Typically this will include fetching the layout attributes and/or cell using the provided index path and collection view, then applying the frame to self.
     
     - Parameter indexPath: The index path of the source item
     - Parameter collectionView: The source collection view
     - Parameter layoutAttributes: The final layout attributes of the receiver
     
     */
    func transition(fromItemAt indexPath: IndexPath, in collectionView: CollectionView, to layoutAttributes: CollectionViewLayoutAttributes)
    
    /**
     Called when the transition from the source has completed and the cell is in it's final position.
     
     - Parameter indexPath: The index path of the source item
     - Parameter collectionView: The source collection view
     
     */
    func finishTransition(fromItemAt indexPath: IndexPath, in collectionView: CollectionView)
    
    
    // MARK: - Transitioning To Source
    /*-------------------------------------------------------------------------------*/
    
    /**
     Called just before the cell is transitioned back to it's source
     
     - Parameter indexPath: The index path of the source item
     - Parameter collectionView: The source collection view
     
     */
    func prepareForTransition(toItemAt indexPath: IndexPath, in collectionView: CollectionView)
    
    
    /**
     Called within the transition animation block in which the cell should move back to its source.
     
     Update the cell to position and style as needed to transition back to it's source. Typically this will include fetching the layout attributes and/or cell using the provided index path and collection view, then applying the frame to self.
     
     - Parameter indexPath: The index path of the source item
     - Parameter collectionView: The source collection view
     
     */
    func transition(toItemAt indexPath: IndexPath, in collectionView: CollectionView)
    
    
    
    /**
     Called when the transition back to the source has completed and the containing preview controller will be removed.
     
     - Parameter indexPath: The index path of the source item
     - Parameter collectionView: The source collection view
     
     */
    func finishTransition(toItemAt indexPath: IndexPath, in collectView: CollectionView)
    
}




/**
 A default implementation of CollectionViewPreviewTransitionCell
*/
open class CollectionViewPreviewCell : CollectionViewCell, CollectionViewPreviewTransitionCell {
    
//    open override var wantsUpdateLayer: Bool { return true }
    
    open override func scrollWheel(with event: NSEvent) { }
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        self.transitionState = .appeaered
    }
    
    
    
    public enum TransitionState {
        case appearing
        case appeaered
        case disappearing
        case disappeared
    }
    
    open var transitionState : TransitionState = .appearing
    open var isTransitioning : Bool {
        return transitionState == .appearing || transitionState == .disappearing
    }
    
    
    // MARK: - Transitioning From Source
    /*-------------------------------------------------------------------------------*/
    
    open func prepareForTransition(fromItemAt indexPath: IndexPath, in collectionView: CollectionView, to layoutAttributes: CollectionViewLayoutAttributes) {
        self.transitionState = .appearing
        guard let attrs = collectionView.layoutAttributesForItem(at: indexPath),
            let converted = self.superview?.convert(attrs.frame, from: collectionView.contentDocumentView) else {
                self.animator().alphaValue = 0
                return
        }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.frame = converted
        CATransaction.flush()
        CATransaction.commit()
        
    }
    
    open func transition(fromItemAt indexPath: IndexPath, in collectionView: CollectionView, to layoutAttributes: CollectionViewLayoutAttributes) {
        self.animator().frame = layoutAttributes.frame
        self.animator().alphaValue = 1
    }
    
    open func finishTransition(fromItemAt indexPath: IndexPath, in collectionView: CollectionView) {
        if transitionState == .appearing {
            self.transitionState = .appeaered
        }
    }
    
    
    // MARK: - Transitioning To Source
    /*-------------------------------------------------------------------------------*/
    
    open func prepareForTransition(toItemAt indexPath: IndexPath, in collectionView: CollectionView) {
        
        if self.transitionState == .appeaered {
            guard let attrs = self.collectionView?.layoutAttributesForItem(at: indexPath),
                let converted = self.collectionView?.convert(attrs.frame, from: self.collectionView?.contentDocumentView) else {
                    self.animator().alphaValue = 0
                    return
            }
            self.removeFromSuperview()
            self.collectionView?.addSubview(self)
            self.frame = converted
        }
        self.transitionState = .disappearing
    }

    open func transition(toItemAt indexPath: IndexPath, in collectionView: CollectionView) {
        guard let attrs = collectionView.layoutAttributesForItem(at: indexPath),
            let converted = self.superview?.convert(attrs.frame, from: collectionView.contentDocumentView) else {
                self.animator().alphaValue = 0
                return
        }
        self.animator().frame = converted
    }
    
    open func finishTransition(toItemAt indexPath: IndexPath, in collectView: CollectionView) {
        if transitionState == .disappearing {
            self.transitionState = .disappeared
        }
        self.removeFromSuperview()
    }
    
    
}

