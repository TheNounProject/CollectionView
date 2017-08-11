//
//  MyController.swift
//  Example
//
//  Created by Wesley Byrne on 8/11/17.
//  Copyright © 2017 Noun Project. All rights reserved.
//

import Foundation
import AppKit
import CollectionView

class MyController : NSViewController, CollectionViewDataSource, CollectionViewDelegate {
    
    @IBOutlet weak var collectionView: CollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        let layout = CollectionViewListLayout()
        layout.itemHeight = 36
        collectionView.collectionViewLayout = layout
        
//        collectionView.register(class: UserCell.self, forCellWithReuseIdentifier: "UserCell")
        let nib = NSNib(nibNamed: "UserCell", bundle: nil)!
        collectionView.register(nib: nib, forCellWithReuseIdentifier: "UserCell")
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.reloadData()
    }
    
    func numberOfSections(in collectionView: CollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int {
        return 5
    }
    
    func collectionView(_ collectionView: CollectionView, cellForItemAt indexPath: IndexPath) -> CollectionViewCell {
     
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserCell", for: indexPath) as! UserCell
        
        return cell
        
    }
    
}
