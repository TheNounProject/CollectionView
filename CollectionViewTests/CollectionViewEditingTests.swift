//
//  CollectionViewEditing.swift
//  CollectionView
//
//  Created by Wesley Byrne on 2/26/18.
//  Copyright © 2018 Noun Project. All rights reserved.
//

import XCTest
@testable import CollectionView

class CollectionViewEditing: XCTestCase, CollectionViewDataSource {

    var data = [Int]()
    lazy var collectionView: CollectionView = {
        let cv = CollectionView(frame: NSRect(x: 0, y: 0, width: 600, height: 600))
        cv.collectionViewLayout = CollectionViewListLayout()
        cv.dataSource = self
        CollectionViewCell.register(in: cv)
        return cv
    }()
    
    func numberOfSections(in collectionView: CollectionView) -> Int {
        return data.count
    }
    func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int {
        return data[section]
    }
    func collectionView(_ collectionView: CollectionView, cellForItemAt indexPath: IndexPath) -> CollectionViewCell {
        return CollectionViewCell.deque(for: indexPath, in: collectionView)
    }
    
    override func setUp() {
        super.setUp()
        self.data = []
        self.collectionView.reloadData()
    }

    func testInsertEmptySection() {
        self.data = [0]
        self.collectionView.insertSections(IndexSet(integer: 0), animated: false)
        XCTAssertEqual(collectionView.numberOfSections, 1)
        XCTAssertEqual(collectionView.numberOfItems(in: 0), 0)
    }
    
    func testInsertPopulatedSection() {
        self.data = [5]
        self.collectionView.insertSections(IndexSet(integer: 0), animated: false)
        XCTAssertEqual(collectionView.numberOfSections, 1)
        XCTAssertEqual(collectionView.numberOfItems(in: 0), 5)
    }
    
    func testRemoveEmptySection() {
        self.data = [0]
        self.collectionView.reloadData()
        self.data = []
        self.collectionView.deleteSections(IndexSet(integer: 0), animated: false)
        XCTAssertEqual(collectionView.numberOfSections, 0)
    }
    
    func testRemovePopulatedSection() {
        self.data = [5]
        self.collectionView.reloadData()
        self.data = []
        self.collectionView.deleteSections(IndexSet(integer: 0), animated: false)
        XCTAssertEqual(collectionView.numberOfSections, 0)
    }
    
    func testInsertItemsWithoutSection() {
        self.data = [1]
        
        self.collectionView.insertSections([0], animated: false)
        XCTAssertEqual(collectionView.numberOfSections, 1)
        XCTAssertEqual(collectionView.numberOfItems(in: 0), 1)
        XCTAssertNotNil(collectionView.cellForItem(at: IndexPath.zero))
    }
    
    func testMoveItemInSection() {
        self.data = [2]
        self.collectionView.reloadData()
        
        let ips = [IndexPath.zero, IndexPath.for(item: 1, section: 0)]
        
        let c1 = self.collectionView.cellForItem(at: ips[0])
        let c2 = self.collectionView.cellForItem(at: ips[1])
        
        self.collectionView.moveItem(at: ips[0], to: ips[1], animated: false)
        
        XCTAssertEqual(collectionView.cellForItem(at: ips[1]), c1)
        XCTAssertEqual(collectionView.cellForItem(at: ips[0]), c2)
    }
    
    func testMoveItemCrossSection() {
        self.data = [2, 2]
        self.collectionView.reloadData()
        
        let from = IndexPath.zero
        let to = IndexPath.for(item: 0, section: 1)
        self.data = [1, 3]
        
        let cell = self.collectionView.cellForItem(at: from)
        self.collectionView.moveItem(at: from, to: to, animated: false)
        
        XCTAssertEqual(self.collectionView.numberOfItems(in: 0), 1)
        XCTAssertEqual(self.collectionView.numberOfItems(in: 1), 3)
        
        XCTAssertEqual(collectionView.cellForItem(at: to), cell)
    }
    
    func testBatchUpdtes() {
        self.data = [3, 3]
        self.collectionView.reloadData()
        
        let c1 = self.collectionView.cellForItem(at: IndexPath.for(item: 0, section: 0))
        let c2 = self.collectionView.cellForItem(at: IndexPath.for(item: 1, section: 1))
        
        let exp = self.expectation(description: "Done")
        
        self.collectionView.performBatchUpdates({
            // Swap the sections
            self.collectionView.moveSection(0, to: 1, animated: true)
            // Move c2 (1,1) to 0,0
            self.collectionView.moveItem(at: IndexPath.for(item: 1, section: 1), to: IndexPath.for(item: 0, section: 0), animated: true)
        }) { (_) in
            exp.fulfill()
        }
        self.waitForExpectations(timeout: 0.8) { (_) in
            XCTAssertEqual(self.collectionView.numberOfItems(in: 0), 3)
            XCTAssertEqual(self.collectionView.numberOfItems(in: 1), 3)
            
            // 0-0 should now be 0-1
            XCTAssertEqual(self.collectionView.cellForItem(at: IndexPath.for(item: 0, section: 1)), c1)
            // 1-1 should now be 0-0
            XCTAssertEqual(self.collectionView.cellForItem(at: IndexPath.for(item: 0, section: 0)), c2)
        }
    }

}
