//
//  CollectionViewHorizontalLayout.swift
//  Lingo
//
//  Created by Wesley Byrne on 3/1/16.
//  Copyright © 2016 The Noun Project. All rights reserved.
//

import Foundation

/// The delegate for CollectionViewHorizontalListLayout
@objc public protocol CollectionViewDelegateHorizontalListLayout: CollectionViewDelegate {
    
    /**
    Asks the delegate for the width of the item at a given index path

     - Parameter collectionView: The collection view containing the item
     - Parameter collectionViewLayout: The layout
     - Parameter indexPath: The index path for the item
     
     - Returns: The desired width of the item at indexPath
     
     */
    @objc optional func collectionView (_ collectionView: CollectionView,
                                        layout collectionViewLayout: CollectionViewLayout,
                                        widthForItemAt indexPath: IndexPath) -> CGFloat
}

/// A full height horizontal scrolling layout 
open class CollectionViewHorizontalListLayout: CollectionViewLayout {
    
    override open var scrollDirection: CollectionViewScrollDirection {
        return CollectionViewScrollDirection.horizontal
    }
    
    private var delegate: CollectionViewDelegateHorizontalListLayout? {
        return self.collectionView?.delegate as? CollectionViewDelegateHorizontalListLayout
    }
    
    open var sectionInsets = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    open var itemWidth: CGFloat = 100
    open var itemSpacing: CGFloat = 8
    
    var cache: [CGRect] = []
    var contentWidth: CGFloat = 0
    
    open override func prepare() {
        cache = []
        self.allIndexPaths.removeAll()
        
        guard let cv = self.collectionView else { return }
        
        let numSections = cv.numberOfSections
        assert(numSections <= 1, "Horizontal collection view cannot have more than 1 section")
        
        if numSections == 0 { return }
        let numRows = cv.numberOfItems(in: 0)
        if numRows == 0 { return }
        
        var xPos: CGFloat = sectionInsets.left - self.itemSpacing
        
        for row in 0..<numRows {
            
            let ip = IndexPath.for(item: row, section: 0)
            self.allIndexPaths.append(ip)
            var height = cv.bounds.height 
            height -= sectionInsets.height
            
            let width = self.delegate?.collectionView?(cv, layout: self, widthForItemAt: ip) ?? itemWidth
            
            var x = xPos
            x += self.itemSpacing
            
            let frame = CGRect(x: x, y: sectionInsets.top, width: width, height: height)
            
            cache.append(frame)
            xPos = x + width
        }
        
        contentWidth = xPos + sectionInsets.right
    }
    
    var _size = CGSize.zero
    open override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if !newBounds.size.equalTo(_size) {
            self._size = newBounds.size
            return true
        }
        return false
    }
    
    open override var collectionViewContentSize: CGSize {
        let numberOfSections = self.collectionView!.numberOfSections
        if numberOfSections == 0 {
            return CGSize.zero
        }
        var contentSize = self.collectionView!.bounds.size as CGSize
        contentSize.width = contentWidth
        return  contentSize
    }
    
    open override func scrollRectForItem(at indexPath: IndexPath, atPosition: CollectionViewScrollPosition) -> CGRect? {
        return layoutAttributesForItem(at: indexPath)?.frame
    }
    
    open override func rectForSection(_ section: Int) -> CGRect {
        guard let cv = self.collectionView else { return CGRect.zero }
        let size = self.collectionViewContentSize
        return CGRect(x: cv.contentInsets.left, y: 0, width: size.width, height: size.height)
    }
    open override func contentRectForSection(_ section: Int) -> CGRect {
        return rectForSection(section)
    }
    
    open override func indexPathsForItems(in rect: CGRect) -> [IndexPath] {
        var ips = [IndexPath]()
        for idx in 0..<cache.count {
            if rect.intersects(cache[idx]) {
                let ip = IndexPath.for(item: idx, section: 0)
                ips.append(ip)
            }
        }
        return ips
    }
    
    open override func layoutAttributesForItem(at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
        let attrs = CollectionViewLayoutAttributes(forCellWith: indexPath)
        attrs.alpha = 1
        attrs.zIndex = 1000
        
        let frame = cache[indexPath._item]
        attrs.frame = frame
        return attrs
    }
}

open class HorizontalCollectionView: CollectionView {
    
    override public init() {
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
