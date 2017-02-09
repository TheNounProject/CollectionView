
//  ResultsController.swift
//  Lingo
//
//  Created by Wesley Byrne on 1/11/17.
//  Copyright © 2017 The Noun Project. All rights reserved.
//

import Foundation
import CoreData

// Test 2

public extension Array where Element:Any {
    public func object(at index: Int) -> Element? {
        if index >= 0 && index < self.count {
            return self[index]
        }
        return nil
    }
}

public enum ResultsControllerError: Error {
    case unknown
}


public protocol CustomDisplayStringConvertible  {
    var displayDescription : String { get }
}

extension String : CustomDisplayStringConvertible {
    public var displayDescription: String { return self }
}

extension NSNumber : CustomDisplayStringConvertible {
    public var displayDescription: String { return "\(self)" }
}

extension Int : CustomDisplayStringConvertible {
    public var displayDescription: String {
        return "\(self)"
    }
}

extension NSNumber : Comparable {
    public static func ==(lhs: NSNumber, rhs: NSNumber) -> Bool {
        return lhs.compare(rhs) == .orderedSame
    }
    
    public static func <(lhs: NSNumber, rhs: NSNumber) -> Bool {
        return lhs.compare(rhs) == .orderedAscending
    }
}


public protocol ResultsController {
    
    var delegate : ResultsControllerDelegate? { get set }
    
    var numberOfSections : Int { get }
    func numberOfObjects(in section: Int) -> Int
    
    var sections : [ResultsControllerSectionInfo] { get }
    var allObjects : [Any] { get }
    
    // MARK: - Getting Items
    /*-------------------------------------------------------------------------------*/
    func sectionInfo(forSectionAt sectionIndexPath: IndexPath) -> ResultsControllerSectionInfo?
    func object(at indexPath: IndexPath) -> Any?
    
    func sectionName(forSectionAt indexPath :IndexPath) -> String
    
    func performFetch() throws
}


public protocol ResultsControllerSectionInfo {
    var object : Any? { get }
    var numberOfObjects : Int { get }
    var objects : [Any] { get }
}

public protocol ResultsControllerDelegate {
    func controllerWillChangeContent(controller: ResultsController)
    func controller(_ controller: ResultsController, didChangeObject object: Any, at indexPath: IndexPath?, for changeType: ResultsControllerChangeType)
    func controller(_ controller: ResultsController, didChangeSection section: ResultsControllerSectionInfo, at indexPath: IndexPath?, for changeType: ResultsControllerChangeType)
    func controllerDidChangeContent(controller: ResultsController)
}




public enum ResultsControllerChangeType {
    case delete
    case update
    case insert(IndexPath)
    case move(IndexPath)
}




/// A set of changes for an entity with with mappings to original Indexes
internal struct ObjectChangeSet<Index: Hashable, Object:NSManagedObject>: CustomStringConvertible {
    
    var inserted = Set<Object>()
    var updated = IndexedSet<Index, Object>()
    var deleted = IndexedSet<Index, Object>()
    
    var count : Int {
        return inserted.count + updated.count + deleted.count
    }
    
    var description: String {
        let str = "Change Set \(Object.className()):"
        + " \(updated.count) Updated, "
        + " \(inserted.count) Inserted, "
        + " \(deleted.count) Deleted"
        return str
    }
    
    init() { }
    
    mutating func add(inserted object: Object) {
        inserted.insert(object)
    }
    
    mutating func add(updated object: Object, for index: Index) {
        self.updated.insert(object, with: index)
    }
    
    mutating func add(deleted object: Object, for index: Index) {
        self.deleted.insert(object, with: index)
    }
    
    func object(for index: Index) -> Object? {
        return updated[index] ?? deleted[index]
    }
    
    func index(for object: Object) -> Index? {
        return updated.index(of: object) ?? deleted.index(of: object)
    }
    
    mutating func reset() {
        self.inserted.removeAll()
        self.deleted.removeAll()
        self.updated.removeAll()
    }
}



