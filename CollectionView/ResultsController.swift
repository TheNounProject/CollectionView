
//  ResultsController.swift
//  Lingo
//
//  Created by Wesley Byrne on 1/11/17.
//  Copyright © 2017 The Noun Project. All rights reserved.
//

import CoreData






/**
 A ResultsController manages data in a way that is usable by a collection view.
 
 - FetchedResultsController
 - RelationalResultsController
 
*/
public protocol ResultsController {
    
    // MARK: - Delegate
    /*-------------------------------------------------------------------------------*/
    /// The delegate to notify about data changes
    var delegate : ResultsControllerDelegate? { get set }
    
    
    // MARK: - Data
    /*-------------------------------------------------------------------------------*/
    /// The number of sections in the results controller
    var numberOfSections : Int { get }
    
    
    /**
     Returns the number of objects in the specified section

     - Parameter section: The section for which to count the objects
     
     - Returns: The number of objects

    */
    func numberOfObjects(in section: Int) -> Int
    
    
    // MARK: - Getting Items
    /*-------------------------------------------------------------------------------*/
    /**
     Returns the section info for the specified index path

     - Parameter sectionIndexPath: The section to retieve info for
     
     - Returns: The section info

    */
//    func sectionInfo(forSectionAt sectionIndexPath: IndexPath) -> SectionInfo?

    
    /**
     Returns the object at the specified index path

     - Parameter indexPath: The index path
     
     - Returns: An object at the specfied index path

    */
//    func object(at indexPath: IndexPath) -> Element? {
//        return nil
//    }
    
    
    /**
     The name of the section at the specfied section

     - Returns: A string representing the name of the section
     
     - Note: The object represented by the section must adopt CustomDisplayStringConvertible, otherwise this returns an empty string

    */
    func sectionName(forSectionAt indexPath :IndexPath) -> String
    
    /// Clear all storage for the controller and stop all observing
    func reset()
}


public protocol SectionType : Hashable { }

struct NoSectionType : SectionType {
    var hashValue: Int { return 0 }
    static func ==(lhs: NoSectionType, rhs: NoSectionType) -> Bool { return true }
}
extension String : SectionType { }
extension NSNumber : SectionType { }
extension Int : SectionType { }


public protocol ResultType : Hashable { }
extension NSManagedObject : ResultType { }
extension NSManagedObject : SectionType { }

/**
 Information about the sections of a results controller
 */
//public protocol SectionInfo {
//    associatedtype RepresentedType = SectionType
//    associatedtype Item = ResultType
//    /**
//     The object represented by the section
//     */
//    var object : RepresentedType? { get }
//    /**
//     The number of objects in the section
//     */
//    var numberOfObjects : Int { get }
//    /**
//     The objects in the section
//     
//     - Note: Calling this method incurs large overhead and should be avoided. Use getter methods on the ResultsController instead.
//     */
//    var objects : [Item] { get }
//}





public extension Array where Element:Any {
    public func object(at index: Int) -> Element? {
        if index >= 0 && index < self.count {
            return self[index]
        }
        return nil
    }
}



/// Errors thrown by results controllers - unimplimented
///
/// - unknown: 
public enum ResultsControllerError: Error {
    case unknown
}





/**
 CustomDisplayStringConvertible allows objects to return a custom description to display
*/
public protocol CustomDisplayStringConvertible  {
    var displayDescription : String { get }
}

extension String : CustomDisplayStringConvertible {
    public var displayDescription: String { return self }
}

extension NSNumber : CustomDisplayStringConvertible {
    public var displayDescription: String { return "\(self)" }
}

/// :nodoc:
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







/**
 The ResultsControllerDelegate defines methods that allow you to respond to changes in the results controller.
 
 Use ResultChangeSet to easily track changes and apply them to a CollectionView
*/
public protocol ResultsControllerDelegate: class {
    
    /// Tells the delegate that the controller will change
    ///
    /// - Parameter controller: The controller that will change
    func controllerWillChangeContent(controller: ResultsController)
    
    /**
     Tells the delegate that the an object was changed

     - Parameter controller: The controller
     - Parameter object: The object that changed
     - Parameter indexPath: The source index path of the object
     - Parameter changeType: The type of change

    */
    func controller(_ controller: ResultsController, didChangeObject object: Any, at indexPath: IndexPath?, for changeType: ResultsControllerChangeType)
    
    
    /**
     Tells the delegate that a section was changed

     - Parameter controller: The controller
     - Parameter section: The info for the updated section
     - Parameter indexPath: the source index path of the section
     - Parameter changeType: The type of change

    */
    func controller(_ controller: ResultsController, didChangeSection section: Any, at indexPath: IndexPath?, for changeType: ResultsControllerChangeType)
    
    
    /**
     Tells the delegate that it has process all changes

     - Parameter controller: The controller that was changed

    */
    func controllerDidChangeContent(controller: ResultsController)
}




/**
 The types of changes reported to ResultsControllerDelegate
 
 - delete: The item was deleted
 - update: The item was updated
 - insert: The item was inserted
 - move: The item was moved

 */
public enum ResultsControllerChangeType  {
    
    case delete
    case update
    case insert(IndexPath)
    case move(IndexPath)
    
    public var isInsert : Bool {
        switch self {
        case .insert: return true
        default: return false
        }
    }
    public var isDelete : Bool {
        switch self {
        case .delete: return true
        default: return false
        }
    }
    public var isMove : Bool {
        switch self {
        case .move: return true
        default: return false
        }
    }
    public var isUpdate : Bool {
        switch self {
        case .update: return true
        default: return false
        }
    }
}




/// A set of changes for an entity with with mappings to original Indexes
internal struct ObjectChangeSet<Index: Hashable, Object:Hashable>: CustomStringConvertible {
    
    var inserted = Set<Object>()
    var updated = IndexedSet<Index, Object>()
    var deleted = IndexedSet<Index, Object>()
    
    var count : Int {
        return inserted.count + updated.count + deleted.count
    }
    
    var description: String {
        let str = "Change Set \(Object.self):"
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
        self.updated.insert(object, for: index)
    }
    
    mutating func add(deleted object: Object, for index: Index) {
        self.deleted.insert(object, for: index)
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



