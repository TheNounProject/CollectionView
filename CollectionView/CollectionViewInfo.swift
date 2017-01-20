//
//  CollectionViewInfo.swift
//  Lingo
//
//  Created by Wesley Byrne on 1/27/16.
//  Copyright © 2016 The Noun Project. All rights reserved.
//

import Foundation



internal struct CollectionViewSectionInfo {
    var section: Int = 0
    var frame : CGRect = CGRect.zero
    var numberOfItems: Int = 0
}

internal final class CollectionViewInfo {
    
    private unowned let collectionView : CollectionView
    private(set) var numberOfSections : Int = 0
    private(set) var sections : [Int: CollectionViewSectionInfo] = [:]
    private(set) var contentSize: CGSize = CGSize.zero
    
    var allIndexPaths = Set<IndexPath>()
    
    init(collectionView: CollectionView) {
        self.collectionView = collectionView
    }
    
    func numberOfItems(in section: Int) -> Int {
        if let count = sections[section]?.numberOfItems { return count }
        return 0
    }
    
    func recalculate() {
        
        self.collectionView.delegate?.collectionViewWillReloadData?(self.collectionView)
        
        let layout = self.collectionView.collectionViewLayout
        var totalNumberOfItems = 0
        self.numberOfSections = self.collectionView.dataSource?.numberOfSectionsInCollectionView(self.collectionView) ?? 0
        if self.numberOfSections > 0 {
            for sIndex in 0..<self.numberOfSections {
                let itemCount = self.collectionView.dataSource?.collectionView(self.collectionView, numberOfItemsInSection: sIndex) ?? 0
                totalNumberOfItems += itemCount
                self.sections[sIndex] = CollectionViewSectionInfo(section: sIndex, frame: CGRect.zero, numberOfItems: itemCount)
            }
        }
        else {
            self.sections = [:]
        }
        
        self.collectionView.collectionViewLayout.prepareLayout()
        if self.sections.count == 0 { return }
        
        self.allIndexPaths = self.collectionView.collectionViewLayout.allIndexPaths
        for sIndex in 0..<self.numberOfSections {
            
            // We're running through all of the items just to find the total size of each section.
            // Although this might seem like a waste, remember that this is only performed each time the
            // collection view is reloaded. The benefits of knowing what area the section encompasses
            // far outweight the cost of effectively running a double-iteration over the data.
            // Additionally, the total size of all of the sections is needed so that we can figure out
            // how large the document view of the collection view needs to be.
            //
            // However, this wastage can be avoided if the collection view layout returns something other
            // than CGRectNull in -rectForSectionAtIndex:, which allows us to bypass this entire section iteration
            // and increase the speed of the layout reloading.
            let potentialSectionFrame = layout.rectForSection(sIndex)
            if !potentialSectionFrame.isEmpty {
                self.sections[sIndex]?.frame = potentialSectionFrame
                continue
            }
            
            let section = self.sections[sIndex];
            if sections[sIndex]?.numberOfItems == 0 { continue }
            
            var sectionFrame = CGRect.null;
            for itemIndex in 0..<section!.numberOfItems {
                let indexPath = IndexPath.for(item:itemIndex, section: sIndex)
                allIndexPaths.insert(indexPath)
                if let attributes = layout.layoutAttributesForItem(at: indexPath) {
                    sectionFrame = sectionFrame.union(attributes.frame);
                }
            }
            for identifier in self.collectionView._allSupplementaryViewIdentifiers {
                if let attributes = layout.layoutAttributesForSupplementaryView(ofKind: identifier.kind, atIndexPath: IndexPath.for(item:0, section: sIndex)) {
                    sectionFrame = sectionFrame.union(attributes.frame)
                }
            }
            self.sections[sIndex]?.frame =  sectionFrame
        }
        self.contentSize = self.calculateContentSize()
    }
    
    
    private func calculateContentSize() -> CGSize {
        var size = self.collectionView.collectionViewLayout.collectionViewContentSize
        if (CGSize.zero.equalTo(size)) {
            var frame = CGRect.null;
            for section in self.sections {
                frame = frame.union(section.1.frame);
            }
            size = frame.size;
        }
        let collectionViewSize = self.collectionView.frame.size;
        
        size.height = max(size.height, collectionViewSize.height - collectionView.contentInsets.top - collectionView.contentInsets.bottom)
        size.width = max(size.width, self.collectionView.contentVisibleRect.size.width - collectionView.contentInsets.left - collectionView.contentInsets.right)
        return size
    }
    
}
