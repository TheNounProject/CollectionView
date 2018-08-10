//
//  IndexedSetTests.swift
//  CollectionViewTests
//
//  Created by Wesley Byrne on 2/13/18.
//  Copyright © 2018 Noun Project. All rights reserved.
//

import XCTest
@testable import CollectionView

class IndexedSetTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testInit() {
        let set: IndexedSet = [
            "index_one": "one",
            "index_two": "two"
        ]
        XCTAssertEqual(set.count, 2)
    }
    func testInitFromDict() {
        let set = IndexedSet<String, String>([
            "index_one": "one",
            "index_two": "two"
        ])
        XCTAssertEqual(set.count, 2)
    }
    
    func testInit_duplicateValue() {
        let set: IndexedSet = [
            "index_one": "one",
            "index_two": "one"
        ]
        XCTAssertEqual(set.count, 1)
    }
    
    func testContains() {
        let set: IndexedSet = [
            "index_one": "one",
            "index_two": "two"
        ]
        XCTAssertTrue(set.contains("one"))
        XCTAssertTrue(set.contains("two"))
    }
    func testContainsValueForIndex() {
        let set: IndexedSet = [
            "index_one": "one",
            "index_two": "two"
        ]
        XCTAssertTrue(set.containsValue(for: "index_one"))
        XCTAssertTrue(set.containsValue(for: "index_two"))
    }
    
    // MARK: - Inserting
    /*-------------------------------------------------------------------------------*/
    
    func testInsert_newValue_newIndex() {
        var set: IndexedSet = [
            "index_one": "one",
            "index_two": "two"
        ]
        set.insert("three", for: "index_three")
        XCTAssertEqual(set.count, 3)
        XCTAssertTrue(set.containsValue(for: "index_three"))
        XCTAssertTrue(set.contains("three"))
    }
    
    func testInsert_dupValue_new_index() {
        var set: IndexedSet = [
            "index_one": "one",
            "index_two": "two"
        ]
        set.insert("two", for: "index_three")
        XCTAssertEqual(set.count, 2)
        XCTAssertTrue(set.containsValue(for: "index_three"))
        XCTAssertFalse(set.contains("three"))
    }
    
    func testInsert_newValue_dupIndex() {
        var set: IndexedSet = [
            "index_one": "one",
            "index_two": "two"
        ]
        set.insert("three", for: "index_two")
        XCTAssertEqual(set.count, 2)
        XCTAssertTrue(set.containsValue(for: "index_two"))
        XCTAssertTrue(set.contains("three"))
        XCTAssertFalse(set.contains("two"))
    }
    
    func testInsert_dupValue_dupIndex() {
        var set: IndexedSet = [
            "index_one": "one",
            "index_two": "two"
        ]
        set.insert("one", for: "index_two")
        XCTAssertEqual(set.count, 1)
        XCTAssertTrue(set.containsValue(for: "index_two"))
        XCTAssertTrue(set.contains("one"))
    }
    
    func testInsert_subscript() {
        var set: IndexedSet = [
            "index_one": "one",
            "index_two": "two"
        ]
        set["index_three"] = "three"
        XCTAssertEqual(set.count, 3)
        XCTAssertTrue(set.containsValue(for: "index_three"))
        XCTAssertTrue(set.contains("three"))
    }
    
    // MARK: - Removing
    /*-------------------------------------------------------------------------------*/
    
    func testRemoveByIndex() {
        var set: IndexedSet = [
            "index_one": "one",
            "index_two": "two"
        ]
        XCTAssertEqual(set.removeValue(for: "index_one"), "one")
        XCTAssertEqual(set.count, 1)
    }
    func testRemoveValue() {
        var set: IndexedSet = [
            "index_one": "one",
            "index_two": "two"
        ]
        XCTAssertEqual(set.remove("one"), "index_one")
        XCTAssertEqual(set.count, 1)
    }
    
    func testUnion() {
        let set: IndexedSet = [
            "index_one": "one",
            "index_two": "two"
        ]
        let set2: IndexedSet = [
            "index_three": "three",
            "index_four": "four"
        ]
        let merged = set.union(set2)
        XCTAssertEqual(merged.count, 4)
    }
    func testUnion_duplicates() {
        let set: IndexedSet = [
            "index_one": "one",
            "index_two": "two"
        ]
        let set2: IndexedSet = [
            "index_one": "three",
            "index_four": "four"
        ]
        let merged = set.union(set2)
        XCTAssertEqual(merged.count, 3)
        XCTAssertEqual(merged.value(for: "index_one"), "three")
        XCTAssertFalse(merged.contains("one"))
    }

    func testInitPerformance() {
        // This is an example of a performance test case.
        var source = [String: String]()
        for n in 0..<5000 {
            source["index_\(n)"] = "value_\(n)"
        }
        self.measure {
            _ = IndexedSet<String, String>(source)
        }
    }
    
    func testInsertPerformance() {
        self.measure {
            var set = IndexedSet<String, String>()
            for n in 0..<5000 {
                set["index_\(n)"] = "value_\(n)"
            }
        }
    }
    
    func testDiplicatePerformance() {
        self.measure {
            var set = IndexedSet<String, String>()
            for n in 0..<5000 {
                set["index_\(n)"] = "value_\(n)"
            }
            for n in stride(from: 0, to: 5000, by: 2) {
                set["index_\(n)"] = "value_\(n)"
            }
        }
    }

}
