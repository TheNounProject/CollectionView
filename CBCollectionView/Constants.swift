//
//  Constants.swift
//  CBCollectionView
//
//  Created by Wesley Byrne on 9/1/16.
//  Copyright © 2016 Noun Project. All rights reserved.
//

import Foundation


public typealias CBAnimationCompletion = (finished: Bool)->Void


public enum CBCollectionElementCategory : UInt {
    case Cell
    case SupplementaryView
}

public enum CBCollectionViewScrollPosition {
    case None
    case Nearest
    case Top
    case Centered
    case Bottom
}

enum CBCollectionViewSelectionMethod {
    case Click
    case Extending
    case Multiple
}

internal enum CBCollectionViewSelectionType {
    case Single
    case Extending
    case Multiple
}


public enum CBCollectionViewScrollDirection {
    case Vertical
    case Horizontal    
}

public enum CBCollectionViewDirection {
    case Left
    case Right
    case Up
    case Down
}
