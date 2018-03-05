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
        
        let parents = [
            "AJfZltmZml" : Parent(rank: 0, name: "AJfZltmZml"),
            "rseRiOCBuq" : Parent(rank: 1, name: "rseRiOCBuq"),
            "powslfCxjt" : Parent(rank: 2, name: "powslfCxjt")
        ]
        
        
        let children = [
            // AJfZltmZml
            "CrukASfzSp" : Child(rank: 0, name: "CrukASfzSp", parent: parents["AJfZltmZml"]!),
            "etbJeVVRcR" : Child(rank: 1, name: "etbJeVVRcR", parent: parents["AJfZltmZml"]!),
            "XowOgYrcee" : Child(rank: 2, name: "XowOgYrcee", parent: parents["AJfZltmZml"]!),
            // rseRiOCBuq
            "pajgRSevdB" : Child(rank: 0, name: "pajgRSevdB", parent: parents["rseRiOCBuq"]!),
            "ZEfIuIDkBm" : Child(rank: 1, name: "ZEfIuIDkBm", parent: parents["rseRiOCBuq"]!),
            "EQyMBBwakO" : Child(rank: 2, name: "EQyMBBwakO", parent: parents["rseRiOCBuq"]!),
            "nomOPsCLae" : Child(rank: 3, name: "nomOPsCLae", parent: parents["rseRiOCBuq"]!),
            "zvBozntvAe" : Child(rank: 4, name: "zvBozntvAe", parent: parents["rseRiOCBuq"]!),
            // powslfCxjt
            "JFcjwqDOIt" : Child(rank: 0, name: "JFcjwqDOIt", parent: parents["powslfCxjt"]!),
            "pRllJqXDvU" : Child(rank: 1, name: "pRllJqXDvU", parent: parents["powslfCxjt"]!),
            "pPtbKKZdEp" : Child(rank: 2, name: "pPtbKKZdEp", parent: parents["powslfCxjt"]!),
            "IScGOquZMC" : Child(rank: 3, name: "IScGOquZMC", parent: parents["powslfCxjt"]!),
            "OGlwqtXHeE" : Child(rank: 4, name: "OGlwqtXHeE", parent: parents["powslfCxjt"]!),
            ]
        
        let changes = [
        ("OGlwqtXHeE", "AJfZltmZml", 0),
        ("pajgRSevdB", "AJfZltmZml", 1),
        ("etbJeVVRcR", "AJfZltmZml", 2),
        ("nomOPsCLae", "AJfZltmZml", 3),
        ("XowOgYrcee", "AJfZltmZml", 4),
        ("IScGOquZMC", "rseRiOCBuq", 1),
        ("pPtbKKZdEp", "rseRiOCBuq", 2),
        ("zvBozntvAe", "rseRiOCBuq", 3),
        ("ZEfIuIDkBm", "rseRiOCBuq", 4),
        ("JFcjwqDOIt", "powslfCxjt", 0),
        
        ("EQyMBBwakO", "powslfCxjt", 1),
        ("CrukASfzSp", "powslfCxjt", 2)
        ]
        
        resultsController.setContent(objects: Array(children.values))
        collectionView.reloadData()
        
        resultsController.beginEditing()
        
        for s in parents.values {
            resultsController.didUpdate(section: s)
        }
        
        resultsController.delete(object: children["pRllJqXDvU"]!)
        resultsController.insert(object: Child(rank: 0, name: "TGKRgzkojw", parent: parents["rseRiOCBuq"]!))
        
        for change in changes {
            children[change.0]?.parent = parents[change.1]
            children[change.0]?.rank = change.2
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
        return lhs.id == rhs.id
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
