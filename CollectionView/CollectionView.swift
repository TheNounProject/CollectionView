//
//  CollectionView.swift
//  Lingo
//
//  Created by Wesley Byrne on 1/27/16.
//  Copyright © 2016 The Noun Project. All rights reserved.
//

import Foundation

open class CollectionView : ScrollView, NSDraggingSource {
    
    public var contentDocumentView : CollectionViewDocumentView {
        return self.documentView as! CollectionViewDocumentView
    }
    open override var mouseDownCanMoveWindow: Bool { return true }
    
    
    
    // MARK: - Data Source & Delegate
    open weak var delegate : CollectionViewDelegate?
    open weak var dataSource : CollectionViewDataSource?
    fileprivate weak var interactionDelegate : CollectionViewInteractionDelegate? {
        return self.delegate as? CollectionViewInteractionDelegate
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
        
//        self.acceptsTouchEvents = true
        collectionViewLayout.collectionView = self
        self.info = CollectionViewInfo(collectionView: self)
        self.wantsLayer = true
        let dView = CollectionViewDocumentView()
        dView.wantsLayer = true
        self.documentView = dView
        self.hasVerticalScroller = true
        self.scrollsDynamically = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(CollectionView.didScroll(_:)), name: NSNotification.Name.NSScrollViewDidLiveScroll, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(CollectionView.willBeginScroll(_:)), name: NSNotification.Name.NSScrollViewWillStartLiveScroll, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(CollectionView.didEndScroll(_:)), name: NSNotification.Name.NSScrollViewDidEndLiveScroll, object: self)
        
        // NSNotification.Name.NSPreferredScrollerStyleDidChange
        
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

    open override var scrollerStyle: NSScrollerStyle {
        didSet {
            Swift.print("Scroller Style changed")
            self.relayout(false)
        }
    }
    
    open override var wantsUpdateLayer: Bool { return true }
    
    open override func updateLayer() {
        super.updateLayer()
        super.wantsUpdateLayer
        self.layer?.backgroundColor = self.drawsBackground ? self.backgroundColor.cgColor : nil
    }
    
    
    // MARK: - Registering reusable cells
    /*-------------------------------------------------------------------------------*/
    
    fileprivate var _cellClasses : [String:CollectionViewCell.Type] = [:]
    fileprivate var _cellNibs : [String:NSNib] = [:]
    
    fileprivate var _supplementaryViewClasses : [SupplementaryViewIdentifier:CollectionReusableView.Type] = [:]
    fileprivate var _supplementaryViewNibs : [SupplementaryViewIdentifier:NSNib] = [:]
    
    open func registerClass(_ cellClass: CollectionViewCell.Type, forCellWithReuseIdentifier identifier: String) {
        assert(cellClass.isSubclass(of: CollectionViewCell.self), "CollectionView: Registered cells views must be subclasses of CollectionViewCell")
        assert(!identifier.isEmpty, "CollectionView: Reuse identifier cannot be an empty or blank string")
        self._cellClasses[identifier] = cellClass
        self._cellNibs[identifier] = nil
    }
    open func registerNib(_ nib: NSNib, forCellWithReuseIdentifier identifier: String) {
        assert(!identifier.isEmpty, "CollectionView: Reuse identifier cannot be an empty or blank string")
        self._cellClasses[identifier] = nil
        self._cellNibs[identifier] = nib
    }
    open func registerClass(_ viewClass: CollectionReusableView.Type, forSupplementaryViewOfKind kind: String, withReuseIdentifier identifier: String) {
        assert(viewClass.isSubclass(of: CollectionReusableView.self), "CollectionView: Registered supplementary views must be subclasses of CollectionReusableview")
        assert(!identifier.isEmpty, "CollectionView: Reuse identifier cannot be an empty or blank string")
        let id = SupplementaryViewIdentifier(kind: kind, reuseIdentifier: identifier)
        self._supplementaryViewClasses[id] = viewClass
        self._supplementaryViewNibs[id] = nil
        self._registeredSupplementaryViewKinds.insert(kind)
        self._allSupplementaryViewIdentifiers.insert(id)
    }
    open func registerNib(_ nib: NSNib, forSupplementaryViewOfKind kind: String, withReuseIdentifier identifier: String) {
        assert(!identifier.isEmpty, "CollectionView: Reuse identifier cannot be an empty or blank string")
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
        }
        assert(foundObject != nil, "CollectionView: Could not find view of type \(aClass) in nib. Make sure the top level object in the nib is of this type.")
        return foundObject as? NSView
    }
    
    
    
    
    // MARK: - Dequeing reusable cells
    /*-------------------------------------------------------------------------------*/
    
    fileprivate var _reusableCells : [String:Set<CollectionViewCell>] = [:]
    fileprivate var _reusableSupplementaryView : [SupplementaryViewIdentifier:[CollectionReusableView]] = [:]
    
    public final func dequeueReusableCellWithReuseIdentifier(_ identifier: String, forIndexPath indexPath: IndexPath) -> CollectionViewCell {
        
        var cell =  self._reusableCells[identifier]?.first
        if cell == nil {
            if let nib = self._cellNibs[identifier] {
                cell = _firstObjectOfClass(CollectionViewCell.self, inNib: nib) as? CollectionViewCell
            }
            else if let aClass = self._cellClasses[identifier] {
                cell = aClass.init()
            }
            assert(cell != nil, "CollectionView: No cell could be dequed with identifier '\(identifier) for item: \(indexPath._item) in section \(indexPath._section)'. Make sure you have registered your cell class or nib for that identifier.")
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
    public final func dequeueReusableSupplementaryViewOfKind(_ elementKind: String, withReuseIdentifier identifier: String, forIndexPath indexPath: IndexPath) -> CollectionReusableView {
        let id = SupplementaryViewIdentifier(kind: elementKind, reuseIdentifier: identifier)
        var view = self._reusableSupplementaryView[id]?.first
        if view == nil {
            if let nib = self._supplementaryViewNibs[id] {
                view = _firstObjectOfClass(CollectionReusableView.self, inNib: nib) as? CollectionReusableView
            }
            else if let aClass = self._supplementaryViewClasses[id] {
                view = aClass.init()
            }
            assert(view != nil, "CollectionView: No view could be dequed for supplementary view of kind \(elementKind) with identifier '\(identifier) in section \(indexPath._section)'. Make sure you have registered your view class or nib for that identifier.")
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
    
    final func enqueueCellForReuse(_ item: CollectionViewCell) {
        item.isHidden = true
        item.indexPath = nil
        guard let id = item.reuseIdentifier else { return }
        if self._reusableCells[id] == nil {
            self._reusableCells[id] = []
        }
        self._reusableCells[id]?.insert(item)
    }
    
    final func enqueueSupplementaryViewForReuse(_ item: CollectionReusableView, withIdentifier: SupplementaryViewIdentifier) {
        item.isHidden = true
        item.indexPath = nil
        let newID = SupplementaryViewIdentifier(kind: withIdentifier.kind, reuseIdentifier: item.reuseIdentifier ?? withIdentifier.reuseIdentifier)
        if self._reusableSupplementaryView[newID] == nil {
            self._reusableSupplementaryView[newID] = []
        }
        self._reusableSupplementaryView[newID]?.append(item)
    }
    
    final func _loadCell(at indexPath: IndexPath) -> CollectionViewCell? {
        guard let cell = self.contentDocumentView.preparedCellIndex[indexPath] ?? self.dataSource?.collectionView(self, cellForItemAtIndexPath: indexPath) else {
            debugPrint("For some reason collection view tried to load cells without a data source")
            return nil
        }
        assert(cell.collectionView != nil, "Attemp to load cell without using deque")
        return cell
    }
    
    
    // MARK: - Data
    fileprivate var info : CollectionViewInfo!
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
    
    open var collectionViewLayout : CollectionViewLayout = CollectionViewLayout() {
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
            self.isScrollEnabled = true
            self.clipView?.shouldAnimateOriginChange = false
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
        
        if self.collectionViewLayout.shouldInvalidateLayoutForBoundsChange(self.documentVisibleRect) {
            let _size = self.info.contentSize
            
            self.info.recalculate()
            
            contentDocumentView.frame.size = self.collectionViewLayout.collectionViewContentSize()
            //self.info.contentSize.height != _size.height,
            if let ip = _topIP, var rect = self.collectionViewLayout.scrollRectForItemAtIndexPath(ip, atPosition: CollectionViewScrollPosition.top) {
                
                if self.collectionViewLayout.scrollDirection == .vertical {
                    rect = CGRect(origin: rect.origin, size: self.bounds.size)
                    rect.origin.x = self.contentInsets.left
                }
                else {
                    rect = CGRect(origin: rect.origin, size: self.bounds.size)
//                    rect.origin.y = self.contentInsets.top
                }
                
                _ = self.clipView?.scrollRectToVisible(rect, animated: false, completion: nil)
            }
            self.reflectScrolledClipView(self.clipView!)
            self.contentDocumentView.prepareRect(prepareAll ? contentDocumentView.frame : self.contentVisibleRect, force: true)
        }
    }
    
    
    /**
     Trigger the collection view to relayout all items
     
     - parameter animated:       If the layout should be animated
     - parameter scrollPosition: Where (if any) the scroll position should be pinned
     */
    open func relayout(_ animated: Bool, scrollPosition: CollectionViewScrollPosition = .nearest, completion: AnimationCompletion? = nil) {
        
        var absoluteCellFrames = [CollectionReusableView:CGRect]()
        
        for cell in self.contentDocumentView.preparedCellIndex {
            absoluteCellFrames[cell.1] = self.convert(cell.1.frame, from: cell.1.superview)
        }
        for cell in self.contentDocumentView.preparedSupplementaryViewIndex {
            absoluteCellFrames[cell.1] = self.convert(cell.1.frame, from: cell.1.superview)
        }
    
        let holdIP : IndexPath? = self.indexPathForFirstVisibleItem()
            //?? self.indexPathsForSelectedItems().intersect(self.indexPathsForVisibleItems()).first

        self.info.recalculate()
       
        let nContentSize = self.info.contentSize
        contentDocumentView.frame.size = nContentSize
        
        if scrollPosition != .none, let ip = holdIP, let rect = self.collectionViewLayout.scrollRectForItemAtIndexPath(ip, atPosition: scrollPosition) ?? self.rectForItemAtIndexPath(ip) {
            self._scrollToRect(rect, atPosition: scrollPosition, animated: false, prepare: false, completion: nil)
        }
        self.reflectScrolledClipView(self.clipView!)
        
        for item in absoluteCellFrames {
            if let attrs = item.0.attributes , attrs.representedElementCategory == CollectionElementCategory.supplementaryView {
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
    
//    open override func touchesEnded(with event: NSEvent) {
//        super.touchesEnded(with: event)
//        if self.isScrolling {
//            Swift.print(" ended: \(event)")
//        }
//        
//    }
    
    
    // MARK: - Scroll Handling
    /*-------------------------------------------------------------------------------*/
    override open class func isCompatibleWithResponsiveScrolling() -> Bool { return true }
    
    open var isScrollEnabled : Bool {
        set { self.clipView?.scrollEnabled = newValue }
        get { return self.clipView?.scrollEnabled ?? true }
    }
    open internal(set) var isScrolling : Bool = false
    
    fileprivate var _previousOffset = CGPoint.zero
    fileprivate var _offsetMark = CACurrentMediaTime()
    
    open fileprivate(set) var scrollVelocity = CGPoint.zero
    open fileprivate(set) var peakScrollVelocity = CGPoint.zero
    
    var _rectToPrepare : CGRect {
        return prepareAll
            ?  CGRect(origin: CGPoint.zero, size: self.info.contentSize)
            : self.contentVisibleRect.insetBy(dx: 0, dy: -100)
    }
    
    final func didScroll(_ notification: Notification) {
        let rect = _rectToPrepare
        self.contentDocumentView.prepareRect(rect)
        
        let _prev = self._previousOffset
        self._previousOffset = self.contentVisibleRect.origin
        let deltaY = _prev.y - self._previousOffset.y
        let deltaX = _prev.x - self._previousOffset.x
        
        self.scrollVelocity = CGPoint(x: deltaX, y: deltaY)
        
//        Swift.print("Did scroll : \(self.contentOffset)")
        
        self.peakScrollVelocity = peakScrollVelocity.maxVelocity(self.scrollVelocity)
        self._offsetMark = CACurrentMediaTime()
        self.delegate?.collectionViewDidScroll?(self)
    }
    
    final func willBeginScroll(_ notification: Notification) {
        self.isScrolling = true
        self.delegate?.collectionViewWillBeginScrolling?(self)
        self._previousOffset = self.contentVisibleRect.origin
        self.peakScrollVelocity = CGPoint.zero
        self.scrollVelocity = CGPoint.zero
    }
    
    final func didEndScroll(_ notification: Notification) {
        self.isScrolling = false
        
//        Swift.print("End scroll : \(self.contentOffset)")
        
        self.delegate?.collectionViewDidEndScrolling?(self, animated: true)
        self.scrollVelocity = CGPoint.zero
        self.peakScrollVelocity = CGPoint.zero
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
        visibleRect.origin.x += self.contentInsets.left
        visibleRect.size.height -= (self.contentInsets.top + self.contentInsets.bottom)
        visibleRect.size.width -= (self.contentInsets.left + self.contentInsets.right)
        
        var closest : IndexPath?
        for sectionIndex in 0..<self.info.numberOfSections  {
            guard let section = self.info.sections[sectionIndex] else { continue }
            if section.frame.isEmpty || !section.frame.intersects(visibleRect) { continue }
            for item in 0..<section.numberOfItems {
                let indexPath = IndexPath.for(item:item, section: sectionIndex)
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
    
    
    
    
    // MARK: - Manipulating Sections
    /*-------------------------------------------------------------------------------*/
    
    
    public func reloadSections(_ sections: IndexSet, animated: Bool) {
        
    }
    
    public func insertSections(_ sections: IndexSet, animated: Bool) {
        self.indexPathForHighlightedItem = nil
        
        var sections = sections
        var changeMap = [(newIP: IndexPath, cell: CollectionViewCell)]()
        
        let cCount = self.numberOfSections()
        var newSection = 0
        
        for sec in 0..<cCount {
            
            while let nSec = sections.first , nSec <= sec {
                sections.remove(nSec)
                newSection += 1
            }
            if newSection != sec {
                for index in 0..<numberOfItemsInSection(sec) {
                    let ip = IndexPath.for(item:index, section: sec)
                    if let cell = self.contentDocumentView.preparedCellIndex.removeValue(forKey: ip) {
                        let newIP = IndexPath.for(item:index, section: newSection)
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
        _ = _selectedIndexPaths.removeSet(updatedSelections)
        _selectedIndexPaths.formUnion(movedSelections)
        
        if batchUpdating { return }
        
        self.relayout(true, scrollPosition: .none)
        self.delegate?.collectionViewDidReloadData?(self)
    }
    
    
    
    
    public func moveSection(_ section: Int, to newSection: Int, animated: Bool) {
        self.deleteSections(IndexSet(integer: section), animated: animated)
        self.insertSections(IndexSet(integer: section), animated: animated)
    }
    
    
    public func deleteSections(_ sections: IndexSet, animated: Bool) {
        self.indexPathForHighlightedItem = nil
        
        var updates = [ItemUpdate]()
        var cellMap = [(newIP: IndexPath, cell: CollectionViewCell)]()
        var viewMap = [(id: SupplementaryViewIdentifier, view: CollectionReusableView)]()
        
        let cCount = self.numberOfSections()
        
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
            if let rSec = sections.first , rSec == sec {
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
                        let ip = IndexPath.for(section:newSection)
                        var s = supp
                        s.indexPath = ip
                        viewMap.append((id: s, view: view))
                    }
                }
                for ip in items.cells {
                    if let view = contentDocumentView.preparedCellIndex.removeValue(forKey: ip) {
                        let ip = IndexPath.for(item: ip._item, section: newSection)
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
        _ = _selectedIndexPaths.removeSet(updatedSelections)
        _selectedIndexPaths.formUnion(movedSelections)
        
        if batchUpdating { return }
        
        self.relayout(true, scrollPosition: .none)
        self.delegate?.collectionViewDidReloadData?(self)

    }
    

    
    
    // MARK: - Manipulating items
    /*-------------------------------------------------------------------------------*/
    
    public func reloadItems(at indexPaths: [IndexPath], animated: Bool) {
        
        var removals = [ItemUpdate]()
        for indexPath in indexPaths {
            guard let cell = self.cellForItemAtIndexPath(indexPath) else {
                debugPrint("Not reloading cell because it is not visible")
                return
            }
            guard let newCell = self.dataSource?.collectionView(self, cellForItemAtIndexPath: indexPath) else {
                debugPrint("For some reason collection view tried to load cells without a data source")
                return
            }
            assert(newCell.collectionView != nil, "Attempt to load cell without using deque:")
            
            let attrs = self.collectionViewLayout.layoutAttributesForItemAtIndexPath(indexPath)
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

    
    
    public func insertItems(at indexPaths: [IndexPath], animated: Bool) {
        
        self.indexPathForHighlightedItem = nil
        
        let sorted = indexPaths.sorted { (ip1, ip2) -> Bool in
            return ip1._item < ip2._item
        }
        
        var newBySection = [Int:[IndexPath]]()
        
        for ip in sorted {
            if newBySection[ip._section] == nil { newBySection[ip._section] = [ip] }
            else { newBySection[ip._section]?.append(ip) }
        }
        
        var changeMap = [(newIP: IndexPath, cell: CollectionViewCell)]()
        for s in newBySection {
            let sectionIndex = s.0
            var newIps = s.1
            
            let cCount = self.numberOfItemsInSection(sectionIndex)
            
            var newIndex = 0
            
            for idx in 0..<cCount {
                while let nIP = newIps.first , nIP._item == newIndex {
                    newIps.removeFirst()
                    newIndex += 1
                }
                
                let old = IndexPath.for(item:idx, section: sectionIndex)
                if newIndex != idx, let cell = self.contentDocumentView.preparedCellIndex.removeValue(forKey: old) {
                    let new = IndexPath.for(item:newIndex, section: sectionIndex)
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
        _ = _selectedIndexPaths.removeSet(updatedSelections)
        _selectedIndexPaths.formUnion(movedSelections)
        
        if batchUpdating { return }
        
        self.relayout(true, scrollPosition: .none)
        self.delegate?.collectionViewDidReloadData?(self)
    }
    

    
    
    public func moveItem(at indexPath : IndexPath, to destinationIndexPath: IndexPath, animated: Bool) {
        
        guard let attrs = self.collectionViewLayout.layoutAttributesForItemAtIndexPath(destinationIndexPath) else { return }
        
        guard self.contentDocumentView.preparedCellIndex[indexPath] != nil || self.contentVisibleRect.intersects(attrs.frame) else {
            debugPrint("Not processing item move because the item is and will not be visible.")
            return
        }
        
        guard let cell = self._loadCell(at: destinationIndexPath) else {
            return
        }
        
        if animated {
            attrs.alpha = 0
        }
        let update = ItemUpdate(view: cell, attrs: cell.attributes!, type: .update)
        
        cell.indexPath = indexPath
        
    
        cell.applyLayoutAttributes(attrs, animated: false)
        
        if cell.superview == nil {
            self.contentDocumentView.addSubview(cell)
        }
        cell.selected = self._selectedIndexPaths.contains(indexPath)
        
        self.contentDocumentView.preparedCellIndex[indexPath] = cell
        cell.viewDidDisplay()
        
        self.contentDocumentView.pendingUpdates.append(update)
        if batchUpdating { return }
        self.relayout(animated, scrollPosition: .none)
        
    }
    
    

    
    
    
    public func deleteItems(at indexPaths: [IndexPath], animated: Bool) {
        
        self.indexPathForHighlightedItem = nil
        
        var bySection = [Int:[IndexPath]]()
        
        let sorted = indexPaths.sorted { (ip1, ip2) -> Bool in return ip1._item < ip2._item }
        for ip in sorted {
            if bySection[ip._section] == nil { bySection[ip._section] = [ip] }
            else { bySection[ip._section]?.append(ip) }
        }
        
        var updates = [ItemUpdate]()
        var changeMap = [(newIP: IndexPath, cell: CollectionViewCell)]()
        
        for s in bySection {
            let sectionIndex = s.0
            var removeIPs = s.1
            
            let cCount = self.numberOfItemsInSection(sectionIndex)
    
            var newIndex = 0
            
            for idx in 0..<cCount {
                if let dIP = removeIPs.first , dIP._item == idx,
                let cell = self.contentDocumentView.preparedCellIndex.removeValue(forKey: dIP),
                let attrs = cell.attributes {
                    removeIPs.removeFirst()
                    updates.append(ItemUpdate(view: cell, attrs: attrs, type: .remove))
                    continue
                }
                
                let old = IndexPath.for(item:idx, section: sectionIndex)
                if newIndex != idx, let cell = self.contentDocumentView.preparedCellIndex.removeValue(forKey: old) {
                    let new = IndexPath.for(item:newIndex, section: sectionIndex)
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
        
        _ = _selectedIndexPaths.removeSet(updatedSelections)
        _selectedIndexPaths.formUnion(movedSelections)
        
        if batchUpdating { return }
        
        self.relayout(true, scrollPosition: .none)
        self.delegate?.collectionViewDidReloadData?(self)
    }
    

    
    
    fileprivate var batchUpdating : Bool = false
    open var animationDuration: TimeInterval = 0.4

    open func performBatchUpdates(_ updates: (()->Void), completion: AnimationCompletion?) {
        
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
        if self.isScrolling { return }
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
    
    
    private func acceptClickEvent(_ event: NSEvent) -> Bool {
        if let view = self.window?.contentView?.hitTest(event.locationInWindow) , view.isDescendant(of: self.contentDocumentView) == false {
            if view == self.clipView || view.isDescendant(of: self) { self.window?.makeFirstResponder(self) }
            return false
        }
        return true
    }
    
    var mouseDownIP: IndexPath?
    open override func mouseDown(with theEvent: NSEvent) {
        
        self.mouseDownIP = nil
        guard acceptClickEvent(theEvent) else {
            return
        }
        
//        if let view = self.window?.contentView?.hitTest(theEvent.locationInWindow) , view.isDescendant(of: self.contentDocumentView) == false {
//            if view == self.clipView || view.isDescendant(of: self) { self.window?.makeFirstResponder(self) }
//            return
//        }
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
        
        guard self.acceptClickEvent(theEvent) else { return }
        
//        if let view = self.window?.contentView?.hitTest(theEvent.locationInWindow) , view.isDescendant(of: self.contentDocumentView) == false && view.isDescendant(of: self._floatingSupplementaryView) == false {
//            if view == self.clipView { self.window?.makeFirstResponder(self) }
//            return
//        }
        
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
        
        if self.selectionMode != .multi {
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
        
        guard self.acceptClickEvent(theEvent) else { return }
        
//        if let view = self.window?.contentView?.hitTest(theEvent.locationInWindow) , view.isDescendant(of: self.contentDocumentView) == false {
//            return
//        }
        
        let point = self.contentView.convert(theEvent.locationInWindow, from: nil)
        if let indexPath = self.indexPathForItemAtPoint(point) {
            self.delegate?.collectionView?(self, didRightClickItemAtIndexPath: indexPath, withEvent: theEvent)
        }
    }
    
    final func moveSelectionInDirection(_ direction: CollectionViewDirection, extendSelection: Bool) {
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
            let extend = selectionMode == .multi || theEvent.modifierFlags.contains(NSEventModifierFlags.shift)
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
    
    
    /// How clicking an item is handled
    ///
    /// - normal: Clicking an item selects the item and deselects others (given no modifier keys are used)
    /// - multi: Clicking an item will add it to the selection, clicking again will deselect it
    public enum SelectionMode {
        case normal
        case multi
    }
    
    /// Determines what happens when an item is clicked
    open var selectionMode: SelectionMode = .normal
    
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
    }

    open func selectItemsAtIndexPaths(_ indexPaths: [IndexPath], animated: Bool) {
        for ip in indexPaths { self._selectItemAtIndexPath(ip, animated: animated, scrollPosition: .none, withEvent: nil, notifyDelegate: false) }
        //        if let ip = indexPaths.last {
        //            self.delegate?.collectionView?(self, didSelectItemAtIndexPath: ip)
        //        }
    }
    
    
    open func selectItemAtIndexPath(_ indexPath: IndexPath?, animated: Bool, scrollPosition: CollectionViewScrollPosition = .none) {
        self._selectItemAtIndexPath(indexPath, animated: animated, scrollPosition: scrollPosition, withEvent: nil, notifyDelegate: false)
    }
    
    fileprivate func _selectItemAtIndexPath(_ indexPath: IndexPath?, animated: Bool, scrollPosition: CollectionViewScrollPosition = .none, withEvent event: NSEvent?, notifyDelegate: Bool = true) {
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
        if (selectionMode == .multi && event != nil) || self._selectedIndexPaths.count == 1 {
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
                                      atScrollPosition: CollectionViewScrollPosition,
                                      animated: Bool,
                                      selectionType: CollectionViewSelectionType) {
        
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
                
                while let idx = nextIndex, idx != indexPath {
                    indexesToSelect.insert(idx)
                    if order == ComparisonResult.orderedAscending {
                        nextIndex = self.indexPathForSelectableIndexPathAfter(idx)
                    }
                    else if order == .orderedDescending {
                        nextIndex = self.indexPathForSelectableIndexPathBefore(idx)
                    }
                }
            }
            else {
                indexesToSelect.insert(IndexPath.Zero)
            }
            indexesToSelect.insert(indexPath)
        }
        
        
        if selectionMode != .multi {
            var deselectIndexes = self._selectedIndexPaths
            _ = deselectIndexes.removeSet(indexesToSelect)
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
        let anIP = self._selectedIndexPaths.first
        self._lastSelection = nil
        
        let ips = self._selectedIndexPaths.intersection(Set(self.indexPathsForVisibleItems()))
        
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
            return IndexPath.for(item: indexPath._item - 1, section: indexPath._section)
        }
        else if indexPath._section - 1 >= 0 && self.info.numberOfSections > 0 {
            let numberOfItems = self.info.sections[indexPath._section - 1]!.numberOfItems;
            let newIndexPath = IndexPath.for(item: numberOfItems - 1, section: indexPath._section - 1)
            if self.validateIndexPath(newIndexPath) { return newIndexPath }
        }
        return nil;
    }
    
    final func indexPathForSelectableIndexPathAfter(_ indexPath: IndexPath) -> IndexPath? {
        if indexPath._item + 1 >= numberOfItemsInSection(indexPath._section) {
            // Jump up to the next section
            let newIndexPath = IndexPath.for(item:0, section: indexPath._section+1)
            if self.validateIndexPath(newIndexPath) { return newIndexPath; }
        }
        else {
            return IndexPath.for(item: indexPath._item + 1, section: indexPath._section)
        }
        return nil;
    }
    
    
    // MARK: - Layout Information
    /*-------------------------------------------------------------------------------*/
    
    public final func frameForSection(_ section: Int) -> CGRect? {
        return self.info.sections[section]?.frame
    }
    public final func layoutAttributesForItemAtIndexPath(_ indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
        return self.collectionViewLayout.layoutAttributesForItemAtIndexPath(indexPath)
    }
    public final func layoutAttributesForSupplementaryElementOfKind(_ kind: String, atIndexPath indexPath: IndexPath) -> CollectionViewLayoutAttributes?  {
        return self.collectionViewLayout.layoutAttributesForSupplementaryViewOfKind(kind, atIndexPath: indexPath)
    }
    
    
    // MARK: - Cells & Index Paths
    /*-------------------------------------------------------------------------------*/
    
    internal final func allIndexPaths() -> Set<IndexPath> { return self.info.allIndexPaths as Set<IndexPath> }
    
    
    
    
    // Visible
    public final func visibleCells() -> [CollectionViewCell]  { return Array( self.contentDocumentView.preparedCellIndex.values) }
    public final func indexPathsForVisibleItems() -> [IndexPath]  { return Array(self.contentDocumentView.preparedCellIndex.keys) as [IndexPath] }
    
    
//    final func isItemVisible(at indexPath: IndexPath) -> Bool {
//        guard let attrs = self.collectionViewLayout.layoutAttributesForItemAtIndexPath(indexPath) else {
//            return false
//        }
//        self.contentVisibleRect.intersects(attrs.frame)
//    }
    
    // Checking visiblility
    public final func itemAtIndexPathIsVisible(_ indexPath: IndexPath) -> Bool {
        if let frame = self.contentDocumentView.preparedCellIndex[indexPath]?.frame {
            return self.contentVisibleRect.intersects(frame)
        }
        return false
    }
    
    // IP & Cell
    public final func cellForItemAtIndexPath(_ indexPath: IndexPath) -> CollectionViewCell?  { return self.contentDocumentView.preparedCellIndex[indexPath] }
    public final func indexPathForCell(_ cell: CollectionViewCell) -> IndexPath?  { return cell.indexPath as IndexPath? }
    
    // IP By Location
    open func indexPathForItemAtPoint(_ point: CGPoint) -> IndexPath?  {
        if self.info.numberOfSections == 0 { return nil }
        for sectionIndex in 0..<self.info.numberOfSections {
            guard let sectionInfo = self.info.sections[sectionIndex] else { continue }
            if !sectionInfo.frame.contains(point) || sectionInfo.numberOfItems == 0 { continue }
            
            for itemIndex in 0...sectionInfo.numberOfItems - 1 {
                let indexPath = IndexPath.for(item:itemIndex, section: sectionIndex)
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
                let indexPath = IndexPath.for(item:item, section: sectionIndex)
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
                return IndexPath.for(item:0, section: sectionIndex)
            }
        }
        return nil
    }
    
    public final func indexPathForSupplementaryView(_ view: CollectionReusableView) -> IndexPath? { return view.indexPath as IndexPath? }
    
    public final func viewForSupplementaryViewOfKind(_ kind: String, atIndexPath: IndexPath) -> CollectionReusableView? {
        let id = SupplementaryViewIdentifier(kind: kind, reuseIdentifier: "", indexPath: atIndexPath)
        return self.contentDocumentView.preparedSupplementaryViewIndex[id]
    }
    
    internal final func _identifiersForSupplementaryViewsInRect(_ rect: CGRect) -> Set<SupplementaryViewIdentifier> {
        var visibleIdentifiers = Set<SupplementaryViewIdentifier>()
        if rect.equalTo(CGRect.zero) { return [] }
        for sectionInfo in self.info.sections {
            if !sectionInfo.1.frame.intersects(rect) { continue }
            for kind in self._registeredSupplementaryViewKinds {
                let ip = IndexPath.for(item:0, section: sectionInfo.1.section)
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
    open func scrollToItemAtIndexPath(_ indexPath: IndexPath, atScrollPosition scrollPosition: CollectionViewScrollPosition, animated: Bool, completion: AnimationCompletion?) {
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
    
    open func scrollToRect(_ aRect: CGRect, atPosition: CollectionViewScrollPosition, animated: Bool, completion: AnimationCompletion?) {
        self._scrollToRect(aRect, atPosition: atPosition, animated: animated, prepare: true, completion: completion)
    }
    
    open func _scrollToRect(_ aRect: CGRect, atPosition: CollectionViewScrollPosition, animated: Bool, prepare: Bool, completion: AnimationCompletion?) {
        var rect = aRect.intersection(self.contentDocumentView.frame)
        
        if rect.isEmpty {
            completion?(false)
            return
        }
        
        let scrollDirection = collectionViewLayout.scrollDirection
        
        let visibleRect = self.contentVisibleRect
        switch atPosition {
        case .top:
            // make the top of our rect flush with the top of the visible bounds
            rect.size.height = visibleRect.height - contentInsets.top;
            rect.origin.y = aRect.origin.y - contentInsets.top;
            break;
        case .centered:
            // TODO
            if self.collectionViewLayout.scrollDirection == .vertical {
                rect.origin.x = 0
                rect.origin.y = rect.center.y - (visibleRect.size.height/2)
            }
            else {
                rect.size.width = self.bounds.size.width
            }
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
        
        if scrollDirection == .vertical {
            rect.origin.x = contentInsets.left
            rect.size.width = contentSize.width
        }
        else {
//            rect.size.
            rect.size.height = self.contentSize.height
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
        
        guard let mouseDown = mouseDownIP else { return }
        guard self.acceptClickEvent(theEvent) else { return }
        
        if self.interactionDelegate?.collectionView?(self, shouldBeginDraggingAtIndexPath: mouseDown, withEvent: theEvent) != true { return }
        
        let ips = self.indexPathsForSelectedItems().sorted { (ip1, ip2) -> Bool in
            let before = ip1._section < ip2._section || (ip1._section == ip2._section && ip1._item < ip2._item)
            return before
        }
        for indexPath in ips {
            var ip = indexPath
            
            let selections = self.indexPathsForSelectedItems()
            if selections.count == 0 { return }
            else if selections.count == 1 && mouseDown != ip {
                self.deselectItemAtIndexPath(ip, animated: true)
                ip = mouseDown
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

