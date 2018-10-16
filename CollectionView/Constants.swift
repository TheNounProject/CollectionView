//
//  Constants.swift
//  CollectionView
//
//  Created by Wesley Byrne on 9/1/16.
//  Copyright © 2016 Noun Project. All rights reserved.
//

import Foundation

/// AnimationCompletion
public typealias AnimationCompletion = (_ finished: Bool) -> Void

/// CollectionElementCategory
///
/// - cell:
/// - supplementaryView: 
public enum CollectionElementCategory {
    case cell
    case supplementaryView
}

/// CollectionViewScrollPosition
///
/// - none:
/// - nearest:
/// - leading:
/// - centered:
/// - trailing:
public enum CollectionViewScrollPosition {
    case none
    case nearest
    case leading
    case centered
    case trailing
}

/// CollectionViewSelectionType
///
/// - single:
/// - extending:
/// - multiple:
internal enum CollectionViewSelectionType {
    case single
    case extending
    case toggle
}

/// CollectionViewScrollDirection
///
/// - vertical:
/// - horizontal:
public enum CollectionViewScrollDirection {
    case vertical
    case horizontal    
}

/// CollectionViewDirection
///
/// - left:
/// - right:
/// - up:
/// - down:
public enum CollectionViewDirection {
    case left
    case right
    case up
    case down
}
