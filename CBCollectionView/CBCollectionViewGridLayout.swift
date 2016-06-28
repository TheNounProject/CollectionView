//
//  CBCollectionViewGridLayout.swift
//  CBCollectionView
//
//  Created by Wesley Byrne on 4/11/16.
//  Copyright © 2016 Noun Project. All rights reserved.
//

import Foundation


/**
 *  The delegate for CBCollectionViewLayout
 */
@objc public protocol CBCollectionViewDelegateGridLayout: CBCollectionViewDelegate {
    
    
    optional func collectionView (collectionView: CBCollectionView, layout collectionViewLayout: CBCollectionViewLayout,
                                  numberOfColumnsInSection section: Int) -> Int
    
    optional func collectionView (collectionView: CBCollectionView,layout collectionViewLayout: CBCollectionViewLayout,
                                  heightForItemsInSection section: Int) -> CGFloat
    
    optional func collectionView (collectionView: CBCollectionView,layout collectionViewLayout: CBCollectionViewLayout,
                                  aspectRatioForItemsInSection indexPath: NSIndexPath) -> CGSize
    
    
    optional func collectionView (collectionView: CBCollectionView, layout collectionViewLayout: CBCollectionViewLayout,
                                  heightForHeaderInSection section: NSInteger) -> CGFloat
    
    optional func collectionView (collectionView: CBCollectionView, layout collectionViewLayout: CBCollectionViewLayout,
                                  heightForFooterInSection section: NSInteger) -> CGFloat
    
    optional func collectionView (collectionView: CBCollectionView, layout collectionViewLayout: CBCollectionViewLayout,
                                  insetsForSectionAtIndex section: NSInteger) -> NSEdgeInsets
    
    // Between to items in the same column
    optional func collectionView (collectionView: CBCollectionView, layout collectionViewLayout: CBCollectionViewLayout,
                                  rowSpacingForSectionAtIndex section: NSInteger) -> CGFloat
    
    optional func collectionview(collectionView: CBCollectionView, layout collectionViewLayout: CBCollectionViewLayout,
                                 columnSpacingForSectionAtIndex section: NSInteger) -> CGFloat
    
}


/// A feature packed collection view layout with pinterest like layouts, aspect ratio sizing, and drag and drop.
public class CBCollectionViewGridLayout : CBCollectionViewLayout {
    
    //MARK: - Default layout values
    
    /// The default column count
    public final var columnCount : NSInteger = 2 { didSet{ invalidateLayout() }}
    
    /// The spacing between each column
    public final var minimumColumnSpacing : CGFloat = 8 { didSet{ invalidateLayout() }}
    
    /// The vertical spacing between items in the same column
    public final var minimumInteritemSpacing : CGFloat = 8 { didSet{ invalidateLayout() }}
    
    /// The height of section header views
    public final var headerHeight : CGFloat = 0.0 { didSet{ invalidateLayout() }}
    
    /// The height of section footer views
    public final var footerHeight : CGFloat = 0.0 { didSet{ invalidateLayout() }}
    
    /// The default height to apply to all items
    public final var defaultItemHeight : CGFloat = 50 { didSet{ invalidateLayout() }}
    
    /// If supplementary views should respect section insets or fill the CollectionView width
    public final var insetSupplementaryViews : Bool = false { didSet{ invalidateLayout() }}
    
    /// Default insets for all sections
    public final var sectionInset : NSEdgeInsets = NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8) { didSet{ invalidateLayout() }}
    
    public final func numberOfColumnsInSection(section: Int) -> Int {
        return columnCounts[section]
    }
    
    // Internal caching
    private var _itemWidth : CGFloat = 0
    private var _cvSize = CGSizeZero
    
    private var numSections : Int { get { return self.collectionView!.numberOfSections() }}
    private func columnsInSection(section : Int) -> Int {
        var cols = self.delegate?.collectionView?(self.collectionView!, layout: self, numberOfColumnsInSection: section) ?? self.columnCount
        if cols <= 0 { cols = 1 }
        return cols
    }
    
    //  private property and method above.
    private weak var delegate : CBCollectionViewDelegateGridLayout? { get{ return self.collectionView!.delegate as? CBCollectionViewDelegateGridLayout }}
    
    
    struct SectionSpec {
        var frame : CGRect
        
        var itemCounts : Int
        var contentRect : CGRect
        var columnWidth: CGFloat
        
        var columnSpacing : CGFloat
        var rowSpacing : CGFloat
        
        var columnCount : Int = 0
    }
    
    private var sections = [SectionSpec]()
    

    private var sectionItemAttributes : [[CBCollectionViewLayoutAttributes]] = []

    private var itemAttributes : [NSIndexPath:CBCollectionViewLayoutAttributes] = [:]
    private var headersAttributes : [Int:CBCollectionViewLayoutAttributes] = [:]
    private var footersAttributes : [Int:CBCollectionViewLayoutAttributes] = [:]
    
    private var sectionIndexPaths : [Int : Set<NSIndexPath>] = [:]
    private var sectionFrames   : [Int : CGRect] = [:]
    
    //    private var unionRects : [CGRect] = []
    private let unionSize = 20
    
    override public init() {
        super.init()
    }
    
//    
//    private func itemWidthInSectionAtIndex (section : NSInteger) -> CGFloat {
//        let colCount = self.delegate?.collectionView?(self.collectionView!, layout: self, numberOfColumnsInSection: section) ?? self.columnCount
//        var insets : NSEdgeInsets!
//        if let sectionInsets = self.delegate?.collectionView?(self.collectionView!, layout: self, insetsForSectionAtIndex: section){
//            insets = sectionInsets
//        }else{
//            insets = self.sectionInset
//        }
//        let width:CGFloat = self.collectionView!.bounds.size.width - insets.left - insets.right
//        let spaceColumCount:CGFloat = CGFloat(colCount-1)
//        return floor((width - (spaceColumCount*self.minimumColumnSpacing)) / CGFloat(colCount))
//    }
    
    override public func prepareLayout(){
        super.prepareLayout()
        
        self.headersAttributes.removeAll()
        self.footersAttributes.removeAll()
        self.itemAttributes.removeAll()
        
        self.sectionIndexPaths.removeAll()
        self.sectionFrames.removeAll()
        
        
        self.allIndexPaths.removeAll()
        
        let numberOfSections = self.collectionView!.numberOfSections()
        if numberOfSections == 0 { return }
        
        var top : CGFloat = 0.0
        
        for section in 0..<numberOfSections {
            let colCount = self.columnsInSection(section)
            
            /*
             * 1. Get section-specific metrics (minimumInteritemSpacing, sectionInset)
             */
            
            let sectionInsets :  NSEdgeInsets =  self.delegate?.collectionView?(self.collectionView!, layout: self, insetsForSectionAtIndex: section) ?? self.sectionInset
            let rowSpacing : CGFloat = self.delegate?.collectionView?(self.collectionView!, layout: self, rowSpacingForSectionAtIndex: section) ?? self.minimumInteritemSpacing
            let colSpacing = self.delegate?.collectionview?(self.collectionView!, layout: self, columnSpacingForSectionAtIndex: section) ?? self.minimumColumnSpacing
            
            let contentWidth = self.collectionView!.bounds.size.width - sectionInsets.left - sectionInsets.right
            let spaceColumCount = CGFloat(colCount-1)
            let itemWidth = (contentWidth - (spaceColumCount*colSpacing)) / CGFloat(colCount)
            _itemWidth = itemWidth
            
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
            
            var sIndexPaths = Set<NSIndexPath>()
            /*
             * 3. Section items
             */
            let itemCount = self.collectionView!.numberOfItemsInSection(section)
            var itemAttributes :[CBCollectionViewLayoutAttributes] = []
            row[section] = [Array](count: colCount, repeatedValue: [])
            
            // Item will be put into shortest column.
            for idx in 0..<itemCount {
                let indexPath = NSIndexPath._indexPathForItem(idx, inSection: section)
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
                attributes.frame = CGRectMake(xOffset, CGFloat(yOffset), itemWidth, itemHeight)
                itemAttributes.append(attributes)
                self.allItemAttributes.append(attributes)
                self.columnHeights[section][columnIndex] = CGRectGetMaxY(attributes.frame) + itemSpacing;
                self.sectionColumnAttributes[section]?[columnIndex].append(attributes)
            }
            self.sectionItemAttributes.append(itemAttributes)
            self.sectionIndexPaths[section] = sIndexPaths
            
            /*
             * 4. Section footer
             */
            let columnIndex  = self.longestColumnIndexInSection(section)
            //            sectionHeight += self.columnHeights[section][columnIndex] - itemSpacing + sectionInsets.bottom - top
            top = self.columnHeights[section][columnIndex] - itemSpacing
            
            let footerHeight = self.delegate?.collectionView?(self.collectionView!, layout: self, heightForFooterInSection: section) ?? self.footerHeight
            if footerHeight > 0 {
                let attributes = CBCollectionViewLayoutAttributes(forSupplementaryViewOfKind: CBCollectionViewLayoutElementKind.SectionFooter, withIndexPath: NSIndexPath._indexPathForItem(0, inSection: section))
                attributes.alpha = 1
                attributes.frame = insetSupplementaryViews ?
                    CGRectMake(sectionInsets.left, top, self.collectionView!.bounds.size.width - sectionInsets.left - sectionInsets.right, footerHeight)
                    : CGRectMake(0, top, self.collectionView!.bounds.size.width, footerHeight)
                self.footersAttributes[section] = attributes
                self.allItemAttributes.append(attributes)
                top = CGRectGetMaxY(attributes.frame)
                //                sectionHeight += footerHeight
            }
            top += sectionInsets.bottom
            
            sectionRect.size.height = top - sectionRect.origin.y
            sectionFrames[section] = sectionRect
            
            //            for idx in 0..<colCount {
            //                self.columnHeights[section][idx] = top
            //            }
        }
        
        //        var idx = 0;
        //        let itemCounts = self.allItemAttributes.count
        //        while(idx < itemCounts){
        //            let rect1 = self.allItemAttributes[idx].frame
        //            idx = min(idx + unionSize, itemCounts) - 1
        //            let rect2 = self.allItemAttributes[idx].frame
        //            self.unionRects.append(CGRectUnion(rect1,rect2))
        //            idx += 1
        //        }
    }
    
    override public func collectionViewContentSize() -> CGSize {
        guard let cv = collectionView else { return CGSizeZero }
        let numberOfSections = cv.numberOfSections()
        if numberOfSections == 0{ return CGSizeZero }
        
        var contentSize = cv.bounds.size as CGSize
        let height = self.sectionFrames[cv.numberOfSections() - 1]?.maxY ?? 0
        if height == 0 { return CGSizeZero }
        contentSize.height = height
        return  contentSize
    }
    
    public override func rectForSection(section: Int) -> CGRect {
        return sectionFrames[section] ?? CGRectZero
    }
    
    public override func layoutAttributesForElementsInRect(rect: CGRect) -> [CBCollectionViewLayoutAttributes]? {
        var attrs : [CBCollectionViewLayoutAttributes] = []
        
        guard let cv = self.collectionView else { return nil }
        if CGRectEqualToRect(rect, CGRectZero) || cv.numberOfSections() == 0 { return attrs }
        for sectionIndex in 0...cv.numberOfSections() - 1 {
            
            guard let sectionFrame = cv.frameForSection(sectionIndex),
                let columns = self.sectionColumnAttributes[sectionIndex] else { continue }
            if CGRectIsEmpty(sectionFrame) || !CGRectIntersectsRect(sectionFrame, rect) { continue }
            for column in columns {
                for attr in column {
                    if attr.frame.intersects(rect) {
                        attrs.append(attr)
                    }
                    else if attr.frame.origin.y > CGRectGetMaxY(rect) { break }
                }
            }
            
            
            //            guard let sectionFrame = cv.frameForSection(sectionIndex) else { continue }
            //            if CGRectIsEmpty(sectionFrame) || !CGRectIntersectsRect(sectionFrame, rect) { continue }
            //            for attr in sectionItemAttributes[sectionIndex] {
            //                if attr.frame.intersects(rect) {
            //                    attrs.append(attr)
            //                }
            //            }
        }
        
        //        if let itemAttrs = self.indexPathsForItemsInRect(rect) {
        //            for ip in itemAttrs {
        //                if let a = layoutAttributesForItemAtIndexPath(ip) {
        //                    attrs.append(a)
        //                }
        //            }
        //        }
        
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
//        switch (self.itemRenderDirection){
//        case .ShortestFirst :
//            index = self.shortestColumnIndexInSection(indexPath._section)
//        case .LeftToRight :
//            index = (indexPath._item % colCount)
//        case .RightToLeft:
//            index = (colCount - 1) - (indexPath._item % colCount);
//        }
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
    
    
    
    public override func indexPathsForItemsInRect(rect: CGRect) -> Set<NSIndexPath>? {
        //        return nil
        
        var indexPaths = Set<NSIndexPath>()
        guard let cv = self.collectionView else { return nil }
        if CGRectEqualToRect(rect, CGRectZero) || cv.numberOfSections() == 0 { return indexPaths }
        for sectionIndex in 0...cv.numberOfSections() - 1 {
            
            if cv.numberOfItemsInSection(sectionIndex) == 0 { continue }
            
            guard let sectionFrame = cv.frameForSection(sectionIndex) else { continue }
            if CGRectIsEmpty(sectionFrame) || !CGRectIntersectsRect(sectionFrame, rect) { continue }
            
            // If the section is completely show, add all the attrs
            if CGRectContainsRect(rect, sectionFrame) {
                if let ips = self.sectionIndexPaths[sectionIndex] {
                    indexPaths.unionInPlace(ips)
                }
            }
            else if let columns = self.sectionColumnAttributes[sectionIndex] where columns.count > 0 {
                for column in columns {
                    for attr in column {
                        if attr.frame.intersects(rect) {
                            indexPaths.insert(attr.indexPath)
                        }
                        else if attr.frame.origin.y > CGRectGetMaxY(rect) { break }
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
            //            let columns = sectionColumnAttributes[currentIndexPath._section]
            
            guard let cAttrs = collectionView.layoutAttributesForItemAtIndexPath(currentIndexPath),
                let columns = sectionColumnAttributes[section] else { return nil }
            
            let cFlat = CGRect(x: cAttrs.frame.origin.x, y: 0, width: cAttrs.frame.size.width, height: 50)
            
            let left = CGRectGetMinX(cAttrs.frame)
            let right = CGRectGetMaxX(cAttrs.frame)
            
            for column in columns {
                if let first = column.first {
                    // This is the first item in the column -> Check the previous section
                    if first.indexPath == currentIndexPath {
                        guard let pColumns = sectionColumnAttributes[section - 1] else { return nil }
                        
                        var last : NSIndexPath?
                        for col in pColumns.reverse() {
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
            
        case .Down:
            
            
            guard let cAttrs = collectionView.layoutAttributesForItemAtIndexPath(currentIndexPath),
                let columns = sectionColumnAttributes[section] else { return nil }
            
            let cFlat = CGRect(x: cAttrs.frame.origin.x, y: 0, width: cAttrs.frame.size.width, height: 50)
            
            let left = CGRectGetMinX(cAttrs.frame)
            let right = CGRectGetMaxX(cAttrs.frame)
            
            for column in columns {
                if let first = column.first {
                    // This is the last item in the column -> Check the previous section
                    if column.last?.indexPath == currentIndexPath {
                        guard let pColumns = sectionColumnAttributes[section + 1] else { return nil }
                        
                        var last : NSIndexPath?
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

