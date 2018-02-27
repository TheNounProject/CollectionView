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

let dateGroupFormatter : DateFormatter = {
    let df = DateFormatter()
    df.dateFormat = "MM-dd-yyyy mm"
    return df
}()



class Parent : NSManagedObject, CustomDisplayStringConvertible {
    
    @NSManaged var children : Set<Child>
    @NSManaged var created: Date
	
    @NSManaged var displayOrder : NSNumber
    
    
    static func create(in moc : NSManagedObjectContext? = nil, withChild child: Bool = true) -> Parent {
        let moc = moc ?? AppDelegate.current.managedObjectContext
        let req = NSFetchRequest<Parent>(entityName: "Parent")
        req.sortDescriptors = [NSSortDescriptor(key: "displayOrder", ascending: false)]
        req.fetchLimit = 1
        let _order = try! moc.fetch(req).first?.displayOrder.intValue ?? 0
        
        let new = NSEntityDescription.insertNewObject(forEntityName: "Parent", into: moc) as! Parent
        new.displayOrder = NSNumber(value: _order + 1)
        new.created = Date()
        
        if child {
            _ = new.createChild()
        }
        return new
    }
    
	
    func createChild() -> Child {
        return createChildren(1).first!
    }
    
    func createChildren(_ count: Int = 1) -> [Child] {
        let start = NSFetchRequest<Child>(entityName: "Child")
        start.predicate = NSPredicate(format: "parent = %@", self)
        start.sortDescriptors = [NSSortDescriptor(key: "displayOrder", ascending: false)]
        start.fetchLimit = 1
        var order = 0
        do {
            if let first = try self.managedObjectContext?.fetch(start).first?.displayOrder.intValue {
                order = first
            }
        }
        catch { }
        
        var res = [Child]()
        for n in 0..<count {
            let child = Child.createOrphan(in: self.managedObjectContext)
            child.displayOrder = NSNumber(value: order + n)
            child.parent = self
            res.append(child)
        }
        return res
    }
    
    var displayDescription: String {
        return "Parent \(displayOrder) - \(formatter.string(from: created))"
    }
}


class Child : NSManagedObject, CustomDisplayStringConvertible {
    
    @NSManaged var parent : Parent?
    @NSManaged var created: Date
    @NSManaged var group: String
    @NSManaged var second: NSNumber
    @NSManaged var displayOrder : NSNumber
    
    var displayDescription: String {
        guard self.isValid else {
            return "Child \(idString) -- Deleted"
        }
        return "Child \(self.idString) - [\(self.parent?.displayOrder.description ?? "?"), \(displayOrder)]"
    }
    
    override var description: String {
        return displayDescription
    }
    
    var dateString : String {
        return formatter.string(from: created)
    }
    
    static func createOrphan(in moc : NSManagedObjectContext? = nil) -> Child {
        let moc = moc ?? AppDelegate.current.managedObjectContext
        let child = NSEntityDescription.insertNewObject(forEntityName: "Child", into: moc) as! Child
        
        child.displayOrder = NSNumber(value: 0)
        
        let d = Date()
        child.created = d
        let s = Calendar.current.component(.second, from: d)
        child.second = NSNumber(value: Int(s/6))
        child.group = dateGroupFormatter.string(from: Date())
        
        return child
    }
    
}


extension NSManagedObject {
    var isValid : Bool {
        return self.managedObjectContext != nil && self.isDeleted == false
    }
    var idString : String {
        let str = self.objectID.uriRepresentation().lastPathComponent
        if self.objectID.isTemporaryID { return str.sub(from: -3) }
        return self.objectID.uriRepresentation().lastPathComponent
    }
}
