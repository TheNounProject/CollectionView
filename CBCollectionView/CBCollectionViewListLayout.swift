//
//  CBCollectionViewListLayout.swift
//  CBCollectionView
//
//  Created by Wesley Byrne on 6/29/16.
//  Copyright © 2016 Noun Project. All rights reserved.
//

import Foundation

@objc public protocol CBCollectionViewDelegateListLayout: CBCollectionViewDelegate {
    
    optional func collectionView(collectionView: CBCollectionView,layout collectionViewLayout: CBCollectionViewLayout,
                                  heightForItemAtIndexPath indexPath: NSIndexPath) -> CGFloat
    
    optional func collectionView(collectionView: CBCollectionView,layout collectionViewLayout: CBCollectionViewLayout,
                                 interitemSpacingForItemsInSection section: Int) -> CGFloat
    
    optional func collectionView(collectionView: CBCollectionView, layout collectionViewLayout: CBCollectionViewLayout,
                                  heightForHeaderInSection section: Int) -> CGFloat
    
    optional func collectionView(collectionView: CBCollectionView, layout collectionViewLayout: CBCollectionViewLayout,
                                  heightForFooterInSection section: Int) -> CGFloat
    
    optional func collectionView(collectionView: CBCollectionView, layout collectionViewLayout: CBCollectionViewLayout,
                                  insetsForSectionAtIndex section: Int) -> NSEdgeInsets

    
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
    public final var sectionInsets : NSEdgeInsets = NSEdgeInsetsZero { didSet{ invalidateLayout() }}
    
    private var numSections : Int { get { return self.collectionView?.numberOfSections() ?? 0 }}
    
    //  private property and method above.
    private weak var delegate : CBCollectionViewDelegateListLayout? { get{ return self.collectionView!.delegate as? CBCollectionViewDelegateListLayout }}
    
    
    private var sectionIndexPaths : [[NSIndexPath]] = []
    private var sectionItemAttributes : [[CBCollectionViewLayoutAttributes]] = []
    
    private var itemAttributes : [NSIndexPath:CBCollectionViewLayoutAttributes] = [:]
    private var headersAttributes : [Int:CBCollectionViewLayoutAttributes] = [:]
    private var footersAttributes : [Int:CBCollectionViewLayoutAttributes] = [:]
    
    private var sectionFrames : [CGRect] = []
    private var sectionContentFrames : [CGRect] = []
    
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
        
        let numberOfSections = self.numSections
        if numberOfSections == 0 { return }
        
        var top : CGFloat = 0.0
        
        self.sectionItemAttributes = Array(count: numberOfSections, repeatedValue: [])
        
        for section in 0..<numberOfSections {
            
            /*
             * 1. Get section-specific metrics (minimumInteritemSpacing, sectionInset)
             */
            
            
            let sectionInsets :  NSEdgeInsets =  self.delegate?.collectionView?(self.collectionView!, layout: self, insetsForSectionAtIndex: section) ?? self.sectionInsets
            let rowSpacing : CGFloat = self.delegate?.collectionView?(self.collectionView!, layout: self, interitemSpacingForItemsInSection: section) ?? self.interitemSpacing
            
            let itemWidth = self.collectionView!.bounds.size.width - sectionInsets.left - sectionInsets.right
            var sectionFrame: CGRect = CGRect(x: sectionInsets.left, y: top, width: itemWidth, height: 0)
            
            
            /*
             * 2. Section header
             */
            let heightHeader : CGFloat = self.delegate?.collectionView?(self.collectionView!, layout: self, heightForHeaderInSection: section) ?? self.headerHeight
            if heightHeader > 0 {
                let attributes = CBCollectionViewLayoutAttributes(forSupplementaryViewOfKind: CBCollectionViewLayoutElementKind.SectionHeader, withIndexPath: NSIndexPath._indexPathForItem(0, inSection: section))
                attributes.alpha = 1
                attributes.frame = insetSupplementaryViews ?
                    CGRectMake(sectionInsets.left, top, self.collectionView!.bounds.size.width - sectionInsets.left - sectionInsets.right, heightHeader)
                    : CGRectMake(0, top, self.collectionView!.bounds.size.width, heightHeader)
                self.headersAttributes[section] = attributes
                top = CGRectGetMaxY(attributes.frame)
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
                    
                    let ip = NSIndexPath._indexPathForItem(idx, inSection: section)
                    
                    
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
                let attributes = CBCollectionViewLayoutAttributes(forSupplementaryViewOfKind: CBCollectionViewLayoutElementKind.SectionFooter, withIndexPath: NSIndexPath._indexPathForItem(0, inSection: section))
                attributes.alpha = 1
                attributes.frame = insetSupplementaryViews ?
                    CGRectMake(sectionInsets.left, top, self.collectionView!.bounds.size.width - sectionInsets.left - sectionInsets.right, footerHeight)
                    : CGRectMake(0, top, self.collectionView!.bounds.size.width, footerHeight)
                self.footersAttributes[section] = attributes
                top = CGRectGetMaxY(attributes.frame)
            }
            top += sectionInsets.bottom
            
            sectionFrame.size.height = top - sectionFrame.origin.y
            
            
            sectionFrames.append(sectionFrame)
            sectionContentFrames.append(contentRect)
        }
    }
    
    override public func collectionViewContentSize() -> CGSize {
        guard let cv = collectionView else { return CGSizeZero }
        let numberOfSections = self.numSections
        if numberOfSections == 0 { return CGSizeZero }
        
        var size = CGSize()
        size.width = cv.bounds.width
        size.height = cv.bounds.height
        if let f = self.sectionFrames.last {
            size.height = CGRectGetMaxY(f)
        }
        return size
    }
    
    public override func rectForSection(section: Int) -> CGRect {
        return sectionFrames[section]
    }
    
    
    public override func indexPathsForItemsInRect(rect: CGRect) -> Set<NSIndexPath>? {
        //        return nil
        
        var indexPaths = Set<NSIndexPath>()
        guard let cv = self.collectionView else { return nil }
        if CGRectEqualToRect(rect, CGRectZero) || self.numSections == 0 { return indexPaths }
        for sectionIndex in 0..<cv.numberOfSections() {
            
            if cv.numberOfItemsInSection(sectionIndex) == 0 { continue }
            
            let contentFrame = sectionContentFrames[sectionIndex]
            if contentFrame.isEmpty || !contentFrame.intersects(rect) { continue }
            
            // If the section is completely show, add all the attrs
            if rect.contains(contentFrame) {
                indexPaths.unionInPlace(sectionIndexPaths[sectionIndex])
                continue
            }
            
            for attr in sectionItemAttributes[sectionIndex] {
                if attr.frame.intersects(rect) {
                    indexPaths.insert(attr.indexPath)
                }
            }
        }
        return indexPaths
    }
    
    
    
    public override func layoutAttributesForElementsInRect(rect: CGRect) -> [CBCollectionViewLayoutAttributes]? {
        var attrs : [CBCollectionViewLayoutAttributes] = []
        
        guard let cv = self.collectionView else { return nil }
        if CGRectEqualToRect(rect, CGRectZero) || cv.numberOfSections() == 0 { return attrs }
        for sectionIdx in  0..<cv.numberOfSections() {
            
            let contentFrame = self.sectionContentFrames[sectionIdx]
            if contentFrame.isEmpty || !contentFrame.intersects(rect) { continue }
            
            if rect.contains(contentFrame) {
                attrs.appendContentsOf(sectionItemAttributes[sectionIdx])
                continue
            }
            
            for attr in sectionItemAttributes[sectionIdx] {
                if attr.frame.intersects(rect) {
                    attrs.append(attr)
                }
            }
        }
        return attrs
    }
    
    public override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> CBCollectionViewLayoutAttributes? {
        return itemAttributes[indexPath]
    }
    
    public override func layoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> CBCollectionViewLayoutAttributes? {
        
        if elementKind == CBCollectionViewLayoutElementKind.SectionHeader {
            let attrs = self.headersAttributes[indexPath._section]?.copy()
            if pinHeadersToTop, let currentAttrs = attrs, let cv = self.collectionView {
                let contentOffset = cv.contentOffset
                let frame = currentAttrs.frame
                
                var nextHeaderOrigin = CGPoint(x: CGFloat.max, y: CGFloat.max)
                if let nextHeader = self.headersAttributes[indexPath._section + 1] {
                    nextHeaderOrigin = nextHeader.frame.origin
                }
                let topInset = cv.contentInsets.top ?? 0
                currentAttrs.frame.origin.y =  min(max(contentOffset.y + topInset , frame.origin.y), nextHeaderOrigin.y - CGRectGetHeight(frame))
                currentAttrs.floating = currentAttrs.frame.origin.y > frame.origin.y
            }
            return attrs
        }
        else if elementKind == CBCollectionViewLayoutElementKind.SectionFooter {
            return self.footersAttributes[indexPath._section]
        }
        return nil
    }
    
    private var _cvSize = CGSizeZero
    override public func shouldInvalidateLayoutForBoundsChange (newBounds : CGRect) -> Bool {
        if !CGSizeEqualToSize(newBounds.size, self._cvSize) {
            self._cvSize = newBounds.size
            return true
        }
        return false
    }
    
    
    public override func scrollRectForItemAtIndexPath(indexPath: NSIndexPath, atPosition: CBCollectionViewScrollPosition) -> CGRect? {
        guard var frame = self.layoutAttributesForItemAtIndexPath(indexPath)?.frame else { return nil }
        if self.pinHeadersToTop, let attrs = self.layoutAttributesForSupplementaryViewOfKind(CBCollectionViewLayoutElementKind.SectionHeader, atIndexPath: NSIndexPath._indexPathForItem(0, inSection: indexPath._section)) {
            var y = frame.origin.y - attrs.frame.size.height
            var height = frame.size.height + attrs.frame.size.height
            frame.size.height = height
            frame.origin.y = y
        }
        return frame
    }
    
    
    
    
    public override func indexPathForNextItemInDirection(direction: CBCollectionViewDirection, afterItemAtIndexPath currentIndexPath: NSIndexPath) -> NSIndexPath? {
        guard let collectionView = self.collectionView else { fatalError() }
        
        var index = currentIndexPath._item
        var section = currentIndexPath._section
        
        let numberOfSections = self.numSections
        let numberOfItemsInSection = collectionView.numberOfItemsInSection(currentIndexPath._section)
        
        guard let cellRect = collectionView.rectForItemAtIndexPath(currentIndexPath) else { return nil }
        let cellHeight = cellRect.height
        
        switch direction {
        case .Up, .Left:
            
            if currentIndexPath._item > 0 {
                return NSIndexPath._indexPathForItem(currentIndexPath._item - 1, inSection: currentIndexPath._section)
            }
            else if currentIndexPath._section == 0 {
                return nil
            }
            
            var ip : NSIndexPath?
            var section = currentIndexPath._section - 1
            while ip == nil && section >= 0 {
                if let _ip = self.sectionIndexPaths[section].last {
                    ip = _ip
                    break
                }
                section -= 1
            }
            return ip
            
        case .Down, .Right:
            
            if currentIndexPath._item < self.sectionIndexPaths[currentIndexPath._section].count - 1 {
                return NSIndexPath._indexPathForItem(currentIndexPath._item + 1, inSection: currentIndexPath._section)
            }
            else if currentIndexPath._section == numberOfSections - 1 {
                return nil
            }
            
            var ip : NSIndexPath?
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


