//
//  CollectionViewController.swift
//  Lingo
//
//  Created by Wesley Byrne on 8/3/16.
//  Copyright © 2016 The Noun Project. All rights reserved.
//

import Foundation
import AppKit
/**
 The UICollectionViewController class represents a view controller whose content consists of a collection view.
*/
open class CollectionViewController: NSViewController, CollectionViewDataSource, CollectionViewDelegate {
    
    public let collectionView = CollectionView()
    
    open override func loadView() {
        if self.nibName != nil { super.loadView() }
        else {
            self.view = NSView(frame: NSRect(origin: CGPoint.zero, size: CGSize(width: 100, height: 100)))
        }
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        let layout = CollectionViewListLayout()
        layout.itemHeight = 40
        layout.sectionInsets = NSEdgeInsetsZero
        
        collectionView.collectionViewLayout = layout
        self.view.addSubview(collectionView)
        collectionView.addConstraintsToMatchParent()
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    // MARK: - Data Source
    /*-------------------------------------------------------------------------------*/
    
    open func numberOfSections(in collectionView: CollectionView) -> Int {
        return 0
    }
    
    open func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }
    
    open func collectionView(_ collectionView: CollectionView, cellForItemAt indexPath: IndexPath) -> CollectionViewCell {
        assertionFailure("CollectionViewController must implement collectionView:cellForItemAt:")
        return CollectionViewCell()
    }
    
    // MARK: - Layout
    /*-------------------------------------------------------------------------------*/
    /**
     Adjust the layout constraints for the collection view
     
     - Parameter insets: The insets to apply to the collection view
     
     */
    open func adjustContentInsets(_ insets: NSEdgeInsets) {
        
        self.adjustConstraint(.top, value: insets.top)
        self.adjustConstraint(.left, value: insets.left)
        self.adjustConstraint(.right, value: insets.right)
        self.adjustConstraint(.bottom, value: insets.bottom)
        
    }
    
    /**
     Adjust the constraints for the collection view
     
     - Parameter attribute: The layout attribute to adjust. Must be .Top, .Right, .Bottom, or .Left
     - Parameter value: The constant to apply to the constraint
     
     */
    open func adjustConstraint(_ attribute: NSLayoutConstraint.Attribute, value: CGFloat?) {
        for constraint in self.view.constraints {
            if (constraint.secondAttribute == attribute && (constraint.secondItem as? CollectionView) == collectionView)
                || (constraint.firstAttribute == attribute && (constraint.firstItem as? CollectionView) == collectionView) {
                if let val = value {
                    constraint.constant = val
                    constraint.isActive = true
                }
                else {
                    constraint.isActive = false
                }
                return
            }
        }
    }
    
}
