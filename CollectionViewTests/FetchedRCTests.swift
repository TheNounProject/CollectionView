//
//  FetchedRCTests.swift
//  CollectionViewTests
//
//  Created by Wesley Byrne on 2/14/18.
//  Copyright © 2018 Noun Project. All rights reserved.
//

import XCTest
@testable import CollectionView

class FetchedRCTests: XCTestCase, ResultsControllerDelegate {
    
    fileprivate lazy var context: NSManagedObjectContext = {
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

    func test_performFetch_empty() {
        let frc = FetchedResultsController<String, Child>(context: self.context, request: NSFetchRequest<Child>(entityName: "Child"))
        XCTAssertNoThrow(try frc.performFetch())
        XCTAssertEqual(frc.numberOfSections, 0)
    }
    
    func test_noSectionKeyPaths() {
        _ = Parent.create(in: self.context, children: 5)
        let frc = FetchedResultsController<String, Child>(context: self.context, request: NSFetchRequest<Child>(entityName: "Child"))
        XCTAssertNoThrow(try frc.performFetch())
        XCTAssertEqual(frc.numberOfSections, 1)
        XCTAssertEqual(frc.numberOfObjects(in: 0), 5)
    }
    
    func test_sectionKeyPath() {
        _ = self.createItemsBySection(5, items: 1)
        let frc = FetchedResultsController<NSNumber, Child>(context: self.context,
                                                            request: NSFetchRequest<Child>(entityName: "Child"),
                                                            sectionKeyPath: \Child.second)
        XCTAssertNoThrow(try frc.performFetch())
        XCTAssertEqual(frc.numberOfSections, 5)
        for n in 0..<5 {
            XCTAssertEqual(frc.numberOfObjects(in: n), 1)
        }
    }
    
    func testSortDescriptors() {
        _ = self.createItemsBySection(1, items: 10)
        let frc = FetchedResultsController<NSNumber, Child>(context: self.context, request: NSFetchRequest<Child>(entityName: "Child"))
        // Check ascending TRUE
        frc.sortDescriptors = [SortDescriptor(\Child.displayOrder, ascending: true)]
        XCTAssertNoThrow(try frc.performFetch())
        for n in 0..<10 {
            XCTAssertEqual(frc.object(at: IndexPath.for(item: n, section: 0))!.displayOrder.intValue, n)
        }
        
        // Check ascending FALSE
        frc.sortDescriptors = [SortDescriptor(\Child.displayOrder, ascending: false)]
        XCTAssertNoThrow(try frc.performFetch())
        for n in 0..<10 {
            XCTAssertEqual(frc.object(at: IndexPath.for(item: n, section: 0))!.displayOrder.intValue, 9 - n)
        }
    }
    
    // MARK: - Inserting
    /*-------------------------------------------------------------------------------*/
    
    func test_delegate_insertItem() {
        let frc = FetchedResultsController<NSNumber, Child>(context: self.context, request: NSFetchRequest<Child>(entityName: "Child"))
        frc.delegate = self
        XCTAssertNoThrow(try frc.performFetch())
        self._expectation = expectation(description: "Delegate")
        _ = Child.createOrphan(in: context)
        waitForExpectations(timeout: 0.1) { (_) in
            XCTAssertEqual(self.changeSet.itemUpdates.inserted.count, 0)
            XCTAssertEqual(self.changeSet.sectionUpdates.inserted.count, 1)
            XCTAssertEqual(frc.numberOfSections, 1)
            XCTAssertEqual(frc.numberOfObjects(in: 0), 1)
        }
    }
    
    func test_delegate_insertMultipleItems() {
        let frc = FetchedResultsController<NSNumber, Child>(context: self.context, request: NSFetchRequest<Child>(entityName: "Child"))
        frc.delegate = self
        XCTAssertNoThrow(try frc.performFetch())
        XCTAssertEqual(frc.numberOfSections, 0)
        
        self._expectation = expectation(description: "Delegate")
        _ = self.createItemsBySection(1, items: 5)
        
        waitForExpectations(timeout: 0.1) { (_) in
            XCTAssertEqual(self.changeSet.itemUpdates.inserted.count, 0)
            XCTAssertEqual(self.changeSet.sectionUpdates.inserted.count, 1)
            XCTAssertEqual(frc.numberOfSections, 1)
            XCTAssertEqual(frc.numberOfObjects(in: 0), 5)
        }
    }
    
    func test_delegate_insertMultipleSections() {
        let frc = FetchedResultsController<NSNumber, Child>(context: self.context, request: NSFetchRequest<Child>(entityName: "Child"))
        frc.setSectionKeyPath(\Child.second)
        frc.delegate = self
        XCTAssertNoThrow(try frc.performFetch())
        XCTAssertEqual(frc.numberOfSections, 0)
        
        self._expectation = expectation(description: "Delegate")
        _ = self.createItemsBySection(5, items: 5)
        waitForExpectations(timeout: 0.1) { (_) in
            XCTAssertEqual(self.changeSet.itemUpdates.inserted.count, 0)
            XCTAssertEqual(self.changeSet.sectionUpdates.inserted.count, 5)
            XCTAssertEqual(frc.numberOfSections, 5)
            for s in 0..<frc.numberOfSections {
                XCTAssertEqual(frc.numberOfObjects(in: s), 5)
            }
        }
    }
    
    // MARK: - Removing Items
    /*-------------------------------------------------------------------------------*/
    
    fileprivate func _testRemoveItems(sections: Int, items: Int, indexPaths: [IndexPath], handler: @escaping ((FetchedResultsController<NSNumber, Child>) -> Void)) {
        let frc = FetchedResultsController<NSNumber, Child>(context: self.context, request: NSFetchRequest<Child>(entityName: "Child"))
        frc.delegate = self
        if sections > 1 {
            frc.setSectionKeyPath(\Child.second)
        }
        frc.fetchRequest.sortDescriptors = [NSSortDescriptor(key: "displayOrder", ascending: true)]
        frc.sortDescriptors = [SortDescriptor<Child>(\Child.displayOrder)]
        frc.sectionSortDescriptors = [SortDescriptor<NSNumber>.ascending]
        let children = self.createItemsBySection(sections, items: items)
        try! frc.performFetch()
        
        self._expectation = expectation(description: "Delegate")
        for ip in indexPaths {
            self.context.delete(children[ip._section][ip._item])
        }
        self.waitForExpectations(timeout: 0.1) { (_) in
            handler(frc)
        }
    }
    
    func test_delegate_removeItem_first() {
        _testRemoveItems(sections: 1, items: 10, indexPaths: [IndexPath.for(item: 0, section: 0)]) { (frc) in
            XCTAssertEqual(self.changeSet.itemUpdates.deleted.count, 1)
            XCTAssertEqual(self.changeSet.itemUpdates.deleted.first, IndexPath.for(item: 0, section: 0))
            XCTAssertEqual(frc.numberOfObjects(in: 0), 9)
        }
    }
    func test_delegate_removeItem_middle() {
        _testRemoveItems(sections: 1, items: 10, indexPaths: [IndexPath.for(item: 5, section: 0)]) { (frc) in
            XCTAssertEqual(self.changeSet.itemUpdates.deleted.count, 1)
            XCTAssertEqual(self.changeSet.itemUpdates.deleted.first, IndexPath.for(item: 5, section: 0))
            XCTAssertEqual(frc.numberOfObjects(in: 0), 9)
        }
    }
    
    func test_delegate_removeItem_last() {
        _testRemoveItems(sections: 1, items: 10, indexPaths: [IndexPath.for(item: 9, section: 0)]) { (frc) in
            XCTAssertEqual(self.changeSet.itemUpdates.deleted.count, 1)
            XCTAssertEqual(self.changeSet.itemUpdates.deleted.first, IndexPath.for(item: 9, section: 0))
            XCTAssertEqual(frc.numberOfObjects(in: 0), 9)
        }
    }
    
    func test_delegate_removeItems_fromMultipleSections() {
        let ips = [
            IndexPath.for(item: 0, section: 0),
            IndexPath.for(item: 0, section: 1),
            IndexPath.for(item: 0, section: 2)
        ]
        
        _testRemoveItems(sections: 4, items: 10, indexPaths: ips) { (frc) in
            XCTAssertEqual(self.changeSet.itemUpdates.deleted.count, 3)
            for ip in ips {
                XCTAssertTrue(self.changeSet.itemUpdates.deleted.contains(ip))
            }
            XCTAssertEqual(frc.numberOfObjects(in: 0), 9)
            XCTAssertEqual(frc.numberOfObjects(in: 1), 9)
            XCTAssertEqual(frc.numberOfObjects(in: 2), 9)
            XCTAssertEqual(frc.numberOfObjects(in: 3), 10)
        }
    }
    
    func test_delegate_removeAllItemsfromSection() {
        let ips = IndexPath.inRange(0..<5, section: 0)
        _testRemoveItems(sections: 4, items: 5, indexPaths: ips) { (frc) in
            XCTAssertEqual(self.changeSet.itemUpdates.deleted.count, 0)
            XCTAssertEqual(self.changeSet.sectionUpdates.deleted.count, 1)
            XCTAssertTrue(self.changeSet.sectionUpdates.deleted.contains(0))
            XCTAssertEqual(frc.numberOfSections, 3)
            XCTAssertEqual(frc.numberOfObjects(in: 0), 5)
            XCTAssertEqual(frc.numberOfObjects(in: 1), 5)
            XCTAssertEqual(frc.numberOfObjects(in: 2), 5)
        }
    }
    
    func test_delegate_removeAllItemsfromLastSection() {
        let ips = IndexPath.inRange(0..<5, section: 3)
        _testRemoveItems(sections: 4, items: 5, indexPaths: ips) { (frc) in
            XCTAssertEqual(self.changeSet.itemUpdates.deleted.count, 0)
            XCTAssertEqual(self.changeSet.sectionUpdates.deleted.count, 1)
            XCTAssertTrue(self.changeSet.sectionUpdates.deleted.contains(3))
            XCTAssertEqual(frc.numberOfSections, 3)
            XCTAssertEqual(frc.numberOfObjects(in: 0), 5)
            XCTAssertEqual(frc.numberOfObjects(in: 1), 5)
            XCTAssertEqual(frc.numberOfObjects(in: 2), 5)
        }
    }
    func test_delegate_removeAllItems() {
        var ips = IndexPath.inRange(0..<5, section: 0)
        ips.append(contentsOf: IndexPath.inRange(0..<5, section: 1))
        ips.append(contentsOf: IndexPath.inRange(0..<5, section: 2))
        ips.append(contentsOf: IndexPath.inRange(0..<5, section: 3))
        
        _testRemoveItems(sections: 4, items: 5, indexPaths: ips) { (frc) in
            XCTAssertEqual(self.changeSet.itemUpdates.deleted.count, 0)
            XCTAssertEqual(self.changeSet.sectionUpdates.deleted.count, 4)
            XCTAssertTrue(self.changeSet.sectionUpdates.deleted.contains(0))
            XCTAssertTrue(self.changeSet.sectionUpdates.deleted.contains(1))
            XCTAssertTrue(self.changeSet.sectionUpdates.deleted.contains(2))
            XCTAssertTrue(self.changeSet.sectionUpdates.deleted.contains(3))
            XCTAssertEqual(frc.numberOfSections, 0)
        }
    }
    
    func test_delegate_moveItemToFront() {
        print("MOVE ITEM TO FRONT")
        let frc = FetchedResultsController<NSNumber, Child>(context: self.context,
                                                            request: NSFetchRequest<Child>(entityName: "Child"),
                                                            sectionKeyPath: \Child.second)
        frc.delegate = self
        frc.sectionSortDescriptors = [SortDescriptor<NSNumber>.ascending]
        frc.sortDescriptors = [SortDescriptor<Child>(\Child.displayOrder)]
        frc.fetchRequest.sortDescriptors = [NSSortDescriptor(key: "displayOrder", ascending: true)]
        let children = self.createItemsBySection(5, items: 5)
        try! frc.performFetch()
        self._expectation = expectation(description: "Delegate")
        
        let moved = children[0][2]
        moved.displayOrder = -1
        for c in children[0] {
            c.minute = NSNumber(value: c.minute.intValue + 1)
        }
        
        self.waitForExpectations(timeout: 0.5) { (_) in
            // There should really only be one move
            XCTAssertEqual(self.changeSet.itemUpdates.count, 3)
            XCTAssertEqual(self.changeSet.itemUpdates.moved.count, 3)
            print(self.changeSet)
            XCTAssertEqual(frc.object(at: IndexPath.zero), moved)
            for move in self.changeSet.itemUpdates.moved {
                XCTAssertEqual(children[move.source._section][move.source._item], frc.object(at: move.destination))
            }
        }
    }
    
    func test_moveItemsCrossSection() {
        
        let frc = FetchedResultsController<NSNumber, Child>(context: self.context,
                                                            request: NSFetchRequest<Child>(entityName: "Child"),
                                                            sectionKeyPath: \Child.second)
        frc.delegate = self
        frc.sectionSortDescriptors = [SortDescriptor<NSNumber>.ascending]
        frc.sortDescriptors = [SortDescriptor<Child>(\Child.displayOrder)]
        
        let children = self.createItemsBySection(5, items: 5)
        try! frc.performFetch()
        self._expectation = expectation(description: "Delegate")
        
        let m1 = children[2][2]
        m1.displayOrder = 5
        m1.second = NSNumber(value: 1)
        
        let m2 = children[2][3]
        m2.displayOrder = 6
        m2.second = NSNumber(value: 1)
        
        self.waitForExpectations(timeout: 0.5) { (_) in
            // There should really only be one move
            XCTAssertEqual(self.changeSet.itemUpdates.count, 2)
            XCTAssertEqual(self.changeSet.itemUpdates.moved.count, 2)
            print(self.changeSet)
            XCTAssertEqual(frc.numberOfObjects(in: 1), 7)
            XCTAssertEqual(frc.numberOfObjects(in: 2), 3)
            XCTAssertEqual(frc.object(at: IndexPath.for(item: 5, section: 1)), m1)
            XCTAssertEqual(frc.object(at: IndexPath.for(item: 6, section: 1)), m2)
        }   
    }
    
    var changeSet = CollectionViewResultsProxy()
    var _expectation: XCTestExpectation?
    func controllerWillChangeContent(controller: ResultsController) {
        print("CONTROLLER WILL CHANGE")
        changeSet.prepareForUpdates()
    }
    func controller(_ controller: ResultsController, didChangeObject object: Any, at indexPath: IndexPath?, for changeType: ResultsControllerChangeType) {
        print("DID CHANGE OBJECT: ip: \(indexPath?.description ?? "nil")  type: \(changeType)")
        changeSet.addChange(forItemAt: indexPath, with: changeType)
    }
    func controller(_ controller: ResultsController, didChangeSection section: Any, at indexPath: IndexPath?, for changeType: ResultsControllerChangeType) {
        print("DID CHANGE Section: ip: \(indexPath?.description ?? "nil")  type: \(changeType)")
        changeSet.addChange(forSectionAt: indexPath, with: changeType)
    }
    func controllerDidChangeContent(controller: ResultsController) {
        print("CONTROLLER DID CHANGE")
        _expectation?.fulfill()
        _expectation = nil
    }

}

/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/
// MARK: - Helpers
/*-------------------------------------------------------------------------------*/
/*-------------------------------------------------------------------------------*/

fileprivate extension NSAttributeDescription {
    convenience init(name: String, type: NSAttributeType) {
        self.init()
        self.name = name
        self.attributeType = type
    }
}

fileprivate class Parent: NSManagedObject {
    @NSManaged var displayOrder: NSNumber
    @NSManaged var createdAt: Date
    @NSManaged var children: Set<Child>
    
    static func create(in moc: NSManagedObjectContext, children: Int = 1) -> Parent {
        let req = NSFetchRequest<Parent>(entityName: "Parent")
        req.sortDescriptors = [NSSortDescriptor(key: "displayOrder", ascending: false)]
        req.fetchLimit = 1
        let _order = try! moc.fetch(req).first?.displayOrder.intValue ?? 0
        let new = NSEntityDescription.insertNewObject(forEntityName: "Parent", into: moc) as! Parent
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
}

fileprivate class Child: NSManagedObject {
    @NSManaged var second: NSNumber
    @NSManaged var minute: NSNumber
    @NSManaged var displayOrder: NSNumber
    @NSManaged var createdAt: Date
    @NSManaged var parent: Parent?
    
    static func createOrphan(in moc: NSManagedObjectContext) -> Child {
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

extension Date: CustomDisplayStringConvertible {
    public var displayDescription: String {
        return "\(self)"
    }
}

fileprivate class TestModel: NSManagedObjectModel {
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
