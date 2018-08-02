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
    @objc optional func collectionView(_ collectionView: CollectionView,
                                       layout collectionViewLayout: CollectionViewLayout,
                                       heightForItemAt indexPath: IndexPath) -> CGFloat
    
    /**
     Asks the delegate for the height of the header in a given section
     
     - Parameter collectionView: The asking collection view
     - Parameter collectionViewLayout: The layout
     - Parameter section: A section index
     
     - Returns: The desired height of section header or 0 for no header
     
     */
    @objc optional func collectionView(_ collectionView: CollectionView,
                                       layout collectionViewLayout: CollectionViewLayout,
                                       heightForHeaderInSection section: Int) -> CGFloat
    
    /**
     Asks the delegate for the height of the footer in a given section.
     
     - Parameter collectionView: The asking collection view
     - Parameter collectionViewLayout: The layout
     - Parameter section: The section of the footer in question
     
     - Returns: The desired height of the section footer or 0 for no footer
     
     */
    @objc optional func collectionView(_ collectionView: CollectionView,
                                       layout collectionViewLayout: CollectionViewLayout,
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
    @objc optional func collectionView(_ collectionView: CollectionView,
                                       layout collectionViewLayout: CollectionViewLayout,
                                       interitemSpacingForItemsInSection section: Int) -> CGFloat

    
    /**
     Asks the delegate for insets to use when laying out items in a given section

     - Parameter collectionView: The asking collection view
     - Parameter collectionViewLayout: The layout
     - Parameter section: A section index
     
     - Returns: The edge insets for the section

    */
    @objc optional func collectionView(_ collectionView: CollectionView,
                                       layout collectionViewLayout: CollectionViewLayout,
                                       insetForSectionAt section: Int) -> NSEdgeInsets

    
}


/// A list layout that makes CollectionView a perfect alternative to NSTableView
public final class CollectionViewListLayout: CollectionViewLayout  {
    
    //MARK: - Default layout values
    
    /// The vertical spacing between items in the same column
    public final var interitemSpacing: CGFloat = 0 { didSet{ invalidate() }}
    
    /// The vertical spacing between items in the same column
    public final var itemHeight: CGFloat = 36 { didSet{ invalidate() }}
    
    /// The height of section header views
    public final var headerHeight: CGFloat = 0.0 { didSet{ invalidate() }}
    
    /// The height of section footer views
    public final var footerHeight: CGFloat = 0.0 { didSet{ invalidate() }}
    
    /// If supplementary views should respect section insets or fill the CollectionView width
    public final var insetSupplementaryViews: Bool = false { didSet { invalidate() }}
    
    /// Default insets for all sections
    public final var sectionInsets: NSEdgeInsets = NSEdgeInsetsZero { didSet { invalidate() }}
    
    private weak var delegate: CollectionViewDelegateListLayout? { get { return self.collectionView!.delegate as? CollectionViewDelegateListLayout }}
    
    
    private var sections: [SectionAttributes] = []
    
    private struct SectionAttributes: CustomStringConvertible {
        var frame = CGRect.zero
        var contentFrame = CGRect.zero
        let insets: NSEdgeInsets
        var header: CollectionViewLayoutAttributes?
        var footer: CollectionViewLayoutAttributes?
        var items: [CollectionViewLayoutAttributes] = []
        init(insets: NSEdgeInsets, count: Int = 0) {
            self.insets = insets
            self.items.reserveCapacity(count)
        }
        var description: String {
            return "Section Attributes : \(frame)  content: \(contentFrame) Items: \(items.count)"
        }
    }
    

    override public init() {
        super.init()
    }
    
    
    private var _cvWidth: CGFloat = 0
    override public func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        defer { self._cvWidth = newBounds.size.width }
        return _cvWidth != newBounds.size.width
    }
    
    fileprivate var numSections: Int { get { return self.collectionView?.numberOfSections ?? 0 }}
    
    override public func prepare(){
        
        self.allIndexPaths.removeAll()
        self.sections.removeAll()
        
        guard let cv = self.collectionView else { return }
        
        let numberOfSections = self.numSections
        guard numberOfSections > 0 else { return }
        
        var top: CGFloat = self.collectionView?.leadingView?.bounds.size.height ?? 0
        let contentInsets = cv.contentInsets
        
        for sectionIdx in 0..<numberOfSections {
            
            // 1. Get section-specific metrics (minimumInteritemSpacing, sectionInset)
            let insets =  self.delegate?.collectionView?(cv, layout: self, insetForSectionAt: sectionIdx) ?? self.sectionInsets
            let rowSpacing: CGFloat = self.delegate?.collectionView?(cv, layout: self, interitemSpacingForItemsInSection: sectionIdx) ?? self.interitemSpacing
            
            let contentWidth = cv.bounds.size.width - contentInsets.width
            let itemWidth = contentWidth - insets.width
            
            let itemCount = cv.numberOfItems(in: sectionIdx)
            var section = SectionAttributes(insets: insets, count: itemCount)
            section.frame = CGRect(x: contentInsets.left, y: top, width: contentWidth, height: 0)
            
            
            // 2. Section header
            let heightHeader : CGFloat = self.delegate?.collectionView?(cv, layout: self, heightForHeaderInSection: sectionIdx) ?? self.headerHeight
            if heightHeader > 0 {
                let attributes = CollectionViewLayoutAttributes(forSupplementaryViewOfKind: CollectionViewLayoutElementKind.SectionHeader,
                                                                with: IndexPath.for(item: 0, section: sectionIdx))
                attributes.alpha = 1
                attributes.frame = insetSupplementaryViews ?
                    CGRect(x: insets.left, y: top, width: itemWidth, height: heightHeader)
                    : CGRect(x: 0, y: top, width: contentWidth, height: heightHeader)
                
                section.header = attributes
                top = attributes.frame.maxY
            }
            
            // Insets are between header and section content
            top += insets.top
            
            //3. Section items
            section.contentFrame = CGRect(x: insets.left, y: top, width: itemWidth, height: 0)
            
            if itemCount > 0 {
                let xPos = section.contentFrame.origin.x
                var yPos = section.contentFrame.origin.y
                
                var newTop: CGFloat = 0
                
                for idx in 0..<itemCount {
                    
                    let ip = IndexPath.for(item:idx, section: sectionIdx)
                    allIndexPaths.append(ip)
                    
                    let attrs = CollectionViewLayoutAttributes(forCellWith: ip)
                    let rowHeight: CGFloat = self.delegate?.collectionView?(cv, layout: self, heightForItemAt: ip) ?? self.itemHeight
                    attrs.frame = NSRect(x: xPos, y: yPos, width: itemWidth, height: rowHeight)
                    newTop = yPos + rowHeight
                    yPos = newTop + rowSpacing
                    
                    section.items.append(attrs)
                }
                top = newTop
            }
            section.contentFrame.size.height = top - section.contentFrame.origin.y
            
            
            // 4. Footers
            let footerHeight = self.delegate?.collectionView?(cv, layout: self, heightForFooterInSection: sectionIdx) ?? self.footerHeight
            if footerHeight > 0 {
                let attributes = CollectionViewLayoutAttributes(forSupplementaryViewOfKind: CollectionViewLayoutElementKind.SectionFooter,
                                                                with: IndexPath.for(item: 0, section: sectionIdx))
                attributes.alpha = 1
                attributes.frame = insetSupplementaryViews ?
                    CGRect(x: insets.left, y: top, width: itemWidth, height: footerHeight)
                    : CGRect(x: 0, y: top, width: contentWidth, height: footerHeight)
                section.footer = attributes
                top = attributes.frame.maxY
            }
            top += insets.bottom

            section.frame.size.height = top - section.frame.origin.y
            sections.append(section)
        }
    }
    
    override public var collectionViewContentSize : CGSize {
        guard let cv = collectionView else { return CGSize.zero }
        var size = cv.contentDocumentView.frame.size
        
        if self.numSections == 0 { return size }
        
        size.width = cv.bounds.size.width - cv.contentInsets.width
        size.height = self.sections.last?.frame.maxY ?? cv.bounds.height
        return size
    }
    
    public override func rectForSection(_ section: Int) -> CGRect {
        return sections[section].frame
    }
    
    public override func contentRectForSection(_ section: Int) -> CGRect {
        return sections[section].contentFrame
    }
    
    public override func indexPathsForItems(in rect: CGRect) -> [IndexPath] {
        return itemAttributes(in: rect) { return $0.indexPath }
    }
    
    public override func layoutAttributesForItems(in rect: CGRect) -> [CollectionViewLayoutAttributes] {
        return itemAttributes(in: rect) { return $0.copy() }
    }
    
    private func itemAttributes<T>(in rect: CGRect, reducer: ((CollectionViewLayoutAttributes) -> T)) -> [T] {
        guard !rect.isEmpty && !self.sections.isEmpty else { return [] }
        
        var results = [T]()
        for section in self.sections {
            
            // If we have passed the target, finish
            guard !section.items.isEmpty && section.frame.intersects(rect) else {
                guard section.frame.origin.y < rect.maxY else { break }
                continue
            }
            
            if rect.contains(section.contentFrame) {
                results.append(contentsOf: section.items.map { return reducer($0) })
            }
            else {
                for item in section.items {
                    guard item.frame.intersects(rect) else {
                        guard item.frame.minY < rect.maxY else { break }
                        continue
                    }
                    results.append(reducer(item))
                }
            }
        }
        return results
    }
    
    public override func layoutAttributesForItem(at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
        return sections.object(at: indexPath._section)?.items.object(at: indexPath._item)?.copy()
    }
    
    public override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
        let section = self.sections[indexPath._section]
        
        if elementKind == CollectionViewLayoutElementKind.SectionHeader {
            guard let attrs = section.header?.copy() else { return nil }
            if pinHeadersToTop, let cv = self.collectionView {
                let contentOffset = cv.contentOffset
                let frame = attrs.frame
                
                var nextHeaderOrigin = CGPoint(x: CGFloat.greatestFiniteMagnitude, y: CGFloat.greatestFiniteMagnitude)
                if let nextHeader = self.sections.object(at: indexPath._section + 1)?.header {
                    nextHeaderOrigin = nextHeader.frame.origin
                }
                let topInset = cv.contentInsets.top 
                attrs.frame.origin.y =  min(max(contentOffset.y + topInset, frame.origin.y), nextHeaderOrigin.y - frame.height)
                attrs.floating = attrs.frame.origin.y > frame.origin.y
            }
            return attrs
        }
        else if elementKind == CollectionViewLayoutElementKind.SectionFooter {
            return section.footer?.copy()
        }
        return nil
    }
   
    public override func scrollRectForItem(at indexPath: IndexPath, atPosition: CollectionViewScrollPosition) -> CGRect? {
        guard var frame = self.layoutAttributesForItem(at: indexPath)?.frame else { return nil }
        if self.pinHeadersToTop, let attrs = self.layoutAttributesForSupplementaryView(ofKind: CollectionViewLayoutElementKind.SectionHeader,
                                                                                       at: IndexPath.for(item: 0, section: indexPath._section)) {
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
