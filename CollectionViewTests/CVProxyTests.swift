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


    
    lazy var collectionView : CollectionView = {
        let cv = CollectionView(frame: NSRect(x: 0, y: 0, width: 600, height: 600))
        cv.collectionViewLayout = CollectionViewListLayout()
        cv.dataSource = self
        CollectionViewCell.register(in: cv)
        return cv
    }()
    private lazy var resultsController : MutableResultsController<Parent, Child> = {
        let rc = MutableResultsController<Parent, Child>(sectionKeyPath: nil, sortDescriptors: [SortDescriptor(\Child.rank)], sectionSortDescriptors: [SortDescriptor(\Parent.rank)])
        rc.setSectionKeyPath(\Child.parent)
        return rc
    }()
    private lazy var provider : CollectionViewProvider = {
        return CollectionViewProvider(self.collectionView, resultsController: self.resultsController)
    }()
    
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
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

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let _data : [(String,[String])] = [
            ("ZSnKWisBqE", ["ueHNbNmzJE","BLDDODjZeP","eObJUPufpv","dOwXZZpyif","RIZOqeMoWM","hGLYuDzKQi","ZOAwicSMDE"]),
            ("WqoQBTNEaY", ["rsubjBxbVb","zgxqrwEMEP","RFMVhYUOBt","TPtWHpAfhO","vGNjxxuxds","EEQzPOqFLm","WqWAgYBpdk"]),
            ("KjqnrhLzeE", ["jmKARnCZQJ","GkVzEtvFEp","VWbpXXYeZH","iiRlRTkGKi","UOGPKdyFLd","hRPjsirdxZ"])
        ]
        
        let parentOrder = ["KjqnrhLzeE", "ZSnKWisBqE", "WqoQBTNEaY"]
        
        let deleted = ["zgxqrwEMEP"]
        let inserted = [("nCcfswhOXr", "KjqnrhLzeE", 0)]
        
        var children = [String:Child]()
        var parents = [String:Parent]()
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
            ("vGNjxxuxds", "KjqnrhLzeE", 2),
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

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}



fileprivate class Child : ResultType, CustomStringConvertible {
    let id = UUID()
    var rank : Int
    var name : String
    var parent : Parent?
    
    init(rank: Int, name: String? = nil, parent: Parent) {
        self.rank = rank
        self.name = name ?? "Child \(rank)"
        self.parent = parent
    }
    
    var hashValue: Int {
        return id.hashValue
    }
    static func ==(lhs: Child, rhs: Child) -> Bool {
        return lhs === rhs
    }
    var description: String {
        return "Child \(self.name) - [\(self.parent?.rank), \(self.rank)]"
    }
}
fileprivate class Parent : SectionType, CustomStringConvertible {
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
