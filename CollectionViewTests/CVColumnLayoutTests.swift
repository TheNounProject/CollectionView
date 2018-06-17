//
//  CVColumnLayoutTests.swift
//  CollectionViewTests
//
//  Created by Wes Byrne on 6/15/18.
//  Copyright © 2018 Noun Project. All rights reserved.
//

import XCTest
@testable import CollectionView

class CVColumnLayoutTests: XCTestCase {

    func testDataSource() {
        let test = LayoutTester(data: [10])
        XCTAssertEqual(test.layout.layoutAttributesForItem(at: IndexPath.zero)?.indexPath, IndexPath.zero)
        XCTAssertEqual(test.layout.layoutAttributesForItem(at: IndexPath.for(item: 1, section: 0))?.indexPath,
                       IndexPath.for(item: 1, section: 0))
        XCTAssertEqual(test.collectionView.indexPathsForVisibleItems.count, 10)
    }
    
    func testInvalidation() {
        let test = LayoutTester(data: [100])
        XCTAssertTrue(test.layout.shouldInvalidateLayout(forBoundsChange: test.frame.insetBy(dx: 1, dy: 0)))
        XCTAssertTrue(test.layout.shouldInvalidateLayout(forBoundsChange: test.frame.insetBy(dx: 0, dy: 1)))
        XCTAssertFalse(test.layout.shouldInvalidateLayout(forBoundsChange: test.frame))
        XCTAssertFalse(test.layout.shouldInvalidateLayout(forBoundsChange: test.frame.offsetBy(dx: 4, dy: 5)))
    }
    
    
    func testRectQuery() {
        let test = LayoutTester(sections: _prepareCounts.sections, itemsPerSection: _prepareCounts.items)
        
        let frame = test.frame
        let items = test.layout.indexPathsForItems(in: frame)
        XCTAssertEqual(items.count, 42)
    }
    
    private let _prepareCounts = (sections: 100, items:  300)
    func testTesterPerformance_bigSection() {
        self.measure {
            _ = LayoutTester(sections: 1, itemsPerSection: _prepareCounts.sections * _prepareCounts.items)
        }
    }
    
    func testPreparePerformance_bigSection() {
        let test = LayoutTester(sections: 1, itemsPerSection: _prepareCounts.sections * _prepareCounts.items)
        self.measure {
            test.layout.invalidate()
            test.layout.prepare()
        }
    }
    
    func testPreparePerformance_multipleSections() {
        let test = LayoutTester(sections: _prepareCounts.sections, itemsPerSection: _prepareCounts.items)
        self.measure {
            test.layout.invalidate()
            test.layout.prepare()
        }
    }
    
    func testPreparePerformance_varyingHeights() {
        let test = LayoutTester(sections: _prepareCounts.sections, itemsPerSection: _prepareCounts.items)
        test.heightProvider = {
            let idx = $0._section + $0._item
            return CGFloat(40 + ((idx % 10) * 5))
        }
        self.measure {
            test.layout.invalidate()
            test.layout.prepare()
        }
    }
    
    func testPreparePerformance_varyingRatios() {
        let test = LayoutTester(sections: _prepareCounts.sections, itemsPerSection: _prepareCounts.items)
        test.ratioProvider = {
            let idx = $0._section + $0._item
            let variance = CGFloat((idx % 10)/10)
            return CGSize(width: 1, height: 0.5 + variance)
        }
        self.measure {
            test.layout.invalidate()
            test.layout.prepare()
        }
    }
    
    
    // MARK: - Multi Section indexPathsForItems(in rect)
    /*-------------------------------------------------------------------------------*/
    
    private let _counts = (sections: 20, items:  2000)
    
    func testIndexPathsInRectPerformance_multiSection_top() {
        let test = LayoutTester(sections: _counts.sections, itemsPerSection: _counts.items)
        let frame = test.frame
        self.measure {
            _ = test.layout.indexPathsForItems(in: frame)
        }
    }
    
    func testIndexPathsInRectPerformance_multiSection_mid() {
        let test = LayoutTester(sections: _counts.sections, itemsPerSection: _counts.items)
        let frame = test.frame.offsetBy(dx: 0,
                                        dy: test.collectionView.contentSize.height/2)
        self.measure {
            _ = test.layout.indexPathsForItems(in: frame)
        }
    }
    
    func testIndexPathsInRectPerformance_multiSection_bottom() {
        let test = LayoutTester(sections: _counts.sections, itemsPerSection: _counts.items)
        let frame = test.frame.offsetBy(dx: 0,
                                        dy: test.collectionView.contentSize.height - test.frame.size.height)
        self.measure {
            _ = test.layout.indexPathsForItems(in: frame)
        }
    }
    
    // MARK: - Single Section indexPathsForItems(in rect)
    /*-------------------------------------------------------------------------------*/
    func testIndexPathsInRectPerformance_bigSection_top() {
        let test = LayoutTester(sections: 1, itemsPerSection: _counts.items * _counts.sections)
        let frame = test.frame
        self.measure {
            _ = test.layout.indexPathsForItems(in: frame)
        }
    }
    
    func testIndexPathsInRectPerformance_bigSection_mid() {
        let test = LayoutTester(sections: 1, itemsPerSection: _counts.items * _counts.sections)
        let frame = test.frame.offsetBy(dx: 0,
                                        dy: test.collectionView.contentSize.height/2)
        self.measure {
            _ = test.layout.indexPathsForItems(in: frame)
        }
    }
    
    func testIndexPathsInRectPerformance_bigSection_bottom() {
        let test = LayoutTester(sections: 1, itemsPerSection: _counts.items * _counts.sections)
        let frame = test.frame.offsetBy(dx: 0,
                                        dy: test.collectionView.contentSize.height - test.frame.size.height)
        self.measure {
            _ = test.layout.indexPathsForItems(in: frame)
        }
    }
    
    
    // MARK: - Querying Layout Attributes
    /*-------------------------------------------------------------------------------*/
    func testAttributesInRectPerformance_big_top() {
        let test = LayoutTester(sections: 1, itemsPerSection: _counts.items * _counts.sections)
        let frame = test.frame
        self.measure {
            _ = test.layout.layoutAttributesForItems(in: frame)
        }
    }
    
}


fileprivate class LayoutTester : CollectionViewDataSource, CollectionViewDelegateColumnLayout {
    
    
    let collectionView = CollectionView(frame: NSRect(x: 0, y: 0, width: 1000, height: 800))
    var frame : CGRect {
        set { self.collectionView.frame = newValue }
        get { return self.collectionView.frame }
    }
    let layout = CollectionViewColumnLayout()
    var data : [Int]
    
    
    let headerHeight : CGFloat = 0
    var defaultHeight : CGFloat = 100
    var heightProvider : ((IndexPath) -> CGFloat)?
    var ratioProvider : ((IndexPath) -> CGSize)?
    
    init(data: [Int] = [10]) {
        self.data = data
        layout.columnCount = 3
        collectionView.dataSource = self
        collectionView.collectionViewLayout = layout
        collectionView.register(class: CollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.register(class: CollectionReusableView.self, forSupplementaryViewOfKind: CollectionViewLayoutElementKind.SectionHeader, withReuseIdentifier: "Header")
        collectionView.reloadData()
    }
    convenience init(sections: Int, itemsPerSection items: Int) {
        self.init(data: [Int](repeating: items, count: sections))
    }
    
    
    // CollectionView Data Source
    func numberOfSections(in collectionView: CollectionView) -> Int {
        return data.count
    }
    func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int {
        return data[section]
    }
    func collectionView(_ collectionView: CollectionView, cellForItemAt indexPath: IndexPath) -> CollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
    }
    func collectionView(_ collectionView: CollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> CollectionReusableView {
        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath)
    }
    
    
    // Layout Delegate
    
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, heightForHeaderInSection section: Int) -> CGFloat {
        return self.headerHeight
    }
    
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, heightForItemAt indexPath: IndexPath) -> CGFloat {
        return self.heightProvider?(indexPath) ?? self.defaultHeight
    }
    
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, aspectRatioForItemAt indexPath: IndexPath) -> CGSize {
        return self.ratioProvider?(indexPath) ?? CGSize.zero
    }
}
