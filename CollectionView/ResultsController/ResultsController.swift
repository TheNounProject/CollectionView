//  ResultsController.swift
//  Lingo
//
//  Created by Wesley Byrne on 1/11/17.
//  Copyright © 2017 The Noun Project. All rights reserved.
//

import CoreData

/// A ResultsController manages data in a way that is usable by a collection view.
///
/// - FetchedResultsController
/// - RelationalResultsController
public protocol ResultsController: AnyObject {
    
    /// The delegate to notify about data changes
    var delegate: ResultsControllerDelegate? { get set }
    
    /// The number of sections in the results controller
    var numberOfSections: Int { get }
    
    /// Returns the number of objects in the specified section
    ///
    /// - Parameter section: The section for which to count the objects
    ///
    /// - Returns: The number of objects
    func numberOfObjects(in section: Int) -> Int
    
    /// The name of the section at the specfied section
    ///
    /// - Returns: A string representing the name of the section
    ///
    /// - Note: The object represented by the section must adopt CustomDisplayStringConvertible, otherwise this returns an empty string
    func sectionName(forSectionAt indexPath: IndexPath) -> String
    
    /// Clear all storage for the controller and stop all observing
    func reset()
}

public extension ResultsController {
    var isEmpty: Bool {
        return self.numberOfSections == 0
    }
}

public protocol SectionType: Hashable { }

struct NoSectionType: SectionType {
    func hash(into hasher: inout Hasher) {
        hasher.combine(0)
    }
    static func == (lhs: NoSectionType, rhs: NoSectionType) -> Bool { return true }
}
extension String: SectionType { }
extension NSNumber: SectionType { }
extension Int: SectionType { }

public protocol ResultType: Hashable { }
extension NSManagedObject: ResultType { }
extension NSManagedObject: SectionType { }

public extension Array where Element: Any {
    func object(at index: Int) -> Element? {
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

/// CustomDisplayStringConvertible allows objects to return a custom description to display
public protocol CustomDisplayStringConvertible {
    var displayDescription: String { get }
}

/// :nodoc:
extension String: CustomDisplayStringConvertible {
    public var displayDescription: String { return self }
}

/// :nodoc:
extension NSNumber: CustomDisplayStringConvertible {
    public var displayDescription: String { return "\(self)" }
}

/// :nodoc:
extension Int: CustomDisplayStringConvertible {
    public var displayDescription: String {
        return "\(self)"
    }
}

/// :nodoc:
extension NSNumber: Comparable {
    public static func == (lhs: NSNumber, rhs: NSNumber) -> Bool {
        return lhs.compare(rhs) == .orderedSame
    }
    public static func < (lhs: NSNumber, rhs: NSNumber) -> Bool {
        return lhs.compare(rhs) == .orderedAscending
    }
}

/// The ResultsControllerDelegate defines methods that allow you to respond to changes in the results controller.
///
/// Use ResultChangeSet to easily track changes and apply them to a CollectionView
public protocol ResultsControllerDelegate: AnyObject {
    
    /// Tells the delegate that the controller did load its initial content
    ///
    /// - Parameter controller: The controller that loaded
    func controllerDidLoadContent(controller: ResultsController)
    
    /// Tells the delegate that the controller will change
    ///
    /// - Parameter controller: The controller that will change
    func controllerWillChangeContent(controller: ResultsController)
    
    /// Tells the delegate that the an object was changed
    ///
    /// - Parameter controller: The controller
    /// - Parameter object: The object that changed
    /// - Parameter indexPath: The source index path of the object
    /// - Parameter changeType: The type of change
    func controller(_ controller: ResultsController, didChangeObject object: Any, at indexPath: IndexPath?, for changeType: ResultsControllerChangeType)
    
    /// Tells the delegate that a section was changed
    ///
    /// - Parameter controller: The controller
    /// - Parameter section: The info for the updated section
    /// - Parameter indexPath: the source index path of the section
    /// - Parameter changeType: The type of change
    func controller(_ controller: ResultsController, didChangeSection section: Any, at indexPath: IndexPath?, for changeType: ResultsControllerChangeType)
    
    /// Tells the delegate that it has process all changes
    ///
    /// - Parameter controller: The controller that was changed
    func controllerDidChangeContent(controller: ResultsController)
}

 public extension ResultsControllerDelegate {
    func controllerDidLoadContent(controller: ResultsController) { }
}

/// The types of changes reported to ResultsControllerDelegate
///
/// - delete: The item was deleted
/// - update: The item was updated
/// - insert: The item was inserted
/// - move: The item was moved
public enum ResultsControllerChangeType {
    
    case delete
    case update
    case insert(IndexPath)
    case move(IndexPath)
    
    public var isInsert: Bool {
        switch self {
        case .insert: return true
        default: return false
        }
    }
    public var isDelete: Bool {
        switch self {
        case .delete: return true
        default: return false
        }
    }
    public var isMove: Bool {
        switch self {
        case .move: return true
        default: return false
        }
    }
    public var isUpdate: Bool {
        switch self {
        case .update: return true
        default: return false
        }
    }
}
