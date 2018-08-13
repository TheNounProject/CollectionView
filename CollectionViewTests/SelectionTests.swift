//
//  CollectionViewTests.swift
//  CollectionViewTests
//
//  Created by Wesley Byrne on 1/11/18.
//  Copyright © 2018 Noun Project. All rights reserved.
//

import XCTest
import CollectionView

class SelectionTests: XCTestCase, CollectionViewDataSource {
    
    var collectionView: CollectionView!
    
    override func setUp() {
        super.setUp()
        
        collectionView = CollectionView()
        collectionView.frame = CGRect(x: 0, y: 0, width: 500, height: 500)
        CollectionViewCell.register(in: collectionView)
        collectionView.dataSource = self
        collectionView.reloadData()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    func numberOfSections(in collectionView: CollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int {
        return 50
    }
    
    func collectionView(_ collectionView: CollectionView, cellForItemAt indexPath: IndexPath) -> CollectionViewCell {
        return CollectionViewCell.deque(for: indexPath, in: collectionView)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDefaults() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let ip = IndexPath.for(item: 5, section: 0)
        let ip2 = IndexPath.for(item: 10, section: 0)
        collectionView.selectItem(at: ip, animated: true)
        assert(collectionView.itemAtIndexPathIsSelected(ip), "Index path not reported as selected")
        
        collectionView.selectItem(at: ip2, animated: true)
        
        assert(collectionView.itemAtIndexPathIsSelected(ip) == false, "Index path not deselect on other selection")
        assert(collectionView.itemAtIndexPathIsSelected(ip2), "Index path 2 not reported as selected")
        
        collectionView.deselectItem(at: ip, animated: true)
        assert(collectionView.itemAtIndexPathIsSelected(ip2), "Index path 2 selected after deselect")
    }
    
}
