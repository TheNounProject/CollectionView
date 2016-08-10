//
//  CBCollectionViewHorizontalLayout.swift
//  Lingo
//
//  Created by Wesley Byrne on 3/1/16.
//  Copyright © 2016 The Noun Project. All rights reserved.
//

import Foundation


@objc public protocol CBCollectionViewDelegateHorizontalListLayout: CBCollectionViewDelegate {
    optional func collectionView (collectionView: CBCollectionView,layout collectionViewLayout: CBCollectionViewLayout,
        widthForItemAtIndexPath indexPath: NSIndexPath) -> CGFloat
}


public class CBCollectionViewHorizontalListLayout : CBCollectionViewLayout {
    
    override public var scrollDirection : CBCollectionViewScrollDirection {
        return CBCollectionViewScrollDirection.Horizontal
    }
    
    public var delegate: CBCollectionViewDelegateHorizontalListLayout? {
        return self.collectionView?.delegate as? CBCollectionViewDelegateHorizontalListLayout
    }
    
    public var sectionInsets = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    public var itemWidth: CGFloat = 100
    public var itemSpacing: CGFloat = 8
    
    var cache : [CGRect]! = []
    var contentWidth: CGFloat = 0
    
    public override func prepareLayout() {
        super.prepareLayout()
        cache = []
        
        guard let cv = self.collectionView else { return }
        
        let numSections = cv.numberOfSections()
        assert(numSections <= 1, "Horizontal collection view cannot have more than 1 section")
        
        if numSections == 0 { return }
        let numRows = cv.numberOfItemsInSection(0)
        if numRows == 0 { return }
        
        var xPos: CGFloat = sectionInsets.left - self.itemSpacing
        
        for row in 0...numRows-1 {
            let ip = NSIndexPath._indexPathForItem(row, inSection: 0)
            var height = cv.bounds.height ?? 50
            height = height - sectionInsets.top - sectionInsets.bottom
            
            let width = self.delegate?.collectionView?(cv, layout: self, widthForItemAtIndexPath: ip) ?? itemWidth
            
            var x = xPos
            x += self.itemSpacing
            
            let frame = CGRect(x: x, y: sectionInsets.top, width: width, height: height)
            
            cache.append(frame)
            xPos = x + width
        }
        
        contentWidth = xPos + sectionInsets.right
    }
    
    var _size = CGSizeZero
    public override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        if !CGSizeEqualToSize(newBounds.size, _size) {
            self._size = newBounds.size
            return true
        }
        return false
    }
    
    public override func collectionViewContentSize() -> CGSize {
        let numberOfSections = self.collectionView!.numberOfSections()
        if numberOfSections == 0{
            return CGSizeZero
        }
        var contentSize = self.collectionView!.bounds.size as CGSize
        contentSize.width = contentWidth
        return  contentSize
    }
    
    public override func scrollRectForItemAtIndexPath(indexPath: NSIndexPath, atPosition: CBCollectionViewScrollPosition) -> CGRect? {
        return layoutAttributesForItemAtIndexPath(indexPath)?.frame
    }
    
    
    public override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> CBCollectionViewLayoutAttributes? {
        let attrs = CBCollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
        attrs.alpha = 1
        attrs.zIndex = 1000
        
        let frame = cache[indexPath._item]
        attrs.frame = frame
        return attrs
    }
}


public class CBHorizontalCollectionView : CBCollectionView {
    
    override init() {
        super.init()
        self.hasVerticalScroller = false
        self.hasHorizontalScroller = true
    }
    required public  init?(coder: NSCoder) {
        super.init(coder: coder)
        self.hasVerticalScroller = false
        self.hasHorizontalScroller = true
    }
    
//    override func scrollWheel(theEvent: NSEvent) {
//        super.scrollWheel(theEvent)
//        if (fabs(theEvent.deltaX) > fabs(theEvent.deltaY) || theEvent.deltaY == 0) == false {
//            self.nextResponder?.scrollWheel(theEvent)
//        }
//    }
}