//
//  CVProxyTests.swift
//  CollectionViewTests
//
//  Created by Wesley Byrne on 3/5/18.
//  Copyright © 2018 Noun Project. All rights reserved.
//

import XCTest
@testable import CollectionView

class CVProxyTests: XCTestCase, CollectionViewDataSource {
    
    lazy var collectionView: CollectionView = {
        let cv = CollectionView(frame: NSRect(x: 0, y: 0, width: 600, height: 600))
        cv.collectionViewLayout = CollectionViewListLayout()
        cv.dataSource = self
        CollectionViewCell.register(in: cv)
        return cv
    }()
    private lazy var resultsController: MutableResultsController<Parent, Child> = {
        let rc = MutableResultsController<Parent, Child>(sectionKeyPath: nil,
                                                         sortDescriptors: [SortDescriptor(\Child.rank)],
                                                         sectionSortDescriptors: [SortDescriptor(\Parent.rank)])
        rc.setSectionKeyPath(\Child.parent)
        return rc
    }()
    private lazy var provider: CollectionViewProvider = {
        return CollectionViewProvider(self.collectionView, resultsController: self.resultsController)
    }()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        provider.populateWhenEmpty = false
        provider.populateEmptySections = false
        provider.defaultCollapse = false
        resultsController.reset()
        collectionView.reloadData()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func numberOfSections(in collectionView: CollectionView) -> Int {
        return provider.numberOfSections
    }
    
    func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int {
        return provider.numberOfItems(in: section)
    }
    
    func collectionView(_ collectionView: CollectionView, cellForItemAt indexPath: IndexPath) -> CollectionViewCell {
        return CollectionViewCell.deque(for: indexPath, in: collectionView)
    }
    
    func assertCounts(_ counts: [Int]) {
        XCTAssertEqual(provider.numberOfSections, counts.count)
        XCTAssertEqual(collectionView.numberOfSections, counts.count)
        for (s, count) in counts.enumerated() {
            XCTAssertEqual(provider.numberOfItems(in: s), count)
            XCTAssertEqual(collectionView.numberOfItems(in: s), count)
        }
    }
    
    // MARK: - Placeholders
    /*-------------------------------------------------------------------------------*/
    
    func testEmptyPlaceholder() {
        provider.populateWhenEmpty = true
        collectionView.reloadData()
        
        self.assertCounts([1])
        XCTAssertTrue(provider.showEmptyState)
    }
    
    func testEmptyPlaceholderReplaced() {
        // Start with empty placeholder and insert a section
        provider.populateWhenEmpty = true
        collectionView.reloadData()
        
        self.assertCounts([1])
        resultsController.insert(section: Parent(rank: 0))
        self.assertCounts([0])
        XCTAssertFalse(provider.showEmptyState)
    }
    
    func testEmptySectionPlaceholder() {
        // Empty sections
        provider.populateEmptySections = true
        let p = Parent(rank: 0)
        resultsController.setContent([(p, [])])
        collectionView.reloadData()
        
        self.assertCounts([1])
        XCTAssertFalse(provider.showEmptyState)
        XCTAssertTrue(provider.showEmptySection(at: IndexPath.zero))
    }
    
    func testReplaceEmptySectionPlaceholder() {
        // Empty sections
        provider.populateEmptySections = true
        let p = Parent(rank: 0)
        resultsController.setContent([(p, [])])
        collectionView.reloadData()
        
        resultsController.beginEditing()
        for c in p.createChildren(5) {
            resultsController.insert(object: c)
        }
        resultsController.endEditing()
        XCTAssertFalse(provider.showEmptySection(at: IndexPath.zero))
        self.assertCounts([5])
        
    }
    
    // MARK: - Section Expanding
    /*-------------------------------------------------------------------------------*/
    
    func testCollapseSection() {
        
        var children = [Child]()
        for n in 0..<3 {
            children.append(contentsOf: Parent(rank: n).createChildren(5))
        }
        
        resultsController.setContent(objects: children)
        collectionView.reloadData()
        
        self.assertCounts([5, 5, 5])
        provider.collapseSection(at: 1, animated: false)
        self.assertCounts([5, 0, 5])
    }
    
    func testExpandSection() {
        var children = [Child]()
        for n in 0..<3 {
            children.append(contentsOf: Parent(rank: n).createChildren(5))
        }
        
        resultsController.setContent(objects: children)
        collectionView.reloadData()

        provider.collapseSection(at: 1, animated: false)
        self.assertCounts([5, 0, 5])
        
        provider.expandSection(at: 1, animated: false)
        self.assertCounts([5, 5, 5])
    }
    
    func testMoveCollapseSection() {
        var children = [Child]()
        var parents = [Parent]()
        for n in 0..<3 {
            let p = Parent(rank: n)
            parents.append(p)
            children.append(contentsOf: p.createChildren(5))
        }
        
        resultsController.setContent(objects: children)
        collectionView.reloadData()
        provider.collapseSection(at: 1, animated: false)
        
        self.assertCounts([5, 0, 5])
        
        // Edit the data
        parents[0].rank = 1
        parents[1].rank = 0
        self.resultsController.beginEditing()
        self.resultsController.didUpdate(section: parents[0])
        self.resultsController.didUpdate(section: parents[1])
        self.resultsController.endEditing()
        
        XCTAssertTrue(provider.isSectionCollapsed(at: 0))
        XCTAssertFalse(provider.isSectionCollapsed(at: 1))
        self.assertCounts([0, 5, 5])
        
        provider.expandSection(at: 0, animated: false)
        XCTAssertFalse(provider.isSectionCollapsed(at: 1))
        self.assertCounts([5, 5, 5])
    }
    
    func testMoveItemsFromCollapsedToExpanded() {
        
        let p0 = Parent(rank: 0)
        let p1 = Parent(rank: 1)
        let c0 = p0.createChildren(5)
        let c1 = p1.createChildren(5)
        
        let children = [c0, c1].flatMap { return $0 }
        
        resultsController.setContent(objects: children)
        collectionView.reloadData()
        provider.collapseSection(at: 0, animated: false)
        
        self.assertCounts([0, 5])
        
        // Edit the data
        c0[0].parent = p1
        
        self.resultsController.beginEditing()
        self.resultsController.didUpdate(object: c0[0])
        self.resultsController.endEditing()
        
        self.assertCounts([0, 6])
        
        provider.expandSection(at: 0, animated: false)
        self.assertCounts([4, 6])
    }
    
    func testMoveItemsFromExpandedToCollapsed() {
        
        let p0 = Parent(rank: 0)
        let p1 = Parent(rank: 1)
        let c0 = p0.createChildren(5)
        let c1 = p1.createChildren(5)
        
        let children = [c0, c1].flatMap { return $0 }
        
        resultsController.setContent(objects: children)
        collectionView.reloadData()
        provider.collapseSection(at: 1, animated: false)
        
        self.assertCounts([5, 0])
        
        // Edit the data
        c0[0].parent = p1
        
        self.resultsController.beginEditing()
        self.resultsController.didUpdate(object: c0[0])
        self.resultsController.endEditing()
        
        self.assertCounts([4, 0])
        
        provider.expandSection(at: 1, animated: false)
        self.assertCounts([4, 6])
    }
    
    func testDefaultCollapsed() {
        
        var children = [Child]()
        children.append(contentsOf: Parent(rank: 0).createChildren(5))
        children.append(contentsOf: Parent(rank: 1).createChildren(5))
        
        provider.defaultCollapse = true
        resultsController.setContent(objects: children)
        collectionView.reloadData()
        
        self.assertCounts([0, 0])
        XCTAssertTrue(provider.isSectionCollapsed(at: 0))
        XCTAssertTrue(provider.isSectionCollapsed(at: 1))
        
        let c = Parent(rank: 2).createChildren(1)
        resultsController.insert(object: c[0])
        self.assertCounts([0, 0, 0])
        XCTAssertTrue(provider.isSectionCollapsed(at: 2))
    }
    
    func testDefaultCollapsedOnInsert() {
        
        var children = [Child]()
        children.append(contentsOf: Parent(rank: 0).createChildren(5))
        children.append(contentsOf: Parent(rank: 1).createChildren(5))
        
        provider.defaultCollapse = true
        resultsController.setContent(objects: children)
        collectionView.reloadData()
        
        provider.expandSection(at: 0, animated: false)
        
        self.assertCounts([5, 0])
        XCTAssertFalse(provider.isSectionCollapsed(at: 0))
        XCTAssertTrue(provider.isSectionCollapsed(at: 1))
        
        let c = Parent(rank: 2).createChildren(1)
        resultsController.insert(object: c[0])
        self.assertCounts([5, 0, 0])
        XCTAssertTrue(provider.isSectionCollapsed(at: 2))
    }

    func testBreakingUseCase1() {
        // A reproduction of a previously breaking case from the demo app
        let _data: [(String, [String])] = [
            ("ZSnKWisBqE", ["ueHNbNmzJE", "BLDDODjZeP", "eObJUPufpv", "dOwXZZpyif", "RIZOqeMoWM", "hGLYuDzKQi", "ZOAwicSMDE"]),
            ("WqoQBTNEaY", ["rsubjBxbVb", "zgxqrwEMEP", "RFMVhYUOBt", "TPtWHpAfhO", "vGNjxxuxds", "EEQzPOqFLm", "WqWAgYBpdk"]),
            ("KjqnrhLzeE", ["jmKARnCZQJ", "GkVzEtvFEp", "VWbpXXYeZH", "iiRlRTkGKi", "UOGPKdyFLd", "hRPjsirdxZ"])
        ]
        
        let parentOrder = ["KjqnrhLzeE", "ZSnKWisBqE", "WqoQBTNEaY"]
        
        let deleted = ["zgxqrwEMEP"]
        let inserted = [("nCcfswhOXr", "KjqnrhLzeE", 0)]
        
        var children = [String: Child]()
        var parents = [String: Parent]()
        for p in _data.enumerated() {
            let id = p.element.0
            let parent = Parent(rank: p.offset, name: id)
            for c in p.element.1.enumerated() {
                children[c.element] = Child(rank: c.offset, name: c.element, parent: parent)
            }
            parents[id] = parent
        }
        
        let changes = [
            ("RIZOqeMoWM", "KjqnrhLzeE", 6),
            ("eObJUPufpv", "KjqnrhLzeE", 1),
            ("GkVzEtvFEp", "ZSnKWisBqE", 2),
            ("dOwXZZpyif", "WqoQBTNEaY", 4),
            ("ueHNbNmzJE", "KjqnrhLzeE", 5),
            ("UOGPKdyFLd", "KjqnrhLzeE", 4),
            ("RFMVhYUOBt", "WqoQBTNEaY", 0),
            ("iiRlRTkGKi", "WqoQBTNEaY", 5),
            ("TPtWHpAfhO", "ZSnKWisBqE", 5),
            ("VWbpXXYeZH", "WqoQBTNEaY", 3),
            ("WqWAgYBpdk", "ZSnKWisBqE", 3),
            ("hRPjsirdxZ", "WqoQBTNEaY", 1),
            ("rsubjBxbVb", "ZSnKWisBqE", 6),
            ("hGLYuDzKQi", "WqoQBTNEaY", 2),
            ("ZOAwicSMDE", "ZSnKWisBqE", 0),
            ("EEQzPOqFLm", "KjqnrhLzeE", 3),
            ("jmKARnCZQJ", "ZSnKWisBqE", 1),
            ("BLDDODjZeP", "ZSnKWisBqE", 4),
            ("vGNjxxuxds", "KjqnrhLzeE", 2)
            ]
        
        resultsController.setContent(objects: Array(children.values))
        collectionView.reloadData()
        
        for change in changes {
            children[change.0]?.parent = parents[change.1]
            children[change.0]?.rank = change.2
        }
        for p in parentOrder.enumerated() {
            let parent = parents[p.element]!
            parent.rank = p.offset
        }
        
        resultsController.beginEditing()
        
        for p in parentOrder.enumerated() {
            let parent = parents[p.element]!
            resultsController.didUpdate(section: parent)
        }
        
        for d in deleted {
            resultsController.delete(object: children[d]!)
        }
        for i in inserted {
            resultsController.insert(object: Child(rank: i.2, name: i.0, parent: parents[i.1]!))
        }
        
        for change in changes {
            resultsController.didUpdate(object: children[change.0]!)
        }
        
        resultsController.endEditing()
        
    }
    
}

fileprivate class Child: ResultType, CustomStringConvertible {
    let id = UUID()
    var rank: Int
    var name: String
    var parent: Parent?
    
    init(rank: Int, name: String? = nil, parent: Parent) {
        self.rank = rank
        self.name = name ?? "Child \(rank)"
        self.parent = parent
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    static func ==(lhs: Child, rhs: Child) -> Bool {
        return lhs === rhs
    }
    var description: String {
        return "Child \(self.name) - [\(self.parent?.rank.description ?? "nil parent"), \(self.rank)]"
    }
}
fileprivate class Parent: SectionType, CustomStringConvertible {
    let id = UUID()
    var rank: Int
    var name: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }

    init(rank: Int, name: String? = nil) {
        self.rank = rank
        self.name = name ?? "Parent \(rank)"
    }
    static func ==(lhs: Parent, rhs: Parent) -> Bool {
        return lhs === rhs
    }
    
    func createChildren(_ n: Int) -> [Child] {
        var _children = [Child]()
        for idx in 0..<n {
            _children.append(Child(rank: idx, name: "Child \(idx)", parent: self))
        }
        return _children
    }
    var description: String {
        return "Parent \(self.name) - \(self.rank)"
    }
}
