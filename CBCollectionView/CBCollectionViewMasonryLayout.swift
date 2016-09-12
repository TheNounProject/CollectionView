//
//  CBCollectionViewMasonryLayout.swift
//  CBCollectionView
//
//  Created by Wesley Byrne on 9/12/16.
//  Copyright © 2016 Noun Project. All rights reserved.
//

import Foundation




final class CBCollectionViewMasonryLayout : CBCollectionViewLayout {
    
    override func prepareLayout() {
        super.prepareLayout()
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [CBCollectionViewLayoutAttributes]? {
        return nil
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> CBCollectionViewLayoutAttributes? {
        return nil
    }
    
    override func layoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> CBCollectionViewLayoutAttributes? {
        return nil
    }
    
    override func indexPathsForItemsInRect(rect: CGRect) -> Set<NSIndexPath>? {
        return nil
    }
    
    override func rectForSection(section: Int) -> CGRect {
        return CGRectZero
    }
    
    override func collectionViewContentSize() -> CGSize {
        return self.collectionView?.bounds.size ?? CGSizeZero
    }
}