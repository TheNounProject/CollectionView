//
//  MRCTests.swift
//  CollectionViewTests
//
//  Created by Wesley Byrne on 2/16/18.
//  Copyright © 2018 Noun Project. All rights reserved.
//

import XCTest
@testable import CollectionView

fileprivate class Child: ResultType, CustomStringConvertible {
    let id = UUID()
    var rank: Int
    var name: String
    var parent: Parent
    
    init(rank: Int, name: String? = nil, parent: Parent) {
        self.rank = rank
        self.name = name ?? "Child \(rank)"
        self.parent = parent
    }
    
    var hashValue: Int {
        return id.hashValue
    }
    static func ==(lhs: Child, rhs: Child) -> Bool {
        return lhs.id == rhs.id
    }
    var description: String {
        return "Child \(self.name) - [\(self.parent.rank), \(self.rank)]"
    }
}
fileprivate class Parent: SectionType, CustomStringConvertible {
    let id = UUID()
    var rank: Int
    var name: String
    var hashValue: Int {
        return id.hashValue
    }
    init(rank: Int, name: String? = nil) {
        self.rank = rank
        self.name = name ?? "Parent \(rank)"
    }
    static func ==(lhs: Parent, rhs: Parent) -> Bool {
        return lhs.id == rhs.id
    }
    
    func createChildren(_ n: Int) -> [Child] {
        var _children = [Child]()
        for idx in 0..<n {
            _children.append(Child(rank: idx, name: "Child \(idx)", parent: self))
        }
        return _children
    }
    var description: String {
        return "Parent \(self.id) - \(self.rank)"
    }
}

extension MutableCollection {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        
        for (firstUnshuffled, unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: IndexDistance = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            let i = index(firstUnshuffled, offsetBy: d)
            swapAt(firstUnshuffled, i)
        }
    }
}

class MRCObjectTests: XCTestCase, ResultsControllerDelegate {
    
    fileprivate func create(containers: Int, objects: Int) -> (containers: [UUID: Parent], objects: [Child]) {
        var _parents = [UUID: Parent]()
        var _children = [Child]()
        for cIdx in 0..<containers {
            let p = Parent(rank: cIdx, name: "Container \(cIdx)")
            _parents[p.id] = p
            _children.append(contentsOf: p.createChildren(objects))
        }
        return (_parents, _children)
    }
    
    // MARK: - Mutating Objects
    /*-------------------------------------------------------------------------------*/
    
    func test_insertFirstObject() {
        let mrc = MutableResultsController<NoSectionType, Child>()
        mrc.sortDescriptors = [SortDescriptor(\Child.rank)]
        
        let child = create(containers: 1, objects: 1).objects[0]
        mrc.insert(object: child)
        
        XCTAssertEqual(mrc.numberOfSections, 1)
        XCTAssertEqual(mrc.numberOfObjects(in: 0), 1)
        XCTAssertEqual(mrc.object(at: IndexPath.zero), child)
    }
    
    func test_insertMultipleObjects() {
        let mrc = MutableResultsController<NoSectionType, Child>()
        mrc.sortDescriptors = [SortDescriptor(\Child.rank)]
        
        let children = create(containers: 1, objects: 5).objects
        mrc.beginEditing()
        mrc.insert(objects: children)
        mrc.endEditing()
        
        XCTAssertEqual(mrc.numberOfSections, 1)
        XCTAssertEqual(mrc.numberOfObjects(in: 0), 5)
        for n in 0..<5 {
            XCTAssertEqual(mrc.object(at: IndexPath.for(item: n, section: 0)), children[n])
        }
    }
    
    func test_insertObjects_withSections() {
        let mrc = MutableResultsController<Parent, Child>()
        mrc.sortDescriptors = [SortDescriptor(\Child.rank)]
        mrc.setSectionKeyPath(\Child.parent)
        
        let children = create(containers: 3, objects: 5).objects
        mrc.beginEditing()
        mrc.insert(objects: children)
        mrc.endEditing()
        
        XCTAssertEqual(mrc.numberOfSections, 3)
        for n in 0..<3 {
            XCTAssertEqual(mrc.numberOfObjects(in: n), 5)
        }
    }
    
    // MARK: - Mutating Sections
    /*-------------------------------------------------------------------------------*/
    
    func test_insertSection() {
        let mrc = MutableResultsController<Parent, Child>(sectionKeyPath: \Child.parent,
                                                          sortDescriptors: [SortDescriptor(\Child.rank)],
                                                          sectionSortDescriptors: [SortDescriptor(\Parent.rank)])
        
        XCTAssertEqual(mrc.numberOfSections, 0)
        mrc.insert(section: Parent(rank: 0, name: "Parent 1"))
        XCTAssertEqual(mrc.numberOfSections, 1)
        XCTAssertEqual(mrc.numberOfObjects(in: 0), 0)
    }
    
    func test_insertSections_sorted() {
        let mrc = MutableResultsController<Parent, Child>(sectionKeyPath: \Child.parent,
                                                          sortDescriptors: [SortDescriptor(\Child.rank)],
                                                          sectionSortDescriptors: [SortDescriptor(\Parent.rank)])
        XCTAssertEqual(mrc.numberOfSections, 0)
        let ranks = [5, 3, 6, 2, 4, 1]
        for n in ranks {
            mrc.insert(section: Parent(rank: n, name: "Parent \(n)"))
        }
        XCTAssertEqual(mrc.numberOfSections, ranks.count)
        for (idx, n) in ranks.sorted().enumerated() {
            XCTAssertEqual(mrc.object(forSectionAt: IndexPath.for(section: idx))?.rank, n)
        }
    }
    
    func test_updateSection() {
        let mrc = MutableResultsController<Parent, Child>(sectionKeyPath: \Child.parent,
                                                          sortDescriptors: [SortDescriptor(\Child.rank)],
                                                          sectionSortDescriptors: [SortDescriptor(\Parent.rank)])
        
        let p1 = Parent(rank: 1)
        let p2 = Parent(rank: 2)
        mrc.insert(section: p1)
        mrc.insert(section: p2)
        
        XCTAssertEqual(mrc.object(forSectionAt: IndexPath.for(section: 0)), p1)
        XCTAssertEqual(mrc.object(forSectionAt: IndexPath.for(section: 1)), p2)
        
        p2.rank = 0
        mrc.didUpdate(section: p2)
        
        XCTAssertEqual(mrc.numberOfSections, 2)
        
        XCTAssertEqual(mrc.object(forSectionAt: IndexPath.for(section: 0)), p2)
        XCTAssertEqual(mrc.object(forSectionAt: IndexPath.for(section: 1)), p1)
    }
    
    func test_deleteSection() {
        let mrc = MutableResultsController<Parent, Child>(sectionKeyPath: \Child.parent,
                                                          sortDescriptors: [SortDescriptor(\Child.rank)],
                                                          sectionSortDescriptors: [SortDescriptor(\Parent.rank)])
        
        let p1 = Parent(rank: 1)
        let p2 = Parent(rank: 2)
        let p3 = Parent(rank: 3)
        mrc.setContent([p1, p2, p3].map({ (p) -> (Parent, [Child]) in
            return (p, [])
        }))
        
        mrc.delete(section: p2)
        XCTAssertEqual(mrc.numberOfSections, 2)
        
        XCTAssertEqual(mrc.object(forSectionAt: IndexPath.for(section: 0)), p1)
        XCTAssertEqual(mrc.object(forSectionAt: IndexPath.for(section: 1)), p3)
    }
    
    func test_moveObjectCrossSection() {
        let mrc = MutableResultsController<Parent, Child>(sectionKeyPath: \Child.parent,
                                                          sortDescriptors: [SortDescriptor(\Child.rank)],
                                                          sectionSortDescriptors: [SortDescriptor(\Parent.rank)])
        
        let p1 = Parent(rank: 1)
        let p2 = Parent(rank: 2)
        let c1 = p1.createChildren(5)
        let c2 = p2.createChildren(5)
        
        let move = c2[3]
        mrc.setContent([(p1, c1), (p2, c2)])
        
        move.parent = p1
        mrc.didUpdate(object: move)
        
        XCTAssertEqual(mrc.numberOfObjects(in: 0), 6)
        XCTAssertEqual(mrc.numberOfObjects(in: 1), 4)
        
        XCTAssertEqual(mrc.object(at: IndexPath.for(item: 4, section: 0))!, move)
    }
    
    func test_moveAllObjectsOutOfSection() {
        let mrc = MutableResultsController<Parent, Child>(sectionKeyPath: \Child.parent,
                                                          sortDescriptors: [SortDescriptor(\Child.rank)],
                                                          sectionSortDescriptors: [SortDescriptor(\Parent.rank)])
        
        let p1 = Parent(rank: 1)
        let p2 = Parent(rank: 2)
        let p3 = Parent(rank: 2)
        let c1 = p1.createChildren(5)
        let c2 = p2.createChildren(5)
        let c3 = p3.createChildren(5)
        
        mrc.setContent([(p1, c1), (p2, c2), (p3, c3)])
        
        mrc.beginEditing()
        for c in c1 {
            c.parent = p2
            mrc.didUpdate(object: c)
        }
        mrc.endEditing()
        
        XCTAssertEqual(mrc.numberOfSections, 2)
        XCTAssertEqual(mrc.object(forSectionAt: IndexPath.for(section: 0)), p2)
        XCTAssertEqual(mrc.object(forSectionAt: IndexPath.for(section: 1)), p3)
        XCTAssertEqual(mrc.numberOfObjects(in: 0), 10)
        XCTAssertEqual(mrc.numberOfObjects(in: 1), 5)
    }
    
    func testBreakingOperation() {
        
        let p0 = Parent(rank: 0)
        let c0 = p0.createChildren(8)
        
        let p1 = Parent(rank: 1)
        let c1 = p0.createChildren(8)
        
        let p2 = Parent(rank: 2)
        var c2 = p0.createChildren(6)
        
        for n in ["lwpYbKhfiG", "mkIMIFswjn", "ltNeWStiEM", "druXHaGSbQ", "rVQAeFgtlf", "fzTRcptguz", "lIUPRmNvCg", "fxuRNRbcMw"].enumerated() {
            c0[n.offset].name = n.element
        }
        
        for n in ["JqxaRRwiwn", "mkCZsTjRGb", "YiEApHQDdK", "DgXqDmWzye", "KqmuVFUwVu", "sCLUNVUWeg", "jSKlGSZNbG", "MKdrVDyWnU"].enumerated() {
            c1[n.offset].name = n.element
        }
        for n in ["QhpuDscFdA", "TVVMWMtNxW", "oWhWzJhrlw", "XiBDxjsdUu", "mUYSuqGpoA", "nqASWhRVMu"].enumerated() {
            c2[n.offset].name = n.element
        }
        
        let mrc = MutableResultsController<Parent, Child>(sectionKeyPath: \Child.parent,
                                                          sortDescriptors: [SortDescriptor(\Child.rank)],
                                                          sectionSortDescriptors: [SortDescriptor(\Parent.rank)])
        
        mrc.setContent([(p0, c0), (p1, c1), (p2, c2)])
        mrc.delegate = self
        
        let c0Rank = [1, 4, 3, 5, 5, 3, 7, 1]
        let c0Parents = [p1, p2, p2, p0, p1, p0, p0, p2]
        
        let c1Rank = [5, 1, 0, 6, 3, 4, 2, 2]
        let c1Parents = [p2, p0, p0, p1, p1, p0, p0, p2]
        
        let c2Rank = [2, 7, 6, 4, 0]
        let c2Parents = [p1, p1, p0, p1, p2]
        
        self._expectation = expectation(description: "Delegate")
        
        for c in c0.enumerated() {
            c.element.rank = c0Rank[c.offset]
            c.element.parent = c0Parents[c.offset]
        }
        for c in c1.enumerated() {
            c.element.rank = c1Rank[c.offset]
            c.element.parent = c1Parents[c.offset]
        }
        let r = c2.removeLast()
        for c in c2.enumerated() {
            c.element.rank = c2Rank[c.offset]
            c.element.parent = c2Parents[c.offset]
        }
        
        p1.rank = 0
        p0.rank = 1
        
        let new = p1.createChildren(1)[0]
        new.name = "SyDBgaLenT"
        new.rank = 0
        
        mrc.beginEditing()
        
        var objects = c0
        objects.append(contentsOf: c1)
        objects.append(contentsOf: c2)
        objects.shuffle()
        for c in objects {
            mrc.didUpdate(object: c)
        }
        
        mrc.delete(object: r)
        mrc.insert(object: new)
        mrc.didUpdate(section: p0)
        mrc.didUpdate(section: p1)
        
        mrc.endEditing()
        self.waitForExpectations(timeout: 0.5) { (_) in
            XCTAssertEqual(self.changeSet.itemUpdates.inserted.count, 1)
            XCTAssertEqual(self.changeSet.itemUpdates.deleted.count, 1)
            print("Done")
        }
    }
    
    var changeSet = CollectionViewResultsProxy()
    var _expectation: XCTestExpectation?
    func controllerWillChangeContent(controller: ResultsController) {
        changeSet.prepareForUpdates()
    }
    func controller(_ controller: ResultsController, didChangeObject object: Any, at indexPath: IndexPath?, for changeType: ResultsControllerChangeType) {
        changeSet.addChange(forItemAt: indexPath, with: changeType)
    }
    func controller(_ controller: ResultsController, didChangeSection section: Any, at indexPath: IndexPath?, for changeType: ResultsControllerChangeType) {
        changeSet.addChange(forSectionAt: indexPath, with: changeType)
    }
    func controllerDidChangeContent(controller: ResultsController) {
        _expectation?.fulfill()
        _expectation = nil
    }
    
    // MARK: - Performance Tests
    /*-------------------------------------------------------------------------------*/
    
    func testSmallInsertPerformance() {
        let mrc = MutableResultsController<Parent, Child>(sectionKeyPath: \Child.parent,
                                                          sortDescriptors: [SortDescriptor(\Child.rank)],
                                                          sectionSortDescriptors: [SortDescriptor(\Parent.rank)])
        
        let data = self.create(containers: 1, objects: 1000)
        let parent = data.containers.first!.value
        
        self.measure {
            mrc.setContent(objects: data.objects)
            mrc.beginEditing()
            mrc.insert(objects: parent.createChildren(200))
            mrc.endEditing()
        }
    }
    
    func testMediumInsertPerformance() {
        let mrc = MutableResultsController<Parent, Child>(sectionKeyPath: \Child.parent,
                                                          sortDescriptors: [SortDescriptor(\Child.rank)],
                                                          sectionSortDescriptors: [SortDescriptor(\Parent.rank)])
        
        let data = self.create(containers: 1, objects: 2000)
        let parent = data.containers.first!.value
        
        self.measure {
            mrc.setContent(objects: data.objects)
            mrc.beginEditing()
            mrc.insert(objects: parent.createChildren(200))
            mrc.endEditing()
        }
    }
    
    func testLargeInsertPerformance() {
        let mrc = MutableResultsController<Parent, Child>(sectionKeyPath: \Child.parent,
                                                          sortDescriptors: [SortDescriptor(\Child.rank)],
                                                          sectionSortDescriptors: [SortDescriptor(\Parent.rank)])
        
        let data = self.create(containers: 1, objects: 5000)
        let parent = data.containers.first!.value
        
        self.measure {
            mrc.setContent(objects: data.objects)
            mrc.beginEditing()
            mrc.insert(objects: parent.createChildren(500))
            mrc.endEditing()
        }
    }
    
    func testHugeInsertPerformance() {
        let mrc = MutableResultsController<Parent, Child>(sectionKeyPath: \Child.parent,
                                                          sortDescriptors: [SortDescriptor(\Child.rank)],
                                                          sectionSortDescriptors: [SortDescriptor(\Parent.rank)])
        
        let data = self.create(containers: 1, objects: 10000)
        let parent = data.containers.first!.value
        
        self.measure {
            mrc.setContent(objects: data.objects)
            mrc.beginEditing()
            mrc.insert(objects: parent.createChildren(1000))
            mrc.endEditing()
        }
    }
    
}
