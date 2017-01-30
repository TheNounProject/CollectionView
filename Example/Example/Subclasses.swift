//
//  Subclasses.swift
//  ResultsController
//
//  Created by Wesley Byrne on 1/12/17.
//  Copyright © 2017 WCB Media. All rights reserved.
//

import Foundation
import CoreData
import CollectionView


let formatter : DateFormatter = {
    let df = DateFormatter()
    df.dateFormat = "MM-dd-yyyy mm:ss"
    return df
}()

let minuteFormatter : DateFormatter = {
    let df = DateFormatter()
    df.dateFormat = "MM-dd-yyyy mm"
    return df
}()


class Parent : NSManagedObject, CustomDisplayStringConvertible {
    
    @NSManaged var children : Set<Child>
    @NSManaged var created: Date
    @NSManaged var displayOrder : NSNumber
    
    static func create(in moc : NSManagedObjectContext? = nil) -> Parent {
        
        let moc = moc ?? AppDelegate.current.managedObjectContext
        let req = NSFetchRequest<Parent>(entityName: "Parent")
        req.sortDescriptors = [NSSortDescriptor(key: "displayOrder", ascending: false)]
        req.fetchLimit = 1
        let _order = try! moc.fetch(req).first?.displayOrder.intValue ?? -1
        
        let new = NSEntityDescription.insertNewObject(forEntityName: "Parent", into: moc) as! Parent
        new.displayOrder = NSNumber(value: _order + 1)
        new.created = Date()
        new.createChild()
        return new
    }
    
    func createChild() {
        let child = NSEntityDescription.insertNewObject(forEntityName: "Child", into: self.managedObjectContext!) as! Child
        
        let order = self.children.sorted(using: [NSSortDescriptor(key: "displayOrder", ascending: true)]).last?.displayOrder.intValue ?? -1
        child.displayOrder = NSNumber(value: order + 1)
        
        child.created = Date()
        child.parent = self
        child.minute = minuteFormatter.string(from: Date())
    }
    
    var displayDescription: String {
        return "Parent \(displayOrder) - \(formatter.string(from: created))"
    }
}


class Child : NSManagedObject, CustomDisplayStringConvertible {
    
    @NSManaged var parent : Parent?
    @NSManaged var created: Date
    @NSManaged var minute: String
    @NSManaged var displayOrder : NSNumber
    
    var displayDescription: String {
        return "Child \(displayOrder) - \(formatter.string(from: created))"
    }
    
    var dateString : String {
        return formatter.string(from: created)
    }
    
    
    static func createOrphan(in moc : NSManagedObjectContext? = nil) {      
        
        let moc = moc ?? AppDelegate.current.managedObjectContext
        let child = NSEntityDescription.insertNewObject(forEntityName: "Child", into: moc) as! Child
        
        child.displayOrder = NSNumber(value: 0)
        child.created = Date()
        child.minute = minuteFormatter.string(from: Date())
    }
    
}
