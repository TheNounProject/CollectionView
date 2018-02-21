//
//  MRCTests.swift
//  CollectionViewTests
//
//  Created by Wesley Byrne on 2/16/18.
//  Copyright © 2018 Noun Project. All rights reserved.
//

import XCTest
@testable import CollectionView

fileprivate struct Child : ResultType {
    let id = UUID()
    var rank : Int
    var name : String
    var parent : Parent
    
    var hashValue: Int {
        return id.hashValue
    }
    static func ==(lhs: Child, rhs: Child) -> Bool {
        return lhs.id == rhs.id
    }
}
fileprivate struct Parent : SectionType {
    let id = UUID()
    var rank : Int
    var name : String
    var hashValue: Int {
        return id.hashValue
    }
    static func ==(lhs: Parent, rhs: Parent) -> Bool {
        return lhs.id == rhs.id
    }
}

class MRCTests: XCTestCase {
    
    fileprivate func create(containers: Int, objects: Int) -> (containers: [UUID:Parent], objects: [Child]) {
        var _containers = [UUID:Parent]()
        var _objects = [Child]()
        for cIdx in 0..<containers {
            let container = Parent(rank: cIdx, name: "Container \(cIdx)")
            _containers[container.id] = container
            for oIdx in 0..<objects {
                _objects.append(Child(rank: oIdx, name: "Object \(oIdx)", parent: container))
            }
        }
        return (_containers, _objects)
    }

    func test_noSections() {
        let data = create(containers: 5, objects: 5)
        
        let mrc = MutableResultsController<NoSectionType, Child>()
        mrc.setContent(data.objects)
        
        XCTAssertEqual(mrc.numberOfSections, 1)
        XCTAssertEqual(mrc.numberOfObjects(in: 0), 25)
    }
    
    func test_noSections_sorted() {
        let data = create(containers: 1, objects: 10)
        
        let mrc = MutableResultsController<NoSectionType, Child>()
        mrc.sortDescriptors = [SortDescriptor(\Child.rank, ascending: false)]
        mrc.setContent(data.objects)
        
        XCTAssertEqual(mrc.numberOfSections, 1)
        XCTAssertEqual(mrc.numberOfObjects(in: 0), 10)
        
        XCTAssertEqual(mrc.object(at: IndexPath.zero)!.rank, data.objects[9].rank)
        XCTAssertEqual(mrc.object(at: IndexPath.for(item: 9, section: 0))!.rank, data.objects[0].rank)
    }
    
    func test_withSections() {
        let data = create(containers: 5, objects: 5)
        
        let mrc = MutableResultsController<Parent, Child>()
        mrc.sectionKeyPath = \Child.parent
        mrc.setContent(data.objects)
        
        XCTAssertEqual(mrc.numberOfSections, 5)
        for s in 0..<5 {
            XCTAssertEqual(mrc.numberOfObjects(in: s), 5)
        }   
    }
    
    func test_withSections_sorted() {
        let data = create(containers: 5, objects: 5)
        
        let mrc = MutableResultsController<Parent, Child>()
        mrc.sectionKeyPath = \Child.parent
        mrc.sortDescriptors = [SortDescriptor(\Child.rank)]
        mrc.sectionSortDescriptors = [SortDescriptor(\Parent.rank)]
        mrc.setContent(data.objects)
        
        XCTAssertEqual(mrc.numberOfSections, 5)
        for s in 0..<5 {
            XCTAssertEqual(mrc.numberOfObjects(in: s), 5)
        }
    }

    func testPerformance_withSections_sorted() {
        // This is an example of a performance test case.
        let data = create(containers: 10, objects: 500)
        self.measure {
            let mrc = MutableResultsController<Parent, Child>()
            mrc.sectionKeyPath = \Child.parent
            mrc.sortDescriptors = [SortDescriptor(\Child.rank)]
            mrc.sectionSortDescriptors = [SortDescriptor(\Parent.rank)]
            mrc.setContent(data.objects)
        }
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
        print("MOVE ITEM TO FRONT")
        let frc = MutableResultsController<Parent, Child>(sectionKeyPath: \Child.parent,
                                                          sortDescriptors: [SortDescriptor<Child>(keyPath: \Child.rank)],
                                                          sectionSortDescriptors: [SortDescriptor<Parent>(keyPath: \Parent.rank)]
        )
        frc.delegate = self
        
        try! self.context.save()
        
        try! frc.performFetch()
        self._expectation = expectation(description: "Delegate")
        
        let moved = parents[3]
        moved.displayOrder = -1
        
        self.waitForExpectations(timeout: 0.5) { (err) in
            // There should really only be one move
            XCTAssertEqual(self.changeSet.sections.count, 1)
            XCTAssertEqual(self.changeSet.sections.moved.count, 1)
            XCTAssertGreaterThan(self.changeSet.sections.moved.count, 0)
            print(self.changeSet)
            XCTAssertEqual(frc.object(forSectionAt: IndexPath.zero), moved)
        }
    }
    
    
    
    
}
