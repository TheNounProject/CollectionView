//
//  CBCollectionView.swift
//  Lingo
//
//  Created by Wesley Byrne on 1/27/16.
//  Copyright © 2016 The Noun Project. All rights reserved.
//

import Foundation

struct SupplementaryViewIdentifier: Hashable {
    let indexPath: NSIndexPath?
    let kind: String!
    let reuseIdentifier : String!
    
    var hashValue: Int {
        let section = indexPath == nil ? "*" : "\(indexPath!._section)"
        return "\(section)/\(self.kind)/\(self.reuseIdentifier)".hashValue
    }
    
    init(kind: String, reuseIdentifier: String, indexPath: NSIndexPath? = nil) {
        self.kind = kind
        self.reuseIdentifier = reuseIdentifier
        self.indexPath = indexPath
    }
}

func ==(lhs: SupplementaryViewIdentifier, rhs: SupplementaryViewIdentifier) -> Bool {
    return lhs.indexPath == rhs.indexPath && lhs.kind == rhs.kind && lhs.reuseIdentifier == rhs.reuseIdentifier
}


public class CBScrollView : NSScrollView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.swapClipView()
    }
    public override var flipped : Bool { return true }
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.swapClipView()
    }
    public var clipView : CBClipView? {
        return self.contentView as? CBClipView
    }
    
    func swapClipView() {
        if self.contentView.isKindOfClass(CBClipView) { return }
        self.wantsLayer = true
        let docView = self.documentView
        let clipView = CBClipView(frame: self.contentView.frame)
        self.contentView = clipView
        self.documentView = docView
    }
}

class FloatingSupplementaryView : NSView {
    override var flipped : Bool { return true }
    internal override func hitTest(aPoint: NSPoint) -> NSView? {
        for view in self.subviews {
            if view.frame.contains(aPoint){
                return super.hitTest(aPoint)
            }
        }
        return nil
    }
}


public class CBCollectionView : CBScrollView, NSDraggingSource {
    
    private var _reusableCells : [String:Set<CBCollectionViewCell>] = [:]
//    private var _visibleCellIndex : [NSIndexPath:CBCollectionViewCell] = [:]
    private var _cellClasses : [String:CBCollectionViewCell.Type] = [:]
    private var _cellNibs : [String:NSNib] = [:]
    
    private var _reusableSupplementaryView : [SupplementaryViewIdentifier:[CBCollectionReusableView]] = [:]
//    private var _visibleSupplementaryViewIndex : [SupplementaryViewIdentifier:CBCollectionReusableView] = [:]
    private var _supplementaryViewClasses : [SupplementaryViewIdentifier:CBCollectionReusableView.Type] = [:]
    private var _supplementaryViewNibs : [SupplementaryViewIdentifier:NSNib] = [:]
    
//    internal var collectionViewDocumentView : CBCollectionViewDocumentView! { return self.documentView as! CBCollectionViewDocumentView }
    public var contentDocumentView : CBCollectionViewDocumentView! { return self.documentView as! CBCollectionViewDocumentView }
    public var contentVisibleRect : CGRect { return self.documentVisibleRect }
    
    
    public var contentOffset : CGPoint {
        get{ return self.contentVisibleRect.origin }
        set {
            self.clipView?.scrollToPoint(newValue)
            self.reflectScrolledClipView(self.clipView!)
            self.contentDocumentView.prepareRect(self.contentVisibleRect)
        }
    }
    
    let _floatingSupplementaryView = FloatingSupplementaryView(frame: NSZeroRect)
    
    // MARK: - Data Source & Delegate
    public weak var delegate : CBCollectionViewDelegate?
    private var interactionDelegate : CBCollectionViewInteractionDelegate? {
        return self.delegate as? CBCollectionViewInteractionDelegate
    }
    public weak var dataSource : CBCollectionViewDataSource?
    
    // MARK: - Selection options
    public var allowsSelection: Bool = true
    public var multiSelect: Bool = false
    public var allowsMultipleSelection: Bool = true
    
    // MARK: - Layout
    public var collectionViewLayout : CBCollectionViewLayout! = CBCollectionViewLayout() {
        didSet {
            collectionViewLayout.collectionView = self
            self.hasHorizontalScroller = collectionViewLayout.scrollDirection == .Horizontal
            self.hasVerticalScroller = collectionViewLayout.scrollDirection == .Vertical
        }}
    
    public init() {
        super.init(frame: NSZeroRect)
        self.setup()
       
    }
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    func setup() {
        collectionViewLayout.collectionView = self
        self.info = CBCollectionViewInfo(collectionView: self)
        self.wantsLayer = true
        self.documentView = CBCollectionViewDocumentView()
//        self.contentDocumentView.wantsLayer = true
        self.hasVerticalScroller = true
//        self.scrollsDynamically = true
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CBCollectionView.didScroll(_:)), name: NSScrollViewDidLiveScrollNotification, object: self)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CBCollectionView.didEndScroll(_:)), name: NSScrollViewDidEndLiveScrollNotification, object: self)
        
        self.addSubview(_floatingSupplementaryView, positioned: .Above, relativeTo: self.clipView!)
        self._floatingSupplementaryView.wantsLayer = true
        _floatingSupplementaryView.frame = self.bounds
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        self._reusableCells.removeAll()
        self._reusableSupplementaryView.removeAll()
        self.contentDocumentView.preparedCellIndex.removeAll()
        self.contentDocumentView.preparedSupplementaryViewIndex.removeAll()
        for view in self.contentDocumentView.subviews {
            view.removeFromSuperview()
        }
    }

    
    // MARK: - Registering reusable cells
    public func registerClass(cellClass: CBCollectionViewCell.Type!, forCellWithReuseIdentifier identifier: String!) {
        assert(cellClass.isSubclassOfClass(CBCollectionViewCell), "CBCollectionView: Registered cells views must be subclasses of CBCollectionViewCell")
        assert(!identifier.isEmpty, "CBCollectionView: Reuse identifier cannot be an empty or blank string")
        self._cellClasses[identifier] = cellClass
        self._cellNibs[identifier] = nil
    }
    public func registerNib(nib: NSNib!, forCellWithReuseIdentifier identifier: String!) {
        assert(!identifier.isEmpty, "CBCollectionView: Reuse identifier cannot be an empty or blank string")
        self._cellClasses[identifier] = nil
        self._cellNibs[identifier] = nib
    }
    public func registerClass(viewClass: CBCollectionReusableView.Type!, forSupplementaryViewOfKind kind: String!, withReuseIdentifier identifier: String!) {
        assert(viewClass.isSubclassOfClass(CBCollectionReusableView), "CBCollectionView: Registered supplementary views must be subclasses of CBCollectionReusableview")
        assert(!identifier.isEmpty, "CBCollectionView: Reuse identifier cannot be an empty or blank string")
        let id = SupplementaryViewIdentifier(kind: kind, reuseIdentifier: identifier)
        self._supplementaryViewClasses[id] = viewClass
        self._supplementaryViewNibs[id] = nil
    }
    public func registerNib(nib: NSNib, forSupplementaryViewOfKind kind: String!, withReuseIdentifier identifier: String!) {
        assert(!identifier.isEmpty, "CBCollectionView: Reuse identifier cannot be an empty or blank string")
        let id = SupplementaryViewIdentifier(kind: kind, reuseIdentifier: identifier)
        self._supplementaryViewClasses[id] = nil
        self._supplementaryViewNibs[id] = nib
    }
    
    internal func _allSupplementaryViewIdentifiers() -> [SupplementaryViewIdentifier] {
        var all = Array(self._supplementaryViewClasses.keys)
        all.appendContentsOf(Array(self._supplementaryViewNibs.keys))
        return all
    }
    
    private func _firstObjectOfClass(aClass: AnyClass, inNib: NSNib) -> NSView? {
        var foundObject: AnyObject? = nil
        var topLevelObjects :NSArray?
        if inNib.instantiateWithOwner(self, topLevelObjects: &topLevelObjects) {
            let index = topLevelObjects!.indexOfObjectPassingTest({ (obj, idx, stop) -> Bool in
                if obj.isKindOfClass(aClass) {
                    stop.memory = true
                    return true
                }
                return false
            })
            if index != NSNotFound {
                foundObject = topLevelObjects![index]
            }
        }
        assert(foundObject != nil, "CBCollectionView: Could not find view of type \(aClass) in nib. Make sure the opt level object in the nib is of this type.")
        return foundObject as? NSView
    }
    
    
    
    
    // MARK: - Dequeing reusable cells
    public func dequeueReusableCellWithReuseIdentifier(identifier: String, forIndexPath indexPath: NSIndexPath) -> CBCollectionViewCell {
        
        var cell = self._reusableCells[identifier]?.first
        if cell == nil {
            if let nib = self._cellNibs[identifier] {
                cell = _firstObjectOfClass(CBCollectionViewCell.self, inNib: nib) as? CBCollectionViewCell
            }
            else if let aClass = self._cellClasses[identifier] {
                cell = aClass.init()
            }
            assert(cell != nil, "CBCollectionView: No cell could be dequed with identifier '\(identifier) for item: \(indexPath._item) in section \(indexPath._section)'. Make sure you have registered your cell class or nib for that identifier.")
        }
        else {
            self._reusableCells[identifier]?.removeFirst()
        }
        cell?.reuseIdentifier = identifier
        cell?.prepareForReuse()
        return cell!
    }
    public func dequeueReusableSupplementaryViewOfKind(elementKind: String, withReuseIdentifier identifier: String, forIndexPath indexPath: NSIndexPath) -> CBCollectionReusableView {
        let id = SupplementaryViewIdentifier(kind: elementKind, reuseIdentifier: identifier)
        var view = self._reusableSupplementaryView[id]?.first
        if view == nil {
            if let nib = self._supplementaryViewNibs[id] {
                view = _firstObjectOfClass(CBCollectionReusableView.self, inNib: nib) as? CBCollectionReusableView
            }
            else if let aClass = self._supplementaryViewClasses[id] {
                view = aClass.init()
            }
            assert(view != nil, "CBCollectionView: No view could be dequed for supplementary view of kind \(elementKind) with identifier '\(identifier) in section \(indexPath._section)'. Make sure you have registered your view class or nib for that identifier.")
        }
        else {
            self._reusableSupplementaryView[id]?.removeFirst()
        }
        view?.reuseIdentifier = identifier
        view?.prepareForReuse()
        return view!
    }
    
    func enqueueCellForReuse(item: CBCollectionViewCell) {
//        item.removeFromSuperviewWithoutNeedingDisplay()
        item.hidden = true
        guard let id = item.reuseIdentifier else { return }
        if self._reusableCells[id] == nil {
            self._reusableCells[id] = []
        }
        self._reusableCells[id]?.insert(item)
    }
    
    func enqueueSupplementaryViewForReuse(item: CBCollectionReusableView, withIdentifier: SupplementaryViewIdentifier) {
        let newID = SupplementaryViewIdentifier(kind: withIdentifier.kind, reuseIdentifier: withIdentifier.reuseIdentifier)
        if self._reusableSupplementaryView[newID] == nil {
            self._reusableSupplementaryView[newID] = []
        }
        self._reusableSupplementaryView[newID]?.append(item)
    }
    
    
    // MARK: - Data
    private var info : CBCollectionViewInfo!
    public func numberOfSections() -> Int { return self.info.numberOfSections }
    public func numberOfItemsInSection(section: Int) -> Int { return self.info.numberOfItemsInSection(section) }
    public func frameForSectionAtIndexPath(indexPath: NSIndexPath) -> CGRect? {
        return self.info.sections[indexPath._section]?.frame
    }
    
    
    // discard the dataSource and delegate data and requery as necessary
    public func reloadData() {
        self.contentDocumentView.reset()
        self.info.recalculate()
        contentDocumentView.frame.size = self.info.contentSize
        self.contentDocumentView.prepareRect(self.contentVisibleRect)
    }
    
    public func relayout(animated: Bool, scrollToTop: Bool = true) {
        
//        return
        let firstIP = indexPathForFirstVisibleItem()
        var refFrame : CGRect = CGRectZero
        var refVisibleFrame : CGRect = CGRectZero
        if firstIP != nil, let cell = cellForItemAtIndexPath(firstIP!) {
            refFrame = cell.frame
            refVisibleFrame = self.convertRect(cell.frame, fromView: self.contentDocumentView)
        }
        self.info.recalculate()
        let nContentSize = self.info.contentSize
        contentDocumentView.frame.size = nContentSize
        
        if firstIP != nil, let attrs = self.collectionViewLayout.layoutAttributesForItemAtIndexPath(firstIP!) {
            var nRef = self.convertRect(attrs.frame, fromView: self.contentDocumentView)
            nRef.origin.y -= refVisibleFrame.origin.y
            nRef = self.convertRect(nRef, toView: self.contentDocumentView)
            self.scrollToRect(nRef, atPosition: .Top, animated: false)
        }
        
        self.contentDocumentView.prepareRect(self.contentVisibleRect, force: true)
        
        
        return
        
        if animated {
            NSAnimationContext.runAnimationGroup({ (context) -> Void in
                context.duration = 0.5
                context.allowsImplicitAnimation = true
                self.contentDocumentView.frame.size = nContentSize
                }) { () -> Void in
                    
            }
        }
        else {
            contentDocumentView.frame.size = nContentSize
        }
        
        let nFirstIP = self.indexPathForFirstVisibleItem()
        if nFirstIP != firstIP, let ip = firstIP, let rect = self.collectionViewLayout.scrollRectForItemAtIndexPath(ip, atPosition: CBCollectionViewScrollPosition.Top) {
            self.scrollToRect(rect, atPosition: .Top, animated: false)
        }
        self.contentDocumentView.prepareRect(self.contentVisibleRect)
    }
    
    func didScroll(notification: NSNotification) {
        let rect = CGRectInset(self.contentVisibleRect, 0, -100)
        self.contentDocumentView.prepareRect(rect)
    }
    
    func didEndScroll(notification: NSNotification) {
//        let rect = CGRectInset(self.contentVisibleRect, 0, -self.frame.size.height)
//        self.contentDocumentView.prepareRect(CGRectInset(self.contentVisibleRect, 0, -self.contentVisibleRect.size.height/2))
    }

    public func indexPathForFirstVisibleItem() -> NSIndexPath? {
        for sectionIndex in 0...self.info.numberOfSections - 1 {
            guard let section = self.info.sections[sectionIndex] else { continue }
            if CGRectIsEmpty(section.frame) || !CGRectIntersectsRect(section.frame, self.contentVisibleRect) { continue }
            for item in 0...section.numberOfItems - 1 {
                let indexPath = NSIndexPath._indexPathForItem(item, inSection: sectionIndex)
                if let attributes = self.collectionViewLayout.layoutAttributesForItemAtIndexPath(indexPath) {
                    if (CGRectIntersectsRect(attributes.frame, self.contentVisibleRect)) {
                        return indexPath
                    }
                }
            }
        }
        return nil
    }
    
    var _topIP: NSIndexPath?
    public override func viewWillStartLiveResize() {
        _topIP = indexPathForFirstVisibleItem()
    }
    
    public override func viewDidEndLiveResize() {
        _topIP = nil
    }
    
    public override func layout() {
        _floatingSupplementaryView.frame = self.bounds
        super.layout()
        
        if self.collectionViewLayout.shouldInvalidateLayoutForBoundsChange(self.documentVisibleRect) {
            self.info.recalculate()
            contentDocumentView.frame.size = self.info.contentSize
            
            if let ip = _topIP, let rect = self.collectionViewLayout.scrollRectForItemAtIndexPath(ip, atPosition: CBCollectionViewScrollPosition.Top) {
                self.scrollToRect(rect, atPosition: .Top, animated: false)
            }
            self.contentDocumentView.preparedRect = CGRectZero
            self.contentDocumentView.prepareRect(self.contentVisibleRect, force: true)
        }
        
    }
    
    public func reloadItemAtIndexPath(indexPath: NSIndexPath) {
        guard let cell = self.cellForItemAtIndexPath(indexPath) else {
            debugPrint("Not reloading cell because it is not visible")
            return
        }
        guard let newCell = self.dataSource?.collectionView(self, cellForItemAtIndexPath: indexPath) else {
            debugPrint("For some reason collection view tried to load cells without a data source")
            return
        }
        cell.hidden = true
        cell._indexPath = nil
        self.enqueueCellForReuse(cell)
        
        newCell._indexPath = indexPath
        let attrs = self.collectionViewLayout.layoutAttributesForItemAtIndexPath(indexPath)
        if attrs != nil {
            newCell.applyLayoutAttributes(attrs!)
        }
        if newCell.superview == nil {
            self.contentDocumentView.addSubview(newCell)
        }
        newCell.selected = self._selectedIndexPaths.contains(indexPath)
        self.contentDocumentView.preparedCellIndex[indexPath] = newCell
    }
    
    
    func _identifiersForSupplementaryViewsInRect(rect: CGRect) -> Set<SupplementaryViewIdentifier> {
        var visibleIdentifiers = Set<SupplementaryViewIdentifier>()
        if CGRectEqualToRect(rect, CGRectZero) { return [] }
        for sectionInfo in self.info.sections {
            if !CGRectIntersectsRect(sectionInfo.1.frame, rect) { continue }
            for identifier in self._allSupplementaryViewIdentifiers() {
                let ip = NSIndexPath._indexPathForItem(0, inSection: sectionInfo.1.section)
                if let attrs = self.collectionViewLayout.layoutAttributesForSupplementaryViewOfKind(identifier.kind, atIndexPath: ip) {
                    if CGRectIntersectsRect(attrs.frame, rect) {
                        visibleIdentifiers.insert(SupplementaryViewIdentifier(kind: identifier.kind, reuseIdentifier: identifier.reuseIdentifier, indexPath: ip))
                    }
                }
            }
        }
        return visibleIdentifiers
    }
    
    
    // MARK: - Selections
    // Select
    private var _firstSelection : NSIndexPath?
    private var _lastSelection : NSIndexPath?
    var _selectedIndexPaths = Set<NSIndexPath>()
    
    public func indexPathsForSelectedItems() -> Set<NSIndexPath> { return _selectedIndexPaths }
    public func sortedIndexPathsForSelectedItems() -> [NSIndexPath] {
        return indexPathsForSelectedItems().sort { (ip1, ip2) -> Bool in
            let before =  ip1._section < ip2._section || (ip1._section == ip2._section && ip1._item < ip2._item)
            return before
        }
    }
    
    public func itemAtIndexPathIsSelected(indexPath: NSIndexPath) -> Bool {
        return _selectedIndexPaths.contains(indexPath)
    }
    public func itemAtIndexPathIsVisible(indexPath: NSIndexPath) -> Bool {
        if let frame = self.contentDocumentView.preparedCellIndex[indexPath]?.frame {
            return self.contentVisibleRect.intersects(frame)
        }
        return false
    }
    
    public func selectAllItems(animated: Bool = true) {
        self.selectItemsAtIndexPaths(Array(self.contentDocumentView.preparedCellIndex.keys), animated: animated)
        _selectedIndexPaths = Set(self.allIndexPaths())
    }
    public func selectItemsAtIndexPaths(indexPaths: [NSIndexPath], animated: Bool) {
        for ip in indexPaths { self.selectItemAtIndexPath(ip, animated: animated, scrollPosition: .None) }
    }
    public func selectItemAtIndexPath(indexPath: NSIndexPath?, animated: Bool, scrollPosition: CBCollectionViewScrollPosition = .None) {
        self._selectItemAtIndexPath(indexPath, animated: animated, scrollPosition: scrollPosition, withEvent: nil)
    }
    
    private func _selectItemAtIndexPath(indexPath: NSIndexPath?, animated: Bool, scrollPosition: CBCollectionViewScrollPosition = .None, withEvent event: NSEvent?) {
        guard let indexPath = indexPath else {
            self.deselectAllItems(animated)
            return
        }
        
        if indexPath._section >= self.info.numberOfSections || indexPath._item >= self.info.numberOfItemsInSection(indexPath._section) { return }
        
        if !self.allowsSelection { return }
        if let shouldSelect = self.delegate?.collectionView?(self, shouldSelectItemAtIndexPath: indexPath, withEvent: event) where !shouldSelect { return }
        
        if self.allowsMultipleSelection == false {
            self.deselectAllItems()
        }
        
        self.cellForItemAtIndexPath(indexPath)?.setSelected(true, animated: animated)
        self._selectedIndexPaths.insert(indexPath)
        if self._selectedIndexPaths.count == 1 {
            self._firstSelection = indexPath
        }
        self._lastSelection = indexPath
        self.delegate?.collectionView?(self, didSelectItemAtIndexPath: indexPath)
        
        if scrollPosition != .None {
            self.scrollToItemAtIndexPath(indexPath, atScrollPosition: scrollPosition, animated: animated)
        }
    }
    
    // Deselect
    public func deselectItemsAtIndexPaths(indexPaths: [NSIndexPath], animated: Bool) {
        for ip in indexPaths { self.deselectItemAtIndexPath(ip, animated: animated) }
    }
    public func deselectAllItems(animated: Bool = false) {
        self._lastSelection = nil
        self._selectedIndexPaths.removeAll()
        for ip in Array(self.contentDocumentView.preparedCellIndex.keys) { self.deselectItemAtIndexPath(ip, animated: animated) }
    }
    public func deselectItemAtIndexPath(indexPath: NSIndexPath, animated: Bool) {
        if let deselect = self.delegate?.collectionView?(self, shouldDeselectItemAtIndexPath: indexPath) where !deselect { return }
        contentDocumentView.preparedCellIndex[indexPath]?.setSelected(false, animated: true)
        self._selectedIndexPaths.remove(indexPath)
        self.delegate?.collectionView?(self, didDeselectItemAtIndexPath: indexPath)
    }
    
    
    // Multiple selections
    func selectItemAtIndexPath(indexPath: NSIndexPath,
        atScrollPosition: CBCollectionViewScrollPosition,
        animated: Bool,
        selectionType: CBCollectionViewSelectionType) {
        
            var indexesToSelect = Set<NSIndexPath>()
            
            if selectionType == .Single {
                indexesToSelect.insert(indexPath)
            }
            else if selectionType == .Multiple {
                indexesToSelect.unionInPlace(self._selectedIndexPaths)
                if indexesToSelect.contains(indexPath) {
                    indexesToSelect.remove(indexPath)
                }
                else {
                    indexesToSelect.insert(indexPath)
                }
            }
            else {
                let firstIndex =  self._firstSelection
                if let index = firstIndex {
                    let order = index.compare(indexPath)
                    var nextIndex : NSIndexPath? = firstIndex
                    
                    while (nextIndex != nil && nextIndex! != indexPath) {
                        indexesToSelect.insert(nextIndex!)
                        if order == NSComparisonResult.OrderedAscending {
                            nextIndex = self.indexPathForSelectableIndexPathAfter(nextIndex!)
                        }
                        else if order == .OrderedDescending {
                            nextIndex = self.indexPathForSelectableIndexPathBefore(nextIndex!)
                        }
                    }
                }
                else {
                    indexesToSelect.insert(NSIndexPath.Zero)
                }
                indexesToSelect.insert(indexPath)
            }
            var deselectIndexes = self._selectedIndexPaths
            deselectIndexes.removeAllInSet(indexesToSelect)
            
            self.deselectItemsAtIndexPaths(Array(deselectIndexes), animated: true)
            for ip in indexesToSelect {
                self._selectItemAtIndexPath(ip, animated: true, scrollPosition: .None, withEvent: nil)
            }
            self.scrollToItemAtIndexPath(indexPath, atScrollPosition: atScrollPosition, animated: animated)
            self._lastSelection = indexPath
    }
    
    
    func validateIndexPath(indexPath: NSIndexPath) -> Bool {
        if self.info.sections[indexPath._section] == nil { return false }
        return indexPath._section < self.info.numberOfSections && indexPath._item < self.info.sections[indexPath._section]!.numberOfItems
    }
    
    func indexPathForSelectableIndexPathBefore(indexPath: NSIndexPath) -> NSIndexPath?{
        if (indexPath._item - 1 >= 0) {
            return NSIndexPath._indexPathForItem(indexPath._item - 1, inSection: indexPath._section)
        }
        else if indexPath._section - 1 >= 0 && self.info.numberOfSections > 0 {
            let numberOfItems = self.info.sections[indexPath._section - 1]!.numberOfItems;
            let newIndexPath = NSIndexPath._indexPathForItem(numberOfItems - 1, inSection: indexPath._section - 1)
            if self.validateIndexPath(newIndexPath) { return newIndexPath }
        }
        return nil;
    }
    
    func indexPathForSelectableIndexPathAfter(indexPath: NSIndexPath) -> NSIndexPath? {
        if (indexPath._item + 1 >= self.info.sections[indexPath._section]?.numberOfItems) {
            // Jump up to the next section
            let newIndexPath = NSIndexPath._indexPathForItem(0, inSection: indexPath._section+1)
            if self.validateIndexPath(newIndexPath) { return newIndexPath; }
        }
        else {
            return NSIndexPath._indexPathForItem(indexPath._item + 1, inSection: indexPath._section)
        }
        return nil;
    }
    
    
    // MARK: - Layout Information
    public func frameForSection(section: Int) -> CGRect? {
        return self.info.sections[section]?.frame
    }
    public func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> CBCollectionViewLayoutAttributes? {
        return self.collectionViewLayout.layoutAttributesForItemAtIndexPath(indexPath)
    }
    public func layoutAttributesForSupplementaryElementOfKind(kind: String, atIndexPath indexPath: NSIndexPath) -> CBCollectionViewLayoutAttributes?  {
        return self.collectionViewLayout.layoutAttributesForSupplementaryViewOfKind(kind, atIndexPath: indexPath)
    }
    
    // MARK: - Retrieve Cells & Indexes
    internal func allIndexPaths() -> Set<NSIndexPath> { return self.info.allIndexPaths }
    public func indexPathForCell(cell: CBCollectionViewCell) -> NSIndexPath?  { return cell._indexPath }
    public func indexPathForSupplementaryView(view: CBCollectionReusableView) -> NSIndexPath? { return view._indexPath }
    
    public func indexPathForSectionAtPoint(point: CGPoint) -> NSIndexPath? {
        for sectionIndex in 0..<self.info.numberOfSections {
            guard let sectionInfo = self.info.sections[sectionIndex] else { continue }
            if CGRectContainsPoint(sectionInfo.frame, point) {
                return NSIndexPath._indexPathForItem(0, inSection: sectionIndex)
            }
        }
        return nil
    }
    
    public func indexPathForItemAtPoint(point: CGPoint) -> NSIndexPath?  {
        if self.info.numberOfSections == 0 { return nil }
        for sectionIndex in 0..<self.info.numberOfSections {
            guard let sectionInfo = self.info.sections[sectionIndex] else { continue }
            if !CGRectContainsPoint(sectionInfo.frame, point) || sectionInfo.numberOfItems == 0 { continue }
            
            for itemIndex in 0...sectionInfo.numberOfItems - 1 {
                let indexPath = NSIndexPath._indexPathForItem(itemIndex, inSection: sectionIndex)
                if let attributes = self.collectionViewLayout.layoutAttributesForItemAtIndexPath(indexPath) {
                    if CGRectContainsPoint(attributes.frame, point) {
                        return indexPath;
                    }
                }
            }
        }
        return nil;
    }
    
    
    public func indexPathsForItemsInRect(rect: CGRect) -> Set<NSIndexPath> {
        if let providedIndexPaths = self.collectionViewLayout.indexPathsForItemsInRect(rect) { return providedIndexPaths }
        if CGRectEqualToRect(rect, CGRectZero) || self.info.numberOfSections == 0 { return [] }
        var indexPaths = Set<NSIndexPath>()
        for sectionIndex in 0...self.info.numberOfSections - 1 {
            guard let section = self.info.sections[sectionIndex] else { continue }
            if CGRectIsEmpty(section.frame) || !CGRectIntersectsRect(section.frame, rect) { continue }
            for item in 0...section.numberOfItems - 1 {
                let indexPath = NSIndexPath._indexPathForItem(item, inSection: sectionIndex)
                if let attributes = self.collectionViewLayout.layoutAttributesForItemAtIndexPath(indexPath) {
                    if (CGRectIntersectsRect(attributes.frame, rect)) {
                        indexPaths.insert(indexPath)
                    }
                }
            }
        }
        return indexPaths
    }
    
    public func cellForItemAtIndexPath(indexPath: NSIndexPath) -> CBCollectionViewCell?  { return self.contentDocumentView.preparedCellIndex[indexPath] }
    
    public func viewForSupplementaryViewOfKind(kind: String, withReuseIdentifier: String, atIndexPath: NSIndexPath) -> CBCollectionReusableView? {
        let id = SupplementaryViewIdentifier(kind: kind, reuseIdentifier: withReuseIdentifier, indexPath: atIndexPath)
        return self.contentDocumentView.preparedSupplementaryViewIndex[id]
    }
    
    
    public func visibleCells() -> [CBCollectionViewCell]  { return Array( self.contentDocumentView.preparedCellIndex.values) }
    public func indexPathsForVisibleItems() -> [NSIndexPath]  { return Array(self.contentDocumentView.preparedCellIndex.keys) }
    
    
    func rectForItemAtIndexPath(indexPath: NSIndexPath) -> CGRect? {
        if indexPath._section < self.info.numberOfSections {
            let attributes = self.collectionViewLayout.layoutAttributesForItemAtIndexPath(indexPath);
            return attributes?.frame;
        }
        return nil
    }
    
    // MARK: - Scrolling
    
    
    public func scrollToItemAtIndexPath(indexPath: NSIndexPath, atScrollPosition scrollPosition: CBCollectionViewScrollPosition, animated: Bool) {
        if self.info.numberOfItemsInSection(indexPath._section) < indexPath._item { return }
        if let shouldScroll = self.delegate?.collectionView?(self, shouldScrollToItemAtIndexPath: indexPath) where shouldScroll != true { return }
        
        guard let rect = self.collectionViewLayout.scrollRectForItemAtIndexPath(indexPath, atPosition: scrollPosition) ?? self.rectForItemAtIndexPath(indexPath) else { return }
        
        self.scrollToRect(rect, atPosition: scrollPosition, animated: animated)
        self.delegate?.collectionView?(self, didScrollToItemAtIndexPath: indexPath)
    }
    
    public func scrollToRect(aRect: CGRect, atPosition: CBCollectionViewScrollPosition, animated: Bool) {
        var rect = aRect
        let visibleRect = self.documentVisibleRect
        switch atPosition {
        case .Top:
            // make the top of our rect flush with the top of the visible bounds
            rect.size.height = CGRectGetHeight(visibleRect) - contentInsets.top;
            rect.origin.y = aRect.origin.y - contentInsets.top;
            break;
        case .Centered:
            // TODO
            rect.size.height = self.bounds.size.height;
            rect.origin.y += (CGRectGetHeight(visibleRect) / 2.0) - CGRectGetHeight(rect);
            break;
        case .Bottom:
            // make the bottom of our rect flush with the bottom of the visible bounds
            rect.size.height = CGRectGetHeight(visibleRect);
            rect.origin.y -= CGRectGetHeight(visibleRect) - contentInsets.top;
            break;
        case .None:
            // no scroll needed
            return;
        case .Nearest:
            
            let vRect = self.contentDocumentView.visibleRect
            if rect.origin.y < vRect.origin.y {
                rect.origin.y -= self.contentInsets.top
                
//                if self.collectionViewLayout.pinHeadersToTop, let attrs = collectionViewLayout.layoutAttributesForSupplementaryViewOfKind(CBCollectionViewLayoutElementKind.SectionHeader, atIndexPath: indexPath) {
//                    rect.origin.y -= 36
//                }
            }
            // We just pass the cell's frame onto the scroll view. It calculates this for us.
            break;
        }
        
        self.contentDocumentView.prepareRect(CGRectUnion(rect, self.contentVisibleRect), force: false)
        self.clipView?.scrollRectToVisible(rect, animated: animated, completion: { (fin) -> Void in
//            self._layoutItems(false, forceAll: false)
//            self._layoutSupplementaryViews(false, forceAll: false)
        })
//        self.clipView!.scrollRectToVisible(rect, animated: animated, completion: )

    }
    
    var mouseDownIP: NSIndexPath?
    public override func mouseDown(theEvent: NSEvent) {
        
//        if theEvent.clickCount == 2 { return }
        
        self.mouseDownIP = nil
        if let view = self.window?.contentView?.hitTest(theEvent.locationInWindow) where view.isDescendantOf(self) == false {
            return
        }
        
        // super.mouseDown(theEvent) DONT DO THIS, it will consume the event and mouse up is not called
        self.window?.makeFirstResponder(self)
        let point = self.contentView.convertPoint(theEvent.locationInWindow, fromView: nil)
        self.mouseDownIP = self.indexPathForItemAtPoint(point)
        self.delegate?.collectionView?(self, mouseDownInItemAtIndexPath: self.mouseDownIP, withEvent: theEvent)
    }
    
    public override func mouseUp(theEvent: NSEvent) {
        super.mouseUp(theEvent)
        
        if let view = self.window?.contentView?.hitTest(theEvent.locationInWindow) where view.isDescendantOf(self) == false {
            return
        }
        
        let point = self.contentView.convertPoint(theEvent.locationInWindow, fromView: nil)
        let indexPath = self.indexPathForItemAtPoint(point)
        
        if mouseDownIP == nil {
            self.deselectAllItems()
        }
        
        self.delegate?.collectionView?(self, mouseUpInItemAtIndexPath: indexPath, withEvent: theEvent)
        guard let ip = indexPath where ip == mouseDownIP else { return }
        
        if theEvent.clickCount == 2 {
            self.delegate?.collectionView?(self, didDoubleClickItemAtIndexPath: ip, withEvent: theEvent)
            return
        }
        else if theEvent.modifierFlags.contains(NSEventModifierFlags.ControlKeyMask) {
            self.rightMouseDown(theEvent)
            self.deselectAllItems()
            self.selectItemAtIndexPath(ip, animated: false)
            return
        }
        else if allowsMultipleSelection && theEvent.modifierFlags.contains(NSEventModifierFlags.ShiftKeyMask) {
            self.selectItemAtIndexPath(ip, atScrollPosition: .Nearest, animated: true, selectionType: .Extending)
            return
        }
        else if allowsMultipleSelection && theEvent.modifierFlags.contains(NSEventModifierFlags.CommandKeyMask) {
            if self._selectedIndexPaths.contains(ip) {
                if self._selectedIndexPaths.count == 1 { return }
                self.deselectItemAtIndexPath(ip, animated: true)
            }
            else {
                self.selectItemAtIndexPath(ip, animated: true)
            }
            return
        }
        
        if !self.multiSelect {
            self.deselectAllItems()
        }
        else if self.itemAtIndexPathIsSelected(ip) {
            self.deselectItemAtIndexPath(ip, animated: true)
            return
        }
        self._selectItemAtIndexPath(ip, animated: true, scrollPosition: .None, withEvent: theEvent)
    }
    
    public override func rightMouseDown(theEvent: NSEvent) {
        super.rightMouseDown(theEvent)
        let point = self.contentView.convertPoint(theEvent.locationInWindow, fromView: nil)
        if let indexPath = self.indexPathForItemAtPoint(point) {
            self.delegate?.collectionView?(self, didRightClickItemAtIndexPath: indexPath, withEvent: theEvent)
        }
    }
    
    func moveSelectionInDirection(direction: CBCollectionViewDirection, extendSelection: Bool) {
        guard let indexPath = (extendSelection ? _lastSelection : _firstSelection) ?? self._selectedIndexPaths.first else { return }
        if let moveTo = self.collectionViewLayout.indexPathForNextItemInDirection(direction, afterItemAtIndexPath: indexPath) {
            if let move = self.delegate?.collectionView?(self, shouldSelectItemAtIndexPath: moveTo, withEvent: NSApp.currentEvent) where move != true { return }
            self.selectItemAtIndexPath(moveTo, atScrollPosition: .Nearest, animated: true, selectionType: extendSelection ? .Extending : .Single)
        }
    }
    
    public override func keyDown(theEvent: NSEvent) {
        if theEvent.keyCode == 123 { self.moveSelectionLeft(theEvent.modifierFlags.contains(NSEventModifierFlags.ShiftKeyMask)) }
        else if theEvent.keyCode == 124 { self.moveSelectionRight(theEvent.modifierFlags.contains(NSEventModifierFlags.ShiftKeyMask)) }
        else if theEvent.keyCode == 125 { self.moveSelectionDown(theEvent.modifierFlags.contains(NSEventModifierFlags.ShiftKeyMask)) }
        else if theEvent.keyCode == 126 { self.moveSelectionUp(theEvent.modifierFlags.contains(NSEventModifierFlags.ShiftKeyMask)) }
//        else if theEvent.keyCode == 0 && theEvent.modifierFlags.contains(NSEventModifierFlags.CommandKeyMask) {
//            self.selectAllItems(true)
//        }
//        else if theEvent.keyCode == 2 && theEvent.modifierFlags.contains(NSEventModifierFlags.CommandKeyMask) {
//            self.deselectAllItems(true)
//        }
        else {
            super.keyDown(theEvent)
//            super.interpretKeyEvents([theEvent])
        }
    }
    
    
    
    public func moveSelectionLeft(extendSelection: Bool) {
        self.moveSelectionInDirection(.Left, extendSelection: extendSelection)
    }
    public func moveSelectionRight(extendSelection: Bool) {
        self.moveSelectionInDirection(.Right, extendSelection: extendSelection)
    }
    public func moveSelectionUp(extendSelection: Bool) {
        self.moveSelectionInDirection(.Up, extendSelection: extendSelection)
    }
    public func moveSelectionDown(extendSelection: Bool) {
        self.moveSelectionInDirection(.Down, extendSelection: extendSelection)
    }
    
    
    public var scrollEnabled = true
    public override func scrollWheel(theEvent: NSEvent) {
        if scrollEnabled {
            super.scrollWheel(theEvent)
        }
    }
    
    
    // MARK: - Dragging Source
    var draggedIPs : [NSIndexPath] = []
    
    override public var acceptsFirstResponder : Bool { return true }
    public override func acceptsFirstMouse(theEvent: NSEvent?) -> Bool { return true }
    public override func becomeFirstResponder() -> Bool { return true }
//    public override func hitTest(aPoint: NSPoint) -> NSView? {
//        if (NSMouseInRect(aPoint, self.frame, true)) { return self }
//        return nil;
//    }
    
    public func indexPathsForDraggingItems() -> [NSIndexPath] { return draggedIPs }
    
    override public func mouseDragged(theEvent: NSEvent) {
        super.mouseDragged(theEvent)
        self.window?.makeFirstResponder(self)
        self.draggedIPs = []
        var items : [NSDraggingItem] = []
        
        if mouseDownIP == nil { return }
        
        if self.interactionDelegate?.collectionView?(self, shouldBeginDraggingAtIndexPath: mouseDownIP!, withEvent: theEvent) != true { return }
        
        let ips = self.indexPathsForSelectedItems().sort { (ip1, ip2) -> Bool in
            let before = ip1._section < ip2._section || (ip1._section == ip2._section && ip1._item < ip2._item)
            return before
        }
        for indexPath in ips {
            var ip = indexPath
            
            let selections = self.indexPathsForSelectedItems()
            if selections.count == 0 { return }
            else if selections.count == 1 && mouseDownIP != ip, let mIP = mouseDownIP {
                self.deselectItemAtIndexPath(ip, animated: true)
                ip = mIP
                self.selectItemAtIndexPath(ip, animated: true)
            }
            
            
            if let writer = self.dataSource?.collectionView?(self, pasteboardWriterForItemAtIndexPath: ip) {
//                let cell = self.cellForItemAtIndexPath(ip) as? AssetCell
                guard let rect = self.rectForItemAtIndexPath(ip) else { continue }
                // The frame of the cell in relation to the document. This is where the dragging
                // image should start.
                let originalFrame = UnsafeMutablePointer<CGRect>.alloc(1)
                let oFrame = self.convertRect( rect,
                    fromView: self.documentView as? NSView
                )
                originalFrame.initialize(oFrame)
                self.dataSource?.collectionView?(self, dragRectForItemAtIndexPath: ip, withStartingRect: originalFrame)
                var image = self.dataSource?.collectionView?(self, dragContentsForItemAtIndexPath: ip)
                
                if image == nil{
                    image = NSImage(named: "empty_project")
                }
                
                self.draggedIPs.append(ip)
                let item = NSDraggingItem(pasteboardWriter: writer)
                item.setDraggingFrame(originalFrame.memory, contents: image!)
                items.append(item)
            }
        }
        
        if items.count > 0 {
            let session = self.beginDraggingSessionWithItems(items, event: theEvent, source: self)
            if items.count > 1 {
                session.draggingFormation = .Pile
            }
        }
    }
    
    public func draggingSession(session: NSDraggingSession, sourceOperationMaskForDraggingContext context: NSDraggingContext) -> NSDragOperation {
        if context == NSDraggingContext.OutsideApplication { return .Copy }
        return .Move
    }
    
    public func draggingSession(session: NSDraggingSession, willBeginAtPoint screenPoint: NSPoint) {
        self.interactionDelegate?.collectionView?(self, draggingSession: session, willBeginAtPoint: screenPoint)
    }
    
    public func draggingSession(session: NSDraggingSession, movedToPoint screenPoint: NSPoint) {
        self.interactionDelegate?.collectionView?(self, draggingSession: session, didMoveToPoint: screenPoint)
    }
    
    public func draggingSession(session: NSDraggingSession, endedAtPoint screenPoint: NSPoint, operation: NSDragOperation) {
        self.mouseDownIP = nil
        self.interactionDelegate?.collectionView?(self, draggingSession: session, enedAtPoint: screenPoint, withOperation: operation, draggedIndexPaths: draggedIPs)
        self.draggedIPs = []
    }
    
    
    // MARK: - Draggng Destination
    public override func draggingEntered(sender: NSDraggingInfo) -> NSDragOperation {
        if let operation = self.interactionDelegate?.collectionView?(self, dragEntered: sender) {
            return operation
        }
        return .None
    }
    public override func draggingExited(sender: NSDraggingInfo?) {
        self.interactionDelegate?.collectionView?(self, dragExited: sender)
    }
    public override func draggingEnded(sender: NSDraggingInfo?) {
        self.interactionDelegate?.collectionView?(self, dragEnded: sender)
    }
    public override func draggingUpdated(sender: NSDraggingInfo) -> NSDragOperation {
        if let operation = self.interactionDelegate?.collectionView?(self, dragUpdated: sender) {
            return operation
        }
        return sender.draggingSourceOperationMask()
    }
    public override func performDragOperation(sender: NSDraggingInfo) -> Bool {
        if let perform = self.interactionDelegate?.collectionView?(self, performDragOperation: sender) {
            return perform
        }
        return false
    }
    
}

