//
//  Constants.swift
//  CollectionView
//
//  Created by Wesley Byrne on 9/1/16.
//  Copyright © 2016 Noun Project. All rights reserved.
//

import Foundation


/**
 AnimationCompletion
*/
public typealias AnimationCompletion = (_ finished: Bool)->Void

/**
 CollectionElementCategory
*/
public enum CollectionElementCategory {
    case cell
    case supplementaryView
}


/**
 CollectionViewScrollPosition
*/
public enum CollectionViewScrollPosition {
    case none
    case nearest
    case leading
    case centered
    case trailing
}

//enum CollectionViewSelectionMethod {
//    case click
//    case extending
//    case multiple
//}

internal enum CollectionViewSelectionType {
    case single
    case extending
    case multiple
}


/**
 CollectionViewScrollDirection
*/
public enum CollectionViewScrollDirection {
    case vertical
    case horizontal    
}


/**
 CollectionViewDirection
*/
public enum CollectionViewDirection {
    case left
    case right
    case up
    case down
}
