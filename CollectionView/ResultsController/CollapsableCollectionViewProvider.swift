//
//  CollapsableCollectionViewProvider.swift
//  CollectionView
//
//  Created by Wesley Byrne on 4/2/18.
//  Copyright © 2018 Noun Project. All rights reserved.
//

import Foundation

public class CollapsableCollectionViewProvider: CollectionViewResultsProxy {
    
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
    
    /// If true, a cell will be inserted when a section becomes empty
    ///
    /// ## Discussion
    /// When displaying sections within a CollectionView, it can be helpful to fill empty sections with a placholder cell. This causes an issue when responding to updates from a results controller. For example, when an object is inserted into an empty section, the results controller will report a single insert change. The CollectionView though would need to remove the exisitng cell AND insert the new one.
    ///
    /// Setting hasEmptySectionPlaceholders to true, will report changes as such, making it easy to propagate the reported changes to a CollectionView.
    public var populateEmptySections = false
    
    /// If true, a cell will be inserted when a collection view becomes completely empty
    ///
    /// ## Discussion
    /// When displaying sections within a CollectionView, it can be helpful to display a cell representing the empty state. This causes an issue when responding to updates from a results controller. For example, when the last section is removed from a data source (i.e. ResultsController), the controller will report a single remove change. The CollectionView though would need to remove those cells AND insert the new one to act as the palceholder.
    ///
    /// Setting populateWhenEmpty to true, will report changes as such, making it easy to propagate the reported changes to a CollectionView.
    public var populateWhenEmpty = false
}

// MARK: - Results Controller Delegate
/*-------------------------------------------------------------------------------*/
extension CollapsableCollectionViewProvider: ResultsControllerDelegate {
    
    public func controllerDidLoadContent(controller: ResultsController) {
        self.sectionCount = controller.numberOfSections
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
        if self.populateWhenEmpty {
            let isEmpty = controller.numberOfSections == 0
            let wasEmpty = self.sectionCount == 0
            if !wasEmpty && isEmpty {
                // populate
                self.addChange(forSectionAt: nil, with: .insert(IndexPath.zero))
            } else if wasEmpty && !isEmpty {
                // Remove placeholder
                self.addChange(forSectionAt: IndexPath.zero, with: .delete)
            }
        } else if self.populateEmptySections && controller.numberOfSections > 0 {
            
        }
        let completion = self.delegate?.providerDidChangeContent(self)
        self.collectionView.applyChanges(from: self, completion: completion)
    }
}
