//
//  DelegateChangeSets.swift
//  CollectionView
//
//  Created by Wesley Byrne on 1/31/17.
//  Copyright © 2017 Noun Project. All rights reserved.
//

import Foundation



@available(*, unavailable, renamed: "ResultsControllerProvider")
public struct ResultsChangeSet { }


/**
 A helper object to easily track changes reported by a ResultsController and apply them to a CollectionView
*/
public class ResultsControllerProvider {
    
    var items = ItemChangeSet()
    var sections = SectionChangeSet()
    
    
    
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
    
    
    /// When set as the delegate
    public weak var collectionView : CollectionView?
    
    
    public init() { }
    
    
    
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
    
    /// Remove all changes
    @available(*, deprecated, renamed: "prepareForUpdates")
    public func removeAll() {
        self.prepareForUpdates()
    }
    
    public func prepareForUpdates() {
        items.reset()
        sections.reset()
    }
    
    public func commit() {
        precondition(self.collectionView != nil, "ResultsControllerProvider must have a collection view to commit changes to")
        
    }
    
    
    /**
     Merge this set with another

     - Parameter other: Another change set

    */
    public func union(with other: ResultsControllerProvider) {
        self.items.inserted.formUnion(other.items.inserted)
        self.items.deleted.formUnion(other.items.deleted)
        self.items.updated.formUnion(other.items.updated)

        self.sections.inserted.formUnion(other.sections.inserted)
        self.sections.deleted.formUnion(other.sections.deleted)
        self.sections.updated.formUnion(other.sections.updated)
    }
}

extension ResultsControllerProvider : ResultsControllerDelegate {
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
        guard let collectionView = self.collectionView else {
            print("ERROR: ResultsContrllerProvider with a delegate must have a collection view")
            return
        }
        
        if self.populateWhenEmpty {
            let isEmpty = controller.numberOfSections == 0
            let wasEmpty = collectionView.numberOfSections == 0
            if !wasEmpty && isEmpty {
                // populate
                self.addChange(forItemAt: nil, with: .insert(IndexPath.zero))
            }
            else if wasEmpty && !isEmpty {
                // Remove placeholder
                self.addChange(forItemAt: IndexPath.zero, with: .delete)
            }
        }
        else if self.populateEmptySections && controller.numberOfSections > 0 {
            
            
        }
        
        
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
//            print("Delete item at \(source!)")
            deleted.insert(source!)
        case .update:
//            print("Update item at \(source!)")
            updated.insert(source!)
        case let .move(newIndexPath):
//            print("Move item at \(source!) to \(newIndexPath)")
            moved.append((source!, newIndexPath))
        case let .insert(newIndexPath):
//            print("Insert item at \(newIndexPath)")
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
//            print("Delete section at \(source!)")
            deleted.insert(source!._section)
        case .update:
//            print("Update section at \(source!)")
            updated.insert(source!._section)
            break;
        case let .move(newIndexPath):
//            print("Move section \(source!) to \(newIndexPath)")
            moved.append((source!._section, newIndexPath._section))
        case let .insert(newIndexPath):
//            print("Insert section at \(newIndexPath)")
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
    public func applyChanges(from changeSet: ResultsChangeSet, completion: AnimationCompletion? = nil) {
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


