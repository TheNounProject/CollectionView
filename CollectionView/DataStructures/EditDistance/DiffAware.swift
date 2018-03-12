//
//  DiffAware.swift
//  DeepDiff
//
//  Created by Khoa Pham on 03.01.2018.
//  Copyright © 2018 Khoa Pham. All rights reserved.
//

import Foundation

public protocol DiffAware {
    func diff<T: Collection>(old: T, new: T) -> [Edit<T.Iterator.Element>] where T.Iterator.Element:Hashable, T.Index == Int, T.IndexDistance == Int
}

extension DiffAware {
    func preprocess<T: Collection>(old: T, new: T) -> [Edit<T.Iterator.Element>]? where T.Iterator.Element:Hashable, T.Index == Int, T.IndexDistance == Int {
        switch (old.isEmpty, new.isEmpty) {
        case (true, true):
            // empty
            return []
        case (true, false):
            // all .insert
            return new.enumerated().map { e in
                return Edit(.insertion, value: e.element, index: e.offset)
            }
        case (false, true):
            // all .delete
            return old.enumerated().map { e in
                return Edit(.deletion, value: e.element, index: e.offset)
            }
        default:
            return nil
        }
    }
}
