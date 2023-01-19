//
//  CollectionViewHorizontalLayout.swift
//  Lingo
//
//  Created by Wesley Byrne on 3/1/16.
//  Copyright © 2016 The Noun Project. All rights reserved.
//

import Foundation

/// The delegate for CollectionViewHorizontalListLayout
public protocol CollectionViewDelegateHorizontalListLayout: CollectionViewDelegate {
    
    /// Asks the delegate for the width of the item at a given index path
    ///
    /// - Parameter collectionView: The collection view containing the item
    /// - Parameter collectionViewLayout: The layout
    /// - Parameter indexPath: The index path for the item
    ///
    /// - Returns: The desired width of the item at indexPath
    func collectionView (_ collectionView: CollectionView,
                         layout collectionViewLayout: CollectionViewHorizontalListLayout,
                         widthForItemAt indexPath: IndexPath) -> CGFloat
}

public extension CollectionViewDelegateHorizontalListLayout {
    func collectionView (_ collectionView: CollectionView,
                         layout collectionViewLayout: CollectionViewHorizontalListLayout,
                         widthForItemAt indexPath: IndexPath) -> CGFloat {
        return collectionViewLayout.itemWidth
    }
}

/// A full height horizontal scrolling layout 
open class CollectionViewHorizontalListLayout: CollectionViewLayout {
    public var collectionView: CollectionView?
    
    public var allIndexPaths = OrderedSet<IndexPath>()
    
    open var scrollDirection: CollectionViewScrollDirection {
        return CollectionViewScrollDirection.horizontal
    }
    
    private var delegate: CollectionViewDelegateHorizontalListLayout? {
        return self.collectionView?.delegate as? CollectionViewDelegateHorizontalListLayout
    }
    
    open var sectionInsets = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    open var itemWidth: CGFloat = 100
    open var itemSpacing: CGFloat = 8
    
    public var centerContent: Bool = false
    
    var cache = [[CGRect]]()
    var contentWidth: CGFloat = 0
    
    public init() { }
    
    public func invalidate() {
        
    }
    
    open func prepare() {
        cache = []
        self.allIndexPaths.removeAll()
        
        guard let cv = self.collectionView else { return }
        
        let numSections = cv.numberOfSections
        var xPos: CGFloat = 0
        
        for sectionIdx in 0..<numSections {
            xPos += sectionInsets.left
            
            var items = [CGRect]()
            let numItems = cv.numberOfItems(in: sectionIdx)
            for idx in 0..<numItems {
                let ip = IndexPath.for(item: idx, section: sectionIdx)
                self.allIndexPaths.append(ip)
                var height = cv.bounds.height
                height -= sectionInsets.height
                
                let width = self.delegate?.collectionView(cv, layout: self, widthForItemAt: ip) ?? itemWidth
                
                var x = xPos
                if !items.isEmpty {
                    x += self.itemSpacing
                }
                
                let frame = CGRect(x: x, y: sectionInsets.top, width: width, height: height).integral
                
                items.append(frame)
                xPos = x + width
            }
            self.cache.append(items)
        }
        contentWidth = xPos + sectionInsets.right
        
        let cvWidth = cv.contentVisibleRect.width
        if contentWidth < cvWidth {
            let adjust = (cvWidth - contentWidth)/2

            self.cache = self.cache.map { sec in
                return sec.map { $0.offsetBy(dx: adjust, dy: 0) }
            }
            self.contentWidth += adjust
        }
    }
    
    var _size = CGSize.zero
    open func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if !newBounds.size.equalTo(_size) {
            self._size = newBounds.size
            return true
        }
        return false
    }
    
    open var collectionViewContentSize: CGSize {
        let numberOfSections = self.collectionView!.numberOfSections
        if numberOfSections == 0 {
            return CGSize.zero
        }
        var contentSize = self.collectionView!.bounds.size as CGSize
        contentSize.width = contentWidth
        return  contentSize
    }
    
    open func scrollRectForItem(at indexPath: IndexPath, atPosition: CollectionViewScrollPosition) -> CGRect? {
        return layoutAttributesForItem(at: indexPath)?.frame
    }
    
    open func rectForSection(_ section: Int) -> CGRect {
        guard let sectionItems = self.cache.object(at: section), !sectionItems.isEmpty else { return CGRect.zero }
        return sectionItems.reduce(CGRect.null) { partialResult, rect in
            return partialResult.union(rect)
        }
    }
    open func contentRectForSection(_ section: Int) -> CGRect {
        return rectForSection(section)
    }
    
    open func indexPathsForItems(in rect: CGRect) -> [IndexPath] {
        var ips = [IndexPath]()
        
        for (sectionIdx, section) in cache.enumerated() {
            for (idx, item) in section.enumerated() where rect.intersects(item) {
                let ip = IndexPath.for(item: idx, section: sectionIdx)
                ips.append(ip)
            }
        }
        return ips
    }
    
    open func layoutAttributesForItem(at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
        let attrs = CollectionViewLayoutAttributes(forCellWith: indexPath)
        attrs.alpha = 1
        attrs.zIndex = 1000
        
        let frame = cache[indexPath._section][indexPath._item]
        attrs.frame = frame
        return attrs
    }
    
    public func layoutAttributesForSupplementaryView(ofKind kind: String, at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
        return nil
    }
    
    public func indexPathForNextItem(moving direction: CollectionViewDirection, from currentIndexPath: IndexPath) -> IndexPath? {
        return nil
    }
}

open class HorizontalCollectionView: CollectionView {
    
    public override init() {
        super.init()
        self.hasVerticalScroller = false
        self.hasHorizontalScroller = false
    }
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.hasVerticalScroller = false
        self.hasHorizontalScroller = false
    }
}
