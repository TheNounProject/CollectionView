//
//  CollectionViewLayout.swift
//  Lingo
//
//  Created by Wesley Byrne on 1/27/16.
//  Copyright © 2016 The Noun Project. All rights reserved.
//

import Foundation

/// The delegate for CollectionViewColumnLayout to dynamically customize the layout
@objc public protocol CollectionViewDelegateColumnLayout: CollectionViewDelegate {
    
    // MARK: - Spacing & Insets
    /*-------------------------------------------------------------------------------*/
    
    /// Asks the delegate for the number fo columns in a section
    ///
    /// - Parameter collectionView: The collection view
    /// - Parameter collectionViewLayout: The layout
    /// - Parameter section: A section index
    ///
    /// - Returns: The desired number of columns in the section
    @objc optional func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout,
                                       numberOfColumnsInSection section: Int) -> Int
    
    /// Asks the delegate for insets to be applied to content of a given section
    ///
    /// - Parameter collectionView: The collection view
    /// - Parameter collectionViewLayout: The layout
    /// - Parameter section: A section index
    ///
    /// - Returns: Insets for the section
    @objc optional func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout,
                                       insetForSectionAt section: NSInteger) -> NSEdgeInsets
    
    // Between to items in the same column
    
    /// Asks the delegate for the item spacing to be applied to items of the same column of a section
    ///
    /// - Parameter collectionView: The collection view
    /// - Parameter collectionViewLayout: The layout
    /// - Parameter section: A section index
    ///
    /// - Returns: The desired spacing between items in the same column
    @objc optional func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout,
                                       interitemSpacingForSectionAt section: Int) -> CGFloat
    
    /// Asks the delegate for the column spacing to applied to items in a given section
    ///
    /// - Parameter collectionView: The collection view
    /// - Parameter collectionViewLayout: The layout
    /// - Parameter section: A section index
    ///
    /// - Returns: The desired spacing between columns in the section
    @objc optional func collectionview(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout,
                                       columnSpacingForSectionAt section: Int) -> CGFloat
    
    // MARK: - Item Size
    /*-------------------------------------------------------------------------------*/
    
    /// The height for the item at the given indexPath (Priority 2)
    ///
    /// - parameter collectionView:       The collection view the item is in
    /// - parameter collectionViewLayout: The CollectionViewLayout
    /// - parameter indexPath:            The indexPath for the item
    ///
    /// - returns: The height for the item
    @objc optional func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout,
                                       heightForItemAt indexPath: IndexPath) -> CGFloat
    
    /// The aspect ration for the item at the given indexPath (Priority 1). Width and height must be greater than 0.
    ///
    /// - parameter collectionView:       The collection view the item is in
    /// - parameter collectionViewLayout: The CollectionViewLayout
    /// - parameter indexPath:            The indexPath for the item
    ///
    /// - returns: The aspect ration for the item
    @objc optional func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout,
                                       aspectRatioForItemAt indexPath: IndexPath) -> CGSize
    
    // MARK: - Header & Footer Size
    /*-------------------------------------------------------------------------------*/
    
    /// Asks the delegate for the height of the header in the given section
    ///
    /// - Parameter collectionView: The collection view
    /// - Parameter collectionViewLayout: The layout
    /// - Parameter section: A section index
    /// - Returns: The desired header height or 0 for no header
    @objc optional func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout,
                                       heightForHeaderInSection section: Int) -> CGFloat
    
    /// Asks the delegate for the height of the footer in the given section
    ///
    /// - Parameter collectionView: The collection view
    /// - Parameter collectionViewLayout: The layout
    /// - Parameter section: A section index
    /// - Returns: The desired footer height or 0 for no footer
    @objc optional func collectionView (_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout,
                                        heightForFooterInSection section: Int) -> CGFloat
    
}

/// CollectionViewLayoutElementKind
public struct CollectionViewLayoutElementKind {
    public static let SectionHeader: String = "CollectionElementKindSectionHeader"
    public static let SectionFooter: String = "CollectionElementKindSectionFooter"
}

extension CollectionViewColumnLayout {
    @available(*, deprecated, renamed: "LayoutStrategy")
    public typealias ItemRenderDirection = LayoutStrategy
    
    @available(*, deprecated, renamed: "layoutStrategy")
    open var itemRenderDirection: LayoutStrategy {
        get { return layoutStrategy }
        set { self.layoutStrategy = newValue }
    }
}

/**
 This layout is column based which means you provide the number of columns and cells are placed in the appropriate one. It can be display items all the same size or as a "Pinterest" style layout.
 
 The number of columns can be set dynamically by the delegate or you can provide a default value using `layout.columnCount`.
 
 You can also set the `sectionInsets` and `minimumColumnSpacing` which will affect the width of each column.
 
 With the itemWidth set by the column, you have 3 options to set the height of each item. They are used in the order here. So if aspectRatioForItemAtIndexPath is implemented it is used, otherwise, it checks the next one.
 
 1. aspectRatioForItemAtIndexPath (delegate)
 2. heightForItemAtIndexPath (delegate)
 3. layout.defaultItemHeight
 
 The delegate method aspectRatioForItemAtIndexPath scales the size of the cell to maintain that ratio while fitting within the caclulated column width.
 
 Mixed use of ratios and heights is also supported. Returning CGSize.zero for a ratio will fall back to the hight. If a valid ratio and height are provided, the height will be appended to the height to respect the ratio. For example, if the column width comes out to 100, a ratio of 2 will determine a height of 200. If a height is also provided by the delegate for the same item, say 20 it will be added, totalling 220.
 
*/
open class CollectionViewColumnLayout: CollectionViewLayout {
    
    /// The method to use when directing items into columns
    ///
    /// - shortestFirst: Use the current column
    /// - leftToRight: Always insert left to right
    /// - rightToLeft: Always insert right to left
    public enum LayoutStrategy {
        case shortestFirst
        case leftToRight
        case rightToLeft
    }
    
    // MARK: - Default layout values
    
    /// The default column count
    open var columnCount: NSInteger = 2 { didSet { invalidate() }}

    /// The spacing between each column
    open var columnSpacing: CGFloat = 8 { didSet { invalidate() }}
    
    /// The vertical spacing between items in the same column
    open var interitemSpacing: CGFloat = 8 { didSet { invalidate() }}

    /// The height of section header views
    open var headerHeight: CGFloat = 0.0 { didSet { invalidate() }}

    /// The height of section footer views
    open var footerHeight: CGFloat = 0.0 { didSet { invalidate() }}

    /// The default height to apply to all items
    open var itemHeight: CGFloat = 50 { didSet { invalidate() }}

    /// If supplementary views should respect section insets or fill the CollectionView width
    open var insetSupplementaryViews: Bool = false { didSet { invalidate() }}
    
    /// If set to true, the layout will invalidate on all bounds changes, if false only on width changes
    open var invalidateOnBoundsChange: Bool = false { didSet { invalidate() }}

    /// Default insets for all sections
    open var sectionInset: NSEdgeInsets = NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8) { didSet { invalidate() }}
    
    // MARK: - Render Options
    /// A hint as to how to render items when deciding which column to place them in
    open var layoutStrategy: LayoutStrategy = .leftToRight { didSet { invalidate() }}

    //  private property and method above.
    private weak var delegate: CollectionViewDelegateColumnLayout? { return self.collectionView!.delegate as? CollectionViewDelegateColumnLayout }
    
    private var sections: [SectionAttributes] = []
    
    private class Column {
        var frame: CGRect
        var height: CGFloat { return items.last?.frame.maxY ?? 0 }
        var items: [CollectionViewLayoutAttributes] = []
        init(frame: CGRect) {
            self.frame = frame
        }
        func append(item: CollectionViewLayoutAttributes) {
            self.items.append(item)
            self.frame = self.frame.union(item.frame)
        }
    }
    
    private class SectionAttributes: CustomStringConvertible {
        var frame = CGRect.zero
        var contentFrame = CGRect.zero
        let insets: NSEdgeInsets
        var header: CollectionViewLayoutAttributes?
        var footer: CollectionViewLayoutAttributes?
        
        var columns = [Column]()
        var items = [CollectionViewLayoutAttributes]()
        
        init(frame: CGRect, insets: NSEdgeInsets) {
            self.frame = frame
            self.insets = insets
        }
        
        func prepareColumns(_ count: Int, spacing: CGFloat, in rect: CGRect) {
            self.contentFrame = rect
            let y = rect.minY
            let gapCount = CGFloat(count-1)
            let width = round((rect.width - (gapCount * spacing)) / CGFloat(count))
            var x = rect.minX - spacing - width
            
            self.columns = (0..<count).map({ _ -> Column in
                x += (spacing + width)
                return Column(frame: CGRect(x: x, y: y, width: width, height: 0))
            })
        }
        
        var description: String {
            return "Section Attributes : \(frame)  content: \(contentFrame) Items: \(items.count)"
        }
        
        func addItem(for indexPath: IndexPath, aspectRatio ratio: CGSize?, variableHeight: CGFloat?, defaultHeight: CGFloat, spacing: CGFloat, strategy: LayoutStrategy) {
            
            let column = self.nextColumnIndexForItem(indexPath, strategy: strategy)
            let width = column.frame.size.width
            
            var itemHeight: CGFloat = 0
            if let ratio = ratio, ratio.width != 0 && ratio.height != 0 {
                let h = ratio.height * (width/ratio.width)
                itemHeight = floor(h)
                
                if let addHeight = variableHeight {
                    itemHeight += addHeight
                }
            } else {
                itemHeight = variableHeight ?? defaultHeight
            }
            
            let item = CollectionViewLayoutAttributes(forCellWith: indexPath)
            let y = column.frame.maxY + spacing
            item.frame = CGRect(x: column.frame.minX, y: y,
                                width: width, height: itemHeight)
            
            self.items.append(item)
            column.append(item: item)
        }
        
        func finalizeColumns() {
            let cBounds = columns.reduce(CGRect.null) { return $0.union($1.frame) }
            self.contentFrame = self.contentFrame.union(cBounds)
            self.frame = self.frame.union(self.contentFrame)
        }
        
        private func nextColumnIndexForItem(_ indexPath: IndexPath, strategy: LayoutStrategy) -> Column {
            switch strategy {
            case .shortestFirst :
                return columns.min(by: { (c1, c2) -> Bool in
                    return c1.frame.size.height < c2.frame.size.height
                })!
            case .leftToRight :
                let colCount = self.columns.count
                let index = (indexPath._item % colCount)
                return self.columns[index]
            case .rightToLeft:
                let colCount = self.columns.count
                let index = (colCount - 1) - (indexPath._item % colCount)
                return self.columns[index]
            }
        }
    }

    override public init() {
        super.init()
    }
    
    private var _lastSize = CGSize.zero
    override open func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return _lastSize != newBounds.size
    }
    
    override open func prepare() {
        self.allIndexPaths.removeAll()
        self.sections.removeAll()
        
        guard let cv = self.collectionView, cv.numberOfSections > 0 else {
            return
        }
        self._lastSize = cv.frame.size
        
        let numberOfSections = cv.numberOfSections
        let contentInsets = cv.contentInsets
        var top: CGFloat = self.collectionView?.leadingView?.bounds.size.height ?? 0
        
        for sectionIdx in 0..<numberOfSections {
            
            let colCount: Int = {
                let c = self.delegate?.collectionView?(cv, layout: self, numberOfColumnsInSection: sectionIdx) ?? self.columnCount
                return max(c, 1)
            }()
            
            // 1. Get section-specific metrics (minimumInteritemSpacing, sectionInset)
 
            let sectionInsets = self.delegate?.collectionView?(cv, layout: self, insetForSectionAt: sectionIdx) ?? self.sectionInset
            let itemSpacing = self.delegate?.collectionView?(cv, layout: self, interitemSpacingForSectionAt: sectionIdx) ?? self.interitemSpacing
            let columnSpacing = self.delegate?.collectionview?(cv, layout: self, columnSpacingForSectionAt: sectionIdx) ?? self.columnSpacing
            
            let contentWidth = cv.contentVisibleRect.size.width - (contentInsets.width + sectionInsets.width)
            
            let section = SectionAttributes(frame: CGRect(x: contentInsets.left, y: top, width: contentWidth, height: 0), insets: sectionInsets)
            
            // 2. Section header
            
            let heightHeader: CGFloat = self.delegate?.collectionView?(cv, layout: self, heightForHeaderInSection: sectionIdx) ?? self.headerHeight
            if heightHeader > 0 {
                let attributes = CollectionViewLayoutAttributes(forSupplementaryViewOfKind: CollectionViewLayoutElementKind.SectionHeader,
                                                                with: IndexPath.for(section: sectionIdx))
                attributes.frame = insetSupplementaryViews
                    ? CGRect(x: sectionInsets.left, y: top, width: contentWidth, height: heightHeader).integral
                    : CGRect(x: contentInsets.left, y: top, width: cv.frame.size.width - contentInsets.width, height: heightHeader).integral
                section.header = attributes
                top = attributes.frame.maxY
            }
            
            top += sectionInsets.top
    
            section.prepareColumns(colCount,
                                   spacing: columnSpacing,
                                   in: CGRect(x: sectionInsets.left, y: top, width: contentWidth, height: 0))
            
            // 3. Section items

            let itemCount = cv.numberOfItems(in: sectionIdx)
            
            // Item will be put into shortest column.
            for idx in 0..<itemCount {
                let indexPath = IndexPath.for(item: idx, section: sectionIdx)
                allIndexPaths.append(indexPath)
                
                let ratio = self.delegate?.collectionView?(cv, layout: self, aspectRatioForItemAt: indexPath)
                let height = self.delegate?.collectionView?(cv, layout: self, heightForItemAt: indexPath)
                
                section.addItem(for: indexPath,
                                aspectRatio: ratio,
                                variableHeight: height,
                                defaultHeight: self.itemHeight,
                                spacing: itemSpacing, strategy: self.layoutStrategy)

            }
            
            // 4. Section footer
            
            section.finalizeColumns()
            top = section.frame.maxY
            
            let footerHeight = self.delegate?.collectionView?(cv, layout: self, heightForFooterInSection: sectionIdx) ?? self.footerHeight
            if footerHeight > 0 {
                let attributes = CollectionViewLayoutAttributes(forSupplementaryViewOfKind: CollectionViewLayoutElementKind.SectionFooter,
                                                                with: IndexPath.for(item: 0, section: sectionIdx))
                attributes.frame = insetSupplementaryViews ?
                    CGRect(x: sectionInsets.left, y: top, width: cv.contentVisibleRect.size.width - sectionInsets.width, height: footerHeight)
                    : CGRect(x: 0, y: top, width: cv.contentVisibleRect.size.width, height: footerHeight)
                
                section.footer = attributes
                section.frame.size.height += attributes.frame.size.height
                top = attributes.frame.maxY
            }
            section.frame.size.height += sectionInsets.bottom
            top = section.frame.maxY
            sections.append(section)
        }
    }
    
    override open var collectionViewContentSize: CGSize {
        guard let cv = collectionView else { return CGSize.zero }
        let numberOfSections = cv.numberOfSections
        if numberOfSections == 0 { return CGSize.zero }
        
        var contentSize = cv.contentVisibleRect.size
        contentSize.width -= cv.contentInsets.width
        
        let height = self.sections.last?.frame.maxY ?? 0
        if height == 0 { return CGSize.zero }
        contentSize.height = height
        return  contentSize
    }
    
    open override func rectForSection(_ section: Int) -> CGRect {
        return self.sections[section].frame
    }
    open override func contentRectForSection(_ section: Int) -> CGRect {
        return self.sections[section].contentFrame
    }
    
    open override func indexPathsForItems(in rect: CGRect) -> [IndexPath] {
        return itemAttributes(in: rect) { return $0.indexPath }
    }
    
    open override func layoutAttributesForItems(in rect: CGRect) -> [CollectionViewLayoutAttributes] {
        return itemAttributes(in: rect) { return $0.copy() }
    }
    
    open func itemAttributes<T>(in rect: CGRect, reducer: ((CollectionViewLayoutAttributes) -> T)) -> [T] {
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
            } else {
                for column in section.columns {
                    guard column.frame.intersects(rect) else {
                        continue
                    }
                    for item in column.items {
                        guard item.frame.intersects(rect) else {
                            continue
                        }
                        results.append(reducer(item))
                    }
                }
            }
        }
        return results
    }
    
    open override func layoutAttributesForItem(at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
        return self.sections.object(at: indexPath._section)?.items.object(at: indexPath._item)?.copy()
    }
    
    open override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
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
                attrs.floating = indexPath._section == 0 || attrs.frame.origin.y > frame.origin.y
            }
            return attrs
        } else if elementKind == CollectionViewLayoutElementKind.SectionFooter {
            return section.footer?.copy()
        }
        return nil
    }
    
    open override func scrollRectForItem(at indexPath: IndexPath, atPosition: CollectionViewScrollPosition) -> CGRect? {
        guard var frame = self.layoutAttributesForItem(at: indexPath)?.frame else { return nil }
        let inset = (self.collectionView?.contentInsets.top ?? 0)
        
        if self.pinHeadersToTop,
            let attrs = self.layoutAttributesForSupplementaryView(ofKind: CollectionViewLayoutElementKind.SectionHeader,
                                                                  at: IndexPath.for(item: 0, section: indexPath._section)) {
            let y = (frame.origin.y - attrs.frame.size.height) // + inset
            
            let height = frame.size.height + attrs.frame.size.height
            frame.size.height = height
            frame.origin.y = y
        } else {
            frame.origin.y += inset
        }
        return frame
    }
    
    open override func indexPathForNextItem(moving direction: CollectionViewDirection, from currentIndexPath: IndexPath) -> IndexPath? {
        guard let collectionView = self.collectionView else { fatalError() }
        
        var index = currentIndexPath._item
        var section = currentIndexPath._section
        
        let numberOfSections = collectionView.numberOfSections
        let numberOfItemsInSection = collectionView.numberOfItems(in: currentIndexPath._section)
        
        guard collectionView.rectForItem(at: currentIndexPath) != nil else { return nil }
        
        switch direction {
        case .up:
            guard let cAttrs = collectionView.layoutAttributesForItem(at: currentIndexPath),
                let columns = self.sections.object(at: section)?.columns else { return nil }
            
            let cFlat = CGRect(x: cAttrs.frame.origin.x, y: 0, width: cAttrs.frame.size.width, height: 50)
            
            for column in columns {
                if let first = column.items.first {
                    // This is the first item in the column -> Check the previous section
                    if first.indexPath == currentIndexPath {
                        guard let previousSection = sections.object(at: section - 1) else { return nil }
                        let pColumns = previousSection.columns
                        for col in pColumns.reversed() where !col.items.isEmpty {
                            let flat = CGRect(x: col.frame.origin.x, y: 0, width: col.frame.size.width, height: 50)
                            if cFlat.intersects(flat) {
                                return col.items.last?.indexPath
                            }
                        }
                        return previousSection.items.last?.indexPath
                    }
                    
                    let flat = CGRect(x: first.frame.origin.x, y: 0, width: first.frame.size.width, height: 50)
                    
                    // Get the same column
                    if cFlat.intersects(flat) {
                        guard let idx = (column.items.firstIndex { return $0.indexPath == currentIndexPath  }) else {
                            return nil
                        }
                        let next = column.items.index(before: idx)
                        return column.items.object(at: next)?.indexPath
                    }
                }
            }
            return nil
            
        case .down:
            
            guard let cAttrs = collectionView.layoutAttributesForItem(at: currentIndexPath),
                let columns = self.sections.object(at: section)?.columns else { return nil }
            
            let cFlat = CGRect(x: cAttrs.frame.origin.x, y: 0, width: cAttrs.frame.size.width, height: 50)
            
            for column in columns {
                if let first = column.items.first {
                    // This is the last item in the column -> Check the previous section
                    if column.items.last?.indexPath == currentIndexPath {
                        guard let nextSection = sections.object(at: section + 1) else { return nil }
                        let pColumns = nextSection.columns
                        
                        for col in pColumns where !col.items.isEmpty {
                            let flat = CGRect(x: col.frame.origin.x, y: 0, width: col.frame.size.width, height: 50)
                            if cFlat.intersects(flat) {
                                return col.items.first?.indexPath
                            }
                        }
                        return nextSection.items.last?.indexPath
                    }
                    
                    let flat = CGRect(x: first.frame.origin.x, y: 0, width: first.frame.size.width, height: 50)
                    
                    // Get the same column
                    if cFlat.intersects(flat) {
                        guard let idx = (column.items.firstIndex { return $0.indexPath == currentIndexPath  }) else {
                            return nil
                        }
                        let next = column.items.index(after: idx)
                        return column.items.object(at: next)?.indexPath
                    }
                }
            }
            return nil
            
        case .left:
            if section == 0 && index == 0 {
                return currentIndexPath
            }
            if index > 0 {
                index -= 1
            } else {
                section -= 1
                index = collectionView.numberOfItems(in: currentIndexPath._section - 1) - 1
            }
            return IndexPath.for(item: index, section: section)
        case .right :
            if section == numberOfSections - 1 && index == numberOfItemsInSection - 1 {
                return currentIndexPath
            }
            if index < numberOfItemsInSection - 1 {
                index += 1
            } else {
                section += 1
                index = 0
            }
            return IndexPath.for(item: index, section: section)
        }
    }
}
