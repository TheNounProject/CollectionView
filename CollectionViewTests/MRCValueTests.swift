//
//  MRCTests.swift
//  CollectionViewTests
//
//  Created by Wesley Byrne on 2/16/18.
//  Copyright © 2018 Noun Project. All rights reserved.
//

import XCTest
@testable import CollectionView

fileprivate struct Child: ResultType {

    let id: UUID
    var rank: Int
    var name: String
    var parent: Parent
    
    init(id: UUID = UUID(), rank: Int, name: String? = nil, parent: Parent) {
        self.id = id
        self.rank = rank
        self.name = name ?? "Child \(rank)"
        self.parent = parent
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    static func == (lhs: Child, rhs: Child) -> Bool {
        return lhs.id == rhs.id
    }
}
fileprivate struct Parent: SectionType {
    let id: UUID
    var rank: Int
    var name: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    init(id: UUID = UUID(), rank: Int, name: String? = nil) {
        self.id = id
        self.rank = rank
        self.name = name ?? "Parent \(rank)"
    }
    static func == (lhs: Parent, rhs: Parent) -> Bool {
        return lhs.id == rhs.id
    }
}

class MRCValueTests: XCTestCase, ResultsControllerDelegate {
    
    fileprivate func create(containers: Int, objects: Int) -> (containers: [UUID: Parent], objects: [Child]) {
        var _containers = [UUID: Parent]()
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
        mrc.setContent(objects: data.objects)
        
        XCTAssertEqual(mrc.numberOfSections, 1)
        XCTAssertEqual(mrc.numberOfObjects(in: 0), 25)
    }
    
    func test_noSections_sorted() {
        let data = create(containers: 1, objects: 10)
        
        let mrc = MutableResultsController<NoSectionType, Child>()
        mrc.sortDescriptors = [SortDescriptor(\Child.rank, ascending: false)]
        mrc.setContent(objects: data.objects)
        
        XCTAssertEqual(mrc.numberOfSections, 1)
        XCTAssertEqual(mrc.numberOfObjects(in: 0), 10)
        
        XCTAssertEqual(mrc.object(at: IndexPath.zero)!.rank, data.objects[9].rank)
        XCTAssertEqual(mrc.object(at: IndexPath.for(item: 9, section: 0))!.rank, data.objects[0].rank)
    }
    
    func test_withSections() {
        let data = create(containers: 5, objects: 5)
        
        let mrc = MutableResultsController<Parent, Child>()
        mrc.setSectionKeyPath(\Child.parent)
        mrc.setContent(objects: data.objects)
        
        XCTAssertEqual(mrc.numberOfSections, 5)
        for s in 0..<5 {
            XCTAssertEqual(mrc.numberOfObjects(in: s), 5)
        }   
    }
    
    func test_withSections_sorted() {
        let data = create(containers: 5, objects: 5)
        
        let mrc = MutableResultsController<Parent, Child>()
        mrc.setSectionKeyPath(\Child.parent)
        mrc.sortDescriptors = [SortDescriptor(\Child.rank)]
        mrc.sectionSortDescriptors = [SortDescriptor(\Parent.rank)]
        mrc.setContent(objects: data.objects)
        
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
            mrc.setSectionKeyPath(\Child.parent)
            mrc.sortDescriptors = [SortDescriptor(\Child.rank)]
            mrc.sectionSortDescriptors = [SortDescriptor(\Parent.rank)]
            mrc.setContent(objects: data.objects)
        }
    }

    func testUpdateContent() {
        let children = create(containers: 3, objects: 3).objects
        let mrc = MutableResultsController<Parent, Child>()
        mrc.delegate = self
        mrc.setSectionKeyPath(\Child.parent)
        mrc.sortDescriptors = [SortDescriptor(\Child.rank)]
        mrc.sectionSortDescriptors = [SortDescriptor(\Parent.rank)]
        mrc.setContent(objects: children)

        let p0 = children[0].parent
        let p1 = children[3].parent
        let p2 = children[6].parent

        let content = [
            Child(id: children[0].id, rank: 1, name: nil, parent: p0),
            Child(id: children[1].id, rank: 0, name: nil, parent: p0),
            Child(id: children[3].id, rank: 2, name: nil, parent: p0),
            Child(id: children[2].id, rank: 0, name: nil, parent: p1),
            Child(id: children[4].id, rank: 0, name: nil, parent: p2)
        ]

        self._expectation = expectation(description: "Delegate")

        mrc.updateContent(with: content)
        XCTAssertEqual(mrc.object(at: IndexPath.for(item: 0, section: 0)), children[1])
        XCTAssertEqual(mrc.object(at: IndexPath.for(item: 1, section: 0)), children[0])

        waitForExpectations(timeout: 0.1) { (_) in
            XCTAssertEqual(self.changeSet.itemUpdates.inserted.count, 0)
            XCTAssertEqual(self.changeSet.itemUpdates.updated.count, 0)
            XCTAssertEqual(self.changeSet.itemUpdates.moved.count, 3)
            XCTAssertEqual(self.changeSet.itemUpdates.deleted.count, 4)
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

    // Test mutation with value types
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
}
