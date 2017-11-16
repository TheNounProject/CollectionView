//
//  CollectionViewListLayout.swift
//  CollectionView
//
//  Created by Wesley Byrne on 6/29/16.
//  Copyright © 2016 Noun Project. All rights reserved.
//

import Foundation



/**
 A vertical list based layout similiar to a native table view
*/
@objc public protocol CollectionViewDelegateListLayout: CollectionViewDelegate {
    
    // MARK: - Element Size
    /*-------------------------------------------------------------------------------*/
    /**
     Asks the delegate for the height of the item at index path

     - Parameter collectionView: The asking collection view
     - Parameter collectionViewLayout: The layout
     - Parameter indexPath: The index path for the item in question
     
     - Returns: The height for the item

    */
    @objc optional func collectionView(_ collectionView: CollectionView,layout collectionViewLayout: CollectionViewLayout,
                                  heightForItemAt indexPath: IndexPath) -> CGFloat
    
    
    /**
     Asks the delegate for the height of the header in a given section
     
     - Parameter collectionView: The asking collection view
     - Parameter collectionViewLayout: The layout
     - Parameter section: A section index
     
     - Returns: The desired height of section header or 0 for no header
     
     */
    @objc optional func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout,
                                       heightForHeaderInSection section: Int) -> CGFloat
    
    /**
     Asks the delegate for the height of the footer in a given section.
     
     - Parameter collectionView: The asking collection view
     - Parameter collectionViewLayout: The layout
     - Parameter section: The section of the footer in question
     
     - Returns: The desired height of the section footer or 0 for no footer
     
     */
    @objc optional func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout,
                                       heightForFooterInSection section: Int) -> CGFloat
    
    // MARK: - Spacing & Insets
    /*-------------------------------------------------------------------------------*/
    
    /**
     Asks the delegate for the spacing between items in a given section

     - Parameter collectionView: The asking collection view
     - Parameter collectionViewLayout: The layout
     - Parameter section: A section index
     
     - Returns: The desired item spacing to be applied between items in the given section

    */
    @objc optional func collectionView(_ collectionView: CollectionView,layout collectionViewLayout: CollectionViewLayout,
                                 interitemSpacingForItemsInSection section: Int) -> CGFloat

    
    /**
     Asks the delegate for insets to use when laying out items in a given section

     - Parameter collectionView: The asking collection view
     - Parameter collectionViewLayout: The layout
     - Parameter section: A section index
     
     - Returns: The edge insets for the section

    */
    @objc optional func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout,
                                  insetForSectionAt section: Int) -> NSEdgeInsets

    
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
    public final var sectionInsets : NSEdgeInsets = NSEdgeInsetsZero { didSet{ invalidate() }}
    
    fileprivate var numSections : Int { get { return self.collectionView?.numberOfSections ?? 0 }}
    
    private weak var delegate : CollectionViewDelegateListLayout? { get{ return self.collectionView!.delegate as? CollectionViewDelegateListLayout }}
    
    
    private var sectionIndexPaths : [[IndexPath]] = []
    private var sectionItemAttributes : [[CollectionViewLayoutAttributes]] = []
    
    private var itemAttributes : [IndexPath:CollectionViewLayoutAttributes] = [:]
    private var headersAttributes : [Int:CollectionViewLayoutAttributes] = [:]
    private var footersAttributes : [Int:CollectionViewLayoutAttributes] = [:]
    
    private var sectionFrames : [CGRect] = []
    private var sectionContentFrames : [CGRect] = []
    
    override public init() {
        super.init()
    }
    
    private var _cvWidth : CGFloat = 0
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
        
        var top : CGFloat = self.collectionView?.leadingView?.bounds.size.height ?? 0
        
        self.sectionItemAttributes = Array(repeating: [], count: numberOfSections)
        
        guard let cv = self.collectionView else { return }
        let contentInsets = cv.contentInsets
        
        for section in 0..<numberOfSections {
            
            /*
             * 1. Get section-specific metrics (minimumInteritemSpacing, sectionInset)
             */
            
            
            let insets :  NSEdgeInsets =  self.delegate?.collectionView?(cv, layout: self, insetForSectionAt: section) ?? self.sectionInsets
            
//            insets.left += contentInsets.left
//            insets.right += contentInsets.right
            
            let rowSpacing : CGFloat = self.delegate?.collectionView?(cv, layout: self, interitemSpacingForItemsInSection: section) ?? self.interitemSpacing
            
            let contentWidth = cv.bounds.size.width - (contentInsets.left + contentInsets.right)
            let itemWidth = cv.bounds.size.width - (insets.left + insets.right)
            var sectionFrame: CGRect = CGRect(x: contentInsets.left, y: top, width: contentWidth, height: 0)
            
            /*
             * 2. Section header
             */
            let heightHeader : CGFloat = self.delegate?.collectionView?(cv, layout: self, heightForHeaderInSection: section) ?? self.headerHeight
            if heightHeader > 0 {
                let attributes = CollectionViewLayoutAttributes(forSupplementaryViewOfKind: CollectionViewLayoutElementKind.SectionHeader, with: IndexPath.for(item: 0, section: section))
                attributes.alpha = 1
                attributes.frame = insetSupplementaryViews ?
                    CGRect(x: insets.left, y: top, width: itemWidth, height: heightHeader)
                    : CGRect(x: 0, y: top, width: contentWidth, height: heightHeader)
                self.headersAttributes[section] = attributes
                top = attributes.frame.maxY
            }
            
            top += insets.top
            
            
            
            /*
             * 3. Section items
             */
            
            var contentRect: CGRect = CGRect(x: insets.left, y: top, width: itemWidth, height: 0)
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
                    allIndexPaths.add(ip)
                    
                    let attrs = CollectionViewLayoutAttributes(forCellWith: ip)
                    let rowHeight : CGFloat = self.delegate?.collectionView?(cv, layout: self, heightForItemAt: ip) ?? self.itemHeight
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
            
            let footerHeight = self.delegate?.collectionView?(cv, layout: self, heightForFooterInSection: section) ?? self.footerHeight
            if footerHeight > 0 {
                let attributes = CollectionViewLayoutAttributes(forSupplementaryViewOfKind: CollectionViewLayoutElementKind.SectionFooter, with: IndexPath.for(item:0, section: section))
                attributes.alpha = 1
                attributes.frame = insetSupplementaryViews ?
                    CGRect(x: insets.left, y: top, width: itemWidth, height: footerHeight)
                    : CGRect(x: 0, y: top, width: contentWidth, height: footerHeight)
                self.footersAttributes[section] = attributes
                top = attributes.frame.maxY
            }
            top += insets.bottom

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
        size.width = cv.bounds.size.width - (cv.contentInsets.left + cv.contentInsets.right)
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
        guard collectionView.rectForItem(at: currentIndexPath) != nil else { return nil }
        
        func shouldSelectItem(at indexPath: IndexPath) -> IndexPath? {
            let set = Set([indexPath])
            let valid = self.collectionView?.delegate?.collectionView?(collectionView, shouldSelectItemsAt: set) ?? set
            return valid.first
        }
        
        switch direction {
        case .up, .left:
            var ip = currentIndexPath
            while true {
                guard let prop = self.allIndexPaths.object(before: ip) else { return nil }
                if let p = shouldSelectItem(at: prop) {
                    return p
                }
                ip = prop
            }
            
//            if let ip = currentIndexPath.previous {
//                return ip
//            }
//            else if currentIndexPath._section == 0 {
//                return nil
//            }
//            
//            var ip : IndexPath?
//            var section = currentIndexPath._section - 1
//            while ip == nil && section >= 0 {
//                if let _ip = self.sectionIndexPaths[section].last {
//                    ip = _ip
//                    break
//                }
//                section -= 1
//            }
//            return ip
            
        case .down, .right:
            
            var ip = currentIndexPath
            while true {
                guard let prop = self.allIndexPaths.object(after: ip) else { return nil }
                if let p = shouldSelectItem(at: prop) {
                    return p
                }
                ip = prop
            }
            
            
//            if currentIndexPath._item < self.sectionIndexPaths[currentIndexPath._section].count - 1 {
//                return IndexPath.for(item: currentIndexPath._item + 1, section: currentIndexPath._section)
//            }
//            else if currentIndexPath._section == numberOfSections - 1 {
//                return nil
//            }
//            
//            var ip : IndexPath?
//            var section = currentIndexPath._section + 1
//            while ip == nil && section < numberOfSections {
//                if let _ip = self.sectionIndexPaths[section].first {
//                    ip = _ip
//                    break
//                }
//                section += 1
//            }
//            return ip
        }
        
    }
    
}


