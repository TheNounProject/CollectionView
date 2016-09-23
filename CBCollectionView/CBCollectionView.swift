//
//  CBCollectionView.swift
//  Lingo
//
//  Created by Wesley Byrne on 1/27/16.
//  Copyright © 2016 The Noun Project. All rights reserved.
//

import Foundation
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}



open class CBCollectionView : CBScrollView, NSDraggingSource {
    
    open weak var contentDocumentView : CBCollectionViewDocumentView! {
        return self.documentView as! CBCollectionViewDocumentView
    }
    open override var mouseDownCanMoveWindow: Bool { return true }
    
    
    
    // MARK: - Data Source & Delegate
    open weak var delegate : CBCollectionViewDelegate?
    open weak var dataSource : CBCollectionViewDataSource?
    fileprivate weak var interactionDelegate : CBCollectionViewInteractionDelegate? {
        return self.delegate as? CBCollectionViewInteractionDelegate
    }
    
    
    
    // MARK: - Intialization
    /*-------------------------------------------------------------------------------*/
    
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
        let dView = CBCollectionViewDocumentView()
        dView.wantsLayer = true
        self.documentView = dView
        self.hasVerticalScroller = true
        self.scrollsDynamically = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(CBCollectionView.didScroll(_:)), name: NSNotification.Name.NSScrollViewDidLiveScroll, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(CBCollectionView.willBeginScroll(_:)), name: NSNotification.Name.NSScrollViewWillStartLiveScroll, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(CBCollectionView.didEndScroll(_:)), name: NSNotification.Name.NSScrollViewDidEndLiveScroll, object: self)
        
        self.addSubview(_floatingSupplementaryView, positioned: .above, relativeTo: self.clipView!)
        self._floatingSupplementaryView.wantsLayer = true
        _floatingSupplementaryView.frame = self.bounds
    }
    
    deinit {
        self.delegate = nil
        self.dataSource = nil
        NotificationCenter.default.removeObserver(self)
        self._reusableCells.removeAll()
        self._reusableSupplementaryView.removeAll()
        self.contentDocumentView.preparedCellIndex.removeAll()
        self.contentDocumentView.preparedSupplementaryViewIndex.removeAll()
        for view in self.contentDocumentView.subviews {
            view.removeFromSuperview()
        }
    }

    
    
    
    
    // MARK: - Registering reusable cells
    /*-------------------------------------------------------------------------------*/
    
    fileprivate var _cellClasses : [String:CBCollectionViewCell.Type] = [:]
    fileprivate var _cellNibs : [String:NSNib] = [:]
    
    fileprivate var _supplementaryViewClasses : [SupplementaryViewIdentifier:CBCollectionReusableView.Type] = [:]
    fileprivate var _supplementaryViewNibs : [SupplementaryViewIdentifier:NSNib] = [:]
    
    open func registerClass(_ cellClass: CBCollectionViewCell.Type!, forCellWithReuseIdentifier identifier: String!) {
        assert(cellClass.isSubclass(of: CBCollectionViewCell.self), "CBCollectionView: Registered cells views must be subclasses of CBCollectionViewCell")
        assert(!identifier.isEmpty, "CBCollectionView: Reuse identifier cannot be an empty or blank string")
        self._cellClasses[identifier] = cellClass
        self._cellNibs[identifier] = nil
    }
    open func registerNib(_ nib: NSNib!, forCellWithReuseIdentifier identifier: String!) {
        assert(!identifier.isEmpty, "CBCollectionView: Reuse identifier cannot be an empty or blank string")
        self._cellClasses[identifier] = nil
        self._cellNibs[identifier] = nib
    }
    open func registerClass(_ viewClass: CBCollectionReusableView.Type!, forSupplementaryViewOfKind kind: String!, withReuseIdentifier identifier: String!) {
        assert(viewClass.isSubclass(of: CBCollectionReusableView.self), "CBCollectionView: Registered supplementary views must be subclasses of CBCollectionReusableview")
        assert(!identifier.isEmpty, "CBCollectionView: Reuse identifier cannot be an empty or blank string")
        let id = SupplementaryViewIdentifier(kind: kind, reuseIdentifier: identifier)
        self._supplementaryViewClasses[id] = viewClass
        self._supplementaryViewNibs[id] = nil
        self._registeredSupplementaryViewKinds.insert(kind)
        self._allSupplementaryViewIdentifiers.insert(id)
    }
    open func registerNib(_ nib: NSNib, forSupplementaryViewOfKind kind: String!, withReuseIdentifier identifier: String!) {
        assert(!identifier.isEmpty, "CBCollectionView: Reuse identifier cannot be an empty or blank string")
        let id = SupplementaryViewIdentifier(kind: kind, reuseIdentifier: identifier)
        self._supplementaryViewClasses[id] = nil
        self._supplementaryViewNibs[id] = nib
        self._registeredSupplementaryViewKinds.insert(kind)
        self._allSupplementaryViewIdentifiers.insert(id)
    }
    
    internal var _allSupplementaryViewIdentifiers = Set<SupplementaryViewIdentifier>()
    internal var _registeredSupplementaryViewKinds = Set<String>()
    
    fileprivate func _firstObjectOfClass(_ aClass: AnyClass, inNib: NSNib) -> NSView? {
        var foundObject: AnyObject? = nil
        var topLevelObjects = NSArray()
        if inNib.instantiate(withOwner: self, topLevelObjects: &topLevelObjects) {
            for obj in topLevelObjects {
                if let o = obj as? AnyObject, o.isKind(of: aClass) {
                    foundObject = o
                    break
                }
            }
//            let index = topLevelObjects!.indexOfObject(passingTest: {(obj, idx, stop) -> Bool in
//                
//            })
//            if index != NSNotFound {
//                foundObject = topLevelObjects![index]
//            }
        }
        assert(foundObject != nil, "CBCollectionView: Could not find view of type \(aClass) in nib. Make sure the top level object in the nib is of this type.")
        return foundObject as? NSView
    }
    
    
    
    
    // MARK: - Dequeing reusable cells
    /*-------------------------------------------------------------------------------*/
    
    fileprivate var _reusableCells : [String:Set<CBCollectionViewCell>] = [:]
    fileprivate var _reusableSupplementaryView : [SupplementaryViewIdentifier:[CBCollectionReusableView]] = [:]
    
    public final func dequeueReusableCellWithReuseIdentifier(_ identifier: String, forIndexPath indexPath: IndexPath) -> CBCollectionViewCell {
        
        var cell =  self._reusableCells[identifier]?.first
        if cell == nil {
            if let nib = self._cellNibs[identifier] {
                cell = _firstObjectOfClass(CBCollectionViewCell.self, inNib: nib) as? CBCollectionViewCell
            }
            else if let aClass = self._cellClasses[identifier] {
                cell = aClass.init()
            }
            assert(cell != nil, "CBCollectionView: No cell could be dequed with identifier '\(identifier) for item: \(indexPath._item) in section \(indexPath._section)'. Make sure you have registered your cell class or nib for that identifier.")
            cell?.collectionView = self
        }
        else {
            self._reusableCells[identifier]?.removeFirst()
            cell?.prepareForReuse()
        }
        cell?.reuseIdentifier = identifier
        cell?.indexPath = indexPath
        
        return cell!
    }
    public final func dequeueReusableSupplementaryViewOfKind(_ elementKind: String, withReuseIdentifier identifier: String, forIndexPath indexPath: IndexPath) -> CBCollectionReusableView {
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
            view?.collectionView = self
        }
        else {
            self._reusableSupplementaryView[id]?.removeFirst()
            view?.prepareForReuse()
        }
        view?.reuseIdentifier = identifier
        view?.indexPath = indexPath
        return view!
    }
    
    final func enqueueCellForReuse(_ item: CBCollectionViewCell) {
        item.isHidden = true
        item.indexPath = nil
        guard let id = item.reuseIdentifier else { return }
        if self._reusableCells[id] == nil {
            self._reusableCells[id] = []
        }
        self._reusableCells[id]?.insert(item)
    }
    
    final func enqueueSupplementaryViewForReuse(_ item: CBCollectionReusableView, withIdentifier: SupplementaryViewIdentifier) {
        item.isHidden = true
        item.indexPath = nil
        let newID = SupplementaryViewIdentifier(kind: withIdentifier.kind, reuseIdentifier: item.reuseIdentifier ?? withIdentifier.reuseIdentifier)
        if self._reusableSupplementaryView[newID] == nil {
            self._reusableSupplementaryView[newID] = []
        }
        self._reusableSupplementaryView[newID]?.append(item)
    }
    
    
    
    // MARK: - Data
    fileprivate var info : CBCollectionViewInfo!
    open func numberOfSections() -> Int { return self.info.numberOfSections }
    open func numberOfItemsInSection(_ section: Int) -> Int { return self.info.numberOfItemsInSection(section) }
    open func frameForSectionAtIndexPath(_ indexPath: IndexPath) -> CGRect? {
        return self.info.sections[indexPath._section]?.frame
    }
    
    
    // MARK: - Floating View
    /*-------------------------------------------------------------------------------*/
    let _floatingSupplementaryView = FloatingSupplementaryView(frame: NSZeroRect)
    open func addAccessoryView(_ view: NSView) {
        self._floatingSupplementaryView.addSubview(view)
    }
    
    
    
    // MARK: - Layout
    /*-------------------------------------------------------------------------------*/
    
    open var collectionViewLayout : CBCollectionViewLayout = CBCollectionViewLayout() {
        didSet {
            collectionViewLayout.collectionView = self
            self.hasHorizontalScroller = collectionViewLayout.scrollDirection == .horizontal
            self.hasVerticalScroller = collectionViewLayout.scrollDirection == .vertical
        }}
    
    open var contentVisibleRect : CGRect { return self.documentVisibleRect }
    open override var contentSize: NSSize {
        return self.collectionViewLayout.collectionViewContentSize()
    }
    open var contentOffset : CGPoint {
        get{ return self.contentVisibleRect.origin }
        set {
            self.clipView?.scroll(to: newValue)
            self.reflectScrolledClipView(self.clipView!)
            self.contentDocumentView.prepareRect(self.contentVisibleRect)
            self.contentDocumentView.preparedRect = self.contentVisibleRect
        }
    }
    
    /// Force layout of all items, not just those in the visible content area (Only applies to reloadData())
    open var prepareAll : Bool = false
    
    
    // Used to track positioning during resize/layout
    var _topIP: IndexPath?
    
    // discard the dataSource and delegate data and requery as necessary
    open func reloadData() {
        self.contentDocumentView.reset()
        self.info.recalculate()
        contentDocumentView.frame.size = self.collectionViewLayout.collectionViewContentSize()
        self.reflectScrolledClipView(self.clipView!)
        
        self._selectedIndexPaths.formIntersection(self.allIndexPaths())
        self.contentDocumentView.prepareRect(prepareAll
            ?  CGRect(origin: CGPoint.zero, size: self.info.contentSize)
            : self.contentVisibleRect, animated: false)
        
        self.delegate?.collectionViewDidReloadData?(self)
    }
    
    
    open override func layout() {
        _floatingSupplementaryView.frame = self.bounds
        super.layout()
        
        var calc : TimeInterval = 0
        var scroll : TimeInterval = 0
        var prep : TimeInterval = 0
        
        if self.collectionViewLayout.shouldInvalidateLayoutForBoundsChange(self.documentVisibleRect) {
            var d = Date()
            
            let _size = self.info.contentSize
            
            self.info.recalculate()
            calc = d.timeIntervalSinceNow
            
            contentDocumentView.frame.size = self.collectionViewLayout.collectionViewContentSize()
            d = Date()
            if self.info.contentSize.height != _size.height, let ip = _topIP, let rect = self.collectionViewLayout.scrollRectForItemAtIndexPath(ip, atPosition: CBCollectionViewScrollPosition.top) {
                let _rect = CGRect(origin: rect.origin, size: self.bounds.size)
                self.clipView?.scrollRectToVisible(_rect, animated: false, completion: nil)
            }
            self.reflectScrolledClipView(self.clipView!)
            scroll = d.timeIntervalSinceNow
            d = Date()
            
            self.contentDocumentView.prepareRect(prepareAll ? contentDocumentView.frame : self.contentVisibleRect, force: true)
            prep = d.timeIntervalSinceNow
            //            Swift.print("Calc: \(calc)  Scroll: \(scroll)  prep: \(prep)")
        }
    }
    
    
    /**
     Trigger the collection view to relayout all items
     
     - parameter animated:       If the layout should be animated
     - parameter scrollPosition: Where (if any) the scroll position should be pinned
     */
    open func relayout(_ animated: Bool, scrollPosition: CBCollectionViewScrollPosition = .nearest, completion: CBAnimationCompletion? = nil) {
        
        var absoluteCellFrames = [CBCollectionReusableView:CGRect]()
        
        for cell in self.contentDocumentView.preparedCellIndex {
            absoluteCellFrames[cell.1] = self.convert(cell.1.frame, from: cell.1.superview)
        }
        for cell in self.contentDocumentView.preparedSupplementaryViewIndex {
            absoluteCellFrames[cell.1] = self.convert(cell.1.frame, from: cell.1.superview)
        }
    
        let holdIP : IndexPath? = self.indexPathForFirstVisibleItem()
            //?? self.indexPathsForSelectedItems().intersect(self.indexPathsForVisibleItems()).first

        self.info.recalculate()
        var vRect = self.contentVisibleRect
        
        let nContentSize = self.info.contentSize
        let docFrame = self.contentDocumentView.frame
        contentDocumentView.frame.size = nContentSize
        
        if scrollPosition != .none, let ip = holdIP, let rect = self.collectionViewLayout.scrollRectForItemAtIndexPath(ip, atPosition: scrollPosition) ?? self.rectForItemAtIndexPath(ip) {
            self._scrollToRect(rect, atPosition: scrollPosition, animated: false, prepare: false, completion: nil)
        }
        self.reflectScrolledClipView(self.clipView!)
        
        for item in absoluteCellFrames {
            if let attrs = item.0.attributes , attrs.representedElementCategory == CBCollectionElementCategory.supplementaryView {
                if let newAttrs = self.layoutAttributesForSupplementaryElementOfKind(attrs.representedElementKind!, atIndexPath: attrs.indexPath as IndexPath) {
                    
                    if newAttrs.floating != attrs.floating {
                        if newAttrs.floating {
                            item.0.removeFromSuperview()
                            self._floatingSupplementaryView.addSubview(item.0)
                            item.0.frame = item.1
                        }
                        else {
                            item.0.removeFromSuperview()
                            self.contentDocumentView.addSubview(item.0)
                            item.0.frame = self.contentDocumentView.convert(item.1, from: self)
                        }
                    }
                    else if newAttrs.floating {
                        item.0.frame = item.1
                    }
                    else {
                        let cFrame = self.contentDocumentView.convert(item.1, from: self)
                        item.0.frame = cFrame
                    }
                    continue
                }
            }
            
            let cFrame = self.contentDocumentView.convert(item.1, from: self)
            item.0.frame = cFrame
        }
        
        self.contentDocumentView.preparedRect = _rectToPrepare
        self.contentDocumentView.prepareRect(_rectToPrepare, animated: animated, force: true, completion: completion)
    }
    
    
    // MARK: - Live Resize
    /*-------------------------------------------------------------------------------*/
    var _resizeStartBounds : CGRect = CGRect.zero
    open override func viewWillStartLiveResize() {
        _resizeStartBounds = self.contentVisibleRect
        _topIP = indexPathForFirstVisibleItem()
    }
    
    open override func viewDidEndLiveResize() {
        _topIP = nil
        self.delegate?.collectionViewDidEndLiveResize?(self)
    }
    
    
    // MARK: - Scroll Handling
    /*-------------------------------------------------------------------------------*/
    
    open var scrollEnabled = true { didSet { self.clipView?.scrollEnabled = scrollEnabled }}
    open internal(set) var scrolling : Bool = false
    fileprivate var _previousOffset = CGPoint.zero
    fileprivate var _offsetMark = CACurrentMediaTime()
    
    open fileprivate(set) var velocity: CGFloat = 0
    open fileprivate(set) var peakVelocityForScroll: CGFloat = 0
    
    var _rectToPrepare : CGRect {
        return prepareAll
            ?  CGRect(origin: CGPoint.zero, size: self.info.contentSize)
            : self.contentVisibleRect.insetBy(dx: 0, dy: -100)
    }
    
    final func didScroll(_ notification: Notification) {
        let rect = _rectToPrepare
        self.contentDocumentView.prepareRect(rect)

        var _prev = self._previousOffset
        self._previousOffset = self.contentVisibleRect.origin
        let delta = _prev.y - self._previousOffset.y
        var timeOffset = CGFloat(CACurrentMediaTime() - _offsetMark)
        self.velocity = delta
        self.peakVelocityForScroll = max(abs(peakVelocityForScroll), abs(self.velocity))
        self._offsetMark = CACurrentMediaTime()
        self.delegate?.collectionViewDidScroll?(self)
    }
    
    final func willBeginScroll(_ notification: Notification) {
        self.scrolling = true
        self.delegate?.collectionViewWillBeginScrolling?(self)
        self._previousOffset = self.contentVisibleRect.origin
        self.peakVelocityForScroll = 0
        self.velocity = 0
    }
    
    final func didEndScroll(_ notification: Notification) {
        self.scrolling = false
        self.delegate?.collectionViewDidEndScrolling?(self, animated: true)
        Swift.print("Peak Velocity: \(self.peakVelocityForScroll)")
        self.velocity = 0
        self.peakVelocityForScroll = 0
//        self.contentDocumentView.preparedRect = self.contentVisibleRect
//        self.contentDocumentView.extendPreparedRect(self.contentVisibleRect.size.height/2)
        
        if trackSectionHover && NSApp.isActive, let point = self.window?.convertFromScreen(NSRect(origin: NSEvent.mouseLocation(), size: CGSize.zero)).origin {
            let loc = self.contentDocumentView.convert(point, from: nil)
            self.delegate?.collectionView?(self, mouseMovedToSection: indexPathForSectionAtPoint(loc))
        }
    }

    open func indexPathForFirstVisibleItem() -> IndexPath? {
        if let ip = self.delegate?.collectionViewLayoutAnchor?(self) {
            return ip
        }
        
        var visibleRect = self.contentVisibleRect //.insetBy(dx: self.contentInsets.left + self.contentInsets.right, dy: self.contentInsets.top + self.contentInsets.bottom)
        visibleRect.origin.y += self.contentInsets.top
        visibleRect.origin.x += self.contentInsets.top
        visibleRect.size.height -= self.contentInsets.top + self.contentInsets.bottom
        visibleRect.size.width -= self.contentInsets.left + self.contentInsets.right
        
        
        var closest : IndexPath?
        for sectionIndex in 0..<self.info.numberOfSections  {
            guard let section = self.info.sections[sectionIndex] else { continue }
            if section.frame.isEmpty || !section.frame.intersects(visibleRect) { continue }
            for item in 0..<section.numberOfItems {
                let indexPath = IndexPath._indexPathForItem(item, inSection: sectionIndex)
                if let attributes = self.collectionViewLayout.layoutAttributesForItemAtIndexPath(indexPath) {
                    if (visibleRect.contains(attributes.frame)) {
                        return indexPath
                    }
                    else if closest == nil && visibleRect.intersects(attributes.frame) {
                        closest = indexPath
                    }
                }
            }
        }
        return closest
    }
    
    
    
    
    // MARK: - Reloading, Inserting & Deleting items
    /*-------------------------------------------------------------------------------*/
    open func reloadItemsAtIndexPaths(_ indexPaths: [IndexPath], animated: Bool) {
        
        
        var removals = [ItemUpdate]()
        for indexPath in indexPaths {
            guard let cell = self.cellForItemAtIndexPath(indexPath) else {
                debugPrint("Not reloading cell because it is not visible")
                return
            }
            let oldFrame = cell.frame
            guard let newCell = self.dataSource?.collectionView(self, cellForItemAtIndexPath: indexPath) else {
                debugPrint("For some reason collection view tried to load cells without a data source")
                return
            }
            assert(newCell.collectionView != nil, "Attempt to load cell without using deque:")
            
            var attrs = self.collectionViewLayout.layoutAttributesForItemAtIndexPath(indexPath)
            attrs?.frame = cell.frame
            
            if animated {
                attrs?.alpha = 0
            }
            removals.append(ItemUpdate(view: cell, attrs: cell.attributes!, type: .remove))
            
            newCell.indexPath = indexPath
            
            if let a = attrs {
                newCell.applyLayoutAttributes(a, animated: false)
            }
            if newCell.superview == nil {
                self.contentDocumentView.addSubview(newCell)
            }
            newCell.selected = self._selectedIndexPaths.contains(indexPath)
            
            self.contentDocumentView.preparedCellIndex[indexPath] = newCell
            newCell.viewDidDisplay()
        }
        self.contentDocumentView.pendingUpdates.append(contentsOf: removals)
        if batchUpdating { return }
        self.relayout(animated, scrollPosition: .none)
    }
    
    
    open func insertItemsAtIndexPaths(_ indexPaths: [IndexPath], animated: Bool) {
        
        self.indexPathForHighlightedItem = nil
        
        var sorted = indexPaths.sorted { (ip1, ip2) -> Bool in
            return ip1._item < ip2._item
        }
        
        var newBySection = [Int:[IndexPath]]()
        
        for ip in sorted {
            if newBySection[ip._section] == nil { newBySection[ip._section] = [ip] }
            else { newBySection[ip._section]?.append(ip) }
        }
        
        var changeMap = [(newIP: IndexPath, cell: CBCollectionViewCell)]()
        for s in newBySection {
            let sectionIndex = s.0
            var newIps = s.1
            
            let cCount = self.numberOfItemsInSection(sectionIndex)
            let nCount = cCount + newIps.count
            
            var newIndex = 0
            
            for idx in 0..<cCount {
                while let nIP = newIps.first , nIP._item == newIndex {
                    newIps.removeFirst()
                    newIndex += 1
                }
                
                let old = IndexPath._indexPathForItem(idx, inSection: sectionIndex)
                if newIndex != idx, let cell = self.contentDocumentView.preparedCellIndex.removeValue(forKey: old) {
                    let new = IndexPath._indexPathForItem(newIndex, inSection: sectionIndex)
                    changeMap.append((newIP: new, cell: cell))
                }
                newIndex += 1
            }
        }
        
        var updatedSelections = Set<IndexPath>()
        var movedSelections = Set<IndexPath>()
        for change in changeMap {
            if let ip = change.cell.indexPath , self._selectedIndexPaths.contains(ip as IndexPath) {
                updatedSelections.insert(ip as IndexPath)
                movedSelections.insert(change.newIP)
            }
            change.cell.indexPath = change.newIP
            self.contentDocumentView.preparedCellIndex[change.newIP] = change.cell
        }
        _selectedIndexPaths.removeSet(updatedSelections)
        _selectedIndexPaths.formUnion(movedSelections)
        
        if batchUpdating { return }

        self.relayout(true, scrollPosition: .none)
        self.delegate?.collectionViewDidReloadData?(self)
    }
    
    
    
    open func deleteItemsAtIndexPaths(_ indexPaths: [IndexPath], animated: Bool) {
        
        self.indexPathForHighlightedItem = nil
        
        var bySection = [Int:[IndexPath]]()
        
        var sorted = indexPaths.sorted { (ip1, ip2) -> Bool in return ip1._item < ip2._item }
        for ip in sorted {
            if bySection[ip._section] == nil { bySection[ip._section] = [ip] }
            else { bySection[ip._section]?.append(ip) }
        }
        
        var updates = [ItemUpdate]()
        var changeMap = [(newIP: IndexPath, cell: CBCollectionViewCell)]()
        
        for s in bySection {
            let sectionIndex = s.0
            var removeIPs = s.1
            
            let cCount = self.numberOfItemsInSection(sectionIndex)
            let nCount = cCount - removeIPs.count
    
            var newIndex = 0
            
            for idx in 0..<cCount {
                if let dIP = removeIPs.first , dIP._item == idx,
                let cell = self.contentDocumentView.preparedCellIndex.removeValue(forKey: dIP),
                let attrs = cell.attributes {
                    removeIPs.removeFirst()
                    updates.append(ItemUpdate(view: cell, attrs: attrs, type: .remove))
                    continue
                }
                
                let old = IndexPath._indexPathForItem(idx, inSection: sectionIndex)
                if newIndex != idx, let cell = self.contentDocumentView.preparedCellIndex.removeValue(forKey: old) {
                    let new = IndexPath._indexPathForItem(newIndex, inSection: sectionIndex)
                    changeMap.append((newIP: new, cell: cell))
                }
                newIndex += 1
            }
        }
        
        self.contentDocumentView.pendingUpdates.append(contentsOf: updates)
        
        var updatedSelections = Set<IndexPath>()
        var movedSelections = Set<IndexPath>()
        for change in changeMap {
            if let ip = change.cell.indexPath , self._selectedIndexPaths.contains(ip as IndexPath) {
                updatedSelections.insert(ip as IndexPath)
                movedSelections.insert(change.newIP)
            }
            change.cell.indexPath = change.newIP
            self.contentDocumentView.preparedCellIndex[change.newIP] = change.cell
        }
        
        _selectedIndexPaths.removeSet(updatedSelections)
        _selectedIndexPaths.formUnion(movedSelections)
        
        if batchUpdating { return }
        
        self.relayout(true, scrollPosition: .none)
        self.delegate?.collectionViewDidReloadData?(self)
    }
    
    
    public final func deleteSections(_ indexes: [Int]) {
        
        self.indexPathForHighlightedItem = nil
        
        var sorted = Set(indexes).sorted()
        
        var updates = [ItemUpdate]()
        var cellMap = [(newIP: IndexPath, cell: CBCollectionViewCell)]()
        var viewMap = [(id: SupplementaryViewIdentifier, view: CBCollectionReusableView)]()
        
        let cCount = self.numberOfSections()
        let nCount = cCount - sorted.count
        
        
        // Create a map of the prepared cells
        var prepared = [Int: (supp: [SupplementaryViewIdentifier], cells: [IndexPath])]()
        for supp in contentDocumentView.preparedSupplementaryViewIndex {
            guard let sec = supp.0.indexPath?._section else { continue }
            if prepared[sec] == nil { prepared[sec] = (supp: [supp.0], cells: []) }
            else { prepared[sec]?.supp.append(supp.0) }
        }
        for item in contentDocumentView.preparedCellIndex {
            let sec = item.0._section
            if prepared[sec] == nil { prepared[sec] = (supp: [], cells: [item.0]) }
            else { prepared[sec]?.cells.append(item.0 as IndexPath) }
        }
        
        
        var newSection = 0
        for sec in 0..<cCount {
            if let rSec = sorted.first , rSec == sec {
                guard let items = prepared[sec] else { continue }
                for supp in items.supp {
                    if let view = contentDocumentView.preparedSupplementaryViewIndex.removeValue(forKey: supp),
                    let attrs = view.attributes {
                        updates.append(ItemUpdate(view: view, attrs: attrs, type: .remove, identifier: supp))
                    }
                }
                for ip in items.cells {
                    if let view = contentDocumentView.preparedCellIndex.removeValue(forKey: ip),
                        let attrs = view.attributes {
                        updates.append(ItemUpdate(view: view, attrs: attrs, type: .remove))
                    }
                }
                continue
            }
            
            if sec != newSection, let items = prepared[sec] {
                for supp in items.supp {
                    if let view = contentDocumentView.preparedSupplementaryViewIndex.removeValue(forKey: supp) {
                        let ip = IndexPath._indexPathForSection(newSection)
                        var s = supp
                        s.indexPath = ip
                        viewMap.append((id: s, view: view))
                    }
                }
                for ip in items.cells {
                    if let view = contentDocumentView.preparedCellIndex.removeValue(forKey: ip) {
                        let ip = IndexPath._indexPathForItem(ip._item, inSection: newSection)
                        cellMap.append((newIP: ip, cell: view))
                    }
                }
            }
            newSection += 1
        }
        
        self.contentDocumentView.pendingUpdates.append(contentsOf: updates)
        
        for change in viewMap {
            change.view.indexPath = change.id.indexPath
            self.contentDocumentView.preparedSupplementaryViewIndex[change.id] = change.view
        }
        
        var updatedSelections = Set<IndexPath>()
        var movedSelections = Set<IndexPath>()
        for change in cellMap {
            if let ip = change.cell.indexPath , self._selectedIndexPaths.contains(ip as IndexPath) {
                updatedSelections.insert(ip as IndexPath)
                movedSelections.insert(change.newIP)
            }
            change.cell.indexPath = change.newIP
            self.contentDocumentView.preparedCellIndex[change.newIP] = change.cell
        }
        _selectedIndexPaths.removeSet(updatedSelections)
        _selectedIndexPaths.formUnion(movedSelections)
        
        if batchUpdating { return }
        
        self.relayout(true, scrollPosition: .none)
        self.delegate?.collectionViewDidReloadData?(self)
        
    }
    
    public final func insertSections(_ indexes: [Int]) {
        
        self.indexPathForHighlightedItem = nil
        
        var sorted = Set(indexes).sorted()
        var changeMap = [(newIP: IndexPath, cell: CBCollectionViewCell)]()
        
        let cCount = self.numberOfSections()
        let nCount = cCount + sorted.count
        
        var newSection = 0
        
        for sec in 0..<cCount {
            
            while let nSec = sorted.first , nSec <= sec {
                sorted.removeFirst()
                newSection += 1
            }
            if newSection != sec {
                for index in 0..<numberOfItemsInSection(sec) {
                    let ip = IndexPath._indexPathForItem(index, inSection: sec)
                    if let cell = self.contentDocumentView.preparedCellIndex.removeValue(forKey: ip) {
                        let newIP = IndexPath._indexPathForItem(index, inSection: newSection)
                        changeMap.append((newIP: newIP, cell: cell))
                    }
                }
            }
            newSection += 1
        }
        
        var updatedSelections = Set<IndexPath>()
        var movedSelections = Set<IndexPath>()
        for change in changeMap {
            if let ip = change.cell.indexPath , self._selectedIndexPaths.contains(ip as IndexPath) {
                updatedSelections.insert(ip as IndexPath)
                movedSelections.insert(change.newIP)
            }
            change.cell.indexPath = change.newIP
            self.contentDocumentView.preparedCellIndex[change.newIP] = change.cell
        }
        _selectedIndexPaths.removeSet(updatedSelections)
        _selectedIndexPaths.formUnion(movedSelections)
        
        if batchUpdating { return }
        
        self.relayout(true, scrollPosition: .none)
        self.delegate?.collectionViewDidReloadData?(self)
        
    }
    
    
    
    fileprivate var batchUpdating : Bool = false
    open var animationDuration: TimeInterval = 0.4

    open func performBatchUpdates(_ updates: (()->Void), completion: CBAnimationCompletion?) {
        
        batchUpdating = true
        updates()
        batchUpdating = false
        self.relayout(true, scrollPosition: .none, completion: completion)
        self.delegate?.collectionViewDidReloadData?(self)
    }
    
    
    
    
    

    
    // MARK: - Mouse Tracking (section highlight)
    /*-------------------------------------------------------------------------------*/
    
    open var trackSectionHover : Bool = false {
        didSet { self.addTracking() }
    }
    var _trackingArea : NSTrackingArea?
    func addTracking() {
        if let ta = _trackingArea {
            self.removeTrackingArea(ta)
        }
        if trackSectionHover {
            _trackingArea = NSTrackingArea(rect: self.bounds, options: [NSTrackingAreaOptions.activeInActiveApp, NSTrackingAreaOptions.mouseEnteredAndExited, NSTrackingAreaOptions.mouseMoved], owner: self, userInfo: nil)
            self.addTrackingArea(_trackingArea!)
        }
    }
    open override func updateTrackingAreas() {
        self.addTracking()
    }
    
    open override func mouseExited(with theEvent: NSEvent) {
        self.delegate?.collectionView?(self, mouseMovedToSection: nil)
    }
    
    open override func mouseMoved(with theEvent: NSEvent) {
        super.mouseMoved(with: theEvent)
        if self.scrolling { return }
        let loc = self.contentDocumentView.convert(theEvent.locationInWindow, from: nil)
        self.delegate?.collectionView?(self, mouseMovedToSection: indexPathForSectionAtPoint(loc))
    }

    
    
    
    // MARK: - Mouse Up/Down
    /*-------------------------------------------------------------------------------*/
    
    override open var acceptsFirstResponder : Bool { return true }
    open override func acceptsFirstMouse(for theEvent: NSEvent?) -> Bool { return true }
    open override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        self.delegate?.collectionView?(self, didChangeFirstResponderStatus: true)
        return true
    }
    
    open override func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
        self.delegate?.collectionView?(self, didChangeFirstResponderStatus: false)
        return true
    }
    
    
    
    //    public override func pressureChangeWithEvent(event: NSEvent) {
    //        Swift.print("Pressue: \(event.pressure)  -- \(event.stage)")
    //
    //        if let ip = mouseDownIP {
    //            self.delegate?.collectionView?(self, pressureChanged: CGFloat(event.pressure), forItemAt: ip)
    //        }
    //    }
    
    var mouseDownIP: IndexPath?
    open override func mouseDown(with theEvent: NSEvent) {
        
        self.mouseDownIP = nil
        if let view = self.window?.contentView?.hitTest(theEvent.locationInWindow) , view.isDescendant(of: self.contentDocumentView) == false {
            if view == self.clipView || view.isDescendant(of: self) { self.window?.makeFirstResponder(self) }
            return
        }
        self.window?.makeFirstResponder(self)
        //        self.nextResponder?.mouseDown(theEvent)
        // super.mouseDown(theEvent) DONT DO THIS, it will consume the event and mouse up is not called
        let point = self.contentView.convert(theEvent.locationInWindow, from: nil)
        self.mouseDownIP = self.indexPathForItemAtPoint(point)
        self.delegate?.collectionView?(self, mouseDownInItemAtIndexPath: self.mouseDownIP, withEvent: theEvent)
    }
    
    
    
    
    open override func mouseUp(with theEvent: NSEvent) {
        //        super.mouseUp(theEvent)
        
        if self.draggedIPs.count > 0 {
            self.draggedIPs = []
            return
        }
        
        let point = self.contentView.convert(theEvent.locationInWindow, from: nil)
        let indexPath = self.indexPathForItemAtPoint(point)
        self.delegate?.collectionView?(self, mouseUpInItemAtIndexPath: indexPath, withEvent: theEvent)
        
        if let view = self.window?.contentView?.hitTest(theEvent.locationInWindow) , view.isDescendant(of: self.contentDocumentView) == false && view.isDescendant(of: self._floatingSupplementaryView) == false {
            if view == self.clipView { self.window?.makeFirstResponder(self) }
            return
        }
        
        if mouseDownIP == nil && allowsEmptySelection {
            self._deselectAllItems(true, notify: true)
        }
        
        guard let ip = indexPath , ip == mouseDownIP else { return }
        
        if theEvent.modifierFlags.contains(NSEventModifierFlags.control) {
            self.rightMouseDown(with: theEvent)
            return
        }
        else if allowsMultipleSelection && theEvent.modifierFlags.contains(NSEventModifierFlags.shift) {
            self._selectItemAtIndexPath(ip, atScrollPosition: .nearest, animated: true, selectionType: .extending)
            return
        }
        else if allowsMultipleSelection && theEvent.modifierFlags.contains(NSEventModifierFlags.command) {
            if self._selectedIndexPaths.contains(ip) {
                if self._selectedIndexPaths.count == 1 { return }
                self._deselectItemAtIndexPath(ip, animated: true, notifyDelegate: true)
            }
            else {
                self._selectItemAtIndexPath(ip, animated: true, withEvent: theEvent, notifyDelegate: true)
            }
            return
        }
        else if theEvent.clickCount == 2 {
            self.delegate?.collectionView?(self, didDoubleClickItemAtIndexPath: ip, withEvent: theEvent)
            return
        }
        
        if !self.multiSelect {
            self._deselectAllItems(true, notify: false)
        }
        else if self.itemAtIndexPathIsSelected(ip) {
            self._deselectItemAtIndexPath(ip, animated: true, notifyDelegate: true)
            return
        }
        self._selectItemAtIndexPath(ip, animated: true, scrollPosition: .none, withEvent: theEvent)
    }
    
    open override func rightMouseDown(with theEvent: NSEvent) {
        super.rightMouseDown(with: theEvent)
        if let view = self.window?.contentView?.hitTest(theEvent.locationInWindow) , view.isDescendant(of: self.contentDocumentView) == false {
            return
        }
        
        let point = self.contentView.convert(theEvent.locationInWindow, from: nil)
        if let indexPath = self.indexPathForItemAtPoint(point) {
            self.delegate?.collectionView?(self, didRightClickItemAtIndexPath: indexPath, withEvent: theEvent)
        }
    }
    
    final func moveSelectionInDirection(_ direction: CBCollectionViewDirection, extendSelection: Bool) {
        guard let indexPath = (extendSelection ? _lastSelection : _firstSelection) ?? self._selectedIndexPaths.first else { return }
        if let moveTo = self.collectionViewLayout.indexPathForNextItemInDirection(direction, afterItemAtIndexPath: indexPath) {
            if let move = self.delegate?.collectionView?(self, shouldSelectItemAtIndexPath: moveTo, withEvent: NSApp.currentEvent) , move != true { return }
            self._selectItemAtIndexPath(moveTo, atScrollPosition: .nearest, animated: true, selectionType: extendSelection ? .extending : .single)
        }
    }
    
    open var keySelectInterval: TimeInterval = 0.08
    var lastEventTime : TimeInterval?
    open fileprivate(set) var repeatKey : Bool = false
    
    open override func keyDown(with theEvent: NSEvent) {
        repeatKey = theEvent.isARepeat
        if Set([123,124,125,126]).contains(theEvent.keyCode) {
            
            if theEvent.isARepeat && keySelectInterval > 0 {
                if let t = lastEventTime , (CACurrentMediaTime() - t) < keySelectInterval {
                    //                    Swift.print(CACurrentMediaTime() - t)
                    return
                }
                lastEventTime = CACurrentMediaTime()
            }
            else {
                lastEventTime = nil
            }
            let extend = multiSelect || theEvent.modifierFlags.contains(NSEventModifierFlags.shift)
            if theEvent.keyCode == 123 { self.moveSelectionLeft(extend) }
            else if theEvent.keyCode == 124 { self.moveSelectionRight(extend) }
            else if theEvent.keyCode == 125 { self.moveSelectionDown(extend) }
            else if theEvent.keyCode == 126 { self.moveSelectionUp(extend) }
        }
        else {
            super.keyDown(with: theEvent)
            //            super.interpretKeyEvents([theEvent])
        }
    }
    open override func keyUp(with theEvent: NSEvent) {
        super.keyUp(with: theEvent)
        self.repeatKey = false
    }
    
    
    
    open func moveSelectionLeft(_ extendSelection: Bool) {
        self.moveSelectionInDirection(.left, extendSelection: extendSelection)
    }
    open func moveSelectionRight(_ extendSelection: Bool) {
        self.moveSelectionInDirection(.right, extendSelection: extendSelection)
    }
    open func moveSelectionUp(_ extendSelection: Bool) {
        self.moveSelectionInDirection(.up, extendSelection: extendSelection)
    }
    open func moveSelectionDown(_ extendSelection: Bool) {
        self.moveSelectionInDirection(.down, extendSelection: extendSelection)
    }
    
    
    
    
    // MARK: - Selection options
    /*-------------------------------------------------------------------------------*/
    open var allowsSelection: Bool = true
    
    /// Clicking items always extends the selection, selecting again deselects
    open var multiSelect: Bool = false
    
    /// allows the selection of multiple items via modifier keys (command & shift)
    open var allowsMultipleSelection: Bool = true
    
    /// If true, clicking empty space will deselect all items
    open var allowsEmptySelection: Bool = true
    
    
    
    
    // MARK: - Selections
    /*-------------------------------------------------------------------------------*/
    
    
  
    // Select
    fileprivate var _firstSelection : IndexPath?
    fileprivate var _lastSelection : IndexPath?
    var _selectedIndexPaths = Set<IndexPath>()
    
    // this ensures that only one item can be highlighted at a time
    // Mouse tracking is inconsistent when doing programatic scrolling
    open internal(set) var indexPathForHighlightedItem: IndexPath? {
        didSet {
            //            Swift.print("New: \(indexPathForHighlightedItem)  OLD: \(oldValue)")
            if oldValue == indexPathForHighlightedItem { return }
            if let ip = oldValue, let cell = self.cellForItemAtIndexPath(ip) , cell.highlighted {
                cell.setHighlighted(false, animated: true)
            }
        }
    }
    open func highlightItemAtIndexPath(_ indexPath: IndexPath?, animated: Bool) {
        
        guard let ip = indexPath else {
            self.indexPathForHighlightedItem = nil
            return
        }
        if let cell = self.cellForItemAtIndexPath(ip) {
            cell.setHighlighted(true, animated: animated)
        }
    }
    
    public final func indexPathsForSelectedItems() -> Set<IndexPath> { return _selectedIndexPaths }
    public final func sortedIndexPathsForSelectedItems() -> [IndexPath] {
        return indexPathsForSelectedItems().sorted { (ip1, ip2) -> Bool in
            let before =  ip1._section < ip2._section || (ip1._section == ip2._section && ip1._item < ip2._item)
            return before
        }
    }
    
    public final func itemAtIndexPathIsSelected(_ indexPath: IndexPath) -> Bool {
        return _selectedIndexPaths.contains(indexPath)
    }
    
    
    
    open func selectAllItems(_ animated: Bool = true) {
        self.selectItemsAtIndexPaths(Array(self.contentDocumentView.preparedCellIndex.keys) as [IndexPath], animated: animated)
//        _selectedIndexPaths = Set(self.allIndexPaths())
    }
    open func selectItemsAtIndexPaths(_ indexPaths: [IndexPath], animated: Bool) {
        for ip in indexPaths { self._selectItemAtIndexPath(ip, animated: animated, scrollPosition: .none, withEvent: nil, notifyDelegate: false) }
        if let ip = indexPaths.last {
            self.delegate?.collectionView?(self, didSelectItemAtIndexPath: ip)
        }
    }
    open func selectItemAtIndexPath(_ indexPath: IndexPath?, animated: Bool, scrollPosition: CBCollectionViewScrollPosition = .none) {
        self._selectItemAtIndexPath(indexPath, animated: animated, scrollPosition: scrollPosition, withEvent: nil, notifyDelegate: false)
    }
    
    fileprivate func _selectItemAtIndexPath(_ indexPath: IndexPath?, animated: Bool, scrollPosition: CBCollectionViewScrollPosition = .none, withEvent event: NSEvent?, notifyDelegate: Bool = true) {
        guard let indexPath = indexPath else {
            self.deselectAllItems(animated)
            return
        }
        
        if indexPath._section >= self.info.numberOfSections || indexPath._item >= self.info.numberOfItemsInSection(indexPath._section) { return }
        
        if !self.allowsSelection { return }
        if let shouldSelect = self.delegate?.collectionView?(self, shouldSelectItemAtIndexPath: indexPath, withEvent: event) , !shouldSelect { return }
        
        if self.allowsMultipleSelection == false {
            self._selectedIndexPaths.remove(indexPath)
            self.deselectAllItems()
        }
        
        self.cellForItemAtIndexPath(indexPath)?.setSelected(true, animated: animated)
        self._selectedIndexPaths.insert(indexPath)
        if (multiSelect && event != nil) || self._selectedIndexPaths.count == 1 {
            self._firstSelection = indexPath
        }
        self._lastSelection = indexPath
        if notifyDelegate {
            self.delegate?.collectionView?(self, didSelectItemAtIndexPath: indexPath)
        }
        
        if scrollPosition != .none {
            self.scrollToItemAtIndexPath(indexPath, atScrollPosition: scrollPosition, animated: animated, completion: nil)
        }
    }
    
    
    
    
    // MARK: Multi Select
    /*-------------------------------------------------------------------------------*/
    final func _selectItemAtIndexPath(_ indexPath: IndexPath,
                                      atScrollPosition: CBCollectionViewScrollPosition,
                                      animated: Bool,
                                      selectionType: CBCollectionViewSelectionType) {
        
        var indexesToSelect = Set<IndexPath>()
        
        if selectionType == .single || !self.allowsMultipleSelection {
            indexesToSelect.insert(indexPath)
        }
        else if selectionType == .multiple {
            indexesToSelect.formUnion(self._selectedIndexPaths)
            if indexesToSelect.contains(indexPath) {
                indexesToSelect.remove(indexPath)
            }
            else {
                indexesToSelect.insert(indexPath)
            }
        }
        else {
            let firstIndex = self._firstSelection
            if let index = firstIndex {
                let order = (index as NSIndexPath).compare(indexPath)
                var nextIndex : IndexPath? = firstIndex
                
                while (nextIndex != nil && nextIndex! != indexPath) {
                    indexesToSelect.insert(nextIndex!)
                    if order == ComparisonResult.orderedAscending {
                        nextIndex = self.indexPathForSelectableIndexPathAfter(nextIndex!)
                    }
                    else if order == .orderedDescending {
                        nextIndex = self.indexPathForSelectableIndexPathBefore(nextIndex!)
                    }
                }
            }
            else {
                indexesToSelect.insert(IndexPath.Zero)
            }
            indexesToSelect.insert(indexPath)
        }
        
        
        if !multiSelect {
            var deselectIndexes = self._selectedIndexPaths
            deselectIndexes.removeSet(indexesToSelect)
            self.deselectItemsAtIndexPaths(Array(deselectIndexes), animated: true)
        }
        
        let finalSelect = indexesToSelect.remove(indexPath)
        for ip in indexesToSelect {
            self._selectItemAtIndexPath(ip, animated: true, scrollPosition: .none, withEvent: nil, notifyDelegate: false)
        }
        
        self.scrollToItemAtIndexPath(indexPath, atScrollPosition: atScrollPosition, animated: animated, completion: nil)
        if let ip = finalSelect {
            self._selectItemAtIndexPath(ip, animated: true, scrollPosition: .none, withEvent: nil, notifyDelegate: true)
        }
        
        //        self.delegate?.collectionView?(self, didSelectItemAtIndexPath: indexPath)
        self._lastSelection = indexPath
    }
    
    
    // MARK: - Deselect
    /*-------------------------------------------------------------------------------*/
    open func deselectItemsAtIndexPaths(_ indexPaths: [IndexPath], animated: Bool) {
        for ip in indexPaths { self._deselectItemAtIndexPath(ip, animated: animated, notifyDelegate: false) }
    }
    open func deselectAllItems(_ animated: Bool = false) {
        self._deselectAllItems(animated, notify: false)
    }
    
    final func _deselectAllItems(_ animated: Bool, notify: Bool) {
        var anIP = self._selectedIndexPaths.first
        self._lastSelection = nil
        
        var ips = self._selectedIndexPaths.intersection(Set(self.indexPathsForVisibleItems()))
        
        for ip in ips { self._deselectItemAtIndexPath(ip, animated: animated, notifyDelegate: false) }
        self._selectedIndexPaths.removeAll()
        if notify, let ip = anIP {
            self.delegate?.collectionView?(self, didDeselectItemAtIndexPath: ip)
        }
    }
    
    open func deselectItemAtIndexPath(_ indexPath: IndexPath, animated: Bool) {
        self._deselectItemAtIndexPath(indexPath, animated: animated, notifyDelegate: false)
    }
    
    final func _deselectItemAtIndexPath(_ indexPath: IndexPath, animated: Bool, notifyDelegate : Bool = true) {
        if let deselect = self.delegate?.collectionView?(self, shouldDeselectItemAtIndexPath: indexPath) , !deselect { return }
        contentDocumentView.preparedCellIndex[indexPath]?.setSelected(false, animated: true)
        self._selectedIndexPaths.remove(indexPath)
        if notifyDelegate {
            self.delegate?.collectionView?(self, didDeselectItemAtIndexPath: indexPath)
        }
    }
    
    
    
    // MARK: - Internal
    /*-------------------------------------------------------------------------------*/
    final func validateIndexPath(_ indexPath: IndexPath) -> Bool {
        if self.info.sections[indexPath._section] == nil { return false }
        return indexPath._section < self.info.numberOfSections && indexPath._item < self.info.sections[indexPath._section]!.numberOfItems
    }
    
    final func indexPathForSelectableIndexPathBefore(_ indexPath: IndexPath) -> IndexPath?{
        if (indexPath._item - 1 >= 0) {
            return IndexPath._indexPathForItem(indexPath._item - 1, inSection: indexPath._section)
        }
        else if indexPath._section - 1 >= 0 && self.info.numberOfSections > 0 {
            let numberOfItems = self.info.sections[indexPath._section - 1]!.numberOfItems;
            let newIndexPath = IndexPath._indexPathForItem(numberOfItems - 1, inSection: indexPath._section - 1)
            if self.validateIndexPath(newIndexPath) { return newIndexPath }
        }
        return nil;
    }
    
    final func indexPathForSelectableIndexPathAfter(_ indexPath: IndexPath) -> IndexPath? {
        if (indexPath._item + 1 >= self.info.sections[indexPath._section]?.numberOfItems) {
            // Jump up to the next section
            let newIndexPath = IndexPath._indexPathForItem(0, inSection: indexPath._section+1)
            if self.validateIndexPath(newIndexPath) { return newIndexPath; }
        }
        else {
            return IndexPath._indexPathForItem(indexPath._item + 1, inSection: indexPath._section)
        }
        return nil;
    }
    
    
    // MARK: - Layout Information
    /*-------------------------------------------------------------------------------*/
    
    public final func frameForSection(_ section: Int) -> CGRect? {
        return self.info.sections[section]?.frame
    }
    public final func layoutAttributesForItemAtIndexPath(_ indexPath: IndexPath) -> CBCollectionViewLayoutAttributes? {
        return self.collectionViewLayout.layoutAttributesForItemAtIndexPath(indexPath)
    }
    public final func layoutAttributesForSupplementaryElementOfKind(_ kind: String, atIndexPath indexPath: IndexPath) -> CBCollectionViewLayoutAttributes?  {
        return self.collectionViewLayout.layoutAttributesForSupplementaryViewOfKind(kind, atIndexPath: indexPath)
    }
    
    
    // MARK: - Cells & Index Paths
    /*-------------------------------------------------------------------------------*/
    
    internal final func allIndexPaths() -> Set<IndexPath> { return self.info.allIndexPaths as Set<IndexPath> }
    
    
    
    
    // Visible
    public final func visibleCells() -> [CBCollectionViewCell]  { return Array( self.contentDocumentView.preparedCellIndex.values) }
    public final func indexPathsForVisibleItems() -> [IndexPath]  { return Array(self.contentDocumentView.preparedCellIndex.keys) as [IndexPath] }
    
    // Checking visiblility
    public final func itemAtIndexPathIsVisible(_ indexPath: IndexPath) -> Bool {
        if let frame = self.contentDocumentView.preparedCellIndex[indexPath]?.frame {
            return self.contentVisibleRect.intersects(frame)
        }
        return false
    }
    
    // IP & Cell
    public final func cellForItemAtIndexPath(_ indexPath: IndexPath) -> CBCollectionViewCell?  { return self.contentDocumentView.preparedCellIndex[indexPath] }
    public final func indexPathForCell(_ cell: CBCollectionViewCell) -> IndexPath?  { return cell.indexPath as IndexPath? }
    
    // IP By Location
    open func indexPathForItemAtPoint(_ point: CGPoint) -> IndexPath?  {
        if self.info.numberOfSections == 0 { return nil }
        for sectionIndex in 0..<self.info.numberOfSections {
            guard let sectionInfo = self.info.sections[sectionIndex] else { continue }
            if !sectionInfo.frame.contains(point) || sectionInfo.numberOfItems == 0 { continue }
            
            for itemIndex in 0...sectionInfo.numberOfItems - 1 {
                let indexPath = IndexPath._indexPathForItem(itemIndex, inSection: sectionIndex)
                if let attributes = self.collectionViewLayout.layoutAttributesForItemAtIndexPath(indexPath) {
                    if attributes.frame.contains(point) {
                        return indexPath;
                    }
                }
            }
        }
        return nil;
    }
    open func indexPathsForItemsInRect(_ rect: CGRect) -> Set<IndexPath> {
        if let providedIndexPaths = self.collectionViewLayout.indexPathsForItemsInRect(rect) { return providedIndexPaths }
        if rect.equalTo(CGRect.zero) || self.info.numberOfSections == 0 { return [] }
        var indexPaths = Set<IndexPath>()
        for sectionIndex in 0...self.info.numberOfSections - 1 {
            guard let section = self.info.sections[sectionIndex] else { continue }
            if section.frame.isEmpty || !section.frame.intersects(rect) { continue }
            for item in 0...section.numberOfItems - 1 {
                let indexPath = IndexPath._indexPathForItem(item, inSection: sectionIndex)
                if let attributes = self.collectionViewLayout.layoutAttributesForItemAtIndexPath(indexPath) {
                    if (attributes.frame.intersects(rect)) {
                        indexPaths.insert(indexPath)
                    }
                }
            }
        }
        return indexPaths
    }
    
    // Rect for item
    internal final func rectForItemAtIndexPath(_ indexPath: IndexPath) -> CGRect? {
        if indexPath._section < self.info.numberOfSections {
            let attributes = self.collectionViewLayout.layoutAttributesForItemAtIndexPath(indexPath);
            return attributes?.frame;
        }
        return nil
    }
    
    
    // MARK: - Supplementary Views & Index Paths
    /*-------------------------------------------------------------------------------*/
    
    public final func indexPathForSectionAtPoint(_ point: CGPoint) -> IndexPath? {
        for sectionIndex in 0..<self.info.numberOfSections {
            guard let sectionInfo = self.info.sections[sectionIndex] else { continue }
            var frame = sectionInfo.frame
            frame.origin.x = 0
            frame.size.width = self.bounds.size.width
            if frame.contains(point) {
                return IndexPath._indexPathForItem(0, inSection: sectionIndex)
            }
        }
        return nil
    }
    
    public final func indexPathForSupplementaryView(_ view: CBCollectionReusableView) -> IndexPath? { return view.indexPath as IndexPath? }
    
    public final func viewForSupplementaryViewOfKind(_ kind: String, atIndexPath: IndexPath) -> CBCollectionReusableView? {
        let id = SupplementaryViewIdentifier(kind: kind, reuseIdentifier: "", indexPath: atIndexPath)
        return self.contentDocumentView.preparedSupplementaryViewIndex[id]
    }
    
    internal final func _identifiersForSupplementaryViewsInRect(_ rect: CGRect) -> Set<SupplementaryViewIdentifier> {
        var visibleIdentifiers = Set<SupplementaryViewIdentifier>()
        if rect.equalTo(CGRect.zero) { return [] }
        for sectionInfo in self.info.sections {
            if !sectionInfo.1.frame.intersects(rect) { continue }
            for kind in self._registeredSupplementaryViewKinds {
                let ip = IndexPath._indexPathForItem(0, inSection: sectionInfo.1.section)
                if let attrs = self.collectionViewLayout.layoutAttributesForSupplementaryViewOfKind(kind, atIndexPath: ip) {
                    if attrs.frame.intersects(rect) {
                        visibleIdentifiers.insert(SupplementaryViewIdentifier(kind: kind, reuseIdentifier: "", indexPath: ip))
                    }
                }
            }
        }
        return visibleIdentifiers
    }
    
    
    
    // MARK: - Programatic Scrolling
    open func scrollToItemAtIndexPath(_ indexPath: IndexPath, atScrollPosition scrollPosition: CBCollectionViewScrollPosition, animated: Bool, completion: CBAnimationCompletion?) {
        if self.info.numberOfItemsInSection(indexPath._section) < indexPath._item { return }
        if let shouldScroll = self.delegate?.collectionView?(self, shouldScrollToItemAtIndexPath: indexPath) , shouldScroll != true {
            completion?(false)
            return
        }
        
        guard let rect = self.collectionViewLayout.scrollRectForItemAtIndexPath(indexPath, atPosition: scrollPosition) ?? self.rectForItemAtIndexPath(indexPath) else {
            completion?(false)
            return
        }
        
        self.scrollToRect(rect, atPosition: scrollPosition, animated: animated, completion: { fin in
            completion?(fin)
            self.delegate?.collectionView?(self, didScrollToItemAtIndexPath: indexPath)
        })
    }
    
    open func scrollToRect(_ aRect: CGRect, atPosition: CBCollectionViewScrollPosition, animated: Bool, completion: CBAnimationCompletion?) {
        self._scrollToRect(aRect, atPosition: atPosition, animated: animated, prepare: true, completion: completion)
    }
    
    open func _scrollToRect(_ aRect: CGRect, atPosition: CBCollectionViewScrollPosition, animated: Bool, prepare: Bool, completion: CBAnimationCompletion?) {
        var rect = aRect
        
        let visibleRect = self.contentVisibleRect
        switch atPosition {
        case .top:
            // make the top of our rect flush with the top of the visible bounds
            rect.size.height = visibleRect.height - contentInsets.top;
            rect.origin.y = aRect.origin.y - contentInsets.top;
            break;
        case .centered:
            // TODO
            rect.size.height = self.bounds.size.height;
            rect.origin.y += (visibleRect.height / 2.0) - rect.height;
            break;
        case .bottom:
            // make the bottom of our rect flush with the bottom of the visible bounds
            rect.size.height = visibleRect.height;
            rect.origin.y -= visibleRect.height - contentInsets.top;
            break;
        case .none:
            // no scroll needed
            completion?(true)
            return;
        case .nearest:
            if visibleRect.contains(rect) {
                completion?(true)
                return
            }
            
            if rect.origin.y < visibleRect.origin.y {
                rect = visibleRect.offsetBy(dx: 0, dy: rect.origin.y - visibleRect.origin.y - self.contentInsets.top)
            }
            else if rect.maxY >  visibleRect.maxY {
                rect = visibleRect.offsetBy(dx: 0, dy: rect.maxY - visibleRect.maxY + self.contentInsets.top)
            }
            // We just pass the cell's frame onto the scroll view. It calculates this for us.
            break;
        }
        if prepare {
            self.contentDocumentView.prepareRect(rect.union(visibleRect), force: false)
        }
        self.clipView?.scrollRectToVisible(rect, animated: animated, completion: completion)
    }
    

    
    
    // MARK: - Dragging Source
    var draggedIPs : [IndexPath] = []
    
    public final func indexPathsForDraggingItems() -> [IndexPath] { return draggedIPs }
    
    override open func mouseDragged(with theEvent: NSEvent) {
        super.mouseDragged(with: theEvent)
        self.window?.makeFirstResponder(self)
        self.draggedIPs = []
        var items : [NSDraggingItem] = []
        
        if mouseDownIP == nil { return }
        
        if self.interactionDelegate?.collectionView?(self, shouldBeginDraggingAtIndexPath: mouseDownIP!, withEvent: theEvent) != true { return }
        
        let ips = self.indexPathsForSelectedItems().sorted { (ip1, ip2) -> Bool in
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
                
//                UnsafeMutablePointer<CGRect>
                let originalFrame = UnsafeMutablePointer<CGRect>.allocate(capacity: 1)
                let oFrame = self.convert( rect, from: self.documentView)
                originalFrame.initialize(to: oFrame)
                self.dataSource?.collectionView?(self, dragRectForItemAtIndexPath: ip, withStartingRect: originalFrame)
                let frame = originalFrame.pointee
                
                self.draggedIPs.append(ip)
                let item = NSDraggingItem(pasteboardWriter: writer)
                item.draggingFrame = frame
                
                if self.itemAtIndexPathIsVisible(ip) {
                    item.imageComponentsProvider = { () -> [NSDraggingImageComponent] in
                        
                        var image = self.dataSource?.collectionView?(self, dragContentsForItemAtIndexPath: ip)
                        if image == nil, let cell = self.cellForItemAtIndexPath(ip) {
                            image = NSImage(data: cell.dataWithPDF(inside: cell.bounds))
                        }
                        let comp = NSDraggingImageComponent(key: NSDraggingImageComponentIconKey)
                        comp.contents = image
                        comp.frame = CGRect(origin: CGPoint.zero, size: frame.size)
                        return [comp]
                    }
                }
            
                items.append(item)
            }
        }
        
        if items.count > 0 {
            let session = self.beginDraggingSession(with: items, event: theEvent, source: self)
            if items.count > 1 {
                session.draggingFormation = .pile
            }
        }
    }
    
    open func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        if context == NSDraggingContext.outsideApplication { return .copy }
        return .move
    }
    
    open func draggingSession(_ session: NSDraggingSession, willBeginAt screenPoint: NSPoint) {
        self.interactionDelegate?.collectionView?(self, draggingSession: session, willBeginAtPoint: screenPoint)
    }
    
    open func draggingSession(_ session: NSDraggingSession, movedTo screenPoint: NSPoint) {
        self.interactionDelegate?.collectionView?(self, draggingSession: session, didMoveToPoint: screenPoint)
    }
    
    open func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
//        self.mouseDownIP = nil
        self.interactionDelegate?.collectionView?(self, draggingSession: session, enedAtPoint: screenPoint, withOperation: operation, draggedIndexPaths: draggedIPs)
    }
    
    
    // MARK: - Draggng Destination
    open override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if let operation = self.interactionDelegate?.collectionView?(self, dragEntered: sender) {
            return operation
        }
        return NSDragOperation()
    }
    open override func draggingExited(_ sender: NSDraggingInfo?) {
        self.interactionDelegate?.collectionView?(self, dragExited: sender)
    }
    open override func draggingEnded(_ sender: NSDraggingInfo?) {
        self.interactionDelegate?.collectionView?(self, dragEnded: sender)
    }
    open override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        if let operation = self.interactionDelegate?.collectionView?(self, dragUpdated: sender) {
            return operation
        }
        return sender.draggingSourceOperationMask()
    }
    open override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if let perform = self.interactionDelegate?.collectionView?(self, performDragOperation: sender) {
            return perform
        }
        return false
    }
    
}

