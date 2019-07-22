//
//  OrderedSetTests.swift
//  CollectionViewTests
//
//  Created by Wesley Byrne on 2/13/18.
//  Copyright © 2018 Noun Project. All rights reserved.
//

import XCTest
import CollectionView

struct Person: Hashable {
    let name: String
    let age: Int
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.name)
        hasher.combine(self.age)
    }
    static func == (lhs: Person, rhs: Person) -> Bool {
        return lhs.age == rhs.age && lhs.name == rhs.name
    }
    
    /// Defaults to 5000
    static func set(with n: Int = 5000, randomAge: Bool = true) -> OrderedSet<Person> {
        var set = OrderedSet<Person>()
        for n in 0..<n {
            let age = randomAge ? Int(arc4random_uniform(50) + 10) : n
            set.append(Person(name: randomName(length: 8), age: age))
        }
        return set
    }
}

class NSPerson: NSObject {
    @objc var name: String
    @objc var age: Int
    init(name: String, age: Int) {
        self.name = name
        self.age = age
        super.init()
    }
    class func array() -> [NSPerson] {
        var arr = [NSPerson]()
        for _ in 0..<5000 {
            let age = Int(arc4random_uniform(50) + 10)
            arr.append(NSPerson(name: randomName(length: 8), age: age))
        }
        return arr
    }
}

func randomName(length: Int) -> String {
    let letters: NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    let len = UInt32(letters.length)
    
    var randomString = ""
    
    for _ in 0 ..< length {
        let rand = arc4random_uniform(len)
        var nextChar = letters.character(at: Int(rand))
        randomString += NSString(characters: &nextChar, length: 1) as String
    }
    return randomString
}

class OrderedSetTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // MARK: - Initialization
    /*-------------------------------------------------------------------------------*/
    
    func testInitArrayLiteral() {
        let set: OrderedSet<String> = ["one", "two", "two", "three"]
        XCTAssertEqual(set[0], "one")
        XCTAssertEqual(set[1], "two")
        XCTAssertEqual(set[2], "three")
    }
    
    func testInitFromCollection() {
        let set = OrderedSet<String>(elements: ["one", "two", "three"])
        XCTAssertEqual(set[0], "one")
        XCTAssertEqual(set[1], "two")
        XCTAssertEqual(set[2], "three")
    }
    
    func testInitWithDuplicates() {
        let set: OrderedSet<String> = ["one", "two", "two", "three"]
        XCTAssertEqual(set[0], "one")
        XCTAssertEqual(set[1], "two")
        XCTAssertEqual(set[2], "three")
    }
    
    // MARK: - Counts & Members
    /*-------------------------------------------------------------------------------*/
    
    func testIsEmpty_true() {
        let set = OrderedSet<String>()
        XCTAssertTrue(set.isEmpty)
    }
    func testIsEmpty_false() {
        let set: OrderedSet<String> = ["some"]
        XCTAssertFalse(set.isEmpty)
    }
    
    func testFirst_empty() {
        let set = OrderedSet<String>()
        XCTAssertNil(set.first)
    }
    
    func testFirst_notEmpty() {
        let set: OrderedSet<String> = ["one", "two", "three"]
        XCTAssertEqual(set.first, "one")
    }

    func testIndexOf() {
        let set: OrderedSet<String> = ["one", "two", "three"]
        XCTAssertEqual(set.index(of: "one"), 0)
        XCTAssertEqual(set.index(of: "two"), 1)
        XCTAssertEqual(set.index(of: "three"), 2)
    }
    func testIndexOf_notFound() {
        let set: OrderedSet<String> = ["one", "two", "three"]
        XCTAssertNil(set.index(of: "four"))
    }
    
    func testContains_true() {
        let set: OrderedSet<String> = ["one", "two", "three"]
        XCTAssertTrue(set.contains("two"))
    }
    func testContains_false() {
        let set: OrderedSet<String> = ["one", "two", "three"]
        XCTAssertFalse(set.contains("other"))
    }
    func testContains_afterAdd() {
        var set = OrderedSet<String>()
        set.append("one")
        XCTAssertTrue(set.contains("one"))
    }
    func testContains_afterRemove_false() {
        var set: OrderedSet<String> = ["one", "two", "three"]
        set.remove("two")
        XCTAssertFalse(set.contains("two"))
    }
    
    // MARK: - Manipulation
    /*-------------------------------------------------------------------------------*/
    
    func testAddFirstObject() {
        var set = OrderedSet<String>()
        set.append("some")
        XCTAssertEqual(set.count, 1)
        XCTAssertEqual(set[0], "some")
    }
    
    func testAddObject_duplicate() {
        var set = OrderedSet<String>()
        set.append("some")
        XCTAssertEqual(set.count, 1)
        set.append("some")
        XCTAssertEqual(set.count, 1)
    }
    
    func testAddCollection() {
        var set = OrderedSet<String>()
        set.append(contentsOf: ["one", "two"])
        XCTAssertEqual(set.count, 2)
        XCTAssertEqual(set[0], "one")
        XCTAssertEqual(set[1], "two")
    }
    
    func testAddCollection_withDuplicates() {
        var set: OrderedSet<String> = ["one", "two"]
        set.append(contentsOf: ["one", "three"])
        XCTAssertEqual(set.count, 3)
        XCTAssertEqual(set[0], "one")
        XCTAssertEqual(set[1], "two")
        XCTAssertEqual(set[2], "three")
    }
    
    func testRemoveObject() {
        var set: OrderedSet<String> = ["some"]
        XCTAssertEqual(set.remove("some"), 0)
        XCTAssertEqual(set.count, 0)
    }
    
    func testRemoveObject_notFound() {
        var set: OrderedSet<String> = ["some"]
        XCTAssertEqual(set.remove("other"), nil)
        XCTAssertEqual(set.count, 1)
    }
    func testRemoveObjectFromMiddle() {
        var set: OrderedSet<String> = ["one", "two", "three", "four"]
        XCTAssertEqual(set.remove("two"), 1)
        XCTAssertEqual(set[0], "one")
        XCTAssertEqual(set[1], "three")
        XCTAssertEqual(set[2], "four")
    }
    
    func testRemoveObjectAtIndex() {
        var set: OrderedSet<String> = ["one", "two", "three", "four"]
        XCTAssertEqual(set.remove(at: 1), "two")
        XCTAssertEqual(set[0], "one")
        XCTAssertEqual(set[1], "three")
        XCTAssertEqual(set[2], "four")
    }
    
    func testRemoveAll() {
        var set: OrderedSet<String> = ["one", "two", "three", "four"]
        set.removeAll()
        XCTAssertEqual(set.count, 0)
    }
    
    func testInsert() {
        var set: OrderedSet<String> = ["one", "two", "four"]
        XCTAssertTrue(set.insert("three", at: 2))
        XCTAssertEqual(set.count, 4)
        XCTAssertEqual(set[2], "three")
        XCTAssertEqual(set[3], "four")
    }
    
    func testInsertDuplicate() {
        var set: OrderedSet<String> = ["one", "two", "three"]
        XCTAssertFalse(set.insert("three", at: 1))
        XCTAssertEqual(set.count, 3)
    }
    
    func testInsertAtEnd() {
        var set: OrderedSet<String> = ["one", "two"]
        XCTAssertTrue(set.insert("three", at: 2))
        XCTAssertEqual(set.count, 3)
        XCTAssertEqual(set[2], "three")
    }
    
    func testInsertMultiple() {
        var set: OrderedSet<String> = ["one", "four"]
        _ = set.insert(contentsOf: ["two", "three"], at: 1)
        XCTAssertEqual(set.count, 4)
        XCTAssertEqual(set[1], "two")
        XCTAssertEqual(set[2], "three")
        XCTAssertEqual(set[3], "four")
    }
    
    // MARK: - Performance
    /*-------------------------------------------------------------------------------*/
    
    func testInitializationPerformance() {
        // This is an example of a performance test case.
        var list = [String]()
        for n in 0..<10000 {
            list.append("Object_\(n)")
        }
        self.measure {
            _ = OrderedSet<String>(elements: list)
        }
    }

    func testAddPerformance() {
        // This is an example of a performance test case.
        self.measure {
            var set: OrderedSet<String> = ["one", "four"]
            for n in 0..<10000 {
                set.append("Object_\(n)")
            }
        }
    }
    
    func testInsertPerformance() {
        // This is an example of a performance test case.
        self.measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            let source = (0..<5000).map { return "Object \($0)" }
            let new = (2000..<2500).map { return "Object \($0)" }
            var set = OrderedSet<String>(unsafe: source)
            let sorts = [SortDescriptor(\String.displayDescription)]
            self.startMeasuring()
            
//            for str in new {
//                set.insert(str, using: sorts)
//            }
            set.insert(contentsOf: new, using: sorts)
        }
    }
    
    func testUnionPerformance() {
        // This is an example of a performance test case.
        var list = [String]()
        for n in 0..<10000 {
            list.append("Object_\(n)")
        }
        self.measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            var set = OrderedSet<String>()
            self.startMeasuring()
            set.append(contentsOf: list)
        }
    }
    
    func setWithObjects(_ n: Int) -> OrderedSet<String> {
        var set = OrderedSet<String>()
        for n in 0..<10000 {
            set.append("Object_\(n)")
        }
        return set
    }
    
    func testRemoveFromMiddlePerformance() {
        // This is an example of a performance test case.
        self.measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            var set = self.setWithObjects(10000)
            self.startMeasuring()
            set.remove(at: 5000)
        }
    }
    func testRemoveFromEndPerformance() {
        // This is an example of a performance test case.
        
        self.measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            var set = self.setWithObjects(10000)
            self.startMeasuring()
            set.remove(at: set.count - 1)
        }
    }
    
    // MARK: - Iteration Performance
    /*-------------------------------------------------------------------------------*/

    func testIterate() {
        let set = Person.set()
        self.measure {
            for e in set {
                _ = e[keyPath: \Person.name]
            }
        }
    }
    
    let performanceInsertCount = 100_000
    
    func testAppendPerformance_arrayControl() {
        self.measure {
            var arr = [Int]()
            for n in 0..<performanceInsertCount {
                arr.append(n)
            }
        }
    }
    
    func testAppendPerformance_basic() {
        self.measure {
            var set = OrderedSet<Int>()
            for n in 0..<performanceInsertCount {
                set.append(n)
            }
        }
    }
    func testAppendPerformance_unsafeBasic() {
        self.measure {
            var set = OrderedSet<Int>()
            for n in 0..<performanceInsertCount {
                set.unsafeAppend(n)
            }
        }
    }
    func testAppendPerformance_provider() {
        self.measure {
            var set = OrderedSet<Int>()
            set.append(performanceInsertCount, provider: {
                return $0
            })
        }
    }
    func testAppendPerformance_unsafeProvider() {
        self.measure {
            var set = OrderedSet<Int>()
            set.unsafeAppend(performanceInsertCount, provider: {
                return $0
            })
        }
    }
    
    func testInitPerformance_unsafeArray() {
        let source = Array(0..<performanceInsertCount)
        self.measure {
            _ = OrderedSet<Int>(unsafe: source)
        }
    }
    
    func testInitPerformance_provider() {
        self.measure {
            _ = OrderedSet<Int>(count: performanceInsertCount, provider: {
                return $0
            })
        }
    }
    
    // MARK: - Sorting
    /*-------------------------------------------------------------------------------*/
    
    func testSort() {
        var set = Person.set(with: 10)
        let ages = set.map { return $0.age }.sorted()
        
        let sort = SortDescriptor(\Person.age)
        set.sort(using: [sort])
        
        for (idx, person) in set.enumerated() {
            XCTAssertEqual(person.age, ages[idx])
        }
    }

    func testArraySort() {
        let sort = SortDescriptor(\Person.age)
        self.measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            var arr = Person.set().objects
            self.startMeasuring()
            arr.sort(using: sort)
        }
    }
    
    // NSSortDescriptor
    func testSortPerformance_withNSSortDescriptors() {
        let sort = NSSortDescriptor(key: "age", ascending: true)
        
        self.measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            let arr = NSMutableArray(array: NSPerson.array())
            self.startMeasuring()
            arr.sort(using: [sort])
        }
    }
    // Direct
    func testSortPerformance_withComparator() {
        
        self.measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            var set = Person.set()
            self.startMeasuring()
            set.sort(by: { (a, b) -> Bool in
                return a.age < b.age
            })
        }
    }
    // Key Paths
    func testSortPerformance_withKeyPaths() {
        
        self.measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            var set = Person.set()
            self.startMeasuring()
            set.sort(by: { (a, b) -> Bool in
                return a[keyPath: \Person.age] < b[keyPath: \Person.age]
            })
        }
    }
    func testSortPerformance_sortDescriptors_uniquePreordered() {
        let sort = SortDescriptor(\Person.age)
        self.measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            var set = Person.set(randomAge: false)
            self.startMeasuring()
            set.sort(using: sort)
        }
    }
    func testSortPerformance_sortDescriptors() {
        let sort = SortDescriptor(\Person.age)
        self.measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            var set = Person.set()
            self.startMeasuring()
            set.sort(using: sort)
        }
    }
    func testSortedPerformance_sortDescriptors() {
        let sort = SortDescriptor(\Person.age)
        self.measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            let set = Person.set()
            self.startMeasuring()
            _ = set.sorted(using: sort)
        }
    }
    func testSortedPerformance_multipleSortDescriptors() {
        
        let sort = [SortDescriptor(\Person.age), SortDescriptor(\Person.name)]
        self.measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            let set = Person.set()
            self.startMeasuring()
            _ = set.sorted(using: sort)
        }
    }

}
