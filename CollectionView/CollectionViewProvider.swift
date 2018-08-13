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
<<<<<<< HEAD
public class CollectionViewResultsProxy: CustomDebugStringConvertible {
=======
public class CollectionViewResultsProxy: CustomDebugStringConvertible   {
>>>>>>> master
    public internal(set) var itemUpdates = ItemChangeSet()
    public internal(set) var sectionUpdates = SectionChangeSet()
    
    public init() { }
    
    public var debugDescription: String {
        return "Items: \(self.itemUpdates)\nSections:\(self.sectionUpdates)"
    }
    
    /// Add an item change
    ///
    /// - Parameter source: The source index path of the section
    /// - Parameter changeType: The change type
    public func addChange(forItemAt source: IndexPath?, with changeType: ResultsControllerChangeType) {
        itemUpdates.addChange(forItemAt: source, with: changeType)
    }
    
    ///  Add a section change
    ///
    /// - Parameter source: The source index path of the section
    /// - Parameter changeType: The change type
    ///
    public func addChange(forSectionAt source: IndexPath?, with changeType: ResultsControllerChangeType) {
        sectionUpdates.addChange(forSectionAt: source, with: changeType)
    }
    
    public func didInsertSection(at indexPath: IndexPath) -> Bool {
        return self.sectionUpdates.inserted.contains(indexPath._section)
    }
    
    public func didInsertObject(at indexPath: IndexPath) -> Bool {
        return self.itemUpdates.inserted.contains(indexPath)
    }
    
    /// The count of changes in the set
    public var count: Int {
        return itemChangeCount + sectionChangeCount
    }
    public var itemChangeCount: Int {
        return itemUpdates.count
    }
    public var sectionChangeCount: Int {
        return sectionUpdates.count
    }
<<<<<<< HEAD
    public var isEmpty: Bool {
=======
    public var isEmpty : Bool {
>>>>>>> master
        return itemUpdates.isEmpty && sectionUpdates.isEmpty
    }
    
    public func prepareForUpdates() {
        itemUpdates.reset()
        sectionUpdates.reset()
    }
    
    /// Merge this set with another
    ///
    /// - Parameter other: Another change set
    ///
    public func union(with other: CollectionViewResultsProxy) {
        self.itemUpdates.formUnion(with: other.itemUpdates)
        self.sectionUpdates.formUnion(with: other.sectionUpdates)
    }
}

public protocol CollectionViewProviderDelegate: class {
    func providerWillChangeContent(_ provider: CollectionViewProvider)
    func provider(_ provider: CollectionViewProvider, didUpdateItem item: Any, at indexPath: IndexPath?, for changeType: ResultsControllerChangeType)
    func provider(_ provider: CollectionViewProvider, didUpdateSection item: Any, at indexPath: IndexPath?, for changeType: ResultsControllerChangeType)
    func providerDidChangeContent(_ provider: CollectionViewProvider) -> AnimationCompletion?
}

public extension CollectionViewProviderDelegate {
    func providerWillChangeContent(_ provider: CollectionViewProvider) { }
    func provider(_ provider: CollectionViewProvider, didUpdateItem item: Any, at indexPath: IndexPath?, for changeType: ResultsControllerChangeType) { }
    func provider(_ provider: CollectionViewProvider, didUpdateSection item: Any, at indexPath: IndexPath?, for changeType: ResultsControllerChangeType) { }
    func providerDidChangeContent(_ provider: CollectionViewProvider) -> AnimationCompletion? { return nil }
}

public extension CollectionViewResultsProxy {
    
    /// Create a proxy for a set of edits in one section
    ///
    /// - Parameters:
    ///   - edits: A set of EditDistance Edits
    ///   - section: The section the changes should apply to
    /// - Returns: A new proxy with the edits added
<<<<<<< HEAD
    public func addEdits<T: Collection>(from edits: EditDistance<T>, for section: Int = 0) where T.Iterator.Element: Hashable, T.Index == Int {
=======
    public func addEdits<T:Collection>(from edits: EditDistance<T>, for section: Int = 0) where T.Iterator.Element: Hashable, T.Index == Int {
>>>>>>> master
        for e in edits.edits {
            switch e.operation {
            case .deletion:
                self.addChange(forItemAt: IndexPath.for(item: e.index, section: section),
                               with: .delete)
            case .insertion:
                self.addChange(forItemAt: nil,
                               with: .insert(IndexPath.for(item: e.index, section: section)))
            case let .move(origin: o):
                self.addChange(forItemAt: IndexPath.for(item: o, section: section),
                               with: .move(IndexPath.for(item: e.index, section: section)))
            case .substitution:
                self.addChange(forItemAt: IndexPath.for(item: e.index, section: section),
                               with: .update)
            }
        }
    }
}

/// A helper object to easily track changes reported by a ResultsController and apply them to a CollectionView
<<<<<<< HEAD
public class CollectionViewProvider: CollectionViewResultsProxy {
=======
public class CollectionViewProvider : CollectionViewResultsProxy {
>>>>>>> master
    
    /// When set as the delegate
    public unowned let collectionView: CollectionView
    public unowned let resultsController: ResultsController
    public weak var delegate: CollectionViewProviderDelegate?
    
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
    
<<<<<<< HEAD
    private class Section: Equatable, CustomStringConvertible {
        var source: Int?
=======
    private class Section : Equatable, CustomStringConvertible {
        var source : Int?
>>>>>>> master
        var target: Int?
        var dataCount: Int = 0
        var displayCount: Int = 0
        
        init(source: Int?, target: Int?, dataCount: Int, displayCount: Int) {
            self.source = source
            self.target = target
            self.dataCount = dataCount
            self.displayCount = displayCount
        }
        
        static func ==(lhs: CollectionViewProvider.Section,
                       rhs: CollectionViewProvider.Section) -> Bool {
            return lhs.source == rhs.source && lhs.target == rhs.target
        }
        var description: String {
            return "Source: \(source ?? -1) Target: \(self.target ?? -1) Count: \(self.dataCount)"
        }
    
    }
    
    private var sections = [Section]()
    var collapsedSections = Set<Int>()
    public var defaultCollapse: Bool = false
    
    public override func prepareForUpdates() {
        super.prepareForUpdates()
        sections = (0..<resultsController.numberOfSections).map {
            return Section(source: $0,
                           target: nil,
                           dataCount: resultsController.numberOfObjects(in: $0),
                           displayCount: self.numberOfItems(in: $0))
        }
    }
    
    func collapseAllSections() {
        
    }
    
    func expandAllSections() {
        
    }
    
    func setSection(at sectionIndex: Int, expanded: Bool, animated: Bool) {
        if expanded {
            self.expandSection(at: sectionIndex, animated: animated)
        }
        else {
            self.collapseSection(at: sectionIndex, animated: animated)
        }
    }
    
    public func isSectionCollapsed(at index: Int) -> Bool {
        return collapsedSections.contains(index)
    }
    
    public func collapseSection(at sectionIndex: Int, animated: Bool) {
        guard !collapsedSections.contains(sectionIndex) else { return }
        let ips = (0..<self.numberOfItems(in: sectionIndex)).map { return IndexPath.for(item: $0, section: sectionIndex) }
        collapsedSections.insert(sectionIndex)
        self.collectionView.deleteItems(at: ips, animated: animated)
    }
    
    public func expandSection(at sectionIndex: Int, animated: Bool) {
        guard collapsedSections.remove(sectionIndex) != nil else { return }
        let ips = (0..<self.numberOfItems(in: sectionIndex)).map { return IndexPath.for(item: $0, section: sectionIndex) }
        self.collectionView.insertItems(at: ips, animated: animated)
    }
}

// MARK: - Data Source
/*-------------------------------------------------------------------------------*/
extension CollectionViewProvider {
    
    public var numberOfSections: Int {
        let sectionCount = resultsController.numberOfSections
        if sectionCount == 0 && self.populateWhenEmpty {
            return 1
        }
        return sectionCount
    }
    
    public func numberOfItems(in section: Int) -> Int {
        guard resultsController.numberOfSections > 0 else {
            return 1 // Must be populated empty state
        }
        if self.collapsedSections.contains(section) {
            return 0
        }
        let itemCount = resultsController.numberOfObjects(in: section)
        if itemCount == 0 && self.populateEmptySections {
            return 1
        }
        return itemCount
    }
    
    public var showEmptyState: Bool {
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
extension CollectionViewProvider: ResultsControllerDelegate {
    
    public func controllerDidLoadContent(controller: ResultsController) {
        self.sectionCount = controller.numberOfSections
        if defaultCollapse {
            self.collapsedSections = Set(0..<self.numberOfSections)
        }
    }
    
    public func controllerWillChangeContent(controller: ResultsController) {
        self.prepareForUpdates()
        self.delegate?.providerWillChangeContent(self)
    }
    
    public func controller(_ controller: ResultsController, didChangeObject object: Any, at indexPath: IndexPath?, for changeType: ResultsControllerChangeType) {
        self.delegate?.provider(self, didUpdateItem: object, at: indexPath, for: changeType)
        self.addChange(forItemAt: indexPath, with: changeType)
    }
    
    public func controller(_ controller: ResultsController, didChangeSection section: Any, at indexPath: IndexPath?, for changeType: ResultsControllerChangeType) {
        self.delegate?.provider(self, didUpdateSection: section, at: indexPath, for: changeType)
        self.addChange(forSectionAt: indexPath, with: changeType)
    }
    
    public func controllerDidChangeContent(controller: ResultsController) {
        defer {
            self.sectionCount = controller.numberOfSections
        }
        guard itemChangeCount > 0 || sectionChangeCount > 0 else {
            return
        }
        
        let target = processSections()
        
        // If any of the sections are collapsed we may need to adjust some of the edits
        if !self.collapsedSections.isEmpty || self.defaultCollapse {
            var _collapsed = Set<Int>()
            for sec in target {
                if let s = sec?.source, self.collapsedSections.contains(s),
                    let t = sec?.target {
                    _collapsed.insert(t)
                }
                else if defaultCollapse, sec?.source == nil, let t = sec?.target {
                    _collapsed.insert(t)
                }
            }
            
            // Ignore deletes for collapsed sections
            self.itemUpdates.deleted = self.itemUpdates.deleted.filter {
                return !self.collapsedSections.contains($0._section)
            }
            // Ignore inserts for collapsed sections
            self.itemUpdates.inserted = self.itemUpdates.inserted.filter {
                return !_collapsed.contains($0._section)
            }
            
            // Ignore inserts for collapsed sections
            var _moves = [ItemChangeSet.Move]()
            for m in self.itemUpdates.moved {
                let sourceCollapsed = collapsedSections.contains(m.source._section)
                let targetCollapsed = _collapsed.contains(m.destination._section)
                
                if sourceCollapsed && !targetCollapsed {
                    self.itemUpdates.inserted.insert(m.destination)
                }
                else if !sourceCollapsed && targetCollapsed {
                    self.itemUpdates.deleted.insert(m.source)
                }
                else if !sourceCollapsed && !targetCollapsed {
                    _moves.append(m)
                }
                // If both are collapsed, drop the update
            }
            self.itemUpdates.moved = _moves
            
            // Set the new collapsed sections
            self.collapsedSections = _collapsed
        }
        
        let isEmpty = controller.numberOfSections == 0
        let wasEmpty = self.sectionCount == 0
        
        if self.populateWhenEmpty && isEmpty != wasEmpty {
            
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
            for sec in target {
                if let s = sec, s.source != nil, let t = s.target, !collapsedSections.contains(t) {
                    let _isEmpty = controller.numberOfObjects(in: t) == 0
                    let _wasEmpty = s.dataCount == 0
                    if !_wasEmpty && _isEmpty {
                        // populate
                        self.addChange(forItemAt: nil, with: .insert(IndexPath.for(section: t)))
                    }
                    else if _wasEmpty && !_isEmpty {
                        // Remove placeholder
                        self.addChange(forItemAt: IndexPath.for(section: t), with: .delete)
                    }
                }
            }
        }
        let completion = self.delegate?.providerDidChangeContent(self)
        self.collectionView.applyChanges(from: self, completion: completion)
    }
    
    private func processSections() -> [Section?] {
        var source = self.sections
        var target = [Section?](repeatElement(nil, count: resultsController.numberOfSections))
        
        // Populate target with inserted
        for s in sectionUpdates.inserted {
            target[s] = Section(source: nil,
                                target: s,
                                dataCount: resultsController.numberOfObjects(in: s),
                                displayCount: 0)
        }
        
        // The things in source that we want to ignore beow
        var transferred = sectionUpdates.deleted
        
        // Populate target with moved
        for m in sectionUpdates.moved {
            transferred.insert(m.0)
            source[m.0].target = m.1
            target[m.1] = source[m.0]
        }
        
        // Insert the remaining sections from source that are carrying over (not deleted)
        // After this target should be fully populated
        var idx = 0
        func incrementInsert() {
            while idx < target.count && target[idx] != nil {
                idx += 1
            }
        }
        for section in source where !transferred.contains(section.source!) {
            incrementInsert()
            section.target = idx
            target[idx] = section
        }
        return target
    }
}

// Deprecated
extension CollectionViewResultsProxy {
    @available(*, deprecated, renamed: "prepareForUpdates")
    public func removeAll() {
        self.prepareForUpdates()
    }
}

public struct ItemChangeSet {
    public typealias Move = (source: IndexPath, destination: IndexPath)
    
    public var inserted = Set<IndexPath>()
    public var deleted = Set<IndexPath>()
    public var updated = Set<IndexPath>()
    public var moved = [Move]()
    
    init() { }
    
    var count: Int {
        return inserted.count + deleted.count + updated.count + moved.count
    }
<<<<<<< HEAD
    var isEmpty: Bool {
=======
    var isEmpty : Bool {
>>>>>>> master
        return inserted.isEmpty && deleted.isEmpty && updated.isEmpty && moved.isEmpty
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
    
    mutating func formUnion(with other: ItemChangeSet) {
        self.inserted.formUnion(other.inserted)
        self.deleted.formUnion(other.deleted)
        self.updated.formUnion(other.updated)
        self.moved.append(contentsOf: other.moved)
    }
    
    mutating func reset() {
        inserted.removeAll()
        deleted.removeAll()
        updated.removeAll()
        moved.removeAll()
    }
}

public struct SectionChangeSet {
    public typealias Move = (source: Int, destination: Int)
    
    public private(set) var inserted = IndexSet()
    public private(set) var deleted = IndexSet()
    public private(set) var updated = IndexSet()
    public private(set) var moved = [Move]()
    
    init() { }
    
    var count: Int {
        return inserted.count + deleted.count + updated.count + moved.count
    }
<<<<<<< HEAD
    var isEmpty: Bool {
=======
    var isEmpty : Bool {
>>>>>>> master
        return inserted.isEmpty && deleted.isEmpty && updated.isEmpty && moved.isEmpty
    }
    
    mutating func addChange(forSectionAt source: IndexPath?, with changeType: ResultsControllerChangeType) {
        switch changeType {
        case .delete:
            deleted.insert(source!._section)
        case .update:
            updated.insert(source!._section)
        case let .move(newIndexPath):
            moved.append((source!._section, newIndexPath._section))
        case let .insert(newIndexPath):
            inserted.insert(newIndexPath._section)
        }
    }
    
    mutating func formUnion(with other: SectionChangeSet) {
        self.inserted.formUnion(other.inserted)
        self.deleted.formUnion(other.deleted)
        self.updated.formUnion(other.updated)
    }
    
    mutating func reset() {
        inserted.removeAll()
        deleted.removeAll()
        updated.removeAll()
        moved.removeAll()
    }
}

/// Extension to make easy use of the ItemChangeSet and SectionChangeSet
public extension CollectionView {
    
    /// Apply all changes in a change set to a collection view
    ///
    /// - Parameter changeSet: The change set to apply
    /// - Parameter completion: A close to call when the update finishes
    public func applyChanges(from changeSet: CollectionViewResultsProxy, completion: AnimationCompletion? = nil) {
        guard !changeSet.isEmpty else {
            completion?(true)
            return
        }

        self.performBatchUpdates({
            applyChanges(changeSet.itemUpdates)
            applyChanges(changeSet.sectionUpdates)
        }, completion: completion)
    }
    
    public func applyChanges(_ changes: SectionChangeSet) {
        self.deleteSections(changes.deleted, animated: true)
        self.insertSections(changes.inserted, animated: true)
        self.reloadSupplementaryViews(in: changes.updated, animated: true)
        for m in changes.moved {
            self.moveSection(m.source, to: m.destination, animated: true)
        }
    }
    
    public func applyChanges(_ changes: ItemChangeSet) {
        self.deleteItems(at: Array(changes.deleted), animated: true)
        self.insertItems(at: Array(changes.inserted), animated: true)
        
        for move in changes.moved {
            self.moveItem(at: move.source, to: move.destination, animated: true)
        }
        self.reloadItems(at: Array(changes.updated), animated: true)
    }
    
}
