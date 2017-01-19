//
//  CollectionViewController.swift
//  Lingo
//
//  Created by Wesley Byrne on 8/3/16.
//  Copyright © 2016 The Noun Project. All rights reserved.
//

import Foundation
import CollectionView


open class CollectionViewController : NSViewController, CollectionViewDataSource, CollectionViewDelegate {
    
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
    
    open func adjustContentInsets(_ insets: EdgeInsets) {
        
        self.adjustConstraint(.top, value: insets.top)
        self.adjustConstraint(.left, value: insets.left)
        self.adjustConstraint(.right, value: insets.right)
        self.adjustConstraint(.bottom, value: insets.bottom)
        
    }
    
    // Must be .Top, .Right, .Bottom, or .Left
    open func adjustConstraint(_ attribute: NSLayoutAttribute, value: CGFloat?) {
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
    
    open func numberOfSectionsInCollectionView(_ collectionView: CollectionView) -> Int {
        return 0
    }
    
    open func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }
    
    open func collectionView(_ collectionView: CollectionView, cellForItemAtIndexPath indexPath: IndexPath) -> CollectionViewCell! {
        assertionFailure("CollectionViewController must implement collectionView:cellForItemAtIndexPath:")
        return CollectionViewCell()
    }
}


