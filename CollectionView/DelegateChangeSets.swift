//
//  DelegateChangeSets.swift
//  CollectionView
//
//  Created by Wesley Byrne on 1/31/17.
//  Copyright © 2017 Noun Project. All rights reserved.
//

import Foundation



@available(*, unavailable, renamed: "CollectionViewProvider")
public struct ResultsChangeSet { }




/// A Helper to 
public class CollectionViewResultsProxy   {
    var items = ItemChangeSet()
    var sections = SectionChangeSet()
    
    
    /**
     Add an item change
     
     - Parameter source: The source index path of the section
     - Parameter changeType: The change type
     
     */
    public func addChange(forItemAt source: IndexPath?, with changeType: ResultsControllerChangeType) {
        items.addChange(forItemAt: source, with: changeType)
    }
    
    
    
    /**
     Add a section change
     
     - Parameter source: The source index path of the section
     - Parameter changeType: The change type
     
     */
    public func addChange(forSectionAt source: IndexPath?, with changeType: ResultsControllerChangeType) {
        sections.addChange(forSectionAt: source, with: changeType)
    }
    
    public func didInsertSection(at indexPath: IndexPath) -> Bool {
        return self.sections.inserted.contains(indexPath._section)
    }
    
    public func didInsertObject(at indexPath: IndexPath) -> Bool {
        return self.items.inserted.contains(indexPath)
    }
    
    /// The count of changes in the set
    public var count : Int {
        return items.count + sections.count
    }
    
    public func prepareForUpdates() {
        items.reset()
        sections.reset()
    }
    
    /**
     Merge this set with another
     
     - Parameter other: Another change set
     
     */
    public func union(with other: CollectionViewResultsProxy) {
        self.items.inserted.formUnion(other.items.inserted)
        self.items.deleted.formUnion(other.items.deleted)
        self.items.updated.formUnion(other.items.updated)
        
        self.sections.inserted.formUnion(other.sections.inserted)
        self.sections.deleted.formUnion(other.sections.deleted)
        self.sections.updated.formUnion(other.sections.updated)
    }
}


//protocol CollectionViewProviderDelegate: class {
//    func provider(_ provider: CollectionViewProvider, didUpdateItem item: Any, at indexPath: IndexPath?, for changeType: ResultsControllerChangeType)
//    func provider(_ provider: CollectionViewProvider, didUpdateSection item: Any, at indexPath: IndexPath?, for changeType: ResultsControllerChangeType)
//    func provider(_ provider: CollectionViewProvider, didUpdateSection item: Any, at indexPath: IndexPath?, for changeType: ResultsControllerChangeType)
//    
//}


/**
 A helper object to easily track changes reported by a ResultsController and apply them to a CollectionView
*/
public class CollectionViewProvider : CollectionViewResultsProxy {
    
    /// When set as the delegate
    unowned let collectionView : CollectionView
    unowned let resultsController : ResultsController
    
    /// The last known section count of real data
    private var sectionCount = 0
    
    public init(_ collectionView: CollectionView, resultsController: ResultsController) {
        self.collectionView = collectionView
        self.resultsController = resultsController
        self.sectionCount = resultsController.numberOfSections
        super.init()
        self.resultsController.delegate = self
    }
    

    /**
     If true, a cell will be inserted when a section becomes empty
     
     ## Discussion
     When displaying sections within a CollectionView, it can be helpful to fill empty sections with a placholder cell. This causes an issue when responding to updates from a results controller. For example, when an object is inserted into an empty section, the results controller will report a single insert change. The CollectionView though would need to remove the exisitng cell AND insert the new one.
     
     Setting hasEmptySectionPlaceholders to true, will report changes as such, making it easy to propagate the reported changes to a CollectionView.
     
    */
    public var populateEmptySections = false
    
    /**
     If true, a cell will be inserted when a collection view becomes completely empty
     
     ## Discussion
     When displaying sections within a CollectionView, it can be helpful to display a cell representing the empty state. This causes an issue when responding to updates from a results controller. For example, when the last section is removed from a data source (i.e. ResultsController), the controller will report a single remove change. The CollectionView though would need to remove those cells AND insert the new one to act as the palceholder.
     
     Setting populateWhenEmpty to true, will report changes as such, making it easy to propagate the reported changes to a CollectionView.
     
     */
    public var populateWhenEmpty = false
    


}


// MARK: - Data Source
/*-------------------------------------------------------------------------------*/
extension CollectionViewProvider {
    
    public var numberOfSections : Int {
        let count = resultsController.numberOfSections
        if count == 0 && self.populateWhenEmpty {
            return 1
        }
        return count
    }
    
    public func numberOfItems(in section: Int) -> Int {
        guard resultsController.numberOfSections > 0 else {
            return 1 // Must be populated empty state
        }
        let count = resultsController.numberOfObjects(in: section)
        if count == 0 && self.populateEmptySections {
            return 1
        }
        return count
    }
    
    public var showEmptyState : Bool {
        return resultsController.numberOfSections == 0
            && self.populateWhenEmpty
    }
    
    public func showEmptySection(at indexPath: IndexPath) -> Bool {
        return self.populateEmptySections
            && self.resultsController.numberOfObjects(in: indexPath.section) == 0
    }
}


// MARK: - Results Controller Delegate
/*-------------------------------------------------------------------------------*/
extension CollectionViewProvider : ResultsControllerDelegate {
    
    public func controllerDidLoadContent(controller: ResultsController) {
        self.sectionCount = controller.numberOfSections
    }
    
    public func controllerWillChangeContent(controller: ResultsController) {
        self.prepareForUpdates()
    }
    
    public func controller(_ controller: ResultsController, didChangeObject object: Any, at indexPath: IndexPath?, for changeType: ResultsControllerChangeType) {
        self.addChange(forItemAt: indexPath, with: changeType)
    }
    
    public func controller(_ controller: ResultsController, didChangeSection section: Any, at indexPath: IndexPath?, for changeType: ResultsControllerChangeType) {
        self.addChange(forSectionAt: indexPath, with: changeType)
    }
    
    public func controllerDidChangeContent(controller: ResultsController) {
        defer {
            self.sectionCount = controller.numberOfSections
        }
        if self.populateWhenEmpty {
            let isEmpty = controller.numberOfSections == 0
            let wasEmpty = self.sectionCount == 0
            if !wasEmpty && isEmpty {
                // populate
                self.addChange(forSectionAt: nil, with: .insert(IndexPath.zero))
            }
            else if wasEmpty && !isEmpty {
                // Remove placeholder
                self.addChange(forSectionAt: IndexPath.zero, with: .delete)
            }
        }
        else if self.populateEmptySections && controller.numberOfSections > 0 {
            
        }
        self.collectionView.applyChanges(from: self)
    }
    
}


// Deprecated
extension CollectionViewResultsProxy {
    @available(*, deprecated, renamed: "prepareForUpdates")
    public func removeAll() {
        self.prepareForUpdates()
    }
}


struct ItemChangeSet {
    typealias Move = (source: IndexPath, destination: IndexPath)
    
    var inserted = Set<IndexPath>()
    var deleted = Set<IndexPath>()
    var updated = Set<IndexPath>()
    var moved = [Move]()
    
    init() { }
    
    var count : Int {
        return inserted.count + deleted.count + updated.count + moved.count
    }
    
    mutating func addChange(forItemAt source: IndexPath?, with changeType: ResultsControllerChangeType) {
        switch changeType {
        case .delete:
            deleted.insert(source!)
        case .update:
            updated.insert(source!)
        case let .move(newIndexPath):
            moved.append((source!, newIndexPath))
        case let .insert(newIndexPath):
            inserted.insert(newIndexPath)
        }
    }
    
    mutating func reset() {
        inserted.removeAll()
        deleted.removeAll()
        updated.removeAll()
        moved.removeAll()
    }
}

struct SectionChangeSet {
     typealias Move = (source: Int, destination: Int)
    
     var inserted = IndexSet()
     var deleted = IndexSet()
     var updated = IndexSet()
     var moved = [Move]()
    
     init() { }
    
    var count : Int {
        return inserted.count + deleted.count + updated.count + moved.count
    }
    
     mutating func addChange(forSectionAt source: IndexPath?, with changeType: ResultsControllerChangeType) {
        switch changeType {
        case .delete:
            deleted.insert(source!._section)
        case .update:
            updated.insert(source!._section)
            break;
        case let .move(newIndexPath):
            moved.append((source!._section, newIndexPath._section))
        case let .insert(newIndexPath):
            inserted.insert(newIndexPath._section)
        }
    }
    
     mutating func reset() {
        inserted.removeAll()
        deleted.removeAll()
        updated.removeAll()
        moved.removeAll()
    }
}


// Extension to make easy use of the ItemChangeSet and SectionChangeSet
public extension CollectionView {
    
    
    /**
     Apply all changes in a change set to a collection view

     - Parameter changeSet: The change set to apply
     - Parameter completion: A close to call when the update finishes

    */
    public func applyChanges(from changeSet: CollectionViewResultsProxy, completion: AnimationCompletion? = nil) {
        guard changeSet.count > 0 else {
            completion?(true)
            return
        }

        self.performBatchUpdates({
            _applyChanges(changeSet.items)
            _applyChanges(changeSet.sections)
        }, completion: completion)
    }
    
    private func _applyChanges(_ changes: SectionChangeSet) {
        self.deleteSections(changes.deleted, animated: true)
        self.insertSections(changes.inserted, animated: true)
        self.reloadSupplementaryViews(in: changes.updated, animated: true)
        for m in changes.moved {
            self.moveSection(m.source, to: m.destination, animated: true)
        }
    }
    
    private func _applyChanges(_ changes: ItemChangeSet) {
        self.deleteItems(at: Array(changes.deleted), animated: true)
        self.insertItems(at: Array(changes.inserted), animated: true)
        
        for move in changes.moved {
            self.moveItem(at: move.source, to: move.destination, animated: true)
        }
        self.reloadItems(at: Array(changes.updated), animated: true)
    }
    
    
}


