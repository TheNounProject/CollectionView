//
//  DelegateChangeSets.swift
//  CollectionView
//
//  Created by Wesley Byrne on 1/31/17.
//  Copyright © 2017 Noun Project. All rights reserved.
//

import Foundation



public struct ItemChangeSet {
    public typealias Move = (source: IndexPath, destination: IndexPath)
    
    public var inserts = Set<IndexPath>()
    public var deletes = Set<IndexPath>()
    public var updates = Set<IndexPath>()
    public var moves = [Move]()
    
    public init() { }
    
    public mutating func addChange(forItemAt source: IndexPath?, with changeType: ResultsControllerChangeType) {
        switch changeType {
        case .delete:
            print("Delete item at \(source!)")
            deletes.insert(source!)
        case .update:
            print("Update item at \(source!)")
            updates.insert(source!)
        case let .move(newIndexPath):
            print("Move item at \(source!) to \(newIndexPath)")
            moves.append((source!, newIndexPath))
        case let .insert(newIndexPath):
            print("Insert item at \(newIndexPath)")
            inserts.insert(newIndexPath)
        }
    }
    
    public mutating func reset() {
        inserts.removeAll()
        deletes.removeAll()
        updates.removeAll()
        moves.removeAll()
    }
}

public struct SectionChangeSet {
    public typealias Move = (source: Int, destination: Int)
    
    public var inserts = IndexSet()
    public var deletes = IndexSet()
    public var updates = IndexSet()
    public var moves = [Move]()
    
    public init() { }
    
    public mutating func addChange(forSectionAt source: IndexPath?, with changeType: ResultsControllerChangeType) {
        switch changeType {
        case .delete:
            deletes.insert(source!._section)
        case .update:
            updates.insert(source!._section)
            break;
        case let .move(newIndexPath):
            moves.append((source!._section, newIndexPath._section))
        case let .insert(newIndexPath):
            inserts.insert(newIndexPath._section)
        }
    }
    
    public mutating func reset() {
        inserts.removeAll()
        deletes.removeAll()
        updates.removeAll()
        moves.removeAll()
    }
}


// Extension to make easy use of the ItemChangeSet and SectionChangeSet
public extension CollectionView {
    
    
    public func applyChanges(_ items: ItemChangeSet, sections: SectionChangeSet, completion: AnimationCompletion? = nil) {
        self.performBatchUpdates({
            applyChanges(sections)
            applyChanges(items)
        }, completion: completion)
    }
    
    public func applyChanges(_ changes: SectionChangeSet) {
        self.deleteSections(changes.deletes, animated: true)
        self.insertSections(changes.inserts, animated: true)
        self.reloadSupplementaryViews(in: changes.updates, animated: true)
    }
    
    public func applyChanges(_ changes: ItemChangeSet) {
        self.deleteItems(at: Array(changes.deletes), animated: true)
        self.insertItems(at: Array(changes.inserts), animated: true)
        
        for move in changes.moves {
            self.moveItem(at: move.source, to: move.destination, animated: true)
        }
        // self.collectionView.reloadItems(at: Array(_updates), animated: true)
    }
    
    
}


