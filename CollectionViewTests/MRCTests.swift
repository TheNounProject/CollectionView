//
//  MRCTests.swift
//  CollectionViewTests
//
//  Created by Wesley Byrne on 2/16/18.
//  Copyright © 2018 Noun Project. All rights reserved.
//

import XCTest
@testable import CollectionView

struct Object : ResultType {
    let id = UUID()
    var rank : Int
    var name : String
    var container : Container
    
    var hashValue: Int {
        return id.hashValue
    }
    static func ==(lhs: Object, rhs: Object) -> Bool {
        return lhs.id == rhs.id
    }
}
struct Container : SectionType {
    let id = UUID()
    var rank : Int
    var name : String
    var hashValue: Int {
        return id.hashValue
    }
    static func ==(lhs: Container, rhs: Container) -> Bool {
        return lhs.id == rhs.id
    }
}

class MRCTests: XCTestCase {
    
    func create(containers: Int, objects: Int) -> (containers: [UUID:Container], objects: [Object]) {
        var _containers = [UUID:Container]()
        var _objects = [Object]()
        for cIdx in 0..<containers {
            let container = Container(rank: cIdx, name: "Container \(cIdx)")
            _containers[container.id] = container
            for oIdx in 0..<objects {
                _objects.append(Object(rank: oIdx, name: "Object \(oIdx)", container: container))
            }
        }
        return (_containers, _objects)
    }

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func test_noSections() {
        let data = create(containers: 5, objects: 5)
        
        let mrc = ManagedResultsController<NoSectionType, Object>()
        mrc.setContent(data.objects)
        
        XCTAssertEqual(mrc.numberOfSections, 1)
        XCTAssertEqual(mrc.numberOfObjects(in: 0), 25)
    }
    
    func test_noSections_sorted() {
        let data = create(containers: 1, objects: 10)
        
        let mrc = ManagedResultsController<NoSectionType, Object>()
        mrc.sortDescriptors = [SortDescriptor(\Object.rank, ascending: false)]
        mrc.setContent(data.objects)
        
        XCTAssertEqual(mrc.numberOfSections, 1)
        XCTAssertEqual(mrc.numberOfObjects(in: 0), 10)
        
        XCTAssertEqual(mrc.object(at: IndexPath.zero)!.rank, data.objects[9].rank)
        XCTAssertEqual(mrc.object(at: IndexPath.for(item: 9, section: 0))!.rank, data.objects[0].rank)
    }
    
    func test_withSections() {
        let data = create(containers: 5, objects: 5)
        
        let mrc = ManagedResultsController<Container, Object>()
        mrc.sectionKeyPath = \Object.container
        mrc.setContent(data.objects)
        
        XCTAssertEqual(mrc.numberOfSections, 5)
        for s in 0..<5 {
            XCTAssertEqual(mrc.numberOfObjects(in: s), 5)
        }   
    }
    
    func test_withSections_sorted() {
        let data = create(containers: 5, objects: 5)
        
        let mrc = ManagedResultsController<Container, Object>()
        mrc.sectionKeyPath = \Object.container
        mrc.sortDescriptors = [SortDescriptor(\Object.rank)]
        mrc.sectionSortDescriptors = [SortDescriptor(\Container.rank)]
        mrc.setContent(data.objects)
        
        XCTAssertEqual(mrc.numberOfSections, 5)
        for s in 0..<5 {
            XCTAssertEqual(mrc.numberOfObjects(in: s), 5)
        }
    }
    
    
    

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
