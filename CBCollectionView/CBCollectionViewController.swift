//
//  CBCollectionViewController.swift
//  Lingo
//
//  Created by Wesley Byrne on 8/3/16.
//  Copyright © 2016 The Noun Project. All rights reserved.
//

import Foundation
import CBCollectionView


public class CBCollectionViewController : NSViewController, CBCollectionViewDataSource, CBCollectionViewDelegate {
    
    public let collectionView = CBCollectionView()
    
    public override func loadView() {
        if self.nibName != nil { super.loadView() }
        else {
            self.view = NSView(frame: NSRect(origin: CGPointZero, size: CGSize(width: 100, height: 100)))
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        let layout = CBCollectionViewListLayout()
        layout.itemHeight = 40
        layout.sectionInsets = NSEdgeInsetsZero
        
        collectionView.collectionViewLayout = layout
        self.view.addSubview(collectionView)
        collectionView.addConstraintsToMatchParent()
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    public func adjustContentInsets(insets: NSEdgeInsets) {
        
        self.adjustConstraint(.Top, value: insets.top)
        self.adjustConstraint(.Left, value: insets.left)
        self.adjustConstraint(.Right, value: insets.right)
        self.adjustConstraint(.Bottom, value: insets.bottom)
        
    }
    
    // Must be .Top, .Right, .Bottom, or .Left
    public func adjustConstraint(attribute: NSLayoutAttribute, value: CGFloat?) {
        var constraint: NSLayoutConstraint?
        for constraint in self.self.view.constraints {
            if (constraint.secondAttribute == attribute && (constraint.secondItem as? CBCollectionView) == collectionView)
            || (constraint.firstAttribute == attribute && (constraint.firstItem as? CBCollectionView) == collectionView) {
                if let val = value {
                    constraint.constant = val
                    constraint.active = true
                }
                else {
                    constraint.active = false
                }
                return
            }
        }
    }
    
    public func numberOfSectionsInCollectionView(collectionView: CBCollectionView) -> Int {
        return 0
    }
    
    public func collectionView(collectionView: CBCollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }
    
    public func collectionView(collectionView: CBCollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> CBCollectionViewCell! {
        assertionFailure("CBCollectionViewController must implement collectionView:cellForItemAtIndexPath:")
        return CBCollectionViewCell()
    }
}


