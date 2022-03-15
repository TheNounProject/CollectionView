//
//  CollectionViewMasonryLayout.swift
//  CollectionView
//
//  Created by Wesley Byrne on 9/12/16.
//  Copyright © 2016 Noun Project. All rights reserved.
//

import Foundation

/// CollectionViewDelegateFlowLayout
public protocol CollectionViewDelegateFlowLayout {
    
    // MARK: - Element Size
    /*-------------------------------------------------------------------------------*/
    
    /// Asks the delegate for the layout style for the item at the specified index path
    ///
    /// - Parameter collectionView: The collection view requesting the information
    /// - Parameter gridLayout: The layout
    /// - Parameter indexPath: The index path of the item to style
    ///
    /// - Returns: A style to apply to the item
    func collectionView(_ collectionView: CollectionView,
                        flowLayout: CollectionViewFlowLayout,
                        styleForItemAt indexPath: IndexPath) -> CollectionViewFlowLayout.ItemStyle
    
    /// Asks the delegate for the height of the header view in a specified section
    ///
    /// Return 0 for no header view
    ///
    /// - Parameter collectionView: The collection view requesting the information
    /// - Parameter collectionViewLayout: The layout
    /// - Parameter section: The section affected by this height
    ///
    /// - Returns: The height to apply to the header view in the specified section
    func collectionView (_ collectionView: CollectionView,
                         flowLayout collectionViewLayout: CollectionViewFlowLayout,
                         heightForHeaderInSection section: Int) -> CGFloat
    
    /// Asks the delegate for the height of the footer view in a specified section
    ///
    /// Return 0 for no footer view
    ///
    /// - Parameter collectionView: The collection view requesting the information
    /// - Parameter collectionViewLayout: The layout
    /// - Parameter section: The section affected by this height
    ///
    /// - Returns: The height to apply to the header view in the specified section
    func collectionView (_ collectionView: CollectionView,
                         flowLayout collectionViewLayout: CollectionViewFlowLayout,
                         heightForFooterInSection section: Int) -> CGFloat
    
    // MARK: - Insets & Transforms
    /*-------------------------------------------------------------------------------*/
    
    /// Asks the delegate for the insets for the content of the specified index path
    ///
    /// - Parameter collectionView: The collection view requesting the information
    /// - Parameter collectionViewLayout: The layout
    /// - Parameter section: Thhe section that the return value will be applied to
    ///
    /// - Returns: Edge insets for the specified section
    func collectionView (_ collectionView: CollectionView,
                         flowLayout collectionViewLayout: CollectionViewFlowLayout,
                         insetsForSectionAt section: Int) -> NSEdgeInsets
    
    /// Asks the delegate for a transform to apply to the content in each row the specified section, defaults to .none
    ///
    /// - Parameter collectionView: The collection requesting the information
    /// - Parameter collectionViewLayout: The layout
    /// - Parameter section: The section to transform
    ///
    /// - Returns: The type of row transform to apply
    func collectionView (_ collectionView: CollectionView,
                         flowLayout collectionViewLayout: CollectionViewFlowLayout,
                         rowTransformForSectionAt section: Int) -> CollectionViewFlowLayout.RowTransform
    
    /// <#Description#>
    /// - Parameters:
    ///   - collectionView: <#collectionView description#>
    ///   - collectionViewLayout: <#collectionViewLayout description#>
    ///   - section: <#section description#>
    func collectionView (_ collectionView: CollectionView,
                         flowLayout collectionViewLayout: CollectionViewFlowLayout,
                         interspanSpacingForSectionAt section: Int) -> CGFloat?
    
    func collectionView (_ collectionView: CollectionView,
                         flowLayout collectionViewLayout: CollectionViewFlowLayout,
                         interitemSpacingForSectionAt section: Int) -> CGFloat
}

extension CollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: CollectionView,
                               flowLayout: CollectionViewFlowLayout,
                               styleForItemAt indexPath: IndexPath) -> CollectionViewFlowLayout.ItemStyle {
        return flowLayout.defaultItemStyle
    }
    
    public func collectionView (_ collectionView: CollectionView,
                                flowLayout collectionViewLayout: CollectionViewFlowLayout,
                                heightForHeaderInSection section: Int) -> CGFloat {
        return collectionViewLayout.defaultHeaderHeight
    }
    
    public func collectionView (_ collectionView: CollectionView,
                                flowLayout collectionViewLayout: CollectionViewFlowLayout,
                                heightForFooterInSection section: Int) -> CGFloat {
        return collectionViewLayout.defaultFooterHeight
    }
    
    public func collectionView (_ collectionView: CollectionView,
                                flowLayout collectionViewLayout: CollectionViewFlowLayout,
                                insetsForSectionAt section: Int) -> NSEdgeInsets {
        return collectionViewLayout.defaultSectionInsets
    }
    
    public func collectionView (_ collectionView: CollectionView,
                                flowLayout collectionViewLayout: CollectionViewFlowLayout,
                                rowTransformForSectionAt section: Int) -> CollectionViewFlowLayout.RowTransform {
        return collectionViewLayout.defaultRowTransform
    }
    
    public func collectionView (_ collectionView: CollectionView,
                                flowLayout collectionViewLayout: CollectionViewFlowLayout,
                                interitemSpacingForSectionAt section: Int) -> CGFloat {
        return collectionViewLayout.interitemSpacing
    }
    
    public func collectionView (_ collectionView: CollectionView,
                                flowLayout collectionViewLayout: CollectionViewFlowLayout,
                                interspanSpacingForSectionAt section: Int) -> CGFloat? {
        return collectionViewLayout.interspanSpacing
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
open class CollectionViewFlowLayout: CollectionViewLayout {
    
    public var collectionView: CollectionView?
    
    public var scrollDirection: CollectionViewScrollDirection { return .vertical}
    
    public var allIndexPaths = OrderedSet<IndexPath>()
    
    // MARK: - Options
    /*-------------------------------------------------------------------------------*/
    /// If supporting views should be pinned to the top of the view
    open var pinHeadersToTop: Bool = true
    
    /// Spacing between flow elements
    public var interitemSpacing: CGFloat = 8
    
    @available(*, renamed: "interspanSpacing")
    public var interpanSpacing: CGFloat?
    /// Vertical spacing between multiple span elements (defaults to interitemSpacing)
    public var interspanSpacing: CGFloat?
    
    /// Top spacing between the span elements that are preceded by flow elements
    public var spanGroupSpacingBefore: CGFloat?
    
    /// Bottom spacing between span elements that are followed by flow elements
    public var spanGroupSpacingAfter: CGFloat?
    
    public var defaultItemStyle = ItemStyle.flow(CGSize(width: 60, height: 60))
    public var defaultFooterHeight: CGFloat = 0
    public var defaultHeaderHeight: CGFloat = 0
    public var defaultRowTransform: RowTransform = .none
    public var defaultSectionInsets: NSEdgeInsets = NSEdgeInsetsZero
    
    /// If supplementary views should be inset to section insets
    public var insetSupplementaryViews = false
    
    // MARK: - Layout Information
    /*-------------------------------------------------------------------------------*/
    
    /// Only used during layout preparation to reference the width of the previously inserted row
    private(set) public var widthOfLastRow: CGFloat?
    
    private var delegate: CollectionViewDelegateFlowLayout? {
        return self.collectionView?.delegate as? CollectionViewDelegateFlowLayout
    }
    
    private var sectionAttributes = [SectionAttributes]()
    
    /// Row transforms can be applied to flow elements that fall within the same row
    ///
    /// - none: No transform
    /// - center: Center the elements at their current size and spacing
    /// - fill: Enlarge the elements to fill the row specifying the max scale (< 1 for no max)
    public enum RowTransform {
        case none
        case center
        case fill(CGFloat)
        case custom(RowTransformer)
    }
    
    public typealias RowTransformer = ([(IndexPath, CGRect)], CGFloat) -> [CGRect]
    
    /// Styles for CollectionViewFlowLayout
    public enum ItemStyle {
        /// Flow items with like other surrounding like-sized items
        case flow(CGSize)
        /// Break from the flow positioning the item in it's own row
        case span(CGSize)
        
        var isSpan: Bool {
            switch self {
            case .span: return true
            default: return false
            }
        }
    }
    
    private struct RowAttributes: CustomStringConvertible {
        var frame = CGRect.null
        var itemHeight: CGFloat {
            return items.last?.frame.size.height ?? 0
        }
        var items: [CollectionViewLayoutAttributes]
        
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
            func apply(_ transformer: RowTransformer) -> CGRect {
                
                let _items = self.items.map { attrs in (attrs.indexPath, attrs.frame)}
                let transformed = transformer(_items, width)
                var union = CGRect()
                for (idx, item) in items.enumerated() {
                    let f = transformed[idx].integral
                    item.frame = f
                    union = union.union(f)
                }
                return union
            }
            var union: CGRect
            switch transform {
            case .center:
                let adjust = ((width - frame.size.width)/2)
                union = apply { (attrs, _) in
                    attrs.map { $0.1.offsetBy(dx: adjust, dy: 0) }
                }
                
            case let .fill(maxScale):
                var scale = width/frame.size.width
                if maxScale > 1 && scale  > maxScale { scale = maxScale }
                var left = leftInset
                union = apply { (attrs, _) in
                    attrs.map { attr -> CGRect in
                        var frame = attr.1
                        frame.origin.x = left
                        frame.size.width *= scale
                        frame.size.height *= scale
                        frame = frame.integral
                        left = frame.maxX + spacing
                        return frame
                    }
                }
            case let .custom(transformer):
                union = apply(transformer)
                
            case .none: union = self.frame
            }
            self.frame = self.frame.union(union)
            return self.frame.maxY
        }
        
        func index(of indexPath: IndexPath) -> Int? {
            guard let f = self.items.first,
                  let l = self.items.last else { return nil }
            
            if f.indexPath > indexPath { return nil }
            if l.indexPath < indexPath { return nil }
            return self.items.firstIndex {
                return $0.indexPath == indexPath
            }
        }
        
        func item(verticallyAlignedTo attrs: CollectionViewLayoutAttributes) -> IndexPath? {
            
            guard self.items.count > 1, !self.items.isEmpty,
                  let l = self.items.last else { return items.last?.indexPath }
            
            let center = attrs.frame.midX
            
            if l.frame.origin.x < center { return l.indexPath }
            return self.items.first {
                return $0.frame.maxX > center
            }?.indexPath
        }
        
        var description: String {
            return "Row Attributes : \(frame) -- \(items.count)"
        }
    }
    
    private struct SectionAttributes: CustomStringConvertible {
        var frame = CGRect.zero
        
        let insets: NSEdgeInsets
        let transform: RowTransform
        var contentFrame = CGRect.zero
        var header: CollectionViewLayoutAttributes?
        var footer: CollectionViewLayoutAttributes?
        var rows: [RowAttributes] = []
        var items: [CollectionViewLayoutAttributes] = []
        
        var description: String {
            return "Section Attributes : \(frame)  content: \(contentFrame)  Rows: \(rows.count)  Items: \(items.count)"
        }
        
        init(insets: NSEdgeInsets, transform: RowTransform) {
            self.insets = insets
            self.transform = transform
        }
    }
    
    public init() { }
    
    // MARK: - Layout Overrides
    /*-------------------------------------------------------------------------------*/
    
    private var _lastSize = CGSize.zero
    open func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return _lastSize != newBounds.size
    }
    
    public func invalidate() {
        
    }
    
    open func prepare() {
        
        self.allIndexPaths.removeAll()
        self.sectionAttributes.removeAll()
        guard let cv = self.collectionView else { return }
        
        self._lastSize = cv.frame.size
        
        let numSections = cv.numberOfSections
        guard numSections > 0 else { return }
        
        var top: CGFloat = self.collectionView?.leadingView?.bounds.size.height ?? 0
        
        let contentInsets = cv.contentInsets
        
        for sec in 0..<numSections {
            
            let _interitemSpacing = self.delegate?.collectionView(cv, flowLayout: self, interitemSpacingForSectionAt: sec) ?? self.interitemSpacing
            let _interspanSpacing = self.delegate?.collectionView(cv, flowLayout: self, interspanSpacingForSectionAt: sec) ?? self.interpanSpacing
            let insets = self.delegate?.collectionView(cv, flowLayout: self, insetsForSectionAt: sec) ?? self.defaultSectionInsets
            let transform = self.delegate?.collectionView(cv, flowLayout: self, rowTransformForSectionAt: sec) ?? self.defaultRowTransform
            
            var sectionAttrs = SectionAttributes(insets: insets, transform: transform)
            let numItems = cv.numberOfItems(in: sec)
            
            sectionAttrs.frame.origin.y = top
            sectionAttrs.contentFrame.origin.y = top
            
            let contentWidth = cv.contentVisibleRect.size.width - insets.width
            
            let heightHeader: CGFloat = self.delegate?.collectionView(cv, flowLayout: self, heightForHeaderInSection: sec) ?? self.defaultHeaderHeight
            if heightHeader > 0 {
                let attrs = CollectionViewLayoutAttributes(forSupplementaryViewOfKind: CollectionViewLayoutElementKind.SectionHeader,
                                                           with: IndexPath.for(section: sec))
                
                attrs.frame = insetSupplementaryViews
                    ? CGRect(x: insets.left, y: top, width: contentWidth, height: heightHeader)
                    : CGRect(x: contentInsets.left, y: top, width: cv.frame.size.width - contentInsets.width, height: heightHeader)
                sectionAttrs.header = attrs
                sectionAttrs.frame = attrs.frame
                top = attrs.frame.maxY
            }
            
            top += insets.top
            sectionAttrs.contentFrame.origin.y = top
            
            var previousStyle: ItemStyle?
            if numItems > 0 {
                
                func adjustOversizedIfNeeded(_ attributes: CollectionViewLayoutAttributes) {
                    if attributes.frame.size.width > contentWidth {
                        let scale = contentWidth/attributes.frame.size.width
                        attributes.frame.size = CGSize(width: attributes.frame.size.width * scale, height: attributes.frame.size.height * scale)
                    }
                }
                
                var forceBreak: Bool = false
                for item in 0..<numItems {
                    let ip = IndexPath.for(item: item, section: sec)
                    allIndexPaths.append(ip)
                    let style = self.delegate?.collectionView(cv, flowLayout: self, styleForItemAt: ip) ?? defaultItemStyle
                    let attrs = CollectionViewLayoutAttributes(forCellWith: ip)
                    
                    switch style {
                    case let .flow(size):
                        
                        func newRow() {
                            
                            var spacing: CGFloat = 0
                            if !sectionAttrs.rows.isEmpty {
                                top = sectionAttrs.rows[sectionAttrs.rows.count - 1].applyTransform(transform,
                                                                                                    leftInset: insets.left,
                                                                                                    width: contentWidth,
                                                                                                    spacing: _interitemSpacing)
                                
                                if let s = self.spanGroupSpacingAfter, previousStyle?.isSpan == true {
                                    spacing = s
                                } else {
                                    spacing = _interitemSpacing
                                }
                            }
                            
                            attrs.frame = CGRect(x: insets.left, y: top + spacing, width: size.width, height: size.height)
                            adjustOversizedIfNeeded(attrs)
                            sectionAttrs.rows.append(RowAttributes(attributes: attrs))
                        }
                        
                        // Check if the last row (if any) matches this items height
                        if !forceBreak, let prev = sectionAttrs.rows.last?.items.last, prev.frame.size.height == size.height {
                            // If there is enough space remaining, add it to the current row
                            let rem = contentWidth - (prev.frame.maxX - contentInsets.left - insets.left) - _interitemSpacing
                            if rem >= size.width {
                                attrs.frame = CGRect(x: prev.frame.maxX + _interitemSpacing, y: prev.frame.origin.y,
                                                     width: size.width, height: size.height)
                                sectionAttrs.rows[sectionAttrs.rows.count - 1].add(attributes: attrs)
                            } else { newRow() }
                        } else { newRow() }
                        forceBreak = false
                        
                    case let .span(size):
                        
                        if !sectionAttrs.rows.isEmpty && previousStyle?.isSpan != true {
                            top = sectionAttrs.rows[sectionAttrs.rows.count - 1].applyTransform(transform,
                                                                                                leftInset: insets.left,
                                                                                                width: contentWidth,
                                                                                                spacing: _interitemSpacing)
                        }
                        
                        var spacing: CGFloat = 0
                        if !sectionAttrs.rows.isEmpty {
                            if let s = self.spanGroupSpacingBefore, previousStyle?.isSpan == false {
                                spacing = s
                            } else if let s = _interspanSpacing, previousStyle?.isSpan == true {
                                spacing = s
                            } else {
                                spacing = _interitemSpacing
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
                if !sectionAttrs.rows.isEmpty {
                    top = sectionAttrs.rows[sectionAttrs.rows.count - 1].applyTransform(transform,
                                                                                        leftInset: insets.left,
                                                                                        width: contentWidth,
                                                                                        spacing: _interitemSpacing)
                }
            }
            
            top += insets.bottom
            sectionAttrs.frame = sectionAttrs.frame.union(sectionAttrs.contentFrame)
            sectionAttrs.frame.size.height += insets.bottom
            
            let footerHeader: CGFloat = self.delegate?.collectionView(cv, flowLayout: self, heightForFooterInSection: sec) ?? 0
            if footerHeader > 0 {
                let attrs = CollectionViewLayoutAttributes(forSupplementaryViewOfKind: CollectionViewLayoutElementKind.SectionFooter,
                                                           with: IndexPath.for(section: sec))
                attrs.frame = insetSupplementaryViews
                    ? CGRect(x: insets.left + contentInsets.left, y: top, width: contentWidth, height: heightHeader)
                    : CGRect(x: contentInsets.left, y: top,
                             width: cv.contentVisibleRect.size.width - contentInsets.left - contentInsets.right, height: heightHeader)
                sectionAttrs.footer = attrs
                sectionAttrs.frame = sectionAttrs.frame.union(attrs.frame)
                top = attrs.frame.maxY
            }
            
            sectionAttributes.append(sectionAttrs)
            
        }
    }
    
    // MARK: - Query Content
    /*-------------------------------------------------------------------------------*/
    open func indexPathsForItems(in rect: CGRect) -> [IndexPath] {
        return itemAttributes(in: rect) { return $0.indexPath }
    }
    
    open func layoutAttributesForItems(in rect: CGRect) -> [CollectionViewLayoutAttributes] {
        return itemAttributes(in: rect) { return $0.copy() }
    }
    
    private func itemAttributes<T>(in rect: CGRect, reducer: ((CollectionViewLayoutAttributes) -> T)) -> [T] {
        guard !rect.isEmpty && !self.sectionAttributes.isEmpty else { return [] }
        
        var results = [T]()
        for sAttrs in self.sectionAttributes {
            
            // If we have passed the target, finish
            guard sAttrs.frame.intersects(rect) else {
                guard sAttrs.frame.origin.y < rect.maxY else { break }
                continue
            }
            
            // If the section is completely shown, add all the attrs
            if rect.contains(sAttrs.frame) {
                results.append(contentsOf: sAttrs.items.map { return reducer($0) })
            }
            // Scan the rows of the section
            else if !sAttrs.rows.isEmpty {
                for row in sAttrs.rows {
                    guard row.frame.intersects(rect) else {
                        guard row.frame.origin.y < rect.maxY else { break }
                        continue
                    }
                    for item in row.items where item.frame.intersects(rect) {
                        results.append(reducer(item))
                    }
                }
            }
        }
        return results
    }
    
    open func layoutAttributesForItem(at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
        return self.sectionAttributes.object(at: indexPath._section)?.items.object(at: indexPath._item)?.copy()
    }
    
    open func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
        
        if elementKind == CollectionViewLayoutElementKind.SectionHeader {
            let attrs = self.sectionAttributes[indexPath._section].header?.copy()
            if pinHeadersToTop, let currentAttrs = attrs, let cv = self.collectionView {
                
                let contentOffset = cv.contentOffset
                let frame = currentAttrs.frame
                
                //                let lead = cv.leadingView?.bounds.size.height ?? 0
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
                currentAttrs.frame.origin.y =  min(max(contentOffset.y + topInset, frame.origin.y), nextHeaderOrigin.y - frame.height)
                currentAttrs.floating = indexPath._section == 0 || currentAttrs.frame.origin.y > frame.origin.y
                //                }
            }
            return attrs
        } else if elementKind == CollectionViewLayoutElementKind.SectionFooter {
            return self.sectionAttributes[indexPath._section].footer?.copy()
        }
        return nil
    }
    
    open func rectForSection(_ section: Int) -> CGRect {
        return sectionAttributes[section].frame
    }
    
    open func contentRectForSection(_ section: Int) -> CGRect {
        return sectionAttributes[section].contentFrame
    }
    
    open var collectionViewContentSize: CGSize {
        guard let cv = collectionView else { return CGSize.zero }
        let numberOfSections = cv.numberOfSections
        if numberOfSections == 0 { return CGSize.zero }
        
        var contentSize = cv.contentVisibleRect.size as CGSize
        let height = self.sectionAttributes.last?.frame.maxY ?? 0
        if height == 0 { return CGSize.zero }
        contentSize.height = max(height, cv.contentVisibleRect.height - cv.contentInsets.height)
        return  contentSize
    }
    
    open func scrollRectForItem(at indexPath: IndexPath, atPosition: CollectionViewScrollPosition) -> CGRect? {
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
        
        frame.origin.y += inset
        return frame
    }
    
    open func indexPathForNextItem(moving direction: CollectionViewDirection, from currentIndexPath: IndexPath) -> IndexPath? {
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
            
            var proposed: IndexPath?
            var prev: RowAttributes?
            for row in sectionAttributes[section].rows {
                if row.index(of: currentIndexPath) != nil {
                    guard let pRow = prev else {
                        guard let pSectionRow = sectionAttributes.object(at: section - 1)?.rows.last else { return nil }
                        proposed = pSectionRow.item(verticallyAlignedTo: cAttrs)
                        break
                    }
                    proposed = pRow.item(verticallyAlignedTo: cAttrs)
                    break
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
            
            var proposed: IndexPath?
            var prev: RowAttributes?
            for row in sectionAttributes[section].rows.reversed() {
                if row.index(of: currentIndexPath) != nil {
                    guard let pRow = prev else {
                        guard let pSectionRow = sectionAttributes.object(at: section + 1)?.rows.first else { return nil }
                        proposed = pSectionRow.item(verticallyAlignedTo: cAttrs)
                        break
                    }
                    proposed = pRow.item(verticallyAlignedTo: cAttrs)
                    break
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
