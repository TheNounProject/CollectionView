//
//  CollectionViewMasonryLayout.swift
//  CollectionView
//
//  Created by Wesley Byrne on 9/12/16.
//  Copyright © 2016 Noun Project. All rights reserved.
//

import Foundation


public protocol CollectionViewDelegateFlowLayout : CollectionViewDelegate {
    func collectionView(_ collectionView: CollectionView, gridLayout: CollectionViewFlowLayout, styleForItemAt indexPath: IndexPath) -> FlowLayoutItemStyle
    
    func collectionView (_ collectionView: CollectionView, gridLayout collectionViewLayout: CollectionViewFlowLayout,
                                        heightForHeaderInSection section: Int) -> CGFloat
    
    func collectionView (_ collectionView: CollectionView, gridLayout collectionViewLayout: CollectionViewFlowLayout,
                                        heightForFooterInSection section: Int) -> CGFloat
    func collectionView (_ collectionView: CollectionView, gridLayout collectionViewLayout: CollectionViewFlowLayout,
                         insetsForSectionAt section: Int) -> EdgeInsets
}

public enum FlowLayoutItemStyle {
    case flow(CGSize)
    case span(CGSize)
}



open class CollectionViewFlowLayout : CollectionViewLayout {
    
    
    public var itemSpacing: CGFloat = 8
    public var sectionInsets : EdgeInsets = NSEdgeInsetsZero
    
    struct RowAttributes : CustomStringConvertible {
        var frame = CGRect.zero
        var itemHeight: CGFloat {
            return items.last?.frame.size.height ?? 0
        }
        var items : [CollectionViewLayoutAttributes]
        
        init() {
            self.items = []
        }
        
        init(attributes: CollectionViewLayoutAttributes) {
            self.items = [attributes]
            self.frame = attributes.frame
        }
        
        mutating func add(attributes: CollectionViewLayoutAttributes) {
            items.append(attributes)
            frame = frame.union(attributes.frame)
        }
        
        func centerItems(between low: CGFloat, _ high: CGFloat) {
            let width = high - low
            let adjust = ((width - frame.size.width)/2)
            for item in items {
                item.frame.origin.x += adjust
                item.frame = item.frame.integral
            }
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
                let f = self.items.first,
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
    
    struct SectionAttributes  : CustomStringConvertible {
        var frame = CGRect.zero
        var insets : EdgeInsets = NSEdgeInsetsZero
        var contentFrame = CGRect.zero
        var header : CollectionViewLayoutAttributes?
        var footer : CollectionViewLayoutAttributes?
        var rows : [RowAttributes] = []
        var items : [CollectionViewLayoutAttributes] = []
        init() { }
        
        var description: String {
            return "Section Attributes : \(frame)  content: \(contentFrame)  Rows: \(rows.count)  Items: \(items.count)"
        }
        
        
        mutating func addItem(with attributes: CollectionViewLayoutAttributes, using style: FlowLayoutItemStyle, in cv: CollectionView, insets: EdgeInsets, itemSpacing: CGFloat) -> CGFloat {
            
            func adjustOversizedIfNeeded() {
                let width = cv.frame.size.width - insets.right - insets.left
                if attributes.frame.size.width > width {
                    let scale = width/attributes.frame.size.width
                    attributes.frame.size = CGSize(width: attributes.frame.size.width * scale, height: attributes.frame.size.height * scale)
                }
            }
            
            switch style {
            case let .flow(size):
                
                func newRow() {
                    let space = rows.count > 0 ? itemSpacing : 0
                    attributes.frame = CGRect(x: insets.left, y: contentFrame.maxY + space, width: size.width, height: size.height)
                    adjustOversizedIfNeeded()
                    if rows.last?.items.count == 0 {
                        rows[rows.count - 1].add(attributes: attributes)
                    }
                    else {
                        rows.last?.centerItems(between: insets.left, cv.frame.size.width - insets.right)
                        rows.append(RowAttributes(attributes: attributes))
                    }
                }
                
                if rows.count > 0, let prev = rows[rows.count - 1].items.last, prev.frame.size.height == size.height {
                    
                    let rem = cv.frame.size.width  - prev.frame.maxX - itemSpacing - insets.right - insets.left
                    if rem > size.width {
                        attributes.frame = CGRect(x: prev.frame.maxX + itemSpacing, y: prev.frame.origin.y, width: size.width, height: size.height)
                        rows[rows.count - 1].add(attributes: attributes)
                    }
                    else {
                        newRow()
                    }
                }
                else {
                    newRow()
                }
                items.append(attributes)
                contentFrame = contentFrame.union(attributes.frame)
                if items.count == 1 {
                    contentFrame = attributes.frame
                }
                return attributes.frame.maxY
                
            case let .span(size):
                attributes.frame = CGRect(x: insets.left, y: contentFrame.maxY + (rows.count > 0 ? itemSpacing : 0), width: size.width, height: size.height)
                //                adjustOversizedIfNeeded()
                
                rows.last?.centerItems(between: insets.left, cv.frame.size.width - insets.right)
                let r = RowAttributes(attributes: attributes)
                r.centerItems(between: insets.left, cv.frame.size.width - insets.right)
                rows.append(r)
                
                rows.append(RowAttributes())
                items.append(attributes)
                contentFrame = contentFrame.union(attributes.frame)
                if items.count == 1 {
                    contentFrame = attributes.frame
                }
                return attributes.frame.maxY
            }
        }
        
        var lastRowWidth : CGFloat {
            for row in rows.reversed() {
                if row.items.count > 0 {
                    return row.frame.size.width
                }
            }
            return 0
        }
    }
    
    var delegate : CollectionViewDelegateFlowLayout? {
        return self.collectionView?.delegate as? CollectionViewDelegateFlowLayout
    }
    
    
    
    
    var sectionAttributes = [SectionAttributes]()
    
    /// Only used during layout preparation to reference the width of the previously inserted row
    private(set) public var widthOfLastRow : CGFloat?
    
    public var insetSupplementaryViews = true
    
    override open func prepareLayout() {
        
        self.sectionAttributes.removeAll()
        guard let cv = self.collectionView else { return }
        
        let numSections = cv.numberOfSections()
        guard numSections > 0 else { return }
        
        var top : CGFloat = 0
        
        for sec in 0..<numSections {
            
            var sectionAttrs = SectionAttributes()
            
            var sectionInsets = self.delegate?.collectionView(cv, gridLayout: self, insetsForSectionAt: sec) ?? self.sectionInsets
            sectionAttrs.insets = sectionInsets
            let numItems = cv.numberOfItems(in: sec)
            
            sectionAttrs.frame.origin.y = top
            sectionAttrs.contentFrame.origin.y = top
            
            
            let heightHeader : CGFloat = self.delegate?.collectionView(cv, gridLayout: self, heightForHeaderInSection: sec) ?? 0
            if heightHeader > 0 {
                let attrs = CollectionViewLayoutAttributes(forSupplementaryViewOfKind: CollectionViewLayoutElementKind.SectionHeader, withIndexPath: IndexPath.for(section: sec))
                attrs.frame = insetSupplementaryViews ?
                    CGRect(x: sectionInsets.left, y: top, width: cv.contentVisibleRect.size.width - sectionInsets.left - sectionInsets.right, height: heightHeader)
                    : CGRect(x: 0, y: top, width: cv.contentVisibleRect.size.width, height: heightHeader)
                sectionAttrs.header = attrs
                sectionAttrs.frame = attrs.frame
                top = attrs.frame.maxY
            }
            
            top += sectionInsets.top
            sectionAttrs.contentFrame.origin.y = top
            
            if numItems > 0 {
                for item in 0..<numItems {
                    let ip = IndexPath.for(item: item, section: sec)
                    
                    guard let style = self.delegate?.collectionView(cv, gridLayout: self, styleForItemAt: ip) else { continue }
                    var attrs = CollectionViewLayoutAttributes(forCellWithIndexPath: ip)
                    top = sectionAttrs.addItem(with: attrs, using: style, in: cv, insets: sectionInsets, itemSpacing: itemSpacing)
                    widthOfLastRow = sectionAttrs.lastRowWidth
                }
                widthOfLastRow = nil
                if sectionAttrs.rows.last?.items.count == 0 {
                    sectionAttrs.rows.removeLast()
                }
                else {
                    sectionAttrs.rows.last?.centerItems(between: sectionInsets.left, cv.frame.size.width - sectionInsets.right)
                }
            }
            
            let footerHeader : CGFloat = self.delegate?.collectionView(cv, gridLayout: self, heightForFooterInSection: sec) ?? 0
            if heightHeader > 0 {
                let attrs = CollectionViewLayoutAttributes(forSupplementaryViewOfKind: CollectionViewLayoutElementKind.SectionFooter, withIndexPath: IndexPath.for(section: sec))
                attrs.frame = insetSupplementaryViews ?
                    CGRect(x: sectionInsets.left, y: top, width: cv.contentVisibleRect.size.width - sectionInsets.left - sectionInsets.right, height: heightHeader)
                    : CGRect(x: 0, y: top, width: cv.contentVisibleRect.size.width, height: heightHeader)
                sectionAttrs.footer = attrs
                sectionAttrs.frame = sectionAttrs.frame.union(attrs.frame)
                top = attrs.frame.maxY
            }
            
            sectionAttrs.frame = sectionAttrs.frame.union(sectionAttrs.contentFrame)
            sectionAttributes.append(sectionAttrs)

        }
    }
    
    
    override open func layoutAttributesForElements(in rect: CGRect) -> [CollectionViewLayoutAttributes]? {
        var attrs : [CollectionViewLayoutAttributes] = []
        
        guard let cv = self.collectionView else { return nil }
        if rect.equalTo(CGRect.zero) || cv.numberOfSections() == 0 { return attrs }
        for sectionIndex in 0...cv.numberOfSections() - 1 {
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
    
    override open func layoutAttributesForSupplementaryView(ofKind elementKind: String, atIndexPath indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
        
        if elementKind == CollectionViewLayoutElementKind.SectionHeader {
            let attrs = self.sectionAttributes[indexPath._section].header?.copy()
            if pinHeadersToTop, let currentAttrs = attrs, let cv = self.collectionView {
                
                let contentOffset = cv.contentOffset
                let frame = currentAttrs.frame
                if indexPath._section == 0 && contentOffset.y < -cv.contentInsets.top {
                    currentAttrs.frame.origin.y = 0
                    currentAttrs.floating = false
                }
                else {
                    var nextHeaderOrigin = CGPoint(x: CGFloat.greatestFiniteMagnitude, y: CGFloat.greatestFiniteMagnitude)
                    if let nextHeader = self.sectionAttributes.object(at: indexPath._section + 1)?.header {
                        nextHeaderOrigin = nextHeader.frame.origin
                    }
                    let topInset = cv.contentInsets.top
                    currentAttrs.frame.origin.y =  min(max(contentOffset.y + topInset , frame.origin.y), nextHeaderOrigin.y - frame.height)
                    currentAttrs.floating = indexPath._section == 0 || currentAttrs.frame.origin.y > frame.origin.y
                }
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
    
    
    override open func indexPathsForItems(in rect: CGRect) -> Set<IndexPath>? {
        var indexPaths = Set<IndexPath>()
        guard let cv = self.collectionView else { return nil }
        if rect.equalTo(CGRect.zero) || cv.numberOfSections() == 0 { return indexPaths }
        for sectionIndex in 0...cv.numberOfSections() - 1 {
            
            if cv.numberOfItems(in: sectionIndex) == 0 { continue }
            
            let sAttrs = self.sectionAttributes[sectionIndex]
            if sAttrs.frame.isEmpty || !sAttrs.frame.intersects(rect) { continue }
            
            // If the section is completely show, add all the attrs
            if rect.contains(sAttrs.frame) {
                for a in sAttrs.items {
                    indexPaths.insert(a.indexPath)
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
                            indexPaths.insert(attr.indexPath as IndexPath)
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
        let numberOfSections = cv.numberOfSections()
        if numberOfSections == 0{ return CGSize.zero }
        
        var contentSize = cv.contentVisibleRect.size as CGSize
        let height = self.sectionAttributes.last?.frame.maxY ?? 0
        if height == 0 { return CGSize.zero }
        contentSize.height = height
        return  contentSize
    }
    
    
    
    open override func scrollRectForItem(at indexPath: IndexPath, atPosition: CollectionViewScrollPosition) -> CGRect? {
        guard var frame = self.layoutAttributesForItem(at: indexPath)?.frame else { return nil }
        let inset = (self.collectionView?.contentInsets.top ?? 0) - sectionAttributes[indexPath._section].insets.top
//        let sectionInsets =
        if self.pinHeadersToTop, let attrs = self.layoutAttributesForSupplementaryView(ofKind: CollectionViewLayoutElementKind.SectionHeader, atIndexPath: indexPath.sectionCopy) {
            let y = (frame.origin.y - attrs.frame.size.height) + inset
            
            let height = frame.size.height + attrs.frame.size.height
            frame.size.height = height
            frame.origin.y = y
        }
        return frame
    }
    
    
    open override func indexPathForNextItem(moving direction: CollectionViewDirection, from currentIndexPath: IndexPath) -> IndexPath? {
        guard let collectionView = self.collectionView else { fatalError() }
        
        var index = currentIndexPath._item
        var section = currentIndexPath._section
        
        let numberOfSections = collectionView.numberOfSections()
        let numberOfItemsInSection = collectionView.numberOfItems(in: currentIndexPath._section)
        
        guard collectionView.rectForItem(at: currentIndexPath) != nil else { return nil }
        
//        func item(in row: RowAttributes, verticallyAlignedTo attrs: CollectionViewLayoutAttributes) -> IndexPath? {
//            for item in row.items {
//                if item.frame.origin.x > attrs.frame.origin.x {
//                    return item.indexPath
//                }
//            }
//            return
//        }
        
        switch direction {
        case .up:
            guard let cAttrs = collectionView.layoutAttributesForItem(at: currentIndexPath) else { return nil }
//            let secAttrs = sectionAttributes.object(at: currentIndexPath._section)
//            let cFlat = CGRect(x: cAttrs.frame.origin.x, y: 0, width: cAttrs.frame.size.width, height: 50)
            
            var prev : RowAttributes?
            for row in sectionAttributes[section].rows {
                if let idx = row.index(of: currentIndexPath) {
                    guard let pRow = prev else {
                        guard let pSectionRow = sectionAttributes.object(at: section - 1)?.rows.last else { return nil }
                        return pSectionRow.item(verticallyAlignedTo: cAttrs)
                    }
                    return pRow.item(verticallyAlignedTo: cAttrs)
                }
                prev = row
            }
            return nil
            
        case .down:
            
            
            guard let cAttrs = collectionView.layoutAttributesForItem(at: currentIndexPath) else { return nil }
//            let secAttrs = sectionAttributes.object(at: currentIndexPath._section)
//            let cFlat = CGRect(x: cAttrs.frame.origin.x, y: 0, width: cAttrs.frame.size.width, height: 50)
            
            var prev : RowAttributes?
            for row in sectionAttributes[section].rows.reversed() {
                if let idx = row.index(of: currentIndexPath) {
                    guard let pRow = prev else {
                        guard let pSectionRow = sectionAttributes.object(at: section + 1)?.rows.first else { return nil }
                        return pSectionRow.item(verticallyAlignedTo: cAttrs)
                    }
                    return pRow.item(verticallyAlignedTo: cAttrs)
                }
                prev = row
            }
            return nil
            
            
//            guard let cAttrs = collectionView.layoutAttributesForItem(at: currentIndexPath),
//                let columns = sectionColumnAttributes[section] else { return nil }
//            
//            let cFlat = CGRect(x: cAttrs.frame.origin.x, y: 0, width: cAttrs.frame.size.width, height: 50)
//            
//            for column in columns {
//                if let first = column.first {
//                    // This is the last item in the column -> Check the previous section
//                    if column.last?.indexPath == currentIndexPath {
//                        guard let pColumns = sectionColumnAttributes[section + 1] else { return nil }
//                        
//                        for col in pColumns {
//                            if let pFirst = col.first {
//                                let flat = CGRect(x: pFirst.frame.origin.x, y: 0, width: pFirst.frame.size.width, height: 50)
//                                if cFlat.intersects(flat) {
//                                    return col.first?.indexPath
//                                }
//                            }
//                        }
//                        return sectionItemAttributes[section + 1].last?.indexPath
//                    }
//                    
//                    let flat = CGRect(x: first.frame.origin.x, y: 0, width: first.frame.size.width, height: 50)
//                    
//                    // Get the same column
//                    if cFlat.intersects(flat) {
//                        for idx in 0..<column.count {
//                            let attr = column[idx]
//                            if attr.indexPath == currentIndexPath {
//                                return column[idx + 1].indexPath
//                            }
//                        }
//                    }
//                }
//            }
            return nil
            
        case .left:
            if section == 0 && index == 0 {
                return currentIndexPath
            }
            if index > 0 {
                index = index - 1
            } else {
                section = section - 1
                index = collectionView.numberOfItems(in: currentIndexPath._section - 1) - 1
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
