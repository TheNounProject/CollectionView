//
//  RelationalRCTests.swift
//  CollectionViewTests
//
//  Created by Wesley Byrne on 2/14/18.
//  Copyright © 2018 Noun Project. All rights reserved.
//

import XCTest
@testable import CollectionView



class RelationalRCTests: XCTestCase, ResultsControllerDelegate {
    
    fileprivate lazy var context : NSManagedObjectContext = {
        let model = TestModel()
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        try! coordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        let ctx = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        ctx.persistentStoreCoordinator = coordinator
        return ctx
    }()
    
    fileprivate func createItemsBySection(_ count: Int, items perSection: Int) -> [[Child]] {
        var res = [[Child]]()
        for s in 0..<count {
            var children = [Child]()
            for _ in 0..<perSection {
                let child = Child.createOrphan(in: self.context)
                child.second = NSNumber(value: s)
                child.displayOrder = NSNumber(value: children.count)
                children.append(child)
            }
            res.append(children)
        }
        try! self.context.save()
        return res
    }
    
    override func tearDown() {
        self.context.reset()
        self._expectation = nil
        self.changeSet.prepareForUpdates()
        super.tearDown()
    }
    
    private func createController(fetchSections: Bool = false) -> RelationalResultsController<Parent, Child> {
        let rc = RelationalResultsController<Parent, Child>(context: self.context,
                                                                 request: NSFetchRequest<Child>(entityName: "Child"),
                                                                 sectionRequest: NSFetchRequest<Parent>(entityName: "Parent"),
                                                                 sectionKeyPath: \Child.parent)
        rc.delegate = self
        rc.fetchSections = fetchSections
        return rc
    }

    func test_performFetch_empty() {
        let content = createController()
        XCTAssertNoThrow(try content.performFetch())
        XCTAssertEqual(content.numberOfSections, 0)
    }
    
    func test_performFetch_fetchSectionsFalse() {
        let content = createController()
        _ = Parent.create(in: self.context, children: 0)
        XCTAssertNoThrow(try content.performFetch())
        XCTAssertEqual(content.numberOfSections, 0)
    }
    func test_performFetch_emptySection_fetchSections() {
        let content = createController(fetchSections: true)
        _ = Parent.create(in: self.context, children: 0)
        XCTAssertNoThrow(try content.performFetch())
        XCTAssertEqual(content.numberOfSections, 1)
        XCTAssertEqual(content.numberOfObjects(in: 0), 0)
    }
    
    
    func test_sectionName_dispayConvertible() {
        let content = createController(fetchSections: true)
        let p = Parent.create(in: self.context, children: 0)
        XCTAssertNoThrow(try content.performFetch())
        XCTAssertEqual(content.sectionName(forSectionAt: IndexPath.zero), p.displayDescription)
    }
    
    func test_sectionName_sectionNameKeyPath() {
        let content = createController(fetchSections: true)
        content.sectionNameKeyPath = \Parent.name
        let p = Parent.create(in: self.context, children: 0)
        XCTAssertNoThrow(try content.performFetch())
        XCTAssertEqual(content.sectionName(forSectionAt: IndexPath.zero), p.name)
    }
    
    
    
    func testSectionSortDescriptors() {
        let content = createController(fetchSections: true)
        for idx in 0..<10 {
            let p = Parent.create(in: self.context)
            p.displayOrder = NSNumber(value: idx)
        }
        
        content.sectionSortDescriptors = [SortDescriptor(\Parent.displayOrder, ascending: true)]
        XCTAssertNoThrow(try content.performFetch())
        for n in 0..<10 {
            let ip = IndexPath.for(item: 0, section: n)
            let object = content.object(forSectionAt: ip)
            XCTAssertEqual(object?.displayOrder.intValue, n)
        }
        
        // Check ascending FALSE
        content.sectionSortDescriptors = [SortDescriptor(\Parent.displayOrder, ascending: false)]
        XCTAssertNoThrow(try content.performFetch())
        for n in 0..<10 {
            let ip = IndexPath.for(item: 0, section: n)
            let object = content.object(forSectionAt: ip)
            XCTAssertEqual(object?.displayOrder.intValue, 9 - n)
        }
    }
    
    
    
    // MARK: - Inserting
    /*-------------------------------------------------------------------------------*/
    
    func test_insertFirstItem_noFetchSections() {
        let content = createController(fetchSections: false)
        try! content.performFetch()
        self._expectation = expectation(description: "Delegate")
        
        _ = Parent.create(in: self.context, children: 1)
        waitForExpectations(timeout: 0.1) { (err) in
            XCTAssertEqual(content.numberOfSections, 1)
            XCTAssertEqual(content.numberOfObjects(in: 0), 1)
        }
    }
    
    func test_insertFirstSection_noFetchSections() {
        let content = createController(fetchSections: false)
        try! content.performFetch()
        self._expectation = expectation(description: "Delegate")
        
        _ = Parent.create(in: self.context, children: 0)
        waitForExpectations(timeout: 0.1) { (err) in
            XCTAssertEqual(content.numberOfSections, 0)
        }
    }
    
    func test_insertFirstSection_fetchSections() {
        let content = createController(fetchSections: true)
        try! content.performFetch()
        self._expectation = expectation(description: "Delegate")
        
        _ = Parent.create(in: self.context, children: 1)
        waitForExpectations(timeout: 0.1) { (err) in
            XCTAssertEqual(content.numberOfSections, 1)
            XCTAssertEqual(content.numberOfObjects(in: 0), 1)
        }
    }
    
    func test_delegate_insertMultipleSections_noFetchSections() {
        let content = createController(fetchSections: false)
        try! content.performFetch()
        self._expectation = expectation(description: "Delegate")
        
        _ = Parent.create(in: self.context, children: 1)
        _ = Parent.create(in: self.context, children: 1)
        _ = Parent.create(in: self.context, children: 1)
        waitForExpectations(timeout: 0.1) { (err) in
            XCTAssertEqual(content.numberOfSections, 3)
        }
    }
    
    func test_delegate_insertMultipleEmptySections_fetchSections() {
        let content = createController(fetchSections: true)
        try! content.performFetch()
        self._expectation = expectation(description: "Delegate")
        
        _ = Parent.create(in: self.context, children: 0)
        _ = Parent.create(in: self.context, children: 0)
        _ = Parent.create(in: self.context, children: 0)
        waitForExpectations(timeout: 0.1) { (err) in
            XCTAssertEqual(content.numberOfSections, 3)
        }
    }
    
    
    // MARK: - Removing Items
    /*-------------------------------------------------------------------------------*/
    
    func test_delegate_removingItemsRemovesSections() {
        // Fetch sections == true
        let content = createController(fetchSections: false)
        let parents = (0..<3).map { _ in
            Parent.create(in: self.context, children: 1)
        }
        try! context.save()
        try! content.performFetch()
        XCTAssertEqual(content.numberOfSections, 3)
        self._expectation = expectation(description: "Delegate")
        for p in parents {
            for c in p.children {
                self.context.delete(c)
            }
        }
        waitForExpectations(timeout: 0.1) { (err) in
            XCTAssertEqual(content.numberOfSections, 0)
        }
    }
    
    func test_delegate_removingItemsLeavesSections() {
        // Fetch sections == true
        let content = createController(fetchSections: true)
        let parents = (0..<3).map { _ in
            Parent.create(in: self.context, children: 1)
        }
        try! context.save()
        try! content.performFetch()
        XCTAssertEqual(content.numberOfSections, 3)
        
        self._expectation = expectation(description: "Delegate")
        
        for p in parents {
            for c in p.children {
                self.context.delete(c)
            }
        }
        waitForExpectations(timeout: 0.1) { (err) in
            XCTAssertEqual(content.numberOfSections, 3)
            for idx in 0..<3 {
                XCTAssertEqual(content.numberOfObjects(in: idx), 0)
            }
        }
    }
    
    
    // MARK: - Moving
    /*-------------------------------------------------------------------------------*/
    
    func test_delegate_movingSections() {
        let content = createController(fetchSections: false)
        content.sectionSortDescriptors = [SortDescriptor(\Parent.displayOrder)]
        
        let parents : [Parent] = (0..<3).map {
            let p = Parent.create(in: self.context, children: 1)
            p.displayOrder = NSNumber(value: $0)
            return p
        }
        try! context.save()
        try! content.performFetch()
        XCTAssertEqual(content.numberOfSections, 3)
        self._expectation = expectation(description: "Delegate")
        
        // Reverse the display orders
        for idx in 0..<3 {
            parents[idx].displayOrder = NSNumber(value: 2 - idx)
        }
        waitForExpectations(timeout: 0.1) { (err) in
            for idx in 0..<3 {
                let ip = IndexPath.for(section: idx)
                XCTAssertEqual(content.object(forSectionAt: ip), parents[2 - idx])
            }
        }
    }
    
    var changeSet = CollectionViewResultsProxy()
    var _expectation : XCTestExpectation?
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

}


// MARK: - Helpers
/*-------------------------------------------------------------------------------*/


fileprivate extension NSAttributeDescription {
    convenience init(name: String, type: NSAttributeType) {
        self.init()
        self.name = name
        self.attributeType = type
    }
}

extension String {
    static func random(_ length: Int) -> String {
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let len = UInt32(letters.length)
        
        var randomString = ""
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        return randomString
    }
}

fileprivate class Parent : NSManagedObject, CustomDisplayStringConvertible {
    @NSManaged var displayOrder : NSNumber
    @NSManaged var name : String
    @NSManaged var createdAt: Date
    @NSManaged var children : Set<Child>
    
    static func create(in moc : NSManagedObjectContext, children: Int = 1) -> Parent {
        let req = NSFetchRequest<Parent>(entityName: "Parent")
        req.sortDescriptors = [NSSortDescriptor(key: "displayOrder", ascending: false)]
        req.fetchLimit = 1
        let _order = try! moc.fetch(req).first?.displayOrder.intValue ?? 0
        let new = NSEntityDescription.insertNewObject(forEntityName: "Parent", into: moc) as! Parent
        new.name = "Parent \(String.random(5))"
        new.displayOrder = NSNumber(value: _order + 1)
        new.createdAt = Date()
        for _ in 0..<children {
            _ = new.createChild()
        }
        return new
    }
    func createChild() -> Child {
        let child = Child.createOrphan(in: self.managedObjectContext!)
        let order = self.children.sorted(using: SortDescriptor(\Child.displayOrder)).last?.displayOrder.intValue ?? -1
        child.displayOrder = NSNumber(value: order + 1)
        child.parent = self
        return child
    }
    var displayDescription: String {
        return "Parent \(self.displayOrder)"
    }
}

fileprivate class Child : NSManagedObject {
    @NSManaged var second: NSNumber
    @NSManaged var minute: NSNumber
    @NSManaged var displayOrder : NSNumber
    @NSManaged var createdAt: Date
    @NSManaged var parent: Parent?
    
    static func createOrphan(in moc : NSManagedObjectContext) -> Child {
        let child = NSEntityDescription.insertNewObject(forEntityName: "Child", into: moc) as! Child
        child.displayOrder = NSNumber(value: 0)
        let d = Date()
        let s = Calendar.current.component(.second, from: d)
        let m = Calendar.current.component(.minute, from: d)
        child.createdAt = d
        child.second = NSNumber(value: Int(s/6))
        child.minute = NSNumber(value: Int(m/6))
        return child
    }
}

fileprivate class TestModel : NSManagedObjectModel {
    override init() {
        super.init()
        
        let parent = NSEntityDescription()
        let child = NSEntityDescription()
        
        parent.name = "Parent"
        parent.managedObjectClassName = Parent.className()
        child.name = "Child"
        child.managedObjectClassName = Child.className()
        
        let childrenRelationship = NSRelationshipDescription()
        let parentRelationship = NSRelationshipDescription()
        
        childrenRelationship.name = "children"
        childrenRelationship.destinationEntity = child
        childrenRelationship.inverseRelationship = parentRelationship
        childrenRelationship.maxCount = 0
        childrenRelationship.minCount = 0
        childrenRelationship.deleteRule = .cascadeDeleteRule
        
        parentRelationship.name = "parent"
        parentRelationship.destinationEntity = parent
        parentRelationship.inverseRelationship = childrenRelationship
        parentRelationship.minCount = 0
        parentRelationship.maxCount = 1
        parentRelationship.isOptional = true
        
        parent.properties = [NSAttributeDescription(name: "displayOrder", type: .integer16AttributeType),
                             NSAttributeDescription(name: "createdAt", type: .dateAttributeType),
                             NSAttributeDescription(name: "name", type: .stringAttributeType),
                             childrenRelationship]
        child.properties = [NSAttributeDescription(name: "displayOrder", type: .integer16AttributeType),
                            NSAttributeDescription(name: "createdAt", type: .dateAttributeType),
                            NSAttributeDescription(name: "minute", type: .integer16AttributeType),
                            NSAttributeDescription(name: "second", type: .integer16AttributeType),
                            parentRelationship]
        
        self.entities = [parent, child]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}




