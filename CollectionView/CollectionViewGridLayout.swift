//
//  CollectionViewGridLayout.swift
//  CollectionView
//
//  Created by Wesley Byrne on 4/11/16.
//  Copyright © 2016 Noun Project. All rights reserved.
//

import Foundation


/**
 *  The delegate for CollectionViewLayout
 */
@objc public protocol CollectionViewDelegateGridLayout: CollectionViewDelegate {
    
    
    @objc optional func collectionView (_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout,
                                  numberOfColumnsInSection section: Int) -> Int
    
    
    /**
     Defined an aspect ration based on the number of columns in the grid.
     
     note: if an aspect ratio and height are supplied via delegate methods for the same item, height is added to the size calculated by the aspect ration. Return CGSizeZero to use a static height for a particular item.
     
     - parameter collectionView:       The collection view
     - parameter collectionViewLayout: The layout asking for the dimensios
     - parameter section:              The section to apply this aspect ratio to
     
     - returns: A size defining the aspect ration or the cells (width x height)
     */
    @objc optional func collectionView (_ collectionView: CollectionView,layout collectionViewLayout: CollectionViewLayout,
                                  aspectRatioForItemsInSection section: Int) -> CGSize
    
    @objc optional func collectionView (_ collectionView: CollectionView,layout collectionViewLayout: CollectionViewLayout,
                                  heightForItemsInSection section: Int) -> CGFloat
    
    @objc optional func collectionView (_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout,
                                  heightForHeaderInSection section: NSInteger) -> CGFloat
    
    @objc optional func collectionView (_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout,
                                  heightForFooterInSection section: NSInteger) -> CGFloat
    
    @objc optional func collectionView (_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout,
                                  insetsForSectionAtIndex section: NSInteger) -> EdgeInsets
    
    // Between to items in the same column
    @objc optional func collectionView (_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout,
                                  rowSpacingForSectionAtIndex section: NSInteger) -> CGFloat
    
    @objc optional func collectionview(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout,
                                 columnSpacingForSectionAtIndex section: NSInteger) -> CGFloat
    
}


/// A feature packed collection view layout with pinterest like layouts, aspect ratio sizing, and drag and drop.
public final class CollectionViewGridLayout : CollectionViewLayout {
    
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
    public final var aspectRatio : CGSize = CGSize(width: 1, height: 1) { didSet{ invalidateLayout() }}
    
    /// If supplementary views should respect section insets or fill the CollectionView width
    public final var insetSupplementaryViews : Bool = false { didSet{ invalidateLayout() }}
    
    /// Default insets for all sections
    public final var sectionInsets : EdgeInsets = EdgeInsets(top: 8, left: 8, bottom: 8, right: 8) { didSet{ invalidateLayout() }}
    
    public final func numberOfColumnsInSection(_ section: Int) -> Int {
        return sections[section].columnCount
    }
    
    // Internal caching
    fileprivate var _cvSize = CGSize.zero
    
    fileprivate var numSections : Int { get { return self.collectionView!.numberOfSections() }}
    fileprivate func columnsInSection(_ section : Int) -> Int {
        var cols = self.delegate?.collectionView?(self.collectionView!, layout: self, numberOfColumnsInSection: section) ?? self.columnCount
        if cols <= 0 { cols = 1 }
        return cols
    }
    
    //  private property and method above.
    fileprivate weak var delegate : CollectionViewDelegateGridLayout? { get{ return self.collectionView!.delegate as? CollectionViewDelegateGridLayout }}
    
    
    struct SectionSpec {
        var frame : CGRect
        var contentRect : CGRect
        
        var itemCounts : Int
        
        var columnCount : Int = 0
        var columnWidth: CGFloat
        var columnSpacing : CGFloat
        
        var rowCount : Int = 0
        var rowHeight : CGFloat
        var rowSpacing : CGFloat
        
        var indexPaths : Set<IndexPath>
        
        
        func frameForRow(_ rowIndex: Int) -> CGRect {
            var width = self.contentRect.size.width
            if rowIndex == rowCount - 1 {
                let rowItemCount = itemCounts % rowCount
                width = CGFloat(rowItemCount) * (self.columnWidth + self.columnSpacing)
            }
            return CGRect(x: self.contentRect.origin.x,
                                  y: self.contentRect.origin.y + (CGFloat(rowIndex) * (self.rowHeight + self.rowSpacing)),
                                  width: width,
                                  height: self.rowHeight)
        }
    }
    
    fileprivate var sections = [SectionSpec]()
    
    fileprivate var sectionRowAttributes : [Int:[[CollectionViewLayoutAttributes]]] = [:]
    fileprivate var sectionItemAttributes : [[CollectionViewLayoutAttributes]] = []

    fileprivate var itemAttributes : [IndexPath:CollectionViewLayoutAttributes] = [:]
    fileprivate var headersAttributes : [Int:CollectionViewLayoutAttributes] = [:]
    fileprivate var footersAttributes : [Int:CollectionViewLayoutAttributes] = [:]
    
    
    override public init() {
        super.init()
    }

    override public func prepareLayout(){
        super.prepareLayout()
        
        if self.aspectRatio.width == 0 || self.aspectRatio.height == 0 {
            Swift.print("CollectionViewGridLayout invalid aspect ratio with 0 width or height. Resetting to 1x1")
            self.aspectRatio = CGSize(width: 1, height: 1)
        }
        
        self.sections.removeAll()
        self.headersAttributes.removeAll()
        self.footersAttributes.removeAll()
        self.itemAttributes.removeAll()
        
        self.sectionRowAttributes.removeAll()
        
        self.allIndexPaths.removeAll()
        
        let numberOfSections = self.collectionView!.numberOfSections()
        if numberOfSections == 0 { return }
        
        var top : CGFloat = 0.0
        
        self.sectionItemAttributes = Array(repeating: [], count: numberOfSections)
        
        for section in 0..<numberOfSections {
            let colCount = self.columnsInSection(section)
            
            
            
            
            
            /*
             * 1. Get section-specific metrics (minimumInteritemSpacing, sectionInset)
             */
            
            let sectionInsets :  EdgeInsets =  self.delegate?.collectionView?(self.collectionView!, layout: self, insetsForSectionAtIndex: section) ?? self.sectionInsets
            let rowSpacing : CGFloat = self.delegate?.collectionView?(self.collectionView!, layout: self, rowSpacingForSectionAtIndex: section) ?? self.minimumInteritemSpacing
            let colSpacing = self.delegate?.collectionview?(self.collectionView!, layout: self, columnSpacingForSectionAtIndex: section) ?? self.minimumColumnSpacing
            
            let contentWidth = self.collectionView!.bounds.size.width - sectionInsets.left - sectionInsets.right
            let spaceColumCount = CGFloat(colCount-1)
            let itemWidth = (contentWidth - (spaceColumCount*colSpacing)) / CGFloat(colCount)
            
            var rowHeight : CGFloat = 0
            
            if let aSize = self.delegate?.collectionView?(self.collectionView!, layout: self, aspectRatioForItemsInSection: section) , aSize.width > 0 && aSize.height > 0 {
                let h = aSize.height * (itemWidth/aSize.width)
                rowHeight = floor(h)
                
                if let addHeight = self.delegate?.collectionView?(self.collectionView!, layout: self, heightForItemsInSection: section) {
                    rowHeight += addHeight
                }
            }
            else if let h = self.delegate?.collectionView?(self.collectionView!, layout: self, heightForItemsInSection: section) {
                rowHeight = h
            }
            else {
                rowHeight = self.aspectRatio.height * (itemWidth/self.aspectRatio.width)
            }
            
            
            
            if rowHeight == 0 {
                rowHeight =  itemWidth * (self.aspectRatio.height/self.aspectRatio.width)
            }
            
            var sectionFrame: CGRect = CGRect(x: sectionInsets.left, y: top, width: contentWidth, height: 0)
            
            
            /*
             * 2. Section header
             */
            let heightHeader : CGFloat = self.delegate?.collectionView?(self.collectionView!, layout: self, heightForHeaderInSection: section) ?? self.headerHeight
            if heightHeader > 0 {
                let attributes = CollectionViewLayoutAttributes(forSupplementaryViewOfKind: CollectionViewLayoutElementKind.SectionHeader, withIndexPath: IndexPath.for(item:0, section: section))
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
            
            var contentRect: CGRect = CGRect(x: sectionInsets.left, y: top, width: contentWidth, height: 0)
            let itemCount = self.collectionView!.numberOfItemsInSection(section)
            var sectionAttrs :[CollectionViewLayoutAttributes] = []
            var sectionIPs = Set<IndexPath>()
            
            let rowCount = Int(ceil(Float(itemCount)/Float(colCount)))
            self.sectionRowAttributes[section] = []
            
            if itemCount > 0 {
                
                var xPos = contentRect.origin.x
                var yPos = contentRect.origin.y
                
                var newTop : CGFloat = 0
                var row : [CollectionViewLayoutAttributes] = []
                
                for idx in 0..<itemCount {
                    
                    let ip = IndexPath.for(item:idx, section: section)
                    sectionIPs.insert(ip)
                    
                    let attrs = CollectionViewLayoutAttributes(forCellWithIndexPath: ip)
                    attrs.frame = NSRect(x: xPos, y: yPos, width: itemWidth, height: rowHeight)
                    newTop = yPos + rowHeight
                    row.append(attrs)
                    
                    sectionAttrs.append(attrs)
                    self.itemAttributes[ip] = attrs
                    
                    if (idx == itemCount - 1) || row.count == colCount {
                        self.sectionRowAttributes[section]?.append(row)
                        row = []
                        xPos = contentRect.origin.x
                        yPos += rowHeight + rowSpacing
                    }
                    else {
                        xPos += itemWidth + colSpacing
                    }
                }
                top = newTop
            }
            
            contentRect.size.height = top - contentRect.origin.y
            
            self.sectionItemAttributes.append(sectionAttrs)
            
            let footerHeight = self.delegate?.collectionView?(self.collectionView!, layout: self, heightForFooterInSection: section) ?? self.footerHeight
            if footerHeight > 0 {
                let attributes = CollectionViewLayoutAttributes(forSupplementaryViewOfKind: CollectionViewLayoutElementKind.SectionFooter, withIndexPath: IndexPath.for(item:0, section: section))
                attributes.alpha = 1
                attributes.frame = insetSupplementaryViews ?
                    CGRect(x: sectionInsets.left, y: top, width: self.collectionView!.bounds.size.width - sectionInsets.left - sectionInsets.right, height: footerHeight)
                    : CGRect(x: 0, y: top, width: self.collectionView!.bounds.size.width, height: footerHeight)
                self.footersAttributes[section] = attributes
                top = attributes.frame.maxY
            }
            top += sectionInsets.bottom
            
            sectionFrame.size.height = top - sectionFrame.origin.y
            
            
            let spec = SectionSpec(frame: sectionFrame,
                                    contentRect: contentRect,
                                    itemCounts: itemCount,
                                    columnCount: colCount,
                                    columnWidth: itemWidth,
                                    columnSpacing: colSpacing,
                                    rowCount: rowCount,
                                    rowHeight: rowHeight,
                                    rowSpacing: rowSpacing,
                                    indexPaths: sectionIPs)
            
            self.sections.append(spec)
            
            
//            var itemAttributes :[CollectionViewLayoutAttributes] = []
//            row[section] = [Array](count: colCount, repeatedValue: [])
            
            // Item will be put into shortest column.
//            for idx in 0..<itemCount {
//                let indexPath = NSIndexPath.for(item:idx, section: section)
//                sIndexPaths.insert(indexPath)
//                allIndexPaths.insert(indexPath)
//                
//                let columnIndex = self.nextColumnIndexForItem(indexPath)
//                let xOffset = sectionInsets.left + (itemWidth + colSpacing) * CGFloat(columnIndex)
//                let yOffset = self.columnHeights[section][columnIndex]
//                var itemHeight : CGFloat = 0
//                let aSize = self.delegate?.collectionView?(self.collectionView!, layout: self, aspectRatioForItemAtIndexPath: indexPath)
//                if aSize != nil && aSize!.width != 0 && aSize!.height != 0 {
//                    let h = aSize!.height * (itemWidth/aSize!.width)
//                    itemHeight = floor(h)
//                    
//                    if let addHeight = self.delegate?.collectionView?(self.collectionView!, layout: self, heightForItemAtIndexPath: indexPath) {
//                        itemHeight += addHeight
//                    }
//                }
//                else {
//                    itemHeight = self.delegate?.collectionView?(self.collectionView!, layout: self, heightForItemAtIndexPath: indexPath) ?? self.defaultItemHeight
//                }
//                
//                let attributes = CollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
//                attributes.alpha = 1
//                attributes.frame = CGRectMake(xOffset, CGFloat(yOffset), itemWidth, itemHeight)
//                itemAttributes.append(attributes)
//                self.allItemAttributes.append(attributes)
//                self.columnHeights[section][columnIndex] = CGRectGetMaxY(attributes.frame) + itemSpacing;
//                self.sectionColumnAttributes[section]?[columnIndex].append(attributes)
//            }
//            self.sectionItemAttributes.append(itemAttributes)
//            self.sectionIndexPaths[section] = sIndexPaths
            
            /*
             * 4. Section footer
             */
//            let columnIndex  = self.longestColumnIndexInSection(section)
            //            sectionHeight += self.columnHeights[section][columnIndex] - itemSpacing + sectionInsets.bottom - top
//            top = self.columnHeights[section][columnIndex] - itemSpacing
            
//            let footerHeight = self.delegate?.collectionView?(self.collectionView!, layout: self, heightForFooterInSection: section) ?? self.footerHeight
//            if footerHeight > 0 {
//                let attributes = CollectionViewLayoutAttributes(forSupplementaryViewOfKind: CollectionViewLayoutElementKind.SectionFooter, withIndexPath: NSIndexPath.for(item:0, section: section))
//                attributes.alpha = 1
//                attributes.frame = insetSupplementaryViews ?
//                    CGRectMake(sectionInsets.left, top, self.collectionView!.bounds.size.width - sectionInsets.left - sectionInsets.right, footerHeight)
//                    : CGRectMake(0, top, self.collectionView!.bounds.size.width, footerHeight)
//                self.footersAttributes[section] = attributes
//                self.allItemAttributes.append(attributes)
//                top = CGRectGetMaxY(attributes.frame)
//                //                sectionHeight += footerHeight
//            }
//            top += sectionInsets.bottom
//            
//            sectionRect.size.height = top - sectionRect.origin.y
//            sectionFrames[section] = sectionRect
            
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
        guard let cv = collectionView else { return CGSize.zero }
        let numberOfSections = cv.numberOfSections()
        if numberOfSections == 0 { return CGSize.zero }
        
        var size = CGSize()
        size.width = cv.bounds.width
        size.height = cv.bounds.height
        if let f = self.sections.last?.frame {
            size.height = f.maxY
        }
        return size
    }
    
    public override func rectForSection(_ section: Int) -> CGRect {
        return sections[section].frame
    }
    
    
    public override func indexPathsForItemsInRect(_ rect: CGRect) -> Set<IndexPath>? {
        //        return nil
        
        var indexPaths = Set<IndexPath>()
        guard let cv = self.collectionView else { return nil }
        if rect.equalTo(CGRect.zero) || cv.numberOfSections() == 0 { return indexPaths }
        for sectionIndex in 0..<cv.numberOfSections() {
            
            if cv.numberOfItemsInSection(sectionIndex) == 0 { continue }
            
            let frame = sections[sectionIndex].contentRect
            if frame.isEmpty || !frame.intersects(rect) { continue }
            
            // If the section is completely show, add all the attrs
            if rect.contains(frame) {
                indexPaths.formUnion(sections[sectionIndex].indexPaths)
                continue
            }
            
            guard let rowAttrs = sectionRowAttributes[sectionIndex] else { continue }
            let sec = sections[sectionIndex]
            for rowIdx in 0..<sec.rowCount {
                let rowFrame = sec.frameForRow(rowIdx)
                if !rowFrame.intersects(rect) { continue }
                
                for attr in rowAttrs[rowIdx] {
                    if attr.frame.intersects(rect) {
                        indexPaths.insert(attr.indexPath as IndexPath)
                    }
                }
            }
        }
        return indexPaths
    }
    
    
    
    public override func layoutAttributesForElementsInRect(_ rect: CGRect) -> [CollectionViewLayoutAttributes]? {
        var attrs : [CollectionViewLayoutAttributes] = []
        
        guard let cv = self.collectionView else { return nil }
        if rect.equalTo(CGRect.zero) || cv.numberOfSections() == 0 { return attrs }
        for sectionIdx in  0..<sections.count {
            let sec = sections[sectionIdx]
            if sec.itemCounts > 0 || sec.contentRect.isEmpty || !sec.contentRect.intersects(rect) { continue }
            
            if rect.contains(sec.contentRect) {
                attrs.append(contentsOf: sectionItemAttributes[sectionIdx])
                continue
            }
            guard let rowAttrs = sectionRowAttributes[sectionIdx] else { continue }
            
            for rowIdx in 0..<sec.rowCount {
                let rowFrame = sec.frameForRow(rowIdx)
                if rowFrame.intersects(rect) { continue }
                
                for attr in rowAttrs[rowIdx] {
                    if attr.frame.intersects(rect) {
                        attrs.append(attr)
                    }
                }
            }
        }
        return attrs
    }
    
    public override func layoutAttributesForItemAtIndexPath(_ indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
        return itemAttributes[indexPath]
    }
    
    public override func layoutAttributesForSupplementaryViewOfKind(_ elementKind: String, atIndexPath indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
        
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
    
    override public func shouldInvalidateLayoutForBoundsChange (_ newBounds : CGRect) -> Bool {
        if !newBounds.size.equalTo(self._cvSize) {
            self._cvSize = newBounds.size
            return true
        }
        return false
    }
    
    
    public override func scrollRectForItemAtIndexPath(_ indexPath: IndexPath, atPosition: CollectionViewScrollPosition) -> CGRect? {
        guard var frame = self.layoutAttributesForItemAtIndexPath(indexPath)?.frame else { return nil }
        if self.pinHeadersToTop, let attrs = self.layoutAttributesForSupplementaryViewOfKind(CollectionViewLayoutElementKind.SectionHeader, atIndexPath: IndexPath.for(item:0, section: indexPath._section)) {
            let y = frame.origin.y - attrs.frame.size.height
            let height = frame.size.height + attrs.frame.size.height
            frame.size.height = height
            frame.origin.y = y
        }
        return frame
    }
    
    

    
    public override func indexPathForNextItemInDirection(_ direction: CollectionViewDirection, afterItemAtIndexPath currentIndexPath: IndexPath) -> IndexPath? {
        guard let collectionView = self.collectionView else { fatalError() }
        
        var index = currentIndexPath._item
        var section = currentIndexPath._section
        
        let numberOfSections = collectionView.numberOfSections()
        let numberOfItemsInSection = collectionView.numberOfItemsInSection(currentIndexPath._section)
        
        guard let cellRect = collectionView.rectForItemAtIndexPath(currentIndexPath) else { return nil }
        // let cellHeight = cellRect.height
        
        switch direction {
        case .up:
            //            let columns = sectionColumnAttributes[currentIndexPath._section]
            
            guard let cAttrs = collectionView.layoutAttributesForItemAtIndexPath(currentIndexPath),
                let rows = sectionRowAttributes[section] else { return nil }
            
            let cFlat = CGRect(x: cAttrs.frame.origin.x, y: 0, width: cAttrs.frame.size.width, height: 50)
            
            let left = cAttrs.frame.minX
            let right = cAttrs.frame.maxX
            /*
            for row in rows {
                if let first = row.first {
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
 */
            return nil
            
        case .down:
            /*
            
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
 */
            return nil

            
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
            return IndexPath.for(item:index, section: section)
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
            return IndexPath.for(item:index, section: section)
        }
    }
    
}

