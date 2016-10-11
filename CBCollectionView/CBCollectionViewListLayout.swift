//
//  CBCollectionViewListLayout.swift
//  CBCollectionView
//
//  Created by Wesley Byrne on 6/29/16.
//  Copyright © 2016 Noun Project. All rights reserved.
//

import Foundation

@objc public protocol CBCollectionViewDelegateListLayout: CBCollectionViewDelegate {
    
    @objc optional func collectionView(_ collectionView: CBCollectionView,layout collectionViewLayout: CBCollectionViewLayout,
                                  heightForItemAtIndexPath indexPath: IndexPath) -> CGFloat
    
    @objc optional func collectionView(_ collectionView: CBCollectionView,layout collectionViewLayout: CBCollectionViewLayout,
                                 interitemSpacingForItemsInSection section: Int) -> CGFloat
    
    @objc optional func collectionView(_ collectionView: CBCollectionView, layout collectionViewLayout: CBCollectionViewLayout,
                                  heightForHeaderInSection section: Int) -> CGFloat
    
    @objc optional func collectionView(_ collectionView: CBCollectionView, layout collectionViewLayout: CBCollectionViewLayout,
                                  heightForFooterInSection section: Int) -> CGFloat
    
    @objc optional func collectionView(_ collectionView: CBCollectionView, layout collectionViewLayout: CBCollectionViewLayout,
                                  insetsForSectionAtIndex section: Int) -> EdgeInsets

    
}


/// A feature packed collection view layout with pinterest like layouts, aspect ratio sizing, and drag and drop.
public final class CBCollectionViewListLayout : CBCollectionViewLayout  {
    
    //MARK: - Default layout values
    
    /// The vertical spacing between items in the same column
    public final var interitemSpacing : CGFloat = 0 { didSet{ invalidateLayout() }}
    
    /// The vertical spacing between items in the same column
    public final var itemHeight : CGFloat = 36 { didSet{ invalidateLayout() }}
    
    /// The height of section header views
    public final var headerHeight : CGFloat = 0.0 { didSet{ invalidateLayout() }}
    
    /// The height of section footer views
    public final var footerHeight : CGFloat = 0.0 { didSet{ invalidateLayout() }}
    
    /// If supplementary views should respect section insets or fill the CollectionView width
    public final var insetSupplementaryViews : Bool = false { didSet{ invalidateLayout() }}
    
    /// Default insets for all sections
    public final var sectionInsets : EdgeInsets = NSEdgeInsetsZero { didSet{ invalidateLayout() }}
    
    fileprivate var numSections : Int { get { return self.collectionView?.numberOfSections() ?? 0 }}
    
    //  private property and method above.
    fileprivate weak var delegate : CBCollectionViewDelegateListLayout? { get{ return self.collectionView!.delegate as? CBCollectionViewDelegateListLayout }}
    
    
    fileprivate var sectionIndexPaths : [[IndexPath]] = []
    fileprivate var sectionItemAttributes : [[CBCollectionViewLayoutAttributes]] = []
    
    fileprivate var itemAttributes : [IndexPath:CBCollectionViewLayoutAttributes] = [:]
    fileprivate var headersAttributes : [Int:CBCollectionViewLayoutAttributes] = [:]
    fileprivate var footersAttributes : [Int:CBCollectionViewLayoutAttributes] = [:]
    
    fileprivate var sectionFrames : [CGRect] = []
    fileprivate var sectionContentFrames : [CGRect] = []
    
    override public init() {
        super.init()
    }
    
    override public func prepareLayout(){
        super.prepareLayout()
        
        self.allIndexPaths.removeAll()
        self.sectionIndexPaths.removeAll()
        self.sectionItemAttributes.removeAll()
        self.headersAttributes.removeAll()
        self.footersAttributes.removeAll()
        self.itemAttributes.removeAll()
        self.sectionFrames.removeAll()
        self.sectionContentFrames.removeAll()
        
        let numberOfSections = self.numSections
        if numberOfSections == 0 { return }
        
        var top : CGFloat = 0.0
        
        self.sectionItemAttributes = Array(repeating: [], count: numberOfSections)
        
        for section in 0..<numberOfSections {
            
            /*
             * 1. Get section-specific metrics (minimumInteritemSpacing, sectionInset)
             */
            
            let sectionInsets :  EdgeInsets =  self.delegate?.collectionView?(self.collectionView!, layout: self, insetsForSectionAtIndex: section) ?? self.sectionInsets
            let rowSpacing : CGFloat = self.delegate?.collectionView?(self.collectionView!, layout: self, interitemSpacingForItemsInSection: section) ?? self.interitemSpacing
            
            let itemWidth = self.collectionView!.contentVisibleRect.size.width - sectionInsets.left - sectionInsets.right
            var sectionFrame: CGRect = CGRect(x: sectionInsets.left, y: top, width: itemWidth, height: 0)
            
            
            /*
             * 2. Section header
             */
            let heightHeader : CGFloat = self.delegate?.collectionView?(self.collectionView!, layout: self, heightForHeaderInSection: section) ?? self.headerHeight
            if heightHeader > 0 {
                let attributes = CBCollectionViewLayoutAttributes(forSupplementaryViewOfKind: CBCollectionViewLayoutElementKind.SectionHeader, withIndexPath: IndexPath._indexPathForItem(0, inSection: section))
                attributes.alpha = 1
                attributes.frame = insetSupplementaryViews ?
                    CGRect(x: sectionInsets.left, y: top, width: self.collectionView!.bounds.size.width - sectionInsets.left - sectionInsets.right, height: heightHeader)
                    : CGRect(x: 0, y: top, width: self.collectionView!.bounds.size.width, height: heightHeader)
                self.headersAttributes[section] = attributes
                top = attributes.frame.maxY
            }
            
            top += sectionInsets.top
            
            
            
            /*
             * 3. Section items
             */
            
            var contentRect: CGRect = CGRect(x: sectionInsets.left, y: top, width: itemWidth, height: 0)
            let itemCount = self.collectionView!.numberOfItemsInSection(section)
            
            // Add the ip and attr arrays for the section, they are filled in below
            self.sectionIndexPaths.append([])
            self.sectionItemAttributes.append([])
            
            if itemCount > 0 {
                var xPos = contentRect.origin.x
                var yPos = contentRect.origin.y
                
                var newTop : CGFloat = 0
                
                for idx in 0..<itemCount {
                    
                    let ip = IndexPath._indexPathForItem(idx, inSection: section)
                    allIndexPaths.insert(ip)
                    
                    let attrs = CBCollectionViewLayoutAttributes(forCellWithIndexPath: ip)
                    var rowHeight : CGFloat = self.delegate?.collectionView?(self.collectionView!, layout: self, heightForItemAtIndexPath: ip) ?? self.itemHeight
                    attrs.frame = NSRect(x: xPos, y: yPos, width: itemWidth, height: rowHeight)
                    newTop = yPos + rowHeight
                    yPos = newTop + rowSpacing
                    
                    self.sectionIndexPaths[section].append(ip)
                    self.sectionItemAttributes[section].append(attrs)
                    self.itemAttributes[ip] = attrs
                }
                top = newTop
            }
            contentRect.size.height = top - contentRect.origin.y
            
            let footerHeight = self.delegate?.collectionView?(self.collectionView!, layout: self, heightForFooterInSection: section) ?? self.footerHeight
            if footerHeight > 0 {
                let attributes = CBCollectionViewLayoutAttributes(forSupplementaryViewOfKind: CBCollectionViewLayoutElementKind.SectionFooter, withIndexPath: IndexPath._indexPathForItem(0, inSection: section))
                attributes.alpha = 1
                attributes.frame = insetSupplementaryViews ?
                    CGRect(x: sectionInsets.left, y: top, width: self.collectionView!.bounds.size.width - sectionInsets.left - sectionInsets.right, height: footerHeight)
                    : CGRect(x: 0, y: top, width: self.collectionView!.bounds.size.width, height: footerHeight)
                self.footersAttributes[section] = attributes
                top = attributes.frame.maxY
            }
            top += sectionInsets.bottom
            
            sectionFrame.size.height = top - sectionFrame.origin.y
            
            
            sectionFrames.append(sectionFrame)
            sectionContentFrames.append(contentRect)
        }
    }
    
    override public func collectionViewContentSize() -> CGSize {
        guard let cv = collectionView else { return CGSize.zero }
        let numberOfSections = self.numSections
        if numberOfSections == 0 { return CGSize.zero }
        
        var size = CGSize()
        size.width = cv.contentVisibleRect.size.width
        size.height = cv.bounds.height
        if let f = self.sectionFrames.last {
            size.height = f.maxY
        }
        return size
    }
    
    public override func rectForSection(_ section: Int) -> CGRect {
        return sectionFrames[section]
    }
    
    
    public override func indexPathsForItemsInRect(_ rect: CGRect) -> Set<IndexPath>? {
        //        return nil
        
        var indexPaths = Set<IndexPath>()
        guard let cv = self.collectionView else { return nil }
        if rect.isEmpty || self.numSections == 0 { return indexPaths }
        for sectionIndex in 0..<cv.numberOfSections() {
            
            if cv.numberOfItemsInSection(sectionIndex) == 0 { continue }
            
            let contentFrame = sectionContentFrames[sectionIndex]
            if contentFrame.isEmpty || !contentFrame.intersects(rect) { continue }
            
            // If the section is completely show, add all the attrs
            if rect.contains(contentFrame) {
                indexPaths.formUnion(sectionIndexPaths[sectionIndex])
                continue
            }
            
            for attr in sectionItemAttributes[sectionIndex] {
                if attr.frame.intersects(rect) {
                    indexPaths.insert(attr.indexPath as IndexPath)
                }
            }
        }
        return indexPaths
    }
    
    
    
    public override func layoutAttributesForElementsInRect(_ rect: CGRect) -> [CBCollectionViewLayoutAttributes]? {
        var attrs : [CBCollectionViewLayoutAttributes] = []
        
        guard let cv = self.collectionView else { return nil }
        if rect.isEmpty || cv.numberOfSections() == 0 { return attrs }
        for sectionIdx in  0..<cv.numberOfSections() {
            
            let contentFrame = self.sectionContentFrames[sectionIdx]
            if contentFrame.isEmpty || !contentFrame.intersects(rect) { continue }
            
            let containsAll = rect.contains(contentFrame)
//            if  {
//                attrs.appendContentsOf(sectionItemAttributes[sectionIdx])
//                continue
//            }
            
            for attr in sectionItemAttributes[sectionIdx] {
                if containsAll || attr.frame.intersects(rect) {
                    attrs.append(attr.copy())
                }
            }
        }
        return attrs
    }
    
    public override func layoutAttributesForItemAtIndexPath(_ indexPath: IndexPath) -> CBCollectionViewLayoutAttributes? {
        return itemAttributes[indexPath]?.copy()
    }
    
    public override func layoutAttributesForSupplementaryViewOfKind(_ elementKind: String, atIndexPath indexPath: IndexPath) -> CBCollectionViewLayoutAttributes? {
        
        if elementKind == CBCollectionViewLayoutElementKind.SectionHeader {
            let attrs = self.headersAttributes[indexPath._section]?.copy()
            if pinHeadersToTop, let currentAttrs = attrs, let cv = self.collectionView {
                let contentOffset = cv.contentOffset
                let frame = currentAttrs.frame
                
                var nextHeaderOrigin = CGPoint(x: CGFloat.greatestFiniteMagnitude, y: CGFloat.greatestFiniteMagnitude)
                if let nextHeader = self.headersAttributes[indexPath._section + 1] {
                    nextHeaderOrigin = nextHeader.frame.origin
                }
                let topInset = cv.contentInsets.top ?? 0
                currentAttrs.frame.origin.y =  min(max(contentOffset.y + topInset , frame.origin.y), nextHeaderOrigin.y - frame.height)
                currentAttrs.floating = currentAttrs.frame.origin.y > frame.origin.y
            }
            return attrs
        }
        else if elementKind == CBCollectionViewLayoutElementKind.SectionFooter {
            return self.footersAttributes[indexPath._section]
        }
        return nil
    }
    
    fileprivate var _cvSize = CGSize.zero
    override public func shouldInvalidateLayoutForBoundsChange (_ newBounds : CGRect) -> Bool {
        if !newBounds.size.equalTo(self._cvSize) {
            self._cvSize = newBounds.size
            return true
        }
        return false
    }
    
    
    public override func scrollRectForItemAtIndexPath(_ indexPath: IndexPath, atPosition: CBCollectionViewScrollPosition) -> CGRect? {
        guard var frame = self.layoutAttributesForItemAtIndexPath(indexPath)?.frame else { return nil }
        if self.pinHeadersToTop, let attrs = self.layoutAttributesForSupplementaryViewOfKind(CBCollectionViewLayoutElementKind.SectionHeader, atIndexPath: IndexPath._indexPathForItem(0, inSection: indexPath._section)) {
            var y = frame.origin.y - attrs.frame.size.height
            var height = frame.size.height + attrs.frame.size.height
            frame.size.height = height
            frame.origin.y = y
        }
        return frame
    }
    
    
    
    
    public override func indexPathForNextItemInDirection(_ direction: CBCollectionViewDirection, afterItemAtIndexPath currentIndexPath: IndexPath) -> IndexPath? {
        guard let collectionView = self.collectionView else { fatalError() }
        
        var index = currentIndexPath._item
        var section = currentIndexPath._section
        
        let numberOfSections = self.numSections
        let numberOfItemsInSection = collectionView.numberOfItemsInSection(currentIndexPath._section)
        
        guard let cellRect = collectionView.rectForItemAtIndexPath(currentIndexPath) else { return nil }
        let cellHeight = cellRect.height
        
        switch direction {
        case .up, .left:
            
            if currentIndexPath._item > 0 {
                return IndexPath._indexPathForItem(currentIndexPath._item - 1, inSection: currentIndexPath._section)
            }
            else if currentIndexPath._section == 0 {
                return nil
            }
            
            var ip : IndexPath?
            var section = currentIndexPath._section - 1
            while ip == nil && section >= 0 {
                if let _ip = self.sectionIndexPaths[section].last {
                    ip = _ip
                    break
                }
                section -= 1
            }
            return ip
            
        case .down, .right:
            if currentIndexPath._item < self.sectionIndexPaths[currentIndexPath._section].count - 1 {
                return IndexPath._indexPathForItem(currentIndexPath._item + 1, inSection: currentIndexPath._section)
            }
            else if currentIndexPath._section == numberOfSections - 1 {
                return nil
            }
            
            var ip : IndexPath?
            var section = currentIndexPath._section + 1
            while ip == nil && section <= numberOfSections {
                if let _ip = self.sectionIndexPaths[section].first {
                    ip = _ip
                    break
                }
                section += 1
            }
            return ip
        }
        
    }
    
}


