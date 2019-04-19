//
//  IndexPath.swift
//  CollectionView
//
//  Created by Wesley Byrne on 3/27/19.
//  Copyright © 2019 Noun Project. All rights reserved.
//

import Foundation

/// Provides support for OSX < 10.11 and provides some helpful additions
public extension IndexPath {

    /// Create an index path with a given item and section
    ///
    /// - Parameter item: An item
    /// - Parameter section: A section
    ///
    /// - Returns: An initialized index path with the item and section
    ///
    /// - Note: item and section must be >= 0
    static func `for`(item: Int = 0, section: Int) -> IndexPath {
        precondition(item >= 0, "Attempt to create an indexPath with negative item")
        precondition(section >= 0, "Attempt to create an indexPath with negative section")
        return IndexPath(indexes: [section, item])
    }

    static var zero: IndexPath { return IndexPath.for(item: 0, section: 0) }

    /// Returns the item of the index path
    var _item: Int { return self[1] }

    /// Returns the section of the index path
    var _section: Int { return self[0] }
    static func inRange(_ range: CountableRange<Int>, section: Int) -> [IndexPath] {
        var ips = [IndexPath]()
        for idx in range {
            ips.append(IndexPath.for(item: idx, section: section))
        }
        return ips
    }

    var previous: IndexPath? {
        guard self._item >= 1 else { return nil }
        return IndexPath.for(item: self._item - 1, section: self._section)
    }
    var next: IndexPath {
        return IndexPath.for(item: self._item + 1, section: self._section)
    }
    var nextSection: IndexPath {
        return IndexPath.for(item: 0, section: self._section + 1)
    }

    var sectionCopy: IndexPath {
        return IndexPath.for(item: 0, section: self._section)
    }

    func with(item: Int) -> IndexPath {
        return IndexPath.for(item: item, section: self._section)
    }
    func with(section: Int) -> IndexPath {
        return IndexPath.for(item: self._item, section: section)
    }

    func adjustingItem(by: Int) -> IndexPath {
        return IndexPath.for(item: self._item + by, section: section)
    }
    func adjustingSection(by: Int) -> IndexPath {
        return IndexPath.for(item: self._item, section: section + by)
    }

    func isBetween(_ start: IndexPath, end: IndexPath) -> Bool {
        if self == start { return true }
        if self == end { return true }
        let _start = Swift.min(start, end)
        let _end = Swift.max(start, end)
        return (_start..<_end).contains(self)
    }
}
