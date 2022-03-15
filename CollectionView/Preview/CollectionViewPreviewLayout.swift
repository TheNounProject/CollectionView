//
//  PreviewCollectionViewLayout.swift
//  Lingo
//
//  Created by Wesley Byrne on 12/15/16.
//  Copyright © 2016 The Noun Project. All rights reserved.
//

import Foundation

protocol CollectionViewDelegatePreviewLayout: AnyObject {
    func previewLayout(_ layout: CollectionViewPreviewLayout, canPreviewItemAt indexPath: IndexPath) -> Bool
}

public final class CollectionViewPreviewLayout: NSObject, CollectionViewLayout {
    public var collectionView: CollectionView?
    
    public var allIndexPaths: OrderedSet<IndexPath> = []
    
    public var scrollDirection: CollectionViewScrollDirection { return .horizontal }
    
    // MARK: - Default layout values
    
    /// The vertical spacing between items in the same column
    public var interItemSpacing: CGFloat = 8 { didSet { invalidate() }}
    
    private var numSections: Int { return self.collectionView?.numberOfSections ?? 0 }
    private var sections = [Section]()
    
    private struct Section {
        var frame = CGRect.null
        var itemAttributes = [CollectionViewLayoutAttributes?]()
    }
    
    var usableIndexPaths = OrderedSet<IndexPath>()
    
    public func invalidate() {
        _cvSize = collectionView?.bounds.size ?? CGSize.zero
    }
    
    var delegate: CollectionViewDelegatePreviewLayout? {
        return self.collectionView?.delegate as? CollectionViewDelegatePreviewLayout
    }
    
    var contentWidth: CGFloat = 0
    
    public func prepare() {
        
        self.allIndexPaths.removeAll()
        self.sections.removeAll()
        self.usableIndexPaths.removeAll()
        
        self.contentWidth = 0
        
        let numberOfSections = self.numSections
        if numberOfSections == 0 { return }
        
        var left: CGFloat = 0.0
        let yPos: CGFloat = 0
        
        let contentInsets = self.collectionView?.contentInsets ?? NSEdgeInsetsZero
        
        for sectionIdx in 0..<numberOfSections {
            
            let itemHeight = self.collectionView!.contentVisibleRect.size.height - contentInsets.top - contentInsets.bottom
            let itemWidth = self.collectionView!.contentVisibleRect.size.width
            let itemSize = CGSize(width: itemWidth, height: itemHeight)
            
            var section = Section()
            
//            var sectionFrame: CGRect = CGRect(x: left, y: 0, width: 0, height: itemSize.height)
            let itemCount = self.collectionView!.numberOfItems(in: sectionIdx)
            
            if itemCount > 0 {
                
                for idx in 0..<itemCount {
                    
                    let ip = IndexPath.for(item: idx, section: sectionIdx)
                    allIndexPaths.append(ip)
                    
                    guard self.delegate?.previewLayout(self, canPreviewItemAt: ip) != false else {
                        section.itemAttributes.append(nil)
                        continue
                    }
                    self.usableIndexPaths.append(ip)
                    
                    let attrs = CollectionViewLayoutAttributes(forCellWith: ip)
                    attrs.frame = NSRect(x: left, y: yPos, width: itemSize.width, height: itemSize.height)
                    section.frame = section.frame.union(attrs.frame)
                    section.itemAttributes.append(attrs)
                    
                    left = attrs.frame.maxX + interItemSpacing
                }
            }
            sections.append(section)
        }
        contentWidth = left
    }
    
    public var collectionViewContentSize: CGSize {
        guard let cv = collectionView else { return CGSize.zero }
        let numberOfSections = self.numSections
        if numberOfSections == 0 { return CGSize.zero }
        
        var size = CGSize()
        size.width = contentWidth
        size.height = cv.contentVisibleRect.size.height - (cv.contentInsets.top + cv.contentInsets.bottom)
        return size
    }
    
    public func rectForSection(_ section: Int) -> CGRect {
        return sections[section].frame
    }
    
    public func indexPathsForItems(in rect: CGRect) -> [IndexPath] {
        
        guard !rect.isEmpty && !sections.isEmpty else { return [] }
        
        var indexPaths = [IndexPath]()
        for sectionIdx in 0..<sections.count {
            
            guard !sections[sectionIdx].itemAttributes.isEmpty
                && sections[sectionIdx].frame.intersects(rect) else { continue }
            
            for attr in sections[sectionIdx].itemAttributes {
                if let f = attr?.frame {
                    if f.intersects(rect) {
                        indexPaths.append(attr!.indexPath)
                    } else if f.minX > rect.maxX {
                        // If we are past the check region, we can return
                        break
                    }
                }
            }
        }
        return indexPaths
    }
    
    public func layoutAttributesForItems(in rect: CGRect) -> [CollectionViewLayoutAttributes] {
        
        guard !rect.isEmpty && !sections.isEmpty else { return [] }
        
        var result: [CollectionViewLayoutAttributes] = []
        
        for sectionIdx in  0..<sections.count {
            
            guard !sections[sectionIdx].itemAttributes.isEmpty,
                sections[sectionIdx].frame.intersects(rect) else { continue }
            
            for attr in sections[sectionIdx].itemAttributes {
                if let f = attr?.frame {
                    if f.intersects(rect) {
                        result.append(attr!)
                    } else if f.minX > rect.maxX {
                        // If we are past the check region, we can return
                        break
                    }
                }
            }
        }
        return result
    }
    
    public func layoutAttributesForItem(at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
        let a = self.sections.object(at: indexPath._section)?.itemAttributes.object(at: indexPath._item)
        return a!
    }
    
    fileprivate var _cvSize = CGSize.zero
    public func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if !newBounds.size.equalTo(self._cvSize) {
            self._cvSize = newBounds.size
            return true
        }
        return false
    }
    
    public func scrollRectForItem(at indexPath: IndexPath, atPosition: CollectionViewScrollPosition) -> CGRect? {
        return self.layoutAttributesForItem(at: indexPath)?.frame
    }
    
    public func indexPathForNextItem(moving direction: CollectionViewDirection, from currentIndexPath: IndexPath) -> IndexPath? {

        switch direction {
        case .up, .left:
            return self.usableIndexPaths.object(before: currentIndexPath)
            
        case .down, .right:
            return self.usableIndexPaths.object(after: currentIndexPath)
        }
        
    }
    
    public func layoutAttributesForSupplementaryView(ofKind kind: String, at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
        return nil
    }
    
}
