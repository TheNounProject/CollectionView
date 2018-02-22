//
//  MRCTests.swift
//  CollectionViewTests
//
//  Created by Wesley Byrne on 2/16/18.
//  Copyright © 2018 Noun Project. All rights reserved.
//

import XCTest
@testable import CollectionView

fileprivate class Child : ResultType {
    let id = UUID()
    var rank : Int
    var name : String
    var parent : Parent
    
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
}
fileprivate class Parent : SectionType {
    let id = UUID()
    var rank : Int
    var name : String
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
}

class MRCObjectTests: XCTestCase {
    
    fileprivate func create(containers: Int, objects: Int) -> (containers: [UUID:Parent], objects: [Child]) {
        var _parents = [UUID:Parent]()
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
        mrc.sectionKeyPath = \Child.parent
        
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
        let ranks = [5,3,6,2,4,1]
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
        mrc.setContent([p1, p2, p3].map({ (p) -> (Parent,[Child]) in
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
    
    
    
    
}
