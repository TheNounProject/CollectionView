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
    lazy var collectionView : CollectionView = {
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
        self.collectionView.insertItems(at: [IndexPath.zero], animated: false)
        XCTAssertEqual(collectionView.numberOfSections, 1)
        XCTAssertEqual(collectionView.numberOfItems(in: 0), 1)
        XCTAssertNotNil(collectionView.cellForItem(at: IndexPath.zero))
    }
    
    func testMoveItemInSection() {
        self.data = [2,2]
        self.collectionView.reloadData()
        
        let ips = [IndexPath.zero, IndexPath.for(item: 1, section: 0)]
        
        let c1 = self.collectionView.cellForItem(at: ips[0])
        let c2 = self.collectionView.cellForItem(at: ips[1])
        
        self.collectionView.moveItem(at: ips[0], to: ips[1], animated: false)
        
        XCTAssertEqual(collectionView.cellForItem(at: ips[1]), c1)
        XCTAssertEqual(collectionView.cellForItem(at: ips[0]), c2)
    }
    
    func testMoveItemCrossSection() {
        self.data = [2,2]
        self.collectionView.reloadData()
        
        let from = IndexPath.zero
        let to = IndexPath.for(item: 0, section: 1)
        self.data = [1,3]
        
        let cell = self.collectionView.cellForItem(at: from)
        self.collectionView.moveItem(at: from, to: to, animated: false)
        
        XCTAssertEqual(self.collectionView.numberOfItems(in: 0), 1)
        XCTAssertEqual(self.collectionView.numberOfItems(in: 1), 3)
        
        XCTAssertEqual(collectionView.cellForItem(at: to), cell)
    }
    
    func testBatchUpdtes() {
        self.data = [3,3]
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
        self.waitForExpectations(timeout: 0.8) { (err) in
            XCTAssertEqual(self.collectionView.numberOfItems(in: 0), 3)
            XCTAssertEqual(self.collectionView.numberOfItems(in: 1), 3)
            
            // 0-0 should now be 0-1
            XCTAssertEqual(self.collectionView.cellForItem(at: IndexPath.for(item: 0, section: 1)), c1)
            // 1-1 should now be 0-0
            XCTAssertEqual(self.collectionView.cellForItem(at: IndexPath.for(item: 0, section: 0)), c2)
        }
    }
    
    
    class Section : CustomStringConvertible {
        var source : Int?
        var target: Int?
        var count : Int = 0

        var expected : Int {
            guard self.target != nil else { return 0 }
            return count + inserted.count - removed.count
        }
        var inserted = Set<Int>()
        var removed = Set<Int>()
        
        init(source: Int?, target: Int?, count: Int) {
            self.source = source
            self.target = target
            self.count = count
        }
        
        var description: String {
            return "Source: \(source ?? -1) Target: \(self.target ?? -1) Count: \(count) expected: \(expected)"
        }
        
    }
    
    
    func testUpdates() {
        

        let data = [3, 3, 3]
        // a -b  c
        // j  h >k
        // x  y  z
        
        // <k  x y  z
        // a  c
        // +g j  h
        // m, n, o
        let insertedItems : [IndexPath] = [[1,0]]
        let deletedItems : [IndexPath] = [[0,1]]
        let movedItems : [(IndexPath, IndexPath)] = [([1,2],[0,0])]
        let insertedSections : [Int] = [3]
        let movedSections : [(Int, Int)] = [(2,0)]
        let deletedSections : [Int] = []
        
        let newData = [4, 2, 3, 3]
        
        var sections = [Section]()
        for s in data.enumerated() {
            sections.append(Section(source: s.offset, target: nil, count: s.element))
        }
        
        var newSections = [Section?](repeatElement(nil, count: 4))
        for section in insertedSections {
            newSections[section] = Section(source: nil, target: section, count: newData[section])
        }
        var transfered = Set<Int>()
        for moved in movedSections {
            transfered.insert(moved.0)
            sections[moved.0].target = moved.1
            newSections[moved.1] = sections[moved.0]
        }

        var idx = 0
        func incrementInsert() {
            while idx < newSections.count && newSections[idx] != nil {
                idx += 1
            }
        }
        for section in sections where !transfered.contains(section.source!) && !deletedSections.contains(section.source!) {
            incrementInsert()
            section.target = idx
            newSections[idx] = section
        }
        
        for d in deletedItems {
            sections[d._section].removed.insert(d._item)
        }
        for i in insertedItems {
            sections[i._section].inserted.insert(i._item)
        }
        for i in movedItems {
            sections[i.0._section].removed.insert(i.0._item)
            newSections[i.1._section]!.inserted.insert(i.1._item)
        }
        
        func section(for previousSection: Int) -> Int {
            return sections[previousSection].target!
        }
        print("---")
        for i in 0..<3 {
            print("Section \(i) is now \(section(for: i))")
        }
        print("---")
        for p in sections {
            print(p)
        }
        print("---")
        for p in newSections {
            print(p!)
        }
        print("---")
    }
    

}
