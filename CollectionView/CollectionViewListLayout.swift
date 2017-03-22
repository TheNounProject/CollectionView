//
//  CollectionViewListLayout.swift
//  CollectionView
//
//  Created by Wesley Byrne on 6/29/16.
//  Copyright © 2016 Noun Project. All rights reserved.
//

import Foundation



/**
 CollectionViewDelegateListLayout
*/
@objc public protocol CollectionViewDelegateListLayout: CollectionViewDelegate {
    
    /**
     <#Description#>

     - Parameter collectionView: <#collectionView description#>
     - Parameter collectionViewLayout: <#collectionViewLayout description#>
     - Parameter indexPath: <#indexPath description#>
     
     - Returns: <#CGFloat return description#>

    */
    @objc optional func collectionView(_ collectionView: CollectionView,layout collectionViewLayout: CollectionViewLayout,
                                  heightForItemAt indexPath: IndexPath) -> CGFloat
    
    /**
     <#Description#>

     - Parameter collectionView: <#collectionView description#>
     - Parameter collectionViewLayout: <#collectionViewLayout description#>
     - Parameter section: <#section description#>
     
     - Returns: <#CGFloat return description#>

    */
    @objc optional func collectionView(_ collectionView: CollectionView,layout collectionViewLayout: CollectionViewLayout,
                                 interitemSpacingForItemsInSection section: Int) -> CGFloat
    
    /**
     <#Description#>

     - Parameter collectionView: <#collectionView description#>
     - Parameter collectionViewLayout: <#collectionViewLayout description#>
     - Parameter section: <#section description#>
     
     - Returns: <#CGFloat return description#>

    */
    @objc optional func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout,
                                  heightForHeaderInSection section: Int) -> CGFloat
    
    /**
     <#Description#>

     - Parameter collectionView: <#collectionView description#>
     - Parameter collectionViewLayout: <#collectionViewLayout description#>
     - Parameter section: <#section description#>
     
     - Returns: <#CGFloat return description#>

    */
    @objc optional func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout,
                                  heightForFooterInSection section: Int) -> CGFloat
    
    /**
     <#Description#>

     - Parameter collectionView: <#collectionView description#>
     - Parameter collectionViewLayout: <#collectionViewLayout description#>
     - Parameter section: <#section description#>
     
     - Returns: <#EdgeInsets return description#>

    */
    @objc optional func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout,
                                  insetForSectionAt section: Int) -> EdgeInsets

    
}


/// A list collection view layout for use in TableView style scroll views
public final class CollectionViewListLayout : CollectionViewLayout  {
    
    //MARK: - Default layout values
    
    /// The vertical spacing between items in the same column
    public final var interitemSpacing : CGFloat = 0 { didSet{ invalidate() }}
    
    /// The vertical spacing between items in the same column
    public final var itemHeight : CGFloat = 36 { didSet{ invalidate() }}
    
    /// The height of section header views
    public final var headerHeight : CGFloat = 0.0 { didSet{ invalidate() }}
    
    /// The height of section footer views
    public final var footerHeight : CGFloat = 0.0 { didSet{ invalidate() }}
    
    /// If supplementary views should respect section insets or fill the CollectionView width
    public final var insetSupplementaryViews : Bool = false { didSet{ invalidate() }}
    
    /// Default insets for all sections
    public final var sectionInsets : EdgeInsets = NSEdgeInsetsZero { didSet{ invalidate() }}
    
    fileprivate var numSections : Int { get { return self.collectionView?.numberOfSections ?? 0 }}
    
    private weak var delegate : CollectionViewDelegateListLayout? { get{ return self.collectionView!.delegate as? CollectionViewDelegateListLayout }}
    
    
    fileprivate var sectionIndexPaths : [[IndexPath]] = []
    fileprivate var sectionItemAttributes : [[CollectionViewLayoutAttributes]] = []
    
    fileprivate var itemAttributes : [IndexPath:CollectionViewLayoutAttributes] = [:]
    fileprivate var headersAttributes : [Int:CollectionViewLayoutAttributes] = [:]
    fileprivate var footersAttributes : [Int:CollectionViewLayoutAttributes] = [:]
    
    fileprivate var sectionFrames : [CGRect] = []
    fileprivate var sectionContentFrames : [CGRect] = []
    
    override public init() {
        super.init()
    }
    
    fileprivate var _cvWidth : CGFloat = 0
    override open func shouldInvalidateLayout(forBoundsChange newBounds : CGRect) -> Bool {
        defer { self._cvWidth = newBounds.size.width }
        return _cvWidth != newBounds.size.width
    }
    
    override public func prepare(){
        
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
            
            let sectionInsets :  EdgeInsets =  self.delegate?.collectionView?(self.collectionView!, layout: self, insetForSectionAt: section) ?? self.sectionInsets
            let rowSpacing : CGFloat = self.delegate?.collectionView?(self.collectionView!, layout: self, interitemSpacingForItemsInSection: section) ?? self.interitemSpacing
            
            let itemWidth = self.collectionView!.contentVisibleRect.size.width - sectionInsets.left - sectionInsets.right
            var sectionFrame: CGRect = CGRect(x: sectionInsets.left, y: top, width: itemWidth, height: 0)
            
            
            /*
             * 2. Section header
             */
            let heightHeader : CGFloat = self.delegate?.collectionView?(self.collectionView!, layout: self, heightForHeaderInSection: section) ?? self.headerHeight
            if heightHeader > 0 {
                let attributes = CollectionViewLayoutAttributes(forSupplementaryViewOfKind: CollectionViewLayoutElementKind.SectionHeader, with: IndexPath.for(item: 0, section: section))
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
            let itemCount = self.collectionView!.numberOfItems(in: section)
            
            // Add the ip and attr arrays for the section, they are filled in below
            self.sectionIndexPaths.append([])
            self.sectionItemAttributes.append([])
            
            if itemCount > 0 {
                let xPos = contentRect.origin.x
                var yPos = contentRect.origin.y
                
                var newTop : CGFloat = 0
                
                for idx in 0..<itemCount {
                    
                    let ip = IndexPath.for(item:idx, section: section)
                    allIndexPaths.insert(ip)
                    
                    let attrs = CollectionViewLayoutAttributes(forCellWith: ip)
                    let rowHeight : CGFloat = self.delegate?.collectionView?(self.collectionView!, layout: self, heightForItemAt: ip) ?? self.itemHeight
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
                let attributes = CollectionViewLayoutAttributes(forSupplementaryViewOfKind: CollectionViewLayoutElementKind.SectionFooter, with: IndexPath.for(item:0, section: section))
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
    
    override open var collectionViewContentSize : CGSize {
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
    
    open override func rectForSection(_ section: Int) -> CGRect {
        return sectionFrames[section]
    }
    public override func contentRectForSection(_ section: Int) -> CGRect {
        return sectionContentFrames[section]
    }
    
    
    open override func indexPathsForItems(in rect: CGRect) -> [IndexPath] {
        
        guard let cv = self.collectionView else { return [] }
        var indexPaths = [IndexPath]()
        
        if rect.isEmpty || self.numSections == 0 { return indexPaths }
        for sectionIndex in 0..<cv.numberOfSections {
            
            if cv.numberOfItems(in: sectionIndex) == 0 { continue }
            
            let contentFrame = sectionContentFrames[sectionIndex]
            if contentFrame.isEmpty || !contentFrame.intersects(rect) { continue }
            
            // If the section is completely show, add all the attrs
            if rect.contains(contentFrame) {
                indexPaths.append(contentsOf: sectionIndexPaths[sectionIndex])
                continue
            }
            
            for attr in sectionItemAttributes[sectionIndex] {
                if attr.frame.intersects(rect) {
                    indexPaths.append(attr.indexPath as IndexPath)
                }
            }
        }
        return indexPaths
    }
    
    
    
    open override func layoutAttributesForItems(in rect: CGRect) -> [CollectionViewLayoutAttributes] {
        var attrs : [CollectionViewLayoutAttributes] = []
        
        guard let cv = self.collectionView else { return [] }
        if rect.isEmpty || cv.numberOfSections == 0 { return attrs }
        for sectionIdx in  0..<cv.numberOfSections {
            
            let contentFrame = self.sectionContentFrames[sectionIdx]
            if contentFrame.isEmpty || !contentFrame.intersects(rect) { continue }
            
            let containsAll = rect.contains(contentFrame)
            for attr in sectionItemAttributes[sectionIdx] {
                if containsAll || attr.frame.intersects(rect) {
                    attrs.append(attr.copy())
                }
            }
        }
        return attrs
    }
    
    public override func layoutAttributesForItem(at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
        return itemAttributes[indexPath]?.copy()
    }
    
    public override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
        
        if elementKind == CollectionViewLayoutElementKind.SectionHeader {
            let attrs = self.headersAttributes[indexPath._section]?.copy()
            if pinHeadersToTop, let currentAttrs = attrs, let cv = self.collectionView {
                let contentOffset = cv.contentOffset
                let frame = currentAttrs.frame
                
                var nextHeaderOrigin = CGPoint(x: CGFloat.greatestFiniteMagnitude, y: CGFloat.greatestFiniteMagnitude)
                if let nextHeader = self.headersAttributes[indexPath._section + 1] {
                    nextHeaderOrigin = nextHeader.frame.origin
                }
                let topInset = cv.contentInsets.top 
                currentAttrs.frame.origin.y =  min(max(contentOffset.y + topInset , frame.origin.y), nextHeaderOrigin.y - frame.height)
                currentAttrs.floating = currentAttrs.frame.origin.y > frame.origin.y
            }
            return attrs
        }
        else if elementKind == CollectionViewLayoutElementKind.SectionFooter {
            return self.footersAttributes[indexPath._section]
        }
        return nil
    }
   
    
    
    public override func scrollRectForItem(at indexPath: IndexPath, atPosition: CollectionViewScrollPosition) -> CGRect? {
        guard var frame = self.layoutAttributesForItem(at: indexPath)?.frame else { return nil }
        if self.pinHeadersToTop, let attrs = self.layoutAttributesForSupplementaryView(ofKind: CollectionViewLayoutElementKind.SectionHeader, at: IndexPath.for(item:0, section: indexPath._section)) {
            let y = frame.origin.y - attrs.frame.size.height
            let height = frame.size.height + attrs.frame.size.height
            frame.size.height = height
            frame.origin.y = y
        }
        return frame
    }
    
    
    
    
    public override func indexPathForNextItem(moving direction: CollectionViewDirection, from currentIndexPath: IndexPath) -> IndexPath? {
        guard let collectionView = self.collectionView else { fatalError() }
        
        let numberOfSections = self.numSections
        guard collectionView.rectForItem(at: currentIndexPath) != nil else { return nil }
        
        switch direction {
        case .up, .left:
            
            if currentIndexPath._item > 0 {
                return IndexPath.for(item: currentIndexPath._item - 1, section: currentIndexPath._section)
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
                return IndexPath.for(item: currentIndexPath._item + 1, section: currentIndexPath._section)
            }
            else if currentIndexPath._section == numberOfSections - 1 {
                return nil
            }
            
            var ip : IndexPath?
            var section = currentIndexPath._section + 1
            while ip == nil && section < numberOfSections {
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


