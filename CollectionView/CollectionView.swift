//
//  CollectionView.swift
//  Lingo
//
//  Created by Wesley Byrne on 1/27/16.
//  Copyright © 2016 The Noun Project. All rights reserved.
//

import Foundation

extension IndexSet {
    
    var indices : [Element] {
        var res = [Element]()
        for idx in self {
            res.append(idx)
        }
        return res
    }
    
}

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
            self.reloadLayout(false)
        }
    }
    
    open override var wantsUpdateLayer: Bool { return true }
    
    open override func updateLayer() {
        super.updateLayer()
        self.layer?.backgroundColor = self.drawsBackground ? self.backgroundColor.cgColor : nil
    }
    
    
    // MARK: - Registering reusable cells
    /*-------------------------------------------------------------------------------*/
    
    fileprivate var _cellClasses : [String:CollectionViewCell.Type] = [:]
    fileprivate var _cellNibs : [String:NSNib] = [:]
    
    fileprivate var _supplementaryViewClasses : [SupplementaryViewIdentifier:CollectionReusableView.Type] = [:]
    fileprivate var _supplementaryViewNibs : [SupplementaryViewIdentifier:NSNib] = [:]
    
    
    public func register(class cellClass: CollectionViewCell.Type, forCellWithReuseIdentifier identifier: String) {
        assert(cellClass.isSubclass(of: CollectionViewCell.self), "CollectionView: Registered cells views must be subclasses of CollectionViewCell")
        assert(!identifier.isEmpty, "CollectionView: Reuse identifier cannot be an empty or blank string")
        self._cellClasses[identifier] = cellClass
        self._cellNibs[identifier] = nil
    }
    public func register(nib: NSNib, forCellWithReuseIdentifier identifier: String) {
        assert(!identifier.isEmpty, "CollectionView: Reuse identifier cannot be an empty or blank string")
        self._cellClasses[identifier] = nil
        self._cellNibs[identifier] = nib
    }
    public func register(class viewClass: CollectionReusableView.Type, forSupplementaryViewOfKind kind: String, withReuseIdentifier identifier: String) {
        assert(viewClass.isSubclass(of: CollectionReusableView.self), "CollectionView: Registered supplementary views must be subclasses of CollectionReusableview")
        assert(!identifier.isEmpty, "CollectionView: Reuse identifier cannot be an empty or blank string")
        let id = SupplementaryViewIdentifier(kind: kind, reuseIdentifier: identifier)
        self._supplementaryViewClasses[id] = viewClass
        self._supplementaryViewNibs[id] = nil
        self._registeredSupplementaryViewKinds.insert(kind)
        self._allSupplementaryViewIdentifiers.insert(id)
    }
    public func register(nib: NSNib, forSupplementaryViewOfKind elementKind: String, withReuseIdentifier identifier: String) {
        assert(!identifier.isEmpty, "CollectionView: Reuse identifier cannot be an empty or blank string")
        let id = SupplementaryViewIdentifier(kind: elementKind, reuseIdentifier: identifier)
        self._supplementaryViewClasses[id] = nil
        self._supplementaryViewNibs[id] = nib
        self._registeredSupplementaryViewKinds.insert(elementKind)
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
    fileprivate var _reusableSupplementaryView : [SupplementaryViewIdentifier:Set<CollectionReusableView>] = [:]
    
    public final func dequeueReusableCell(withReuseIdentifier identifier: String, for indexPath: IndexPath) -> CollectionViewCell {
        
        var cell = self.contentDocumentView.preparedCellIndex[indexPath] ?? self._reusableCells[identifier]?.removeOne()
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
            cell?.prepareForReuse()
        }
        cell?.reuseIdentifier = identifier
//        cell?.indexPath = indexPath
        
        return cell!
    }
    public final func dequeueReusableSupplementaryView(ofKind elementKind: String, withReuseIdentifier identifier: String, for indexPath: IndexPath) -> CollectionReusableView {
        let id = SupplementaryViewIdentifier(kind: elementKind, reuseIdentifier: identifier)
        
        var view = self._reusableSupplementaryView[id]?.removeOne()
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
            // self._reusableSupplementaryView[id]?.removeFirst()
            view?.prepareForReuse()
        }
        view?.reuseIdentifier = identifier
//        view?.indexPath = indexPath
        return view!
    }
    
    final func enqueueCellForReuse(_ item: CollectionViewCell) {
        item.isHidden = true
//        item.indexPath = nil
        guard let id = item.reuseIdentifier else { return }
        if self._reusableCells[id] == nil {
            self._reusableCells[id] = []
        }
        self._reusableCells[id]?.insert(item)
    }
    
    final func enqueueSupplementaryViewForReuse(_ view: CollectionReusableView, withIdentifier: SupplementaryViewIdentifier) {
        view.isHidden = true
//        view.indexPath = nil
        let newID = SupplementaryViewIdentifier(kind: withIdentifier.kind, reuseIdentifier: view.reuseIdentifier ?? withIdentifier.reuseIdentifier)
        if self._reusableSupplementaryView[newID] == nil {
            self._reusableSupplementaryView[newID] = []
        }
        self._reusableSupplementaryView[newID]?.insert(view)
    }
    
    final func _loadCell(at indexPath: IndexPath) -> CollectionViewCell? {
        guard let cell = self.cellForItem(at: indexPath) ?? self.dataSource?.collectionView(self, cellForItemAt: indexPath) else {
            debugPrint("For some reason collection view tried to load cells without a data source")
            return nil
        }
        assert(cell.collectionView != nil, "Attemp to load cell without using deque")
        return cell
    }
    
    final func _loadSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> CollectionReusableView? {
        guard let view = self.supplementaryView(forElementKind: elementKind, at: indexPath) ?? self.dataSource?.collectionView?(self, viewForSupplementaryElementOfKind: elementKind, at: indexPath) else {
            debugPrint("For some reason collection view tried to load views without a data source")
            return nil
        }
        assert(view.collectionView != nil, "Attemp to load cell without using deque")
        return view
    }
    
    
    // MARK: - Data
    /*-------------------------------------------------------------------------------*/
    fileprivate var info : CollectionViewInfo!
    open func numberOfSections() -> Int { return self.info.numberOfSections }
    open func numberOfItems(in section: Int) -> Int { return self.info.numberOfItems(in: section) }
    open func frameForSection(at indexPath: IndexPath) -> CGRect? {
        return self.info.sections[indexPath._section]?.frame
    }
    
    
    // MARK: - Floating View
    /*-------------------------------------------------------------------------------*/
    let _floatingSupplementaryView = FloatingSupplementaryView(frame: NSZeroRect)
    open func addAccessoryView(_ view: NSView) {
        self._floatingSupplementaryView.addSubview(view)
    }
    
    public var  floatingContentView : NSView {
        return _floatingSupplementaryView
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
        return self.collectionViewLayout.collectionViewContentSize
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
        contentDocumentView.frame.size = self.collectionViewLayout.collectionViewContentSize
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
        
        if self.collectionViewLayout.shouldInvalidateLayout(forBoundsChange: self.documentVisibleRect) {
            let _size = self.info.contentSize
            
            self.info.recalculate()
            
            contentDocumentView.frame.size = self.collectionViewLayout.collectionViewContentSize
            //self.info.contentSize.height != _size.height,
            if let ip = _topIP, var rect = self.collectionViewLayout.scrollRectForItem(at: ip, atPosition: CollectionViewScrollPosition.leading) {
                        self.scrollItem(at: ip, to: .leading, animated: false, completion: nil)
//                if self.collectionViewLayout.scrollDirection == .vertical {
//                    rect = CGRect(origin: rect.origin, size: self.bounds.size)
//                    rect.origin.x = self.contentInsets.left
//                }
//                else {
//                    rect = CGRect(origin: rect.origin, size: self.bounds.size)
////                    rect.origin.y = self.contentInsets.top
//                }
                
//                _ = self.clipView?.scrollRectToVisible(rect, animated: false, completion: nil)
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
    
    
    
    
    open func reloadLayout(_ animated: Bool, scrollPosition: CollectionViewScrollPosition = .nearest, completion: AnimationCompletion? = nil) {
        self._reloadLayout(animated, scrollPosition: scrollPosition, completion: completion, needsRecalculation: true)
    }
    
    private func _reloadLayout(_ animated: Bool, scrollPosition: CollectionViewScrollPosition = .nearest, completion: AnimationCompletion?, needsRecalculation: Bool) {
    
        var absoluteCellFrames = [CollectionReusableView:CGRect]()
        
        for cell in self.contentDocumentView.preparedCellIndex {
            
            absoluteCellFrames[cell.value] = self.convert(cell.value.frame, from: cell.value.superview)
        }
        for cell in self.contentDocumentView.preparedSupplementaryViewIndex {
            absoluteCellFrames[cell.1] = self.convert(cell.1.frame, from: cell.1.superview)
        }
    
        let holdIP : IndexPath? = self.indexPathForFirstVisibleItem
            //?? self.indexPathsForSelectedItems().intersect(self.indexPathsForVisibleItems()).first

        if needsRecalculation {
            self.info.recalculate()
        }
        
//        NSGraphicsContext.setCurrent(NSGraphicsContext())
       
        let nContentSize = self.info.contentSize
        contentDocumentView.frame.size = nContentSize
        
        if scrollPosition != .none, let ip = holdIP, let rect = self.collectionViewLayout.scrollRectForItem(at: ip, atPosition: scrollPosition) ?? self.rectForItem(at: ip) {
            self._scrollRect(rect, to: scrollPosition, animated: false, prepare: false, completion: nil)
        }
        self.reflectScrolledClipView(self.clipView!)
        
        for item in absoluteCellFrames {
            if let attrs = item.0.attributes , attrs.representedElementCategory == CollectionElementCategory.supplementaryView {
                if let newAttrs = self.layoutAttributesForSupplementaryElement(ofKind: attrs.representedElementKind!, atIndexPath: attrs.indexPath as IndexPath) {
                    
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
        _topIP = indexPathForFirstVisibleItem
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
            self.delegate?.collectionView?(self, mouseMovedToSection: indexPathForSection(at: loc))
        }
    }

    open var indexPathForFirstVisibleItem : IndexPath? {
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
                if let attributes = self.collectionViewLayout.layoutAttributesForItem(at: indexPath) {
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
    
    
    
    
    
    
    
    // MARK: - Batch Updates
    /*-------------------------------------------------------------------------------*/
    open var animationDuration: TimeInterval = 0.4
    
    open func performBatchUpdates(_ updates: (()->Void), completion: AnimationCompletion?) {
        
        self.beginEditing()
        updates()
//        self.relayout(true, scrollPosition: .none, completion: completion)
        self.endEditing(true, completion: completion)
        self.delegate?.collectionViewDidReloadData?(self)
    }
    
    
    
    // MARK: - Manipulating Sections
    /*-------------------------------------------------------------------------------*/
    
    public func reloadSupplementaryViews(in sections: IndexSet, animated: Bool) {
        
        var prepared = [Int: [(id: SupplementaryViewIdentifier, view: CollectionReusableView)]]()
        
        
        
        for supp in contentDocumentView.preparedSupplementaryViewIndex {
            guard let sec = supp.0.indexPath?._section, sections.contains(sec) else { continue }
            if prepared[sec] == nil { prepared[sec] = [(supp.key, supp.value)] }
            else { prepared[sec]?.append((supp.key, supp.value)) }
        }
        
        var updates = [ItemUpdate]()
        
        for item in prepared {
            let sec = item.key
            
            for viewRef in item.value {
                let id = viewRef.id
                let oldView = viewRef.view
                
                contentDocumentView.preparedSupplementaryViewIndex.removeValue(forKey: id)
                updates.append(ItemUpdate(view: oldView, attrs: oldView.attributes!, type: .remove, identifier: id))
            }
            
        }
        self.contentDocumentView.pendingUpdates.append(contentsOf: updates)
    }
    
    public func insertSections(_ sections: IndexSet, animated: Bool) {
        self.indexPathForHighlightedItem = nil
        
        var sections = sections
        
//        var updates = [ItemUpdate]()
        var cellMap = [(newIP: IndexPath, cell: CollectionViewCell)]()
        var viewMap = [(id: SupplementaryViewIdentifier, view: CollectionReusableView)]()
        
        let cCount = self.numberOfSections()
        var newSection = 0
        
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
        
        for sec in 0..<cCount {
            while let nSec = sections.first , nSec <= sec {
                sections.remove(nSec)
                newSection += 1
                // Inserting a new section, this should happen automatically
            }
            
            if newSection != sec, let items = prepared[sec] {
                // This section has changed to newSection, update related items
                for supp in items.supp {
                    if let view = contentDocumentView.preparedSupplementaryViewIndex.removeValue(forKey: supp) {
                        let ip = IndexPath.for(section:newSection)
                        var s = supp.copy(with: ip)
                        viewMap.append((id: s, view: view))
                    }
                }
                
                for ip in items.cells {
                    if let view = contentDocumentView.preparedCellIndex.removeValue(for: ip) {
                        let ip = IndexPath.for(item: ip._item, section: newSection)
                        cellMap.append((newIP: ip, cell: view))
                    }
                }
            }
            newSection += 1
        }
        
        for change in viewMap {
//            change.view.indexPath = change.id.indexPath
            self.contentDocumentView.preparedSupplementaryViewIndex[change.id] = change.view
        }
        
        var updatedSelections = Set<IndexPath>()
        var movedSelections = Set<IndexPath>()
        for change in cellMap {
//            if let ip = change.cell.indexPath , self._selectedIndexPaths.contains(ip as IndexPath) {
//                updatedSelections.insert(ip as IndexPath)
//                movedSelections.insert(change.newIP)
//            }
//            change.cell.indexPath = change.newIP
            self.contentDocumentView.preparedCellIndex[change.newIP] = change.cell
        }
        _selectedIndexPaths.remove(updatedSelections)
        _selectedIndexPaths.formUnion(movedSelections)
        
//        if batchUpdating { return }
//        
//        self.relayout(true, scrollPosition: .none)
//        self.delegate?.collectionViewDidReloadData?(self)
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
                    if let view = contentDocumentView.preparedCellIndex.removeValue(for:ip),
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
                    if let view = contentDocumentView.preparedCellIndex.removeValue(for:ip) {
                        let ip = IndexPath.for(item: ip._item, section: newSection)
                        cellMap.append((newIP: ip, cell: view))
                    }
                }
            }
            newSection += 1
        }
        
        self.contentDocumentView.pendingUpdates.append(contentsOf: updates)
        
        for change in viewMap {
//            change.view.indexPath = change.id.indexPath
            self.contentDocumentView.preparedSupplementaryViewIndex[change.id] = change.view
        }
        
        var updatedSelections = Set<IndexPath>()
        var movedSelections = Set<IndexPath>()
        for change in cellMap {
//            if let ip = change.cell.indexPath , self._selectedIndexPaths.contains(ip as IndexPath) {
//                updatedSelections.insert(ip as IndexPath)
//                movedSelections.insert(change.newIP)
//            }
//            change.cell.indexPath = change.newIP
            self.contentDocumentView.preparedCellIndex[change.newIP] = change.cell
        }
        _ = _selectedIndexPaths.remove(updatedSelections)
        _selectedIndexPaths.formUnion(movedSelections)
        
//        if batchUpdating { return }
//        
//        self.relayout(true, scrollPosition: .none)
//        self.delegate?.collectionViewDidReloadData?(self)

    }
    
    
    
    // MARK: - Manipulating items
    /*-------------------------------------------------------------------------------*/
    
    public typealias Move = (source: IndexPath, destination: IndexPath)
    
    
    
    private struct UpdateContext : CustomStringConvertible {
        
        var updates = [ItemUpdate]()
        
        private var _sectionDeletions   = IndexSet() // Original Indexes for deleted sections
        private var _sectionInsertions  = IndexSet() // Destination Indexes for inserted sections
        
        var reloadedItems = Set<IndexPath>() // Track reloaded items to reload after adjusting IPs
        
        var _operations = [Int:IOSet]()
        
        mutating func reset() {
            updates.removeAll()
            _sectionDeletions.removeAll()
            _sectionInsertions.removeAll()
            _operations.removeAll()
            reloadedItems.removeAll()
        }
        
        struct IOSet : CustomStringConvertible {
            var _open = IndexSet()
            var _locked = IndexSet()
            
            var _union : IndexSet {
                return _open.union(_locked)
            }
            var _lastIndex : Int? { return _locked.last }
            var _firstIndex : Int? {
                if let o = _open.first, let l = _locked.first {
                    return min(o, l)
                }
                if let o = _open.first { return o }
                return _locked.first
            }
            var _deleteCount = 0
            var _insertCount = 0
            
            init(d index: Int) { self.deleted(at: index) }
            init(i index: Int) { self.inserted(at: index) }
            
            mutating func moved(_ source: Int, to destination: Int) {
                self.deleted(at: source)
                self.inserted(at: destination)
            }
            
            mutating func lock(upTo index: Int) {
                var idx = index - 1
                guard let start = self._firstIndex, start < idx else { return }
                var idxSet = IndexSet(integersIn: start...idx)
                idxSet.subtract(_open)
                self._locked = _locked.union(idxSet)
            }
            
            
            // Auto is set to true when inserting  as the result of an adjustment
            // This keeps it from being counted when adjusting IP out of the edit area
            mutating func deleted(at index: Int, auto: Bool = false) -> IOSet {
                if !auto {
                    _deleteCount += 1
                }
                if _locked.contains(index) {
                    return self
                }
                _open.insert(index)
                return self
            }
            
            // Auto is set to true when inserting  as the result of an adjustment
            // This keeps it from being counted when adjusting IP out of the edit area
            mutating func inserted(at index: Int, auto: Bool = false) -> IOSet {
                _locked.insert(index)
                if !auto {
                    _insertCount += 1
                }
                return self
            }
            
            var description: String {
                var str = "Section Ops\n"
                
                var open = [Int]()
                var locked = [Int]()
                
                let union = _open.union(_locked)
                
                str += "Union \(union.indices)\n"
                if union.count > 0 {
                    for idx in union {
                        open.append(_open.contains(idx) ? 1 : 0)
                        locked.append(_locked.contains(idx) ? 1 : 0)
                    }
                }
                str += "Open: \(open)\n"
                str += "Lock: \(locked)"
                return str
            }
        }
        
        
        mutating func lock(upTo indexPath: IndexPath) {
            _operations[indexPath._section]?.lock(upTo: indexPath._item)
        }
        
        
        mutating func deletedSection(at index: Int) {
            _sectionDeletions.insert(index)
        }
        mutating func insertedSection(at index: Int) {
            _sectionInsertions.insert(index)
        }
        mutating func movedSection(from source: Int, to destination: Int) {
            deletedSection(at: source)
            insertedSection(at: destination)
        }
        
        mutating func deletedItem(at indexPath: IndexPath) {
            let s = indexPath._section, i = indexPath._item
            if _operations[s]?.deleted(at: i) == nil {
                _operations[s] = IOSet(d: i)
            }
        }
        mutating func insertedItem(at indexPath: IndexPath) {
            let s = indexPath._section, i = indexPath._item
            if _operations[s]?.inserted(at: i) == nil {
                _operations[s] = IOSet(i: i)
            }
        }
        
        mutating func movedItem(from source: IndexPath, to destination: IndexPath) {
            deletedItem(at: source)
            insertedItem(at: destination)
        }
        
        mutating func adjust(_ indexPath: IndexPath) -> IndexPath {
            
            let sDelete = _sectionDeletions.count(in: 0...indexPath._section)
            let sInsert = _sectionInsertions.count(in: 0...(indexPath._section))
            
            let section = indexPath._section + sInsert - sDelete
            
            var _proposed = indexPath._item
            guard let ops = _operations[section] else { return indexPath }
            
//            Swift.print("Adjusting: \(_proposed) against : \(ops)")
            
            var all = ops._union
            var idx = all.startIndex
            var last = ops._open[idx]
            
            if _proposed >= last {
                _proposed = last
                
                if ops._locked.contains(last) {
                
                    while idx < all.endIndex {
                        let check = all[idx]
                        var prop = last + 1
                        let isGap = prop < check
//                        let isLocked = ops._locked.contains(prop)
//                        Swift.print("Open: \(ops._open.contains(prop))  Locked: \(ops._locked.contains(prop))")
                        
                        if isGap || (ops._open.contains(prop) && !ops._locked.contains(prop)) {
                           _proposed = prop
                            break;
                        }
                        _proposed = check + 1
                        idx = all.index(after: idx)
                        last = check
                    }
                }
            }
            _operations[section]?.inserted(at: _proposed, auto: true)
            // Open up this space to be filled by another item
            // If it has already been locked, this does nothing
            _operations[indexPath._section]?.deleted(at: indexPath._item, auto: true)
            
            let new = IndexPath.for(item: _proposed, section: section)
//            Swift.print("Adjusted \(indexPath)  to: \(new)")
            return new
        }
        
        var description: String {
            return  ""// "Insertions : \(_insertions)  \n Deletions: \(_deletions)
        }
    }
    
    
    private var _updateMap = IndexedSet<IndexPath, CollectionViewCell>()
    private var _updateSelections : Set<IndexPath>?
    private var _updateContext = UpdateContext()
    
    private var _editing = 0
    private func beginEditing() {
        if _editing == 0 {
            self._firstSelection = nil
            self._updateContext.reset()
            self.info.recalculate()
            self._updateMap.removeAll()
            self._updateSelections = Set<IndexPath>()
//            Swift.print(self.contentDocumentView.preparedCellIndex.orderedLog())
        }
        _editing += 1
    }
    private func endEditing(_ animated: Bool, completion: AnimationCompletion? = nil) {
        
        if _editing == 0 { return }
        if _editing > 1 {
            _editing -= 1
            return
        }
        _editing = 0
        
        var newIndex = _updateMap
//        Swift.print("INdexPaths: \(_selectedIndexPaths)")
        
//        Swift.print("Remaining Cell Index: \(self.contentDocumentView.preparedCellIndex.orderedLog())")
//        Swift.print("Pre-adjust Cell Index: \(newIndex.orderedLog())")
        
        // By now the preparedCellIndex will only contain
//        Swift.print(_updateContext._operations)
        
        var checked = Set<Int>()
        
        for stale in self.contentDocumentView.preparedCellIndex.ordered() {
            
            if !checked.contains(stale.index._section) {
                _updateContext.lock(upTo: stale.index)
                checked.insert(stale.index._section)
            }
            
            let adjustedIP = _updateContext.adjust(stale.index)
            
            if self._selectedIndexPaths.remove(stale.index) != nil {
                _updateSelections?.insert(adjustedIP)
            }
            
            var view = _updateContext.reloadedItems.contains(stale.index)
                ? _prepareReplacementCell(for: stale.value, at: adjustedIP)
                : stale.value
            
            // TODO: Not sure if this actually needs to happen, it will just be reset below
            self.contentDocumentView.preparedCellIndex.remove(view)
            newIndex[adjustedIP] = view
            
            if adjustedIP != stale.index {
                if let attrs = self.layoutAttributesForItem(at: adjustedIP) {
                    _updateContext.updates.append(ItemUpdate(view: view, attrs: attrs, type: .update))
                }
            }
//            Swift.print("Pre-adjust Cell Index: \(newIndex.orderedLog())")
        }
        
        
        
        for sectionOps in self._updateContext._operations {
            let sectionIdx = sectionOps.key
            let ops = sectionOps.value
            
            guard let last = ops._lastIndex else {
                continue
            }
            
            let adjust = ops._insertCount - ops._deleteCount
            let count = self.numberOfItems(in: sectionIdx)
            guard last < count else { continue }
            for idx in last..<count {
                let ip = IndexPath.for(item: idx, section: sectionIdx)
                if self.itemAtIndexPathIsSelected(ip), ip._item + adjust >= 0 {
                    let newIP = IndexPath.for(item: ip._item + adjust, section: sectionIdx)
                    self._updateSelections?.insert(newIP)
                }
            }
        }
        Swift.print("UpdatedSelections: \(_updateSelections!)")
        
        
//        Swift.print("New Cell Index: \(newIndex.orderedLog())")
        self._selectedIndexPaths = _updateSelections!
        self.contentDocumentView.pendingUpdates = _updateContext.updates
        self.contentDocumentView.preparedCellIndex = newIndex
        self._reloadLayout(animated, scrollPosition: .none, completion: nil, needsRecalculation: false)
    }
    
    public func insertItems(at indexPaths: [IndexPath], animated: Bool) {
        self.beginEditing()
        self._insertItems(at: indexPaths)
        self.endEditing(animated)
        
    }
    public func deleteItems(at indexPaths: [IndexPath], animated: Bool) {
        self.beginEditing()
        self._deleteItems(at: indexPaths)
        self.endEditing(animated)
    }
    public func reloadItems(at indexPaths: [IndexPath], animated: Bool) {
        self.beginEditing()
        self._reloadItems(at: indexPaths)
        self.endEditing(animated)
    }
    public func moveItem(at indexPath : IndexPath, to destinationIndexPath: IndexPath, animated: Bool) {
        self.beginEditing()
        self._moveItem(at: indexPath, to: destinationIndexPath)
        self.endEditing(animated)
    }
    public func moveItems(_ moves: [Move], animated: Bool) {
        self.beginEditing()
        for m in moves {
            self._moveItem(at: m.source, to: m.destination)
        }
        self.endEditing(animated)
    }
    
    
    
    
    func _prepareReplacementCell(for currentCell: CollectionViewCell, at indexPath: IndexPath) -> CollectionViewCell {
        
        Swift.print("Preparing replacment cell for item at: \(indexPath)")
        
        // Update the cell index so the same cell be returned via deuque(_:)
//        currentCell.attributes = currentCell.attributes?.copyWithIndexPath(indexPath)
//        self.contentDocumentView.preparedCellIndex[indexPath] = currentCell
        defer {
            self.contentDocumentView.preparedCellIndex.remove(currentCell)
            self.contentDocumentView.preparedCellIndex.removeValue(for: indexPath)
        }
        
        guard let newCell = self.dataSource?.collectionView(self, cellForItemAt: indexPath) else {
            assertionFailure("For some reason collection view tried to load cells without a data source")
            return currentCell
        }
        assert(newCell.collectionView != nil, "Attempt to load cell without using deque:")
        self.contentDocumentView.preparedCellIndex.removeValue(for: indexPath)
        
        Swift.print("Loaded replacement cell \(newCell)")
        
        if newCell == currentCell {
            return newCell
        }
        
        let removal = ItemUpdate(view: currentCell, attrs: currentCell.attributes!, type: .remove)
//        _updateContext.updates.append(removal)
        self.contentDocumentView.removeItem(removal)
        Swift.print("Remove replaced cell \(currentCell.attributes!.indexPath)")
        
        if let a = currentCell.attributes?.copyWithIndexPath(indexPath) {
            newCell.applyLayoutAttributes(a, animated: false)
        }
        if newCell.superview == nil {
            self.contentDocumentView.addSubview(newCell)
        }
        newCell.selected = self._selectedIndexPaths.contains(indexPath)
        newCell.viewDidDisplay()
        return newCell
        
        
    }
    
    
    public func _insertItems(at indexPaths: [IndexPath]) {
        self.indexPathForHighlightedItem = nil
        
        for ip in indexPaths {
            _updateContext.insertedItem(at: ip)
        }
    }
    
    
    
    
    public func _deleteItems(at indexPaths: [IndexPath]) {
        
        for ip in indexPaths {
            self._selectedIndexPaths.remove(ip)
            self._updateContext.deletedItem(at: ip)
            if let cell = self.cellForItem(at: ip) {
                _updateContext.updates.append(ItemUpdate(view: cell, attrs: cell.attributes!, type: .remove))
                contentDocumentView.preparedCellIndex.removeValue(for: ip)
            }
        }
    }
    

    
    public func _reloadItems(at indexPaths: [IndexPath]) {
        self._updateContext.reloadedItems.formUnion(indexPaths)
    }

    public func _moveItem(at indexPath : IndexPath, to destinationIndexPath: IndexPath) {
        
        self._updateContext.movedItem(from: indexPath, to: destinationIndexPath)
        if itemAtIndexPathIsSelected(indexPath) {
            _updateSelections?.insert(destinationIndexPath)
        }
        if let cell = self.cellForItem(at: indexPath),
            let attrs = self.layoutAttributesForItem(at: destinationIndexPath) {
            _updateContext.updates.append(ItemUpdate(view: cell, attrs: attrs, type: .update))
            contentDocumentView.preparedCellIndex.removeValue(for: indexPath)
            _updateMap.insert(cell, with: destinationIndexPath)
        }
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
        self.delegate?.collectionView?(self, mouseMovedToSection: indexPathForSection(at: loc))
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
        self.mouseDownIP = self.indexPathForItem(at: point)
        self.delegate?.collectionView?(self, mouseDownInItemAt: self.mouseDownIP, with: theEvent)
    }
    
    
    open override func mouseUp(with theEvent: NSEvent) {
        //        super.mouseUp(theEvent)
        
        if self.draggedIPs.count > 0 {
            self.draggedIPs = []
            return
        }
        
        let point = self.contentView.convert(theEvent.locationInWindow, from: nil)
        let indexPath = self.indexPathForItem(at: point)
        self.delegate?.collectionView?(self, mouseUpInItemAt: indexPath, with: theEvent)
        
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
            self._selectItem(at: ip, atScrollPosition: .nearest, animated: true, selectionType: .extending)
            return
        }
        else if allowsMultipleSelection && theEvent.modifierFlags.contains(NSEventModifierFlags.command) {
            if self._selectedIndexPaths.contains(ip) {
                if self._selectedIndexPaths.count == 1 { return }
                self._deselectItem(at: ip, animated: true, notifyDelegate: true)
            }
            else {
                self._selectItem(at: ip, animated: true, with: theEvent, notifyDelegate: true)
            }
            return
        }
        else if theEvent.clickCount == 2 {
            self.delegate?.collectionView?(self, didDoubleClickItemAt: ip, with: theEvent)
            return
        }
        
        if self.selectionMode != .multi {
            self._deselectAllItems(true, notify: false)
        }
        else if self.itemAtIndexPathIsSelected(ip) {
            self._deselectItem(at: ip, animated: true, notifyDelegate: true)
            return
        }
        self._selectItem(at: ip, animated: true, scrollPosition: .none, with: theEvent)
    }
    
    open override func rightMouseDown(with theEvent: NSEvent) {
        super.rightMouseDown(with: theEvent)
        
        guard self.acceptClickEvent(theEvent) else { return }
        
//        if let view = self.window?.contentView?.hitTest(theEvent.locationInWindow) , view.isDescendant(of: self.contentDocumentView) == false {
//            return
//        }
        
        let point = self.contentView.convert(theEvent.locationInWindow, from: nil)
        if let indexPath = self.indexPathForItem(at: point) {
            self.delegate?.collectionView?(self, didRightClickItemAt: indexPath, with: theEvent)
        }
    }
    
    final func moveSelectionInDirection(_ direction: CollectionViewDirection, extendSelection: Bool) {
        guard let indexPath = (extendSelection ? _lastSelection : _firstSelection) ?? self._selectedIndexPaths.first else { return }
        if let moveTo = self.collectionViewLayout.indexPathForNextItem(moving: direction, from: indexPath) {
            if let move = self.delegate?.collectionView?(self, shouldSelectItemAt: moveTo, with: NSApp.currentEvent) , move != true { return }
            self._selectItem(at: moveTo, atScrollPosition: .nearest, animated: true, selectionType: extendSelection ? .extending : .single)
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
            if let ip = oldValue, let cell = self.cellForItem(at: ip) , cell.highlighted {
                cell.setHighlighted(false, animated: true)
            }
        }
    }
    open func highlightItem(at indexPath: IndexPath?, animated: Bool) {
        
        guard let ip = indexPath else {
            self.indexPathForHighlightedItem = nil
            return
        }
        if let cell = self.cellForItem(at: ip) {
            cell.setHighlighted(true, animated: animated)
        }
    }
    
    public final var indexPathsForSelectedItems : Set<IndexPath> { return _selectedIndexPaths }
    public final var sortedIndexPathsForSelectedItems : [IndexPath] {
        return indexPathsForSelectedItems.sorted { (ip1, ip2) -> Bool in
            let before =  ip1._section < ip2._section || (ip1._section == ip2._section && ip1._item < ip2._item)
            return before
        }
    }
    
    public final func itemAtIndexPathIsSelected(_ indexPath: IndexPath) -> Bool {
        return _selectedIndexPaths.contains(indexPath)
    }
    
    open func selectAllItems(_ animated: Bool = true) {
        self.selectItems(at: self.contentDocumentView.preparedCellIndex.indexes, animated: animated)
    }

    open func selectItems(at indexPaths: [IndexPath], animated: Bool) {
        for ip in indexPaths { self._selectItem(at: ip, animated: animated, scrollPosition: .none, with: nil, notifyDelegate: false) }
    }
    
    
    open func selectItem(at indexPath: IndexPath?, animated: Bool, scrollPosition: CollectionViewScrollPosition = .none) {
        self._selectItem(at: indexPath, animated: animated, scrollPosition: scrollPosition, with: nil, notifyDelegate: false)
    }
    
    fileprivate func _selectItem(at indexPath: IndexPath?, animated: Bool, scrollPosition: CollectionViewScrollPosition = .none, with event: NSEvent?, notifyDelegate: Bool = true) {
        guard let indexPath = indexPath else {
            self.deselectAllItems(animated)
            return
        }
        
        if indexPath._section >= self.info.numberOfSections || indexPath._item >= self.info.numberOfItems(in: indexPath._section) { return }
        
        if !self.allowsSelection { return }
        if let shouldSelect = self.delegate?.collectionView?(self, shouldSelectItemAt: indexPath, with: event) , !shouldSelect { return }
        
        if self.allowsMultipleSelection == false {
            self._selectedIndexPaths.remove(indexPath)
            self.deselectAllItems()
        }
        
        self.cellForItem(at: indexPath)?.setSelected(true, animated: animated)
        self._selectedIndexPaths.insert(indexPath)
        if (selectionMode == .multi && event != nil) || self._selectedIndexPaths.count == 1 {
            self._firstSelection = indexPath
        }
        self._lastSelection = indexPath
        if notifyDelegate {
            self.delegate?.collectionView?(self, didSelectItemAt: indexPath)
        }
        
        if scrollPosition != .none {
            self.scrollItem(at: indexPath, to: scrollPosition, animated: animated, completion: nil)
        }
    }
    
    
    
    
    // MARK: Multi Select
    /*-------------------------------------------------------------------------------*/
    final func _selectItem(at indexPath: IndexPath,
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
                        nextIndex = self.indexPathForSelectableItem(after: idx)
                    }
                    else if order == .orderedDescending {
                        nextIndex = self.indexPathForSelectableItem(before: idx)
                    }
                }
            }
            else {
                indexesToSelect.insert(IndexPath.zero)
            }
            indexesToSelect.insert(indexPath)
        }
        
        
        if selectionMode != .multi {
            var deselectIndexes = self._selectedIndexPaths
            _ = deselectIndexes.remove(indexesToSelect)
            self.deselectItems(at: Array(deselectIndexes), animated: true)
        }
        
        let finalSelect = indexesToSelect.remove(indexPath)
        for ip in indexesToSelect {
            self._selectItem(at: ip, animated: true, scrollPosition: .none, with: nil, notifyDelegate: false)
        }
        
        self.scrollItem(at: indexPath, to: atScrollPosition, animated: animated, completion: nil)
        if let ip = finalSelect {
            self._selectItem(at: ip, animated: true, scrollPosition: .none, with: nil, notifyDelegate: true)
        }
        
        self._lastSelection = indexPath
    }
    
    
    // MARK: - Deselect
    /*-------------------------------------------------------------------------------*/
    open func deselectItems(at indexPaths: [IndexPath], animated: Bool) {
        for ip in indexPaths { self._deselectItem(at: ip, animated: animated, notifyDelegate: false) }
    }
    open func deselectAllItems(_ animated: Bool = false) {
        self._deselectAllItems(animated, notify: false)
    }
    
    
    final func _deselectAllItems(_ animated: Bool, notify: Bool) {
        let anIP = self._selectedIndexPaths.first
        self._lastSelection = nil
        
        let ips = self._selectedIndexPaths.intersection(Set(self.indexPathsForVisibleItems))
        
        for ip in ips { self._deselectItem(at: ip, animated: animated, notifyDelegate: false) }
        self._selectedIndexPaths.removeAll()
        if notify, let ip = anIP {
            self.delegate?.collectionView?(self, didDeselectItemAt: ip)
        }
    }
    
    open func deselectItem(at indexPath: IndexPath, animated: Bool) {
        self._deselectItem(at: indexPath, animated: animated, notifyDelegate: false)
    }
    
    final func _deselectItem(at indexPath: IndexPath, animated: Bool, notifyDelegate : Bool = true) {
        if let deselect = self.delegate?.collectionView?(self, shouldDeselectItemAt: indexPath) , !deselect { return }
        contentDocumentView.preparedCellIndex[indexPath]?.setSelected(false, animated: true)
        self._selectedIndexPaths.remove(indexPath)
        if notifyDelegate {
            self.delegate?.collectionView?(self, didDeselectItemAt: indexPath)
        }
    }
    
    
    
    // MARK: - Internal
    /*-------------------------------------------------------------------------------*/
    final func validateIndexPath(_ indexPath: IndexPath) -> Bool {
        if self.info.sections[indexPath._section] == nil { return false }
        return indexPath._section < self.info.numberOfSections && indexPath._item < self.info.sections[indexPath._section]!.numberOfItems
    }
    
    final func indexPathForSelectableItem(before indexPath: IndexPath) -> IndexPath?{
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
    
    final func indexPathForSelectableItem(after indexPath: IndexPath) -> IndexPath? {
        if indexPath._item + 1 >= numberOfItems(in: indexPath._section) {
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
    public final func layoutAttributesForItem(at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
        return self.collectionViewLayout.layoutAttributesForItem(at: indexPath)
    }
    public final func layoutAttributesForSupplementaryElement(ofKind kind: String, atIndexPath indexPath: IndexPath) -> CollectionViewLayoutAttributes?  {
        return self.collectionViewLayout.layoutAttributesForSupplementaryView(ofKind: kind, atIndexPath: indexPath)
    }
    
    
    // MARK: - Cells & Index Paths
    /*-------------------------------------------------------------------------------*/
    
    internal final func allIndexPaths() -> Set<IndexPath> { return self.info.allIndexPaths as Set<IndexPath> }
    
    
    // Visible
    public final var visibleCells : [CollectionViewCell]  { return Array( self.contentDocumentView.preparedCellIndex.values) }
    public final var indexPathsForVisibleItems : [IndexPath]  { return Array(self.contentDocumentView.preparedCellIndex.indexes) }
    
    
//    final func isItemVisible(at indexPath: IndexPath) -> Bool {
//        guard let attrs = self.collectionViewLayout.layoutAttributesForItem(at: indexPath) else {
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
    public final func cellForItem(at indexPath: IndexPath) -> CollectionViewCell?  { return self.contentDocumentView.preparedCellIndex[indexPath] }
    public final func indexPath(for cell: CollectionViewCell) -> IndexPath?  { return self.contentDocumentView.preparedCellIndex.index(of: cell) }
    
    // IP By Location
    open func indexPathForItem(at point: CGPoint) -> IndexPath?  {
        if self.info.numberOfSections == 0 { return nil }
        for sectionIndex in 0..<self.info.numberOfSections {
            guard let sectionInfo = self.info.sections[sectionIndex] else { continue }
            if !sectionInfo.frame.contains(point) || sectionInfo.numberOfItems == 0 { continue }
            
            for itemIndex in 0...sectionInfo.numberOfItems - 1 {
                let indexPath = IndexPath.for(item:itemIndex, section: sectionIndex)
                if let attributes = self.collectionViewLayout.layoutAttributesForItem(at: indexPath) {
                    if attributes.frame.contains(point) {
                        return indexPath;
                    }
                }
            }
        }
        return nil;
    }
    
    // IP By Location
    open func firstIndexPathForItem(near point: CGPoint, radius: CGFloat) -> IndexPath?  {
        if self.info.numberOfSections == 0 { return nil }
        
        let rect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
        for sectionIndex in 0..<self.info.numberOfSections {
            guard let sectionInfo = self.info.sections[sectionIndex] else { continue }
            if !sectionInfo.frame.intersects(rect) || sectionInfo.numberOfItems == 0 { continue }
            
            for itemIndex in 0...sectionInfo.numberOfItems - 1 {
                let indexPath = IndexPath.for(item:itemIndex, section: sectionIndex)
                if let attributes = self.collectionViewLayout.layoutAttributesForItem(at: indexPath) {
                    if attributes.frame.intersects(rect) {
                        return indexPath;
                    }
                }
            }
        }
        return nil;
    }
    
    // IP By Location
    open func firstIndexPathForItem(in rect: CGRect) -> IndexPath?  {
        if self.info.numberOfSections == 0 { return nil }
        
        for sectionIndex in 0..<self.info.numberOfSections {
            guard let sectionInfo = self.info.sections[sectionIndex] else { continue }
            if !sectionInfo.frame.intersects(rect) || sectionInfo.numberOfItems == 0 { continue }
            
            for itemIndex in 0...sectionInfo.numberOfItems - 1 {
                let indexPath = IndexPath.for(item:itemIndex, section: sectionIndex)
                if let attributes = self.collectionViewLayout.layoutAttributesForItem(at: indexPath) {
                    if attributes.frame.intersects(rect) {
                        return indexPath;
                    }
                }
            }
        }
        return nil;
    }
    
    
    
    open func indexPathsForItems(in rect: CGRect) -> Set<IndexPath> {
        if let providedIndexPaths = self.collectionViewLayout.indexPathsForItems(in: rect) { return providedIndexPaths }
        if rect.equalTo(CGRect.zero) || self.info.numberOfSections == 0 { return [] }
        var indexPaths = Set<IndexPath>()
        for sectionIndex in 0...self.info.numberOfSections - 1 {
            guard let section = self.info.sections[sectionIndex] else { continue }
            if section.frame.isEmpty || !section.frame.intersects(rect) { continue }
            for item in 0...section.numberOfItems - 1 {
                let indexPath = IndexPath.for(item:item, section: sectionIndex)
                if let attributes = self.collectionViewLayout.layoutAttributesForItem(at: indexPath) {
                    if (attributes.frame.intersects(rect)) {
                        indexPaths.insert(indexPath)
                    }
                }
            }
        }
        return indexPaths
    }
    
    // Rect for item
    internal final func rectForItem(at indexPath: IndexPath) -> CGRect? {
        if indexPath._section < self.info.numberOfSections {
            let attributes = self.collectionViewLayout.layoutAttributesForItem(at: indexPath);
            return attributes?.frame;
        }
        return nil
    }
    
    
    // MARK: - Supplementary Views & Index Paths
    /*-------------------------------------------------------------------------------*/
    
    public final func indexPathForSection(at point: CGPoint) -> IndexPath? {
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
    
    public final func indexPath(forSupplementaryView view: CollectionReusableView) -> IndexPath? { return view.attributes?.indexPath }
    
    public final func supplementaryView(forElementKind kind: String, at indexPath: IndexPath) -> CollectionReusableView? {
        let id = SupplementaryViewIdentifier(kind: kind, reuseIdentifier: "", indexPath: indexPath)
        return self.contentDocumentView.preparedSupplementaryViewIndex[id]
    }
    
    internal final func _identifiersForSupplementaryViews(in rect: CGRect) -> Set<SupplementaryViewIdentifier> {
        var visibleIdentifiers = Set<SupplementaryViewIdentifier>()
        if rect.equalTo(CGRect.zero) { return [] }
        for sectionInfo in self.info.sections {
            if !sectionInfo.1.frame.intersects(rect) { continue }
            for kind in self._registeredSupplementaryViewKinds {
                let ip = IndexPath.for(item:0, section: sectionInfo.1.section)
                if let attrs = self.collectionViewLayout.layoutAttributesForSupplementaryView(ofKind: kind, atIndexPath: ip) {
                    if attrs.frame.intersects(rect) {
                        visibleIdentifiers.insert(SupplementaryViewIdentifier(kind: kind, reuseIdentifier: "", indexPath: ip))
                    }
                }
            }
        }
        return visibleIdentifiers
    }
    
    
    // MARK: - Programatic Scrollin
    /*-------------------------------------------------------------------------------*/
    open func scrollItem(at indexPath: IndexPath, to scrollPosition: CollectionViewScrollPosition, animated: Bool, completion: AnimationCompletion?) {
        if self.info.numberOfItems(in: indexPath._section) < indexPath._item { return }
        if let shouldScroll = self.delegate?.collectionView?(self, shouldScrollToItemAt: indexPath) , shouldScroll != true {
            completion?(false)
            return
        }
        
        guard let rect = self.collectionViewLayout.scrollRectForItem(at: indexPath, atPosition: scrollPosition) ?? self.rectForItem(at: indexPath) else {
            completion?(false)
            return
        }
        
        self.scrollRect(rect, to: scrollPosition, animated: animated, completion: { fin in
            completion?(fin)
            self.delegate?.collectionView?(self, didScrollToItemAt: indexPath)
        })
    }
    
    open func scrollRect(_ aRect: CGRect, to scrollPosition: CollectionViewScrollPosition, animated: Bool, completion: AnimationCompletion?) {
        self._scrollRect(aRect, to: scrollPosition, animated: animated, prepare: true, completion: completion)
    }
    
    open func _scrollRect(_ aRect: CGRect, to scrollPosition: CollectionViewScrollPosition, animated: Bool, prepare: Bool, completion: AnimationCompletion?) {
        var rect = aRect.intersection(self.contentDocumentView.frame)
        
        if rect.isEmpty {
            completion?(false)
            return
        }
        
        let scrollDirection = collectionViewLayout.scrollDirection
        
        let visibleRect = self.contentVisibleRect
        switch scrollPosition {
        case .leading:
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
        case .trailing:
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
            rect.size.height = self.contentSize.height
        }
        
        
        if !animated && scrollPosition == .centered || scrollPosition == .leading {
            if contentSize.height < self.contentVisibleRect.size.height {
                completion?(true)
                return
            }
            if rect.origin.y > self.contentSize.height - self.frame.size.height {
                rect.origin.y = self.contentSize.height - self.frame.size.height + self.contentInsets.top
            }
        }
        
        
//        Swift.print(rect)
//        Swift.print(self.contentDocumentView.frame)
//        Swift.print(self.contentInsets.top)
        
        if animated || prepare {
            self.contentDocumentView.prepareRect(rect.union(visibleRect), force: false)
        }
        self.clipView?.scrollRectToVisible(rect, animated: animated, completion: completion)
        if !animated && prepare {
            self.contentDocumentView.prepareRect(self.contentVisibleRect, force: false)
        }
    }
    

    
    
    // MARK: - Dragging Source
    var draggedIPs : [IndexPath] = []
    
    public var indexPathsForDraggingItems : [IndexPath] {
        return draggedIPs
    }
    
    override open func mouseDragged(with theEvent: NSEvent) {
        super.mouseDragged(with: theEvent)
        self.window?.makeFirstResponder(self)
        self.draggedIPs = []
        var items : [NSDraggingItem] = []
        
        guard let mouseDown = mouseDownIP else { return }
        guard self.acceptClickEvent(theEvent) else { return }
        
        if self.interactionDelegate?.collectionView?(self, shouldBeginDraggingAt: mouseDown, with: theEvent) != true { return }
        
        let ips = self.sortedIndexPathsForSelectedItems
        for indexPath in ips {
            var ip = indexPath
            
            let selections = self.indexPathsForSelectedItems
            if selections.count == 0 { return }
            else if selections.count == 1 && mouseDown != ip {
                self.deselectItem(at: ip, animated: true)
                ip = mouseDown
                self.selectItem(at: ip, animated: true)
            }
            
            
            if let writer = self.dataSource?.collectionView?(self, pasteboardWriterForItemAt: ip) {
//                let cell = self.cellForItem(at: ip) as? AssetCell
                guard let rect = self.rectForItem(at: ip) else { continue }
                // The frame of the cell in relation to the document. This is where the dragging
                // image should start.
                
//                UnsafeMutablePointer<CGRect>
                let originalFrame = UnsafeMutablePointer<CGRect>.allocate(capacity: 1)
                let oFrame = self.convert( rect, from: self.documentView)
                originalFrame.initialize(to: oFrame)
                self.dataSource?.collectionView?(self, dragRectForItemAt: ip, withStartingRect: originalFrame)
                let frame = originalFrame.pointee
                
                self.draggedIPs.append(ip)
                let item = NSDraggingItem(pasteboardWriter: writer)
                item.draggingFrame = frame
                
                if self.itemAtIndexPathIsVisible(ip) {
                    item.imageComponentsProvider = { () -> [NSDraggingImageComponent] in
                        
                        var image = self.dataSource?.collectionView?(self, dragContentsForItemAt: ip)
                        if image == nil, let cell = self.cellForItem(at: ip) {
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
        self.interactionDelegate?.collectionView?(self, draggingSession: session, willBeginAt: screenPoint)
    }
    
    open func draggingSession(_ session: NSDraggingSession, movedTo screenPoint: NSPoint) {
        self.interactionDelegate?.collectionView?(self, draggingSession: session, didMoveTo: screenPoint)
    }
    
    open func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
//        self.mouseDownIP = nil
        self.interactionDelegate?.collectionView?(self, draggingSession: session, didEndAt: screenPoint, with: operation, draggedIndexPaths: draggedIPs)
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

