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
    optional func collectionView (collectionView: CBCollectionView,layout collectionViewLayout: CBCollectionViewLayout,
        heightForItemAtIndexPath indexPath: NSIndexPath) -> CGFloat
    
    /**
     The aspect ration for the item at the given indexPath (Priority 1). Width and height must be greater than 0.
     
     - parameter collectionView:       The collection view the item is in
     - parameter collectionViewLayout: The CollectionViewLayout
     - parameter indexPath:            The indexPath for the item
     
     - returns: The aspect ration for the item
     */
    optional func collectionView (collectionView: CBCollectionView,layout collectionViewLayout: CBCollectionViewLayout,
        aspectRatioForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    
    optional func collectionView (collectionView: CBCollectionView, layout collectionViewLayout: CBCollectionViewLayout,
        heightForHeaderInSection section: NSInteger) -> CGFloat
    
    optional func collectionView (collectionView: CBCollectionView, layout collectionViewLayout: CBCollectionViewLayout,
        heightForFooterInSection section: NSInteger) -> CGFloat
    
    optional func collectionView (collectionView: CBCollectionView, layout collectionViewLayout: CBCollectionViewLayout,
        numberOfColumnsInSection section: Int) -> Int
    
    optional func collectionView (collectionView: CBCollectionView, layout collectionViewLayout: CBCollectionViewLayout,
        insetForSectionAtIndex section: NSInteger) -> NSEdgeInsets
    
    // Between to items in the same column
    optional func collectionView (collectionView: CBCollectionView, layout collectionViewLayout: CBCollectionViewLayout,
        minimumInteritemSpacingForSectionAtIndex section: NSInteger) -> CGFloat
    
    optional func collectionview(collectionView: CBCollectionView, layout collectionViewLayout: CBCollectionViewLayout,
        minimumColumnSpacingForSectionAtIndex section: NSInteger) -> CGFloat
    
}



public enum CBCollectionViewLayoutItemRenderDirection : NSInteger {
    case ShortestFirst
    case LeftToRight
    case RightToLeft
}

public struct CBCollectionViewLayoutElementKind {
    public static let SectionHeader: String = "CBCollectionElementKindSectionHeader"
    public static let SectionFooter: String = "CBCollectionElementKindSectionFooter"
}




/// A feature packed collection view layout with pinterest like layouts, aspect ratio sizing, and drag and drop.
public class CBCollectionViewColumnLayout : CBCollectionViewLayout {
    
    //MARK: - Default layout values
    
    /// The default column count
    public var columnCount : NSInteger = 2 { didSet{ invalidateLayout() }}

    /// The spacing between each column
    public var minimumColumnSpacing : CGFloat = 8 { didSet{ invalidateLayout() }}
    
    /// The vertical spacing between items in the same column
    public var minimumInteritemSpacing : CGFloat = 8 { didSet{ invalidateLayout() }}

    /// The height of section header views
    public var headerHeight : CGFloat = 0.0 { didSet{ invalidateLayout() }}

    /// The height of section footer views
    public var footerHeight : CGFloat = 0.0 { didSet{ invalidateLayout() }}

    /// The default height to apply to all items
    public var defaultItemHeight : CGFloat = 50 { didSet{ invalidateLayout() }}

    /// If supplementary views should respect section insets or fill the CollectionView width
    public var insetSupplementaryViews : Bool = false { didSet{ invalidateLayout() }}

    /// Default insets for all sections
    public var sectionInset : NSEdgeInsets = NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8) { didSet{ invalidateLayout() }}
    
    // MARK: - Render Options
    /// A hint as to how to render items when deciding which column to place them in
    public var itemRenderDirection : CBCollectionViewLayoutItemRenderDirection = .LeftToRight { didSet{ invalidateLayout() }}
    
    
    // Internal caching
    private var _itemWidth : CGFloat = 0
    private var _cvSize = CGSizeZero
    /// the calculated width of items based on the total width and number of columns (read only)
    public var itemWidth : CGFloat { get { return _itemWidth }}
    
    
    private var numSections : Int { get { return self.collectionView!.numberOfSections() }}
    private func columnsInSection(section : Int) -> Int {
        var cols = self.delegate?.collectionView?(self.collectionView!, layout: self, numberOfColumnsInSection: section) ?? self.columnCount
        if cols <= 0 { cols = 1 }
        return cols
    }
    
    //  private property and method above.
    private var delegate : CBCollectionViewDelegateColumnLayout? { get{ return self.collectionView!.delegate as? CBCollectionViewDelegateColumnLayout }}
    
    private var columnHeights : [[CGFloat]]! = []
    private var sectionItemAttributes : [[CBCollectionViewLayoutAttributes]] = []
    private var sectionColumnAttributes : [Int : [[CBCollectionViewLayoutAttributes]]] = [:]
    private var allItemAttributes : [CBCollectionViewLayoutAttributes] = []
    private var headersAttributes : [Int:CBCollectionViewLayoutAttributes] = [:]
    private var footersAttributes : [Int:CBCollectionViewLayoutAttributes] = [:]
    private var sectionFrames   : [Int : CGRect] = [:]
    private var unionRects = NSMutableArray()
    private let unionSize = 20
    
    override public init() {
        super.init()
    }
    
    
    func itemWidthInSectionAtIndex (section : NSInteger) -> CGFloat {
        let colCount = self.delegate?.collectionView?(self.collectionView!, layout: self, numberOfColumnsInSection: section) ?? self.columnCount
        var insets : NSEdgeInsets!
        if let sectionInsets = self.delegate?.collectionView?(self.collectionView!, layout: self, insetForSectionAtIndex: section){
            insets = sectionInsets
        }else{
            insets = self.sectionInset
        }
        let width:CGFloat = self.collectionView!.bounds.size.width - insets.left - insets.right
        let spaceColumCount:CGFloat = CGFloat(colCount-1)
        return floor((width - (spaceColumCount*self.minimumColumnSpacing)) / CGFloat(colCount))
    }
    
    override public func prepareLayout(){
        super.prepareLayout()
        
        let numberOfSections = self.collectionView!.numberOfSections()
        if numberOfSections == 0 {
            return
        }
        
        self.headersAttributes.removeAll()
        self.footersAttributes.removeAll()
        self.unionRects.removeAllObjects()
        self.sectionFrames.removeAll()
        self.columnHeights.removeAll(keepCapacity: false)
        self.allItemAttributes.removeAll()
        self.sectionItemAttributes.removeAll()
        self.sectionColumnAttributes.removeAll()
        
        // Create default column heights for each section
        for sec in 0...self.numSections-1 {
            let colCount = self.columnsInSection(sec)
            columnHeights.append([CGFloat](count: colCount, repeatedValue: 0))
        }
        
        var top : CGFloat = 0.0
//        var attributes = CBCollectionViewLayoutAttributes()
        
        for var section = 0; section < numberOfSections; ++section{
            
            /*
            * 1. Get section-specific metrics (minimumInteritemSpacing, sectionInset)
            */
            let colCount = self.columnsInSection(section)
            let sectionInsets :  NSEdgeInsets =  self.delegate?.collectionView?(self.collectionView!, layout: self, insetForSectionAtIndex: section) ?? self.sectionInset
            let itemSpacing : CGFloat = self.delegate?.collectionView?(self.collectionView!, layout: self, minimumInteritemSpacingForSectionAtIndex: section) ?? self.minimumInteritemSpacing
            let colSpacing = self.delegate?.collectionview?(self.collectionView!, layout: self, minimumColumnSpacingForSectionAtIndex: section) ?? self.minimumColumnSpacing
            
            let contentWidth = self.collectionView!.bounds.size.width - sectionInsets.left - sectionInsets.right
            let spaceColumCount = CGFloat(colCount-1)
            let itemWidth = (contentWidth - (spaceColumCount*colSpacing)) / CGFloat(colCount)
            _itemWidth = itemWidth
            
            var sectionHeight : CGFloat = 0
            var sectionTop : CGFloat = 0
            var sectionRect: CGRect = CGRect(x: sectionInsets.left, y: top, width: contentWidth, height: 0)
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
                self.allItemAttributes.append(attributes)
                top = CGRectGetMaxY(attributes.frame)
            }
            
            top += sectionInsets.top
            for var idx = 0; idx < colCount; idx++ {
                self.columnHeights[section][idx] = top;
            }
            
            /*
            * 3. Section items
            */
            let itemCount = self.collectionView!.numberOfItemsInSection(section)
            var itemAttributes :[CBCollectionViewLayoutAttributes] = []
            sectionColumnAttributes[section] = []
            for c in 0...colCount - 1 {
                sectionColumnAttributes[section]?.append([])
            }
            
            var itemRect = CGRectZero
            
            // Item will be put into shortest column.
            for var idx = 0; idx < itemCount; idx++ {
                let indexPath = NSIndexPath._indexPathForItem(idx, inSection: section)
                
                let columnIndex = self.nextColumnIndexForItem(indexPath)
                let xOffset = sectionInsets.left + (itemWidth + colSpacing) * CGFloat(columnIndex)
                let yOffset = self.columnHeights[section][columnIndex]
                var itemHeight : CGFloat = 0
                let aSize = self.delegate?.collectionView?(self.collectionView!, layout: self, aspectRatioForItemAtIndexPath: indexPath)
                if aSize != nil && aSize!.width != 0 && aSize!.height != 0 {
                    let h = aSize!.height * (itemWidth/aSize!.width)
                    itemHeight = floor(h)
                }
                else {
                    itemHeight = self.delegate?.collectionView?(self.collectionView!, layout: self, heightForItemAtIndexPath: indexPath) ?? self.defaultItemHeight
                }
                
                let attributes = CBCollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
                attributes.alpha = 1
                attributes.frame = CGRectMake(xOffset, CGFloat(yOffset), itemWidth, itemHeight)
                itemAttributes.append(attributes)
                self.allItemAttributes.append(attributes)
                self.columnHeights[section][columnIndex] = CGRectGetMaxY(attributes.frame) + itemSpacing;
                self.sectionColumnAttributes[section]?[columnIndex].append(attributes)
            }
            self.sectionItemAttributes.append(itemAttributes)
            
            /*
            * 4. Section footer
            */
            let columnIndex  = self.longestColumnIndexInSection(section)
//            sectionHeight += self.columnHeights[section][columnIndex] - itemSpacing + sectionInsets.bottom - top
            top = self.columnHeights[section][columnIndex] - itemSpacing + sectionInsets.bottom
            
            let footerHeight = self.delegate?.collectionView?(self.collectionView!, layout: self, heightForFooterInSection: section) ?? self.footerHeight
            if footerHeight > 0 {
                let attributes = CBCollectionViewLayoutAttributes(forSupplementaryViewOfKind: CBCollectionViewLayoutElementKind.SectionFooter, withIndexPath: NSIndexPath._indexPathForItem(0, inSection: section))
                attributes.alpha = 1
                attributes.frame = insetSupplementaryViews ?
                    CGRectMake(sectionInsets.left, top, self.collectionView!.bounds.size.width - sectionInsets.left - sectionInsets.right, heightHeader)
                    : CGRectMake(0, top, self.collectionView!.bounds.size.width, heightHeader)
                self.footersAttributes[section] = attributes
                self.allItemAttributes.append(attributes)
                top = CGRectGetMaxY(attributes.frame)
//                sectionHeight += footerHeight
            }
            
            sectionRect.size.height = top - sectionRect.origin.y
            sectionFrames[section] = sectionRect
            
            for var idx = 0; idx < colCount; idx++ {
                self.columnHeights[section][idx] = top
            }
        }
        
        var idx = 0;
        let itemCounts = self.allItemAttributes.count
        while(idx < itemCounts){
            let rect1 = self.allItemAttributes[idx].frame
            idx = min(idx + unionSize, itemCounts) - 1
            let rect2 = self.allItemAttributes[idx].frame
            self.unionRects.addObject(NSValue(rect:CGRectUnion(rect1,rect2)))
            idx++
        }
    }
    
    override public func collectionViewContentSize() -> CGSize {
        let numberOfSections = self.collectionView!.numberOfSections()
        if numberOfSections == 0{
            return CGSizeZero
        }
        var contentSize = self.collectionView!.bounds.size as CGSize
        let height = self.columnHeights.last?.first ?? 0
        contentSize.height = CGFloat(height)
        return  contentSize
    }
    
    public override func rectForSection(section: Int) -> CGRect {
        return sectionFrames[section] ?? CGRectZero
    }
    
    public override func layoutAttributesForElementsInRect(rect: CGRect) -> [CBCollectionViewLayoutAttributes]? {
        var attrs : [CBCollectionViewLayoutAttributes] = []
        if let itemAttrs = self.indexPathsForItemsInRect(rect) {
            for ip in itemAttrs {
                if let a = layoutAttributesForItemAtIndexPath(ip) {
                    attrs.append(a)
                }
            }
        }
        
        return attrs
    }
    
    public override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> CBCollectionViewLayoutAttributes? {
        if indexPath._section >= self.sectionItemAttributes.count{
            return nil
        }
        if indexPath._item >= self.sectionItemAttributes[indexPath._section].count{
            return nil;
        }
        let list = self.sectionItemAttributes[indexPath._section]
        return list[indexPath._item]
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
            frame.origin.y += attrs.frame.size.height
        }
        return frame
    }
    
    
    /*!
    Find the shortest column in a particular section
    
    :param: section The section to find the shortest column for.
    :returns: The index of the shortest column in the given section
    */
    func shortestColumnIndexInSection(section: Int) -> NSInteger {
        let min =  self.columnHeights[section].minElement()!
        return self.columnHeights[section].indexOf(min)!
    }
    
    /*!
    Find the longest column in a particular section
    
    :param: section The section to find the longest column for.
    :returns: The index of the longest column in the given section
    */
    func longestColumnIndexInSection(section: Int) -> NSInteger {
        let max =  self.columnHeights[section].maxElement()!
        return self.columnHeights[section].indexOf(max)!
    }
    
    /*!
    Find the index of the column the for the next item at the given index path
    
    :param: The indexPath of the section to look ahead of
    :returns: The index of the next column
    */
    func nextColumnIndexForItem (indexPath : NSIndexPath) -> Int {
        let colCount = self.columnsInSection(indexPath._section)
        var index = 0
        switch (self.itemRenderDirection){
        case .ShortestFirst :
            index = self.shortestColumnIndexInSection(indexPath._section)
        case .LeftToRight :
            index = (indexPath._item % colCount)
        case .RightToLeft:
            index = (colCount - 1) - (indexPath._item % colCount);
        }
        return index
    }
    
    
    public override func indexPathsForItemsInRect(rect: CGRect) -> Set<NSIndexPath>? {
//        return nil
        
        var indexPaths = Set<NSIndexPath>()
        guard let cv = self.collectionView else { return nil }
        if CGRectEqualToRect(rect, CGRectZero) || cv.numberOfSections() == 0 { return indexPaths }
        for sectionIndex in 0...cv.numberOfSections() - 1 {
            guard let sectionFrame = cv.frameForSection(sectionIndex) else { continue }
            if CGRectIsEmpty(sectionFrame) || !CGRectIntersectsRect(sectionFrame, rect) { continue }
            
            guard let sColumns = sectionColumnAttributes[sectionIndex] where sColumns.count > 0 else { continue }
            let firstColumn = sColumns[0]
            
            var start = -1
            var end = -1
            let itemCount = cv.numberOfItemsInSection(sectionIndex)
            
            let maxY = CGRectGetMaxY(rect)
            for row in 0...firstColumn.count - 1 {
                let attrs = firstColumn[row]
                let include = CGRectIntersectsRect(attrs.frame, rect)
                if !include { continue }
                if CGRectGetMinY(attrs.frame) > maxY { break }
                if start == -1 { start = row }
                end = row
                indexPaths.insert(NSIndexPath._indexPathForItem(sColumns.count * row, inSection: sectionIndex))
            }
            
            if start == -1 || sColumns.count == 1 { continue }
            
            for c in 1...sColumns.count - 1 {
                for r in start...end {
                    let item = sColumns.count * r + c
                    if item < itemCount {
                        indexPaths.insert(NSIndexPath._indexPathForItem(item, inSection: sectionIndex))
                    }
                }
            }

        }
        return indexPaths
    }
    
    public override func indexPathForNextItemInDirection(direction: CBCollectionViewDirection, afterItemAtIndexPath currentIndexPath: NSIndexPath) -> NSIndexPath? {
        guard let collectionView = self.collectionView else { fatalError() }
        
        var index = currentIndexPath._item
        var section = currentIndexPath._section
        
        let numberOfSections = collectionView.numberOfSections()
        let numberOfItemsInSection = collectionView.numberOfItemsInSection(currentIndexPath._section)
        
        guard let cellRect = collectionView.rectForItemAtIndexPath(currentIndexPath) else { return nil }
        let cellHeight = cellRect.height
        
        switch direction {
        case .Up:
            var point = cellRect.origin
            point.y = point.y - cellHeight
            if let indexPath = collectionView.indexPathForItemAtPoint(point) {
                return indexPath
            }
            point.y = point.y - cellHeight
            if let indexPath = collectionView.indexPathForItemAtPoint(point) {
                return indexPath
            }
            
            point.y = point.y - cellHeight
            if let indexPath = collectionView.indexPathForItemAtPoint(point) {
                return indexPath
            } else {
                return currentIndexPath
            }
            
        case .Down:
            var point = cellRect.origin
            point.y = point.y + cellHeight
            if let indexPath = collectionView.indexPathForItemAtPoint(point) {
                return indexPath
            }
            point.y = point.y + cellHeight
            if let indexPath = collectionView.indexPathForItemAtPoint(point) {
                return indexPath
            }
            
            point.y = point.y + cellHeight
            if let indexPath = collectionView.indexPathForItemAtPoint(point) {
                return indexPath
            } else {
                return currentIndexPath
            }
            
        case .Left:
            if section == 0 && index == 0 {
                return currentIndexPath
            }
            if index > 0 {
                index = index - 1
            } else {
                section = section - 1
                index = collectionView.numberOfItemsInSection(currentIndexPath._section - 1) - 1
            }
            return NSIndexPath._indexPathForItem(index, inSection: section)
        case .Right :
            if section == numberOfSections - 1 && index == numberOfItemsInSection - 1 {
                return currentIndexPath
            }
            if index < numberOfItemsInSection - 1 {
                index = index + 1
            } else {
                section = section + 1
                index = 0
            }
            return NSIndexPath._indexPathForItem(index, inSection: section)
        }
    }
    
}

