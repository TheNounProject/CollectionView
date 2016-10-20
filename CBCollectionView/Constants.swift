//
//  Constants.swift
//  CBCollectionView
//
//  Created by Wesley Byrne on 9/1/16.
//  Copyright © 2016 Noun Project. All rights reserved.
//

import Foundation


public typealias CBAnimationCompletion = (_ finished: Bool)->Void


public enum CBCollectionElementCategory {
    case cell
    case supplementaryView
}

public enum CBCollectionViewScrollPosition {
    case none
    case nearest
    case top
    case centered
    case bottom
}

enum CBCollectionViewSelectionMethod {
    case click
    case extending
    case multiple
}

internal enum CBCollectionViewSelectionType {
    case single
    case extending
    case multiple
}


public enum CBCollectionViewScrollDirection {
    case vertical
    case horizontal    
}

public enum CBCollectionViewDirection {
    case left
    case right
    case up
    case down
}
