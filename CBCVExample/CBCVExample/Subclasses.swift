//
//  Subclasses.swift
//  ResultsController
//
//  Created by Wesley Byrne on 1/12/17.
//  Copyright © 2017 WCB Media. All rights reserved.
//

import Foundation
import CoreData
import CBCollectionView


let formatter : DateFormatter = {
    let df = DateFormatter()
    df.dateFormat = "MM-dd-yyyy mm"
    return df
}()


class Parent : NSManagedObject, CustomDisplayStringConvertible {
    
    @NSManaged var children : Set<Child>
    @NSManaged var created: Date
    @NSManaged var displayOrder : NSNumber
    
    static func create() {
        
        let moc = AppDelegate.current.managedObjectContext
        
        let req = NSFetchRequest<NSNumber>(entityName: "Parent")
        let count = try! moc.count(for: req)
        
        let new = NSEntityDescription.insertNewObject(forEntityName: "Parent", into: moc) as! Parent
        new.displayOrder = NSNumber(value: count)
        new.created = Date()
        new.createChild()
        AppDelegate.current.saveAction(nil)
    }
    
    func createChild() {
        let child = NSEntityDescription.insertNewObject(forEntityName: "Child", into: self.managedObjectContext!) as! Child
        child.displayOrder = NSNumber(value: self.children.count)
        child.created = Date()
        child.parent = self
        child.minute = formatter.string(from: Date())
        AppDelegate.current.saveAction(nil)
    }
    
    var displayDescription: String {
        return "Parent \(displayOrder) - \(formatter.string(from: created))"
    }
}


class Child : NSManagedObject, CustomDisplayStringConvertible {
    
    @NSManaged var parent : Parent
    @NSManaged var created: Date
    @NSManaged var minute: String
    @NSManaged var displayOrder : NSNumber
    
    var displayDescription: String {
        return "Child \(displayOrder) - \(formatter.string(from: created))"
    }
    
    
}
