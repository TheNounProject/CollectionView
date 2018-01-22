//
//  CollectionViewMasonryLayout.swift
//  CollectionView
//
//  Created by Wesley Byrne on 9/12/16.
//  Copyright © 2016 Noun Project. All rights reserved.
//

import Foundation







/**
 CollectionViewDelegateFlowLayout
*/

public protocol CollectionViewDelegateFlowLayout  {
    
    // MARK: - Element Size
    /*-------------------------------------------------------------------------------*/
    /**
     Asks the delegate for the layout style for the item at the specified index path

     - Parameter collectionView: The collection view requesting the information
     - Parameter gridLayout: The layout
     - Parameter indexPath: The index path of the item to style
     
     - Returns: A style to apply to the item

    */
    func collectionView(_ collectionView: CollectionView, flowLayout: CollectionViewFlowLayout, styleForItemAt indexPath: IndexPath) -> CollectionViewFlowLayout.ItemStyle
    
    /**
     Asks the delegate for the height of the header view in a specified section
     
     Return 0 for no header view

     - Parameter collectionView: The collection view requesting the information
     - Parameter collectionViewLayout: The layout
     - Parameter section: The section affected by this height
     
     - Returns: The height to apply to the header view in the specified section
     
    */
    func collectionView (_ collectionView: CollectionView, flowLayout collectionViewLayout: CollectionViewFlowLayout,
                                        heightForHeaderInSection section: Int) -> CGFloat
    
    /**
     Asks the delegate for the height of the footer view in a specified section
     
     Return 0 for no footer view

     - Parameter collectionView: The collection view requesting the information
     - Parameter collectionViewLayout: The layout
     - Parameter section: The section affected by this height
     
     - Returns: The height to apply to the header view in the specified section

    */

    func collectionView (_ collectionView: CollectionView, flowLayout collectionViewLayout: CollectionViewFlowLayout,
                                        heightForFooterInSection section: Int) -> CGFloat
    
    
    // MARK: - Insets & Transforms
    /*-------------------------------------------------------------------------------*/
    
    /**
     Asks the delegate for the insets for the content of the specified index path

     - Parameter collectionView: The collection view requesting the information
     - Parameter collectionViewLayout: The layout
     - Parameter section: Thhe section that the return value will be applied to
     
     - Returns: Edge insets for the specified section

    */
    func collectionView (_ collectionView: CollectionView, flowLayout collectionViewLayout: CollectionViewFlowLayout,
                         insetsForSectionAt section: Int) -> NSEdgeInsets
    
    
    
    /**
     Asks the delegate for a transform to apply to the content in each row the specified section, defaults to .none
     
     - Parameter collectionView: The collection requesting the information
     - Parameter collectionViewLayout: The layout
     - Parameter section: The section to transform
     
     - Returns: The type of row transform to apply
     
     */
    func collectionView (_ collectionView: CollectionView, flowLayout collectionViewLayout: CollectionViewFlowLayout,
                         rowTransformForSectionAt section: Int) -> CollectionViewFlowLayout.RowTransform
}

extension CollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: CollectionView, flowLayout: CollectionViewFlowLayout, styleForItemAt indexPath: IndexPath) -> CollectionViewFlowLayout.ItemStyle {
        return flowLayout.defaultItemStyle
    }
    
    public func collectionView (_ collectionView: CollectionView, flowLayout collectionViewLayout: CollectionViewFlowLayout,
                         heightForHeaderInSection section: Int) -> CGFloat{
        return collectionViewLayout.defaultHeaderHeight
    }
    
    public func collectionView (_ collectionView: CollectionView, flowLayout collectionViewLayout: CollectionViewFlowLayout,
                         heightForFooterInSection section: Int) -> CGFloat {
        return collectionViewLayout.defaultFooterHeight
    }
    
    public func collectionView (_ collectionView: CollectionView, flowLayout collectionViewLayout: CollectionViewFlowLayout,
                         insetsForSectionAt section: Int) -> NSEdgeInsets {
        return collectionViewLayout.defaultSectionInsets
    }
    
    public func collectionView (_ collectionView: CollectionView, flowLayout collectionViewLayout: CollectionViewFlowLayout,
                         rowTransformForSectionAt section: Int) -> CollectionViewFlowLayout.RowTransform {
        return collectionViewLayout.defaultRowTransform
    }
    
    
}


/**
 A variation of UICollectionViewFlowLayout
 
 This layout is primarily row based, but uses ItemStyles to group similar items together.
 
 The layout's delegate, CollectionViewDelegateFlowLayout, is responsible for providing a style for each item in the collection view.
 
 Flow items are grouped together, always placing as many same height items in each row as possible. If the row becomes full or an flow item of a different height is provided, the layout will just to the next row and continue.
 
 Span items are always placed an their own row and fill the width of the Collection View.
 
 ### Example
 ```
 +---------------------------------+
 |   +-----+ +------------+ +--+   |
 |   |  1  | |     2      | | 3|   |
 |   |     | |            | |  |   |
 |   +-----+ +------------+ +--+   |
 |   +--------+ +---------+        |
 |   |   4    | |   5     |        |
 |   |        | |         |        |
 |   |        | |         |        |
 |   |        | |         |        |
 |   +--------+ +---------+        |
 |   +-------------------------+   |
 |   |         6. Span         |   |
 |   +-------------------------+   |
 +---------------------------------+
 ```
 
 ### Transformations
 
 Transformations allow you to adjust the content of each row before moving on to the next row.
 
 The "center" transformation will shift the of the row to be center aligned rather than left aligned.
 
 The fill tranformation will enlarge the items in a row proportionally to fill the row if their is empty space on the right. Note that this will affect the height of the entire row.
 
 
 ### Spacing
 
 Spacing options such as interspanSpacing and spanGroupSpacingBefore allow you to customize the space around different types of style groups.
 
 The spanGroupSpacingBefore/After options will apply a set amount of space before or after a group of span items (one or more spans).
 
 */
open class CollectionViewFlowLayout : CollectionViewLayout {
    
    // MARK: - Options
    /*-------------------------------------------------------------------------------*/
    
    /// Spacing between flow elements
    public var interitemSpacing: CGFloat = 8
    
    
    /// Vertical spacing between multiple span elements
    public var interpanSpacing : CGFloat?
    
    
    /// Top spacing between the span elements that are preceded by flow elements
    public var spanGroupSpacingBefore : CGFloat?
    
    
    /// Bottom spacing between span elements that are followed by flow elements
    public var spanGroupSpacingAfter : CGFloat?
    
    
    public var defaultItemStyle = ItemStyle.flow(CGSize(width: 60, height: 60))
    public var defaultFooterHeight : CGFloat = 0
    public var defaultHeaderHeight : CGFloat = 0
    public var defaultRowTransform : RowTransform = .none
    public var defaultSectionInsets : NSEdgeInsets = NSEdgeInsetsZero
    
    
    /// If supplementary views should be inset to section insets
    public var insetSupplementaryViews = true
    
    
    // MARK: - Layout Information
    /*-------------------------------------------------------------------------------*/
    
    /// Only used during layout preparation to reference the width of the previously inserted row
    private(set) public var widthOfLastRow : CGFloat?
    
    
    
    /// Row transforms can be applied to flow elements that fall within the same row
    ///
    /// - none: No transform
    /// - center: Center the elements at their current size and spacing
    /// - fill: Enlarge the elements to fill the row
    public enum RowTransform {
        case none
        case center
        case fill(CGFloat)
    }
    
    /**
     Styles for CollectionViewFlowLayout
     */
    public enum ItemStyle {
        /// Flow items with like other surrounding like-sized items
        case flow(CGSize)
        /// Break from the flow positioning the item in it's own row
        case span(CGSize)
        
        var isSpan : Bool {
            switch self {
            case .span: return true
            default: return false
            }
        }
    }
    
    private struct RowAttributes : CustomStringConvertible {
        var frame = CGRect.null
        var itemHeight: CGFloat {
            return items.last?.frame.size.height ?? 0
        }
        var items : [CollectionViewLayoutAttributes]
        
        init(attributes: CollectionViewLayoutAttributes) {
            self.items = [attributes]
            self.frame = attributes.frame
        }
        
        mutating func add(attributes: CollectionViewLayoutAttributes) {
            items.append(attributes)
            frame = frame.union(attributes.frame)
        }
        
        func contains(_ indexPath: IndexPath) -> Bool {
            guard let f = items.first?.indexPath._item, f <= indexPath._item else { return false }
            guard let l = items.last?.indexPath._item, l >= indexPath._item else { return false }
            return true
        }
        
        mutating func applyTransform(_ transform: RowTransform, leftInset: CGFloat, width: CGFloat, spacing: CGFloat) -> CGFloat {
            
            switch transform {
            case .center:
                let adjust = ((width - frame.size.width)/2)
                for item in items {
                    item.frame.origin.x += adjust
                    item.frame = item.frame.integral
                }
            case let .fill(maxScale):
                var scale = width/frame.size.width
                if maxScale > 1 && scale  > maxScale { scale = maxScale }
                var left = leftInset
                for item in items {
                    item.frame.origin.x = left
                    item.frame.size.width = item.frame.size.width * scale
                    item.frame.size.height = item.frame.size.height * scale
                    item.frame = item.frame.integral
                    self.frame = frame.union(item.frame)
                    left = item.frame.maxX + spacing
                }
                
            default: break;
            }
            return frame.maxY
        }
        
        func index(of indexPath: IndexPath) -> Int? {
            guard let f = self.items.first,
                let l = self.items.last else { return nil }
            
            if f.indexPath > indexPath { return nil }
            if l.indexPath < indexPath { return nil }
            for (idx, item) in self.items.enumerated() {
                if item.indexPath == indexPath { return idx }
            }
            return nil
        }
        
        func item(verticallyAlignedTo attrs: CollectionViewLayoutAttributes) -> IndexPath? {
            
            guard self.items.count > 1,
                let _ = self.items.first,
                let l = self.items.last else { return items.last?.indexPath }
            
            let center = attrs.frame.midX
            
            if l.frame.origin.x < center { return l.indexPath }
            for item in self.items {
                if item.frame.maxX > center {
                    return item.indexPath
                }
            }
            return nil
        }
        
        var description: String {
            return "Row Attributes : \(frame) -- \(items.count)"
        }
    }
    
    private struct SectionAttributes  : CustomStringConvertible {
        var frame = CGRect.zero
        
        let insets : NSEdgeInsets
        let transform : RowTransform
        
        var contentFrame = CGRect.zero
        var header : CollectionViewLayoutAttributes?
        var footer : CollectionViewLayoutAttributes?
        var rows : [RowAttributes] = []
        var items : [CollectionViewLayoutAttributes] = []
        
        var description: String {
            return "Section Attributes : \(frame)  content: \(contentFrame)  Rows: \(rows.count)  Items: \(items.count)"
        }
        
        init(insets: NSEdgeInsets, transform: RowTransform) {
            self.insets = insets
            self.transform = transform
        }
    }
    
    private var delegate : CollectionViewDelegateFlowLayout? {
        return self.collectionView?.delegate as? CollectionViewDelegateFlowLayout
    }
    
    private var sectionAttributes = [SectionAttributes]()
    
    
    // MARK: - Layout Overrides
    /*-------------------------------------------------------------------------------*/
    
    private var _lastSize = CGSize.zero
    open override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        defer { self._lastSize = newBounds.size }
        return _lastSize != newBounds.size
    }
    
    override open func prepare() {
        
        self.allIndexPaths.removeAll()
        self.sectionAttributes.removeAll()
        guard let cv = self.collectionView else { return }
        
        let numSections = cv.numberOfSections
        guard numSections > 0 else { return }
        
        var top : CGFloat = self.collectionView?.leadingView?.bounds.size.height ?? 0
        
        let contentInsets = cv.contentInsets
        
        for sec in 0..<numSections {
           
            var insets = self.delegate?.collectionView(cv, flowLayout: self, insetsForSectionAt: sec) ?? self.defaultSectionInsets
//            insets.left += contentInsets.left
//            insets.right += contentInsets.right
            let transform = self.delegate?.collectionView(cv, flowLayout: self, rowTransformForSectionAt: sec) ?? self.defaultRowTransform
            
            var sectionAttrs = SectionAttributes(insets: insets, transform: transform)
            let numItems = cv.numberOfItems(in: sec)
            
            sectionAttrs.frame.origin.y = top
            sectionAttrs.contentFrame.origin.y = top
            
            let contentWidth = cv.contentVisibleRect.size.width - (insets.left + insets.right + contentInsets.left + contentInsets.right)
            
            let heightHeader : CGFloat = self.delegate?.collectionView(cv, flowLayout: self, heightForHeaderInSection: sec) ?? self.defaultHeaderHeight
            if heightHeader > 0 {
                let attrs = CollectionViewLayoutAttributes(forSupplementaryViewOfKind: CollectionViewLayoutElementKind.SectionHeader, with: IndexPath.for(section: sec))
                
                attrs.frame = insetSupplementaryViews
                    ? CGRect(x: insets.left, y: top, width: contentWidth, height: heightHeader)
                    : CGRect(x: contentInsets.left, y: top, width: cv.frame.size.width - (contentInsets.left + contentInsets.right), height: heightHeader)
                sectionAttrs.header = attrs
                sectionAttrs.frame = attrs.frame
                top = attrs.frame.maxY
            }
            
            top += insets.top
            sectionAttrs.contentFrame.origin.y = top
            
            var previousStyle : ItemStyle?
            if numItems > 0 {
                
                func adjustOversizedIfNeeded(_ attributes: CollectionViewLayoutAttributes) {
                    if attributes.frame.size.width > contentWidth {
                        let scale = contentWidth/attributes.frame.size.width
                        attributes.frame.size = CGSize(width: attributes.frame.size.width * scale, height: attributes.frame.size.height * scale)
                    }
                }
                
                var forceBreak: Bool = false
                for item in 0..<numItems {
                    allIndexPaths.add(IndexPath.for(item: item, section: sec))
                    let ip = IndexPath.for(item: item, section: sec)
                    let style = self.delegate?.collectionView(cv, flowLayout: self, styleForItemAt: ip) ?? defaultItemStyle
                    var attrs = CollectionViewLayoutAttributes(forCellWith: ip)
                    
                    switch style {
                    case let .flow(size):
                        
                        func newRow() {
                            
                            
                            var spacing : CGFloat = 0
                            if sectionAttrs.rows.count > 0 {
                                top = sectionAttrs.rows[sectionAttrs.rows.count - 1].applyTransform(transform,
                                                                                                    leftInset: insets.left,
                                                                                                    width: contentWidth,
                                                                                                    spacing: interitemSpacing)
                                
                                
                                if let s = self.spanGroupSpacingAfter, previousStyle?.isSpan == true { spacing = s }
                                else { spacing = interitemSpacing }
                            }
                            
                            attrs.frame = CGRect(x: insets.left, y: top + spacing, width: size.width, height: size.height)
                            adjustOversizedIfNeeded(attrs)
                            sectionAttrs.rows.append(RowAttributes(attributes: attrs))
                        }
                        
                        // Check if the last row (if any) matches this items height
                        if !forceBreak, let prev = sectionAttrs.rows.last?.items.last, prev.frame.size.height == size.height {
                            // If there is enough space remaining, add it to the current row
                            let rem = contentWidth - (prev.frame.maxX - contentInsets.left - insets.left) - interitemSpacing
                            if rem >= size.width {
                                attrs.frame = CGRect(x: prev.frame.maxX + interitemSpacing, y: prev.frame.origin.y, width: size.width, height: size.height)
                                sectionAttrs.rows[sectionAttrs.rows.count - 1].add(attributes: attrs)
                            }
                            else { newRow() }
                        }
                        else { newRow() }
                        forceBreak = false
                        
                    case let .span(size):
                        
                        
                        if sectionAttrs.rows.count > 0 && previousStyle?.isSpan != true {
                            top = sectionAttrs.rows[sectionAttrs.rows.count - 1].applyTransform(transform,
                                                                                                    leftInset: insets.left,
                                                                                                    width: contentWidth,
                                                                                                    spacing: interitemSpacing)
                        }
                        
                        var spacing : CGFloat = 0
                        if sectionAttrs.rows.count > 0 {
                            if let s = self.spanGroupSpacingBefore, previousStyle?.isSpan == false {
                                spacing = s
                            }
                            else if let s = self.interpanSpacing, previousStyle?.isSpan == true {
                                spacing = s
                            }
                            else {
                                spacing = interitemSpacing
                            }
                        }                        
                        attrs.frame = CGRect(x: insets.left, y: top + spacing, width: size.width, height: size.height)
                        
                        sectionAttrs.rows.append(RowAttributes(attributes: attrs))
                        forceBreak = true
                    }
                    sectionAttrs.items.append(attrs)
                    sectionAttrs.contentFrame = sectionAttrs.contentFrame.union(attrs.frame)
                    top = sectionAttrs.contentFrame.maxY
                    widthOfLastRow = sectionAttrs.rows.last?.frame.size.width
                    previousStyle = style
                }
                
                // Cleanup section
                widthOfLastRow = nil
                previousStyle = nil
                if sectionAttrs.rows.count > 0 {
                    top = sectionAttrs.rows[sectionAttrs.rows.count - 1].applyTransform(transform,
                                                                                  leftInset: insets.left,
                                                                                  width: contentWidth,
                                                                                  spacing: interitemSpacing)
                }
            }
            
            top += insets.bottom
            sectionAttrs.frame = sectionAttrs.frame.union(sectionAttrs.contentFrame)
            sectionAttrs.frame.size.height += insets.bottom
            
            let footerHeader : CGFloat = self.delegate?.collectionView(cv, flowLayout: self, heightForFooterInSection: sec) ?? 0
            if footerHeader > 0 {
                let attrs = CollectionViewLayoutAttributes(forSupplementaryViewOfKind: CollectionViewLayoutElementKind.SectionFooter, with: IndexPath.for(section: sec))
                attrs.frame = insetSupplementaryViews
                    ? CGRect(x: insets.left + contentInsets.left, y: top, width: contentWidth, height: heightHeader)
                    : CGRect(x: contentInsets.left, y: top, width: cv.contentVisibleRect.size.width - contentInsets.left - contentInsets.right, height: heightHeader)
                sectionAttrs.footer = attrs
                sectionAttrs.frame = sectionAttrs.frame.union(attrs.frame)
                top = attrs.frame.maxY
            }
            
            
            sectionAttributes.append(sectionAttrs)

        }
    }
    
    
    override open func layoutAttributesForItems(in rect: CGRect) -> [CollectionViewLayoutAttributes] {
        var attrs : [CollectionViewLayoutAttributes] = []
        
        guard let cv = self.collectionView else { return [] }
        if rect.equalTo(CGRect.zero) || cv.numberOfSections == 0 { return attrs }
        for sectionIndex in 0..<cv.numberOfSections {
            let sAttrs = self.sectionAttributes[sectionIndex]
            if sAttrs.frame.isEmpty || !sAttrs.frame.intersects(rect) { continue }
            for row in sAttrs.rows {
                guard row.frame.intersects(rect) else { continue }
                for attr in row.items{
                    if attr.frame.intersects(rect) {
                        attrs.append(attr.copy())
                    }
                    else if attr.frame.origin.y > rect.maxY { break }
                }
            }
        }
        return attrs
    }
    
    override open func layoutAttributesForItem(at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
        if indexPath._section >= self.sectionAttributes.count{ return nil }
        if indexPath._item >= self.sectionAttributes[indexPath._section].items.count { return nil }
        let list = self.sectionAttributes[indexPath._section]
        return list.items[indexPath._item].copy()
    }
    
    override open func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
        
        if elementKind == CollectionViewLayoutElementKind.SectionHeader {
            let attrs = self.sectionAttributes[indexPath._section].header?.copy()
            if pinHeadersToTop, let currentAttrs = attrs, let cv = self.collectionView {
                
                let contentOffset = cv.contentOffset
                let frame = currentAttrs.frame
                
                let lead = cv.leadingView?.bounds.size.height ?? 0
//                if indexPath._section == 0 && contentOffset.y < cv.contentInsets.top {
//                    currentAttrs.frame.origin.y = lead
//                    currentAttrs.floating = false
//                }
//                else {
                    var nextHeaderOrigin = CGPoint(x: CGFloat.greatestFiniteMagnitude, y: CGFloat.greatestFiniteMagnitude)
                    if let nextHeader = self.sectionAttributes.object(at: indexPath._section + 1)?.header {
                        nextHeaderOrigin = nextHeader.frame.origin
                    }
                    let topInset = cv.contentInsets.top
                    currentAttrs.frame.origin.y =  min(max(contentOffset.y + topInset , frame.origin.y), nextHeaderOrigin.y - frame.height)
                    currentAttrs.floating = indexPath._section == 0 || currentAttrs.frame.origin.y > frame.origin.y
//                }
            }
            return attrs
        }
        else if elementKind == CollectionViewLayoutElementKind.SectionFooter {
            return self.sectionAttributes[indexPath._section].footer?.copy()
        }
        return nil
    }
    
    open override func rectForSection(_ section: Int) -> CGRect {
        return sectionAttributes[section].frame
    }
    
    open override func contentRectForSection(_ section: Int) -> CGRect {
        return sectionAttributes[section].contentFrame
    }
    
    
    override open func indexPathsForItems(in rect: CGRect) -> [IndexPath] {
        guard let cv = self.collectionView else { return [] }
        
        var indexPaths = [IndexPath]()
        
        if rect.equalTo(CGRect.zero) || cv.numberOfSections == 0 { return indexPaths }
        for sectionIndex in 0..<cv.numberOfSections {
            
            if cv.numberOfItems(in: sectionIndex) == 0 { continue }
            
            let sAttrs = self.sectionAttributes[sectionIndex]
            if sAttrs.frame.isEmpty || !sAttrs.frame.intersects(rect) { continue }
            
            // If the section is completely show, add all the attrs
            if rect.contains(sAttrs.frame) {
                for a in sAttrs.items {
                    indexPaths.append(a.indexPath)
                }
//                if let ips = self.sectionAttributes[sectionIndex] {
//                    indexPaths.formUnion(ips)
//                }
            }
            else if sAttrs.rows.count > 0 {
                for row in sAttrs.rows {
                    guard row.frame.intersects(rect) else { continue }
                    for attr in row.items {
                        if attr.frame.intersects(rect) {
                            indexPaths.append(attr.indexPath as IndexPath)
                        }
                        else if attr.frame.origin.y > rect.maxY { break }
                    }
                }
            }
        }
        return indexPaths
    }
    
    override open var collectionViewContentSize: CGSize {
        guard let cv = collectionView else { return CGSize.zero }
        let numberOfSections = cv.numberOfSections
        if numberOfSections == 0 { return CGSize.zero }
        
        var contentSize = cv.contentVisibleRect.size as CGSize
        contentSize.width = contentSize.width - (cv.contentInsets.left + cv.contentInsets.right)
        let height = self.sectionAttributes.last?.frame.maxY ?? 0
        if height == 0 { return CGSize.zero }
        contentSize.height = height
        return  contentSize
    }
    
    
    
    open override func scrollRectForItem(at indexPath: IndexPath, atPosition: CollectionViewScrollPosition) -> CGRect? {
        guard var frame = self.layoutAttributesForItem(at: indexPath)?.frame else { return nil }
        
        let section = self.sectionAttributes[indexPath._section]
        let inset = (self.collectionView?.contentInsets.top ?? 0) - section.insets.top
        
        if let headerHeight = section.header?.frame.size.height {
            var y = frame.origin.y
            if pinHeadersToTop || section.rows.first?.contains(indexPath) == true {
                 y = (frame.origin.y - headerHeight)
            }
            
            let height = frame.size.height + headerHeight
            frame.size.height = height
            frame.origin.y = y
        }
        
        frame.origin.y = frame.origin.y + inset
        return frame
    }
    
    
    open override func indexPathForNextItem(moving direction: CollectionViewDirection, from currentIndexPath: IndexPath) -> IndexPath? {
        guard let collectionView = self.collectionView else { fatalError() }
        
//        var index = currentIndexPath._item
        let section = currentIndexPath._section
        
//        let numberOfSections = collectionView.numberOfSections
//        let numberOfItemsInSection = collectionView.numberOfItems(in: currentIndexPath._section)
        
        guard collectionView.rectForItem(at: currentIndexPath) != nil else { return nil }
        
        var startingIP = currentIndexPath
        
        func shouldSelectItem(at indexPath: IndexPath) -> IndexPath? {
            let set = Set([indexPath])
            let valid = self.collectionView?.delegate?.collectionView?(collectionView, shouldSelectItemsAt: set) ?? set
            return valid.first
        }
        
        switch direction {
        case .up:
            guard let cAttrs = collectionView.layoutAttributesForItem(at: currentIndexPath) else { return nil }
            
            var proposed : IndexPath?
            var prev : RowAttributes?
            for row in sectionAttributes[section].rows {
                if let _ = row.index(of: currentIndexPath) {
                    guard let pRow = prev else {
                        guard let pSectionRow = sectionAttributes.object(at: section - 1)?.rows.last else { return nil }
                        proposed = pSectionRow.item(verticallyAlignedTo: cAttrs)
                        break;
                    }
                    proposed = pRow.item(verticallyAlignedTo: cAttrs)
                    break;
                }
                prev = row
            }
            guard let ip = proposed else { return nil }
            if let p = shouldSelectItem(at: ip) {
                return p
            }
            startingIP = ip
            fallthrough
            
        case .left:
            var ip = startingIP
            while true {
                guard let prop = self.allIndexPaths.object(before: ip) else { return nil }
                if let p = shouldSelectItem(at: prop) {
                    return p
                }
                ip = prop
            }

            
        case .down:
            guard let cAttrs = collectionView.layoutAttributesForItem(at: currentIndexPath) else { return nil }
            
            var proposed : IndexPath?
            var prev : RowAttributes?
            for row in sectionAttributes[section].rows.reversed() {
                if let _ = row.index(of: currentIndexPath) {
                    guard let pRow = prev else {
                        guard let pSectionRow = sectionAttributes.object(at: section + 1)?.rows.first else { return nil }
                        proposed = pSectionRow.item(verticallyAlignedTo: cAttrs)
                        break;
                    }
                    proposed = pRow.item(verticallyAlignedTo: cAttrs)
                    break;
                }
                prev = row
            }
            guard let ip = proposed else { return nil }
            if let p = shouldSelectItem(at: ip) {
                return p
            }
            startingIP = ip
            fallthrough
            
        
        case .right :
            
            var ip = startingIP
            while true {
                guard let prop = self.allIndexPaths.object(after: ip) else { return nil }
                if let p = shouldSelectItem(at: prop) {
                    return p
                }
                ip = prop
            }
        }
    }
    
}
