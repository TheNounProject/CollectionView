//
//  CBCollectionViewLayout.swift
//  Lingo
//
//  Created by Wesley Byrne on 1/27/16.
//  Copyright © 2016 The Noun Project. All rights reserved.
//

import Foundation



/**
 *  The delegate for CBCollectionViewLayout
 */
@objc public protocol CBCollectionViewDelegateColumnLayout: CBCollectionViewDelegate {
    
    /**
     The height for the item at the given indexPath (Priority 2)
     
     - parameter collectionView:       The collection view the item is in
     - parameter collectionViewLayout: The CollectionViewLayout
     - parameter indexPath:            The indexPath for the item
     
     - returns: The height for the item
     */
    @objc optional func collectionView (_ collectionView: CBCollectionView,layout collectionViewLayout: CBCollectionViewLayout,
        heightForItemAtIndexPath indexPath: IndexPath) -> CGFloat
    
    /**
     The aspect ration for the item at the given indexPath (Priority 1). Width and height must be greater than 0.
     
     - parameter collectionView:       The collection view the item is in
     - parameter collectionViewLayout: The CollectionViewLayout
     - parameter indexPath:            The indexPath for the item
     
     - returns: The aspect ration for the item
     */
    @objc optional func collectionView (_ collectionView: CBCollectionView,layout collectionViewLayout: CBCollectionViewLayout,
        aspectRatioForItemAtIndexPath indexPath: IndexPath) -> CGSize
    
    @objc optional func collectionView (_ collectionView: CBCollectionView, layout collectionViewLayout: CBCollectionViewLayout,
        heightForHeaderInSection section: NSInteger) -> CGFloat
    
    @objc optional func collectionView (_ collectionView: CBCollectionView, layout collectionViewLayout: CBCollectionViewLayout,
        heightForFooterInSection section: NSInteger) -> CGFloat
    
    @objc optional func collectionView (_ collectionView: CBCollectionView, layout collectionViewLayout: CBCollectionViewLayout,
        numberOfColumnsInSection section: Int) -> Int
    
    @objc optional func collectionView (_ collectionView: CBCollectionView, layout collectionViewLayout: CBCollectionViewLayout,
        insetForSectionAtIndex section: NSInteger) -> EdgeInsets
    
    // Between to items in the same column
    @objc optional func collectionView (_ collectionView: CBCollectionView, layout collectionViewLayout: CBCollectionViewLayout,
        minimumInteritemSpacingForSectionAtIndex section: NSInteger) -> CGFloat
    
    @objc optional func collectionview(_ collectionView: CBCollectionView, layout collectionViewLayout: CBCollectionViewLayout,
        minimumColumnSpacingForSectionAtIndex section: NSInteger) -> CGFloat
    
}


public enum CBCollectionViewLayoutItemRenderDirection : NSInteger {
    case shortestFirst
    case leftToRight
    case rightToLeft
}

public struct CBCollectionViewLayoutElementKind {
    public static let SectionHeader: String = "CBCollectionElementKindSectionHeader"
    public static let SectionFooter: String = "CBCollectionElementKindSectionFooter"
}




/// A feature packed collection view layout with pinterest like layouts, aspect ratio sizing, and drag and drop.
open class CBCollectionViewColumnLayout : CBCollectionViewLayout {
    
    //MARK: - Default layout values
    
    /// The default column count
    open var columnCount : NSInteger = 2 { didSet{ invalidateLayout() }}

    /// The spacing between each column
    open var minimumColumnSpacing : CGFloat = 8 { didSet{ invalidateLayout() }}
    
    /// The vertical spacing between items in the same column
    open var minimumInteritemSpacing : CGFloat = 8 { didSet{ invalidateLayout() }}

    /// The height of section header views
    open var headerHeight : CGFloat = 0.0 { didSet{ invalidateLayout() }}

    /// The height of section footer views
    open var footerHeight : CGFloat = 0.0 { didSet{ invalidateLayout() }}

    /// The default height to apply to all items
    open var defaultItemHeight : CGFloat = 50 { didSet{ invalidateLayout() }}

    /// If supplementary views should respect section insets or fill the CollectionView width
    open var insetSupplementaryViews : Bool = false { didSet{ invalidateLayout() }}

    /// Default insets for all sections
    open var sectionInset : EdgeInsets = EdgeInsets(top: 8, left: 8, bottom: 8, right: 8) { didSet{ invalidateLayout() }}
    
    // MARK: - Render Options
    /// A hint as to how to render items when deciding which column to place them in
    open var itemRenderDirection : CBCollectionViewLayoutItemRenderDirection = .leftToRight { didSet{ invalidateLayout() }}
    
    open func numberOfColumnsInSection(_ section: Int) -> Int {
        if columnHeights.count > 0 && section >= 0 && section < columnHeights.count {
            return columnHeights[section].count
        }
        return 0
    }
    
    open var isGrid : Bool = true
    
    // Internal caching
    fileprivate var _itemWidth : CGFloat = 0
    fileprivate var _cvSize = CGSize.zero
    /// the calculated width of items based on the total width and number of columns (read only)
    open var itemWidth : CGFloat { get { return _itemWidth }}
    
    
    fileprivate var numSections : Int { get { return self.collectionView!.numberOfSections() }}
    fileprivate func columnsInSection(_ section : Int) -> Int {
        var cols = self.delegate?.collectionView?(self.collectionView!, layout: self, numberOfColumnsInSection: section) ?? self.columnCount
        if cols <= 0 { cols = 1 }
        return cols
    }
    
    //  private property and method above.
    fileprivate weak var delegate : CBCollectionViewDelegateColumnLayout? { get{ return self.collectionView!.delegate as? CBCollectionViewDelegateColumnLayout }}
    
    fileprivate var columnHeights : [[CGFloat]]! = []
    fileprivate var sectionItemAttributes : [[CBCollectionViewLayoutAttributes]] = []
    fileprivate var sectionColumnAttributes : [Int : [[CBCollectionViewLayoutAttributes]]] = [:]
    fileprivate var allItemAttributes : [CBCollectionViewLayoutAttributes] = []
    fileprivate var headersAttributes : [Int:CBCollectionViewLayoutAttributes] = [:]
    fileprivate var footersAttributes : [Int:CBCollectionViewLayoutAttributes] = [:]
    fileprivate var sectionIndexPaths : [Int : Set<IndexPath>] = [:]
    fileprivate var sectionFrames   : [Int : CGRect] = [:]

//    private var unionRects : [CGRect] = []
    fileprivate let unionSize = 20
    
    override public init() {
        super.init()
    }
    
    
    func itemWidthInSectionAtIndex (_ section : NSInteger) -> CGFloat {
        let colCount = self.delegate?.collectionView?(self.collectionView!, layout: self, numberOfColumnsInSection: section) ?? self.columnCount
        var insets : EdgeInsets!
        if let sectionInsets = self.delegate?.collectionView?(self.collectionView!, layout: self, insetForSectionAtIndex: section){
            insets = sectionInsets
        }else{
            insets = self.sectionInset
        }
        let width:CGFloat = self.collectionView!.contentVisibleRect.size.width - insets.left - insets.right
        let spaceColumCount:CGFloat = CGFloat(colCount-1)
        return floor((width - (spaceColumCount*self.minimumColumnSpacing)) / CGFloat(colCount))
    }
    
    override open func prepareLayout(){
        super.prepareLayout()
        
        let numberOfSections = self.collectionView!.numberOfSections()
        if numberOfSections == 0 {
            return
        }
        
        self.headersAttributes.removeAll()
        self.footersAttributes.removeAll()
        self.sectionIndexPaths.removeAll()
        self.sectionFrames.removeAll()
        self.columnHeights.removeAll(keepingCapacity: false)
        self.allItemAttributes.removeAll()
        self.sectionItemAttributes.removeAll()
        self.sectionColumnAttributes.removeAll()
        self.allIndexPaths.removeAll()
        
        var top : CGFloat = 0.0
        for section in 0..<numberOfSections {
            let colCount = self.columnsInSection(section)
            
            
            /*
            * 1. Get section-specific metrics (minimumInteritemSpacing, sectionInset)
            */
//            let colCount = self.columnsInSection(section)
            let sectionInsets :  EdgeInsets =  self.delegate?.collectionView?(self.collectionView!, layout: self, insetForSectionAtIndex: section) ?? self.sectionInset
            let itemSpacing : CGFloat = self.delegate?.collectionView?(self.collectionView!, layout: self, minimumInteritemSpacingForSectionAtIndex: section) ?? self.minimumInteritemSpacing
            let colSpacing = self.delegate?.collectionview?(self.collectionView!, layout: self, minimumColumnSpacingForSectionAtIndex: section) ?? self.minimumColumnSpacing
            
            let contentWidth = self.collectionView!.contentVisibleRect.size.width - sectionInsets.left - sectionInsets.right
            let spaceColumCount = CGFloat(colCount-1)
            let itemWidth = (contentWidth - (spaceColumCount*colSpacing)) / CGFloat(colCount)
            _itemWidth = itemWidth
            
            var sectionRect: CGRect = CGRect(x: sectionInsets.left, y: top, width: contentWidth, height: 0)
            /*
            * 2. Section header
            */
            let heightHeader : CGFloat = self.delegate?.collectionView?(self.collectionView!, layout: self, heightForHeaderInSection: section) ?? self.headerHeight
            if heightHeader > 0 {
                let attributes = CBCollectionViewLayoutAttributes(forSupplementaryViewOfKind: CBCollectionViewLayoutElementKind.SectionHeader, withIndexPath: IndexPath._indexPathForItem(0, inSection: section))
                attributes.alpha = 1
                attributes.frame = insetSupplementaryViews ?
                     CGRect(x: sectionInsets.left, y: top, width: self.collectionView!.contentVisibleRect.size.width - sectionInsets.left - sectionInsets.right, height: heightHeader)
                    : CGRect(x: 0, y: top, width: self.collectionView!.contentVisibleRect.size.width, height: heightHeader)
                self.headersAttributes[section] = attributes
                self.allItemAttributes.append(attributes)
                top = attributes.frame.maxY
            }
            
            top += sectionInsets.top
            columnHeights.append([CGFloat](repeating: top, count: colCount))
            
            var sIndexPaths = Set<IndexPath>()
            /*
            * 3. Section items
            */
            let itemCount = self.collectionView!.numberOfItemsInSection(section)
            var itemAttributes :[CBCollectionViewLayoutAttributes] = []
            sectionColumnAttributes[section] = [Array](repeating: [], count: colCount)
            
            // Item will be put into shortest column.
            for idx in 0..<itemCount {
                let indexPath = IndexPath._indexPathForItem(idx, inSection: section)
                sIndexPaths.insert(indexPath)
                allIndexPaths.insert(indexPath)
                
                let columnIndex = self.nextColumnIndexForItem(indexPath)
                let xOffset = sectionInsets.left + (itemWidth + colSpacing) * CGFloat(columnIndex)
                let yOffset = self.columnHeights[section][columnIndex]
                var itemHeight : CGFloat = 0
                let aSize = self.delegate?.collectionView?(self.collectionView!, layout: self, aspectRatioForItemAtIndexPath: indexPath)
                if aSize != nil && aSize!.width != 0 && aSize!.height != 0 {
                    let h = aSize!.height * (itemWidth/aSize!.width)
                    itemHeight = floor(h)
                    
                    if let addHeight = self.delegate?.collectionView?(self.collectionView!, layout: self, heightForItemAtIndexPath: indexPath) {
                        itemHeight += addHeight
                    }
                }
                else {
                    itemHeight = self.delegate?.collectionView?(self.collectionView!, layout: self, heightForItemAtIndexPath: indexPath) ?? self.defaultItemHeight
                }
                
                let attributes = CBCollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
                attributes.alpha = 1
                attributes.frame = CGRect(x: xOffset, y: CGFloat(yOffset), width: itemWidth, height: itemHeight)
                itemAttributes.append(attributes)
                self.allItemAttributes.append(attributes)
                self.columnHeights[section][columnIndex] = attributes.frame.maxY + itemSpacing;
                self.sectionColumnAttributes[section]?[columnIndex].append(attributes)
            }
            self.sectionItemAttributes.append(itemAttributes)
            self.sectionIndexPaths[section] = sIndexPaths
            
            /*
            * 4. Section footer
            */
            let columnIndex  = self.longestColumnIndexInSection(section)
            top = self.columnHeights[section][columnIndex] - itemSpacing
            
            let footerHeight = self.delegate?.collectionView?(self.collectionView!, layout: self, heightForFooterInSection: section) ?? self.footerHeight
            if footerHeight > 0 {
                let attributes = CBCollectionViewLayoutAttributes(forSupplementaryViewOfKind: CBCollectionViewLayoutElementKind.SectionFooter, withIndexPath: IndexPath._indexPathForItem(0, inSection: section))
                attributes.alpha = 1
                attributes.frame = insetSupplementaryViews ?
                    CGRect(x: sectionInsets.left, y: top, width: self.collectionView!.contentVisibleRect.size.width - sectionInsets.left - sectionInsets.right, height: footerHeight)
                    : CGRect(x: 0, y: top, width: self.collectionView!.contentVisibleRect.size.width, height: footerHeight)
                self.footersAttributes[section] = attributes
                self.allItemAttributes.append(attributes)
                top = attributes.frame.maxY
            }
            top += sectionInsets.bottom
            
            sectionRect.size.height = top - sectionRect.origin.y
            sectionFrames[section] = sectionRect

        }
    }
    
    override open func collectionViewContentSize() -> CGSize {
        guard let cv = collectionView else { return CGSize.zero }
        let numberOfSections = cv.numberOfSections()
        if numberOfSections == 0{ return CGSize.zero }
        
        var contentSize = cv.contentVisibleRect.size as CGSize
        let height = self.sectionFrames[cv.numberOfSections() - 1]?.maxY ?? 0
        if height == 0 { return CGSize.zero }
        contentSize.height = height
        return  contentSize
    }
    
    open override func rectForSection(_ section: Int) -> CGRect {
        return sectionFrames[section] ?? CGRect.zero
    }
    
    open override func layoutAttributesForElementsInRect(_ rect: CGRect) -> [CBCollectionViewLayoutAttributes]? {
        var attrs : [CBCollectionViewLayoutAttributes] = []
        
        guard let cv = self.collectionView else { return nil }
        if rect.equalTo(CGRect.zero) || cv.numberOfSections() == 0 { return attrs }
        for sectionIndex in 0...cv.numberOfSections() - 1 {
            
            guard let sectionFrame = cv.frameForSection(sectionIndex),
                let columns = self.sectionColumnAttributes[sectionIndex] else { continue }
            if sectionFrame.isEmpty || !sectionFrame.intersects(rect) { continue }
            for column in columns {
                for attr in column {
                    if attr.frame.intersects(rect) {
                        attrs.append(attr.copy())
                    }
                    else if attr.frame.origin.y > rect.maxY { break }
                }
            }
        }
        return attrs
    }
    
    open override func layoutAttributesForItemAtIndexPath(_ indexPath: IndexPath) -> CBCollectionViewLayoutAttributes? {
        if indexPath._section >= self.sectionItemAttributes.count{ return nil }
        if indexPath._item >= self.sectionItemAttributes[indexPath._section].count{ return nil }
        let list = self.sectionItemAttributes[indexPath._section]
        return list[indexPath._item].copy()
    }
    
    open override func layoutAttributesForSupplementaryViewOfKind(_ elementKind: String, atIndexPath indexPath: IndexPath) -> CBCollectionViewLayoutAttributes? {
        
        if elementKind == CBCollectionViewLayoutElementKind.SectionHeader {
            let attrs = self.headersAttributes[indexPath._section]?.copy()
            if pinHeadersToTop, let currentAttrs = attrs, let cv = self.collectionView {
                
                let contentOffset = cv.contentOffset
                let frame = currentAttrs.frame
                if indexPath._section == 0 && contentOffset.y <= -cv.contentInsets.top {
                    currentAttrs.frame.origin.y = 0
                    currentAttrs.floating = false
                }
                else {
                    var nextHeaderOrigin = CGPoint(x: CGFloat.greatestFiniteMagnitude, y: CGFloat.greatestFiniteMagnitude)
                    if let nextHeader = self.headersAttributes[indexPath._section + 1] {
                        nextHeaderOrigin = nextHeader.frame.origin
                    }
                    let topInset = cv.contentInsets.top ?? 0
                    currentAttrs.frame.origin.y =  min(max(contentOffset.y + topInset , frame.origin.y), nextHeaderOrigin.y - frame.height)
                    currentAttrs.floating = currentAttrs.frame.origin.y > frame.origin.y
                }
            }
            return attrs
        }
        else if elementKind == CBCollectionViewLayoutElementKind.SectionFooter {
            return self.footersAttributes[indexPath._section]?.copy()
        }
        return nil
    }
    
    override open func shouldInvalidateLayoutForBoundsChange (_ newBounds : CGRect) -> Bool {
        if !newBounds.size.equalTo(self._cvSize) {
            self._cvSize = newBounds.size
            return true
        }
        return false
    }
    
    
    open override func scrollRectForItemAtIndexPath(_ indexPath: IndexPath, atPosition: CBCollectionViewScrollPosition) -> CGRect? {
        guard var frame = self.layoutAttributesForItemAtIndexPath(indexPath)?.frame else { return nil }
        if self.pinHeadersToTop, let attrs = self.layoutAttributesForSupplementaryViewOfKind(CBCollectionViewLayoutElementKind.SectionHeader, atIndexPath: IndexPath._indexPathForItem(0, inSection: indexPath._section)) {
            var y = frame.origin.y - attrs.frame.size.height
            var height = frame.size.height + attrs.frame.size.height
            frame.size.height = height
            frame.origin.y = y
        }
        return frame
    }
    
    
    /*!
    Find the shortest column in a particular section
    
    :param: section The section to find the shortest column for.
    :returns: The index of the shortest column in the given section
    */
    func shortestColumnIndexInSection(_ section: Int) -> NSInteger {
        let min =  self.columnHeights[section].min()!
        return self.columnHeights[section].index(of: min)!
    }
    
    /*!
    Find the longest column in a particular section
    
    :param: section The section to find the longest column for.
    :returns: The index of the longest column in the given section
    */
    func longestColumnIndexInSection(_ section: Int) -> NSInteger {
        let max =  self.columnHeights[section].max()!
        return self.columnHeights[section].index(of: max)!
    }
    
    /*!
    Find the index of the column the for the next item at the given index path
    
    :param: The indexPath of the section to look ahead of
    :returns: The index of the next column
    */
    func nextColumnIndexForItem (_ indexPath : IndexPath) -> Int {
        let colCount = self.columnsInSection(indexPath._section)
        var index = 0
        switch (self.itemRenderDirection){
        case .shortestFirst :
            index = self.shortestColumnIndexInSection(indexPath._section)
        case .leftToRight :
            index = (indexPath._item % colCount)
        case .rightToLeft:
            index = (colCount - 1) - (indexPath._item % colCount);
        }
        return index
    }
    
    
//    func changesInRect(newRect: CGRect, oldRect: CGRect) -> (new: [CBCollectionViewLayoutAttributes], remove: [CBCollectionViewLayoutAttributes]) {
//        var new : [CBCollectionViewLayoutAttributes] = []
//        var remove : [CBCollectionViewLayoutAttributes] = []
//        
//        let union = newRect.union(oldRect)
//        
//        guard let cv = self.collectionView else { return (new, remove) }
//        
//        if CGRectEqualToRect(union, CGRectZero) || cv.numberOfSections() == 0 { return (new, remove) }
//        for sectionIndex in 0...cv.numberOfSections() - 1 {
//            guard let sectionFrame = cv.frameForSection(sectionIndex) else { continue }
//            if CGRectIsEmpty(sectionFrame) || !CGRectIntersectsRect(sectionFrame, union) { continue }
//            
//            for attr in sectionItemAttributes[sectionIndex] {
//                let inNew = attr.frame.intersects(newRect)
//                let inOld = attr.frame.intersects(oldRect)
//                
//                if inNew && !inOld {
//                    new.append(attr)
//                }
//                else if inOld && !inNew {
//                    remove.append(attr)
//                }
//            }
//        }
//        return (new, remove)
//    }

    
    
    open override func indexPathsForItemsInRect(_ rect: CGRect) -> Set<IndexPath>? {
//        return nil
        
        var indexPaths = Set<IndexPath>()
        guard let cv = self.collectionView else { return nil }
        if rect.equalTo(CGRect.zero) || cv.numberOfSections() == 0 { return indexPaths }
        for sectionIndex in 0...cv.numberOfSections() - 1 {
            
            if cv.numberOfItemsInSection(sectionIndex) == 0 { continue }
            
            guard let sectionFrame = cv.frameForSection(sectionIndex) else { continue }
            if sectionFrame.isEmpty || !sectionFrame.intersects(rect) { continue }
            
            // If the section is completely show, add all the attrs
            if rect.contains(sectionFrame) {
                if let ips = self.sectionIndexPaths[sectionIndex] {
                    indexPaths.formUnion(ips)
                }
            }
            else if let columns = self.sectionColumnAttributes[sectionIndex] , columns.count > 0 {
                for column in columns {
                    for attr in column {
                        if attr.frame.intersects(rect) {
                            indexPaths.insert(attr.indexPath as IndexPath)
                        }
                        else if attr.frame.origin.y > rect.maxY { break }
                    }
                }
            }
            
//                        for attr in sectionItemAttributes[sectionIndex] {
//                if attr.frame.intersects(rect) {
//                    indexPaths.insert(attr.indexPath)
//                }
//            }
            
//            guard let sColumns = sectionColumnAttributes[sectionIndex] where sColumns.count > 0 else { continue }
//            let firstColumn = columns[0]
//            
//            var start = -1
//            var end = -1
//            let itemCount = cv.numberOfItemsInSection(sectionIndex)
//            
//            let maxY = CGRectGetMaxY(rect)
//            for row in 0...firstColumn.count - 1 {
//                let attrs = firstColumn[row]
//                let include = CGRectIntersectsRect(attrs.frame, rect)
//                if !include { continue }
//                if CGRectGetMinY(attrs.frame) > maxY { break }
//                if start == -1 { start = row }
//                end = row
//                indexPaths.insert(NSIndexPath._indexPathForItem(columns.count * row, inSection: sectionIndex))
//            }
//            
//            if start == -1 || columns.count == 1 { continue }
//            
//            for c in 1...columns.count - 1 {
//                for r in start...end {
//                    let item = columns.count * r + c
//                    if item < itemCount {
//                        indexPaths.insert(NSIndexPath._indexPathForItem(item, inSection: sectionIndex))
//                    }
//                }
//            }

        }
        return indexPaths
    }
    
    open override func indexPathForNextItemInDirection(_ direction: CBCollectionViewDirection, afterItemAtIndexPath currentIndexPath: IndexPath) -> IndexPath? {
        guard let collectionView = self.collectionView else { fatalError() }
        
        var index = currentIndexPath._item
        var section = currentIndexPath._section
        
        let numberOfSections = collectionView.numberOfSections()
        let numberOfItemsInSection = collectionView.numberOfItemsInSection(currentIndexPath._section)
        
        guard let cellRect = collectionView.rectForItemAtIndexPath(currentIndexPath) else { return nil }
        let cellHeight = cellRect.height
        
        switch direction {
        case .up:
//            let columns = sectionColumnAttributes[currentIndexPath._section]
            
            guard let cAttrs = collectionView.layoutAttributesForItemAtIndexPath(currentIndexPath),
                let columns = sectionColumnAttributes[section] else { return nil }
            
            let cFlat = CGRect(x: cAttrs.frame.origin.x, y: 0, width: cAttrs.frame.size.width, height: 50)
            
            let left = cAttrs.frame.minX
            let right = cAttrs.frame.maxX
            
            for column in columns {
                if let first = column.first {
                    // This is the first item in the column -> Check the previous section
                    if first.indexPath == currentIndexPath {
                        guard let pColumns = sectionColumnAttributes[section - 1] else { return nil }
                        
                        var last : IndexPath?
                        for col in pColumns.reversed() {
                            if let pFirst = col.first {
                                let flat = CGRect(x: pFirst.frame.origin.x, y: 0, width: pFirst.frame.size.width, height: 50)
                                if cFlat.intersects(flat) {
                                    return col.last?.indexPath
                                }
                            }
                        }
                        return sectionItemAttributes[section - 1].last?.indexPath
                    }
                    
                    let flat = CGRect(x: first.frame.origin.x, y: 0, width: first.frame.size.width, height: 50)
                    
                    // Get the same column
                    if cFlat.intersects(flat) {
                        for idx in 0..<column.count {
                            let attr = column[idx]
                            if attr.indexPath == currentIndexPath {
                                return column[idx - 1].indexPath
                            }
                        }
                    }
                }
            }
            return nil
            
            
//            var point = cellRect.origin
//            point.y = point.y - cellHeight
//            if let indexPath = collectionView.indexPathForItemAtPoint(point) {
//                return indexPath
//            }
//            point.y = point.y - cellHeight
//            if let indexPath = collectionView.indexPathForItemAtPoint(point) {
//                return indexPath
//            }
//            
//            point.y = point.y - cellHeight
//            if let indexPath = collectionView.indexPathForItemAtPoint(point) {
//                return indexPath
//            } else {
//                return currentIndexPath
//            }
            
        case .down:
            
            
            guard let cAttrs = collectionView.layoutAttributesForItemAtIndexPath(currentIndexPath),
                let columns = sectionColumnAttributes[section] else { return nil }
            
            let cFlat = CGRect(x: cAttrs.frame.origin.x, y: 0, width: cAttrs.frame.size.width, height: 50)
            
            let left = cAttrs.frame.minX
            let right = cAttrs.frame.maxX
            
            for column in columns {
                if let first = column.first {
                    // This is the last item in the column -> Check the previous section
                    if column.last?.indexPath == currentIndexPath {
                        guard let pColumns = sectionColumnAttributes[section + 1] else { return nil }
                        
                        var last : IndexPath?
                        for col in pColumns {
                            if let pFirst = col.first {
                                let flat = CGRect(x: pFirst.frame.origin.x, y: 0, width: pFirst.frame.size.width, height: 50)
                                if cFlat.intersects(flat) {
                                    return col.first?.indexPath
                                }
                            }
                        }
                        return sectionItemAttributes[section + 1].last?.indexPath
                    }
                    
                    let flat = CGRect(x: first.frame.origin.x, y: 0, width: first.frame.size.width, height: 50)
                    
                    // Get the same column
                    if cFlat.intersects(flat) {
                        for idx in 0..<column.count {
                            let attr = column[idx]
                            if attr.indexPath == currentIndexPath {
                                return column[idx + 1].indexPath
                            }
                        }
                    }
                }
            }
            return nil
            
            
            
//            var point = cellRect.origin
//            point.y = point.y + cellHeight
//            if let indexPath = collectionView.indexPathForItemAtPoint(point) {
//                return indexPath
//            }
//            point.y = point.y + cellHeight
//            if let indexPath = collectionView.indexPathForItemAtPoint(point) {
//                return indexPath
//            }
//            
//            point.y = point.y + cellHeight
//            if let indexPath = collectionView.indexPathForItemAtPoint(point) {
//                return indexPath
//            } else {
//                return currentIndexPath
//            }
            
        case .left:
            if section == 0 && index == 0 {
                return currentIndexPath
            }
            if index > 0 {
                index = index - 1
            } else {
                section = section - 1
                index = collectionView.numberOfItemsInSection(currentIndexPath._section - 1) - 1
            }
            return IndexPath._indexPathForItem(index, inSection: section)
        case .right :
            if section == numberOfSections - 1 && index == numberOfItemsInSection - 1 {
                return currentIndexPath
            }
            if index < numberOfItemsInSection - 1 {
                index = index + 1
            } else {
                section = section + 1
                index = 0
            }
            return IndexPath._indexPathForItem(index, inSection: section)
        }
    }
    
}

