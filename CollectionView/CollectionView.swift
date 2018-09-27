//
//  CollectionView.swift
//  Lingo
//
//  Created by Wesley Byrne on 1/27/16.
//  Copyright © 2016 The Noun Project. All rights reserved.
//

import Foundation
import AppKit

/**
 A Collection View manages the presentation of items, your app's main job is to provide the data that those items are to represent.
 
 A collection view gets its data from the data source, which is an object that conforms to the CollectionViewDataSource protocol. Data provided by the data source is represented items, which can also be organized into sections, and ultimately displayed as cells.
 
 ### Gathings Data
 
 The data source only has 3 requirements, provide the number of sections, the number of items, and a cell for each item. For performance, cells in a collection view are reusable since only a subset of all the items will often be visbile.
 
 Before you can load a cell, you need to register the cells you will need to represet your data. Cells can be registered from a nib or from a class using `register(class:forCellWithReuseIdentifier:)` or `register(nib:forCellWithReuseIdentifier:)`. The reuse identifier will later be use to get instances of the cell.
 
 To create the cells for each item in your data, implement the data source method `func collectionView(_:cellForItemAt:) -> CollectionViewCell`. In here you will call `dequeueReusableCell(withReuseIdentifier:for:)` which will load an instance of the cell your previously registered for that resuse identifier. After you have dequeued the cell, update it as needed to properly represent the object at the given index path in your data, then return it.
 
 ### Laying Out Items
 
 After the data source has provided all the cells to be displayed, the collection view looks to its CollectionViewLayout to determine where to place each one. The base layout object is designed to be subclassed to generate layout information for different use cases. The goal of a layout is to be able to provide information about the layout to the collection view quickly, this inlcudes the location of each cell, the overall size of all the items, etc.
 
 The following layouts are provided for common uses, for more custom layouts, create a custom CollectionViewLayout subclass.
 - CollectionViewColumnLayout
 - CollectionViewListLayout
 - CollectionViewFlowLayout
 - CollectionViewHorizontalLayout
 
*/
open class CollectionView: ScrollView, NSDraggingSource {
    
    open override var mouseDownCanMoveWindow: Bool { return true }
    
    // MARK: - Data Source & Delegate
    
    /// The object that acts as the delegate to the collection view
    @objc public weak var delegate: CollectionViewDelegate?
    
    /// The object that provides data for the collection view
    public weak var dataSource: CollectionViewDataSource?
    
    private weak var interactionDelegate: CollectionViewDragDelegate? {
        return self.delegate as? CollectionViewDragDelegate
    }
    
    /**
     The content view in which all cells and views are displayed
    */
    public var contentDocumentView: CollectionViewDocumentView {
        return self.documentView as! CollectionViewDocumentView
    }
    
    // MARK: - Intialization
    /*-------------------------------------------------------------------------------*/
    
    public init() {
        super.init(frame: NSRect.zero)
        self.setup()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setup()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    private func setup() {
        
        collectionViewLayout.collectionView = self
        self.wantsLayer = true
        let dView = CollectionViewDocumentView(frame: self.bounds)
        dView.wantsLayer = true
        self.documentView = dView
        self.hasVerticalScroller = true
        self.scrollsDynamically = true
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(CollectionView.didScroll(_:)),
                                               name: NSScrollView.didLiveScrollNotification, object: self)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(CollectionView.willBeginScroll(_:)),
                                               name: NSScrollView.willStartLiveScrollNotification, object: self)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(CollectionView.didEndScroll(_:)),
                                               name: NSScrollView.didEndLiveScrollNotification, object: self)

        self.addSubview(_floatingSupplementaryView, positioned: .above, relativeTo: self.clipView!)
        self._floatingSupplementaryView.wantsLayer = true
//        if #available(OSX 10.12, *) {
//            self._floatingSupplementaryView.addConstraintsToMatchParent()
//        } else {
            _floatingSupplementaryView.frame = self.bounds
//        }
    }
    
    deinit {
        self.delegate = nil
        self.dataSource = nil
        NotificationCenter.default.removeObserver(self)
        self._reusableCells.removeAll()
        self._reusableSupplementaryView.removeAll()
        self._updateContext.reset()
        self.contentDocumentView.preparedCellIndex.removeAll()
        self.contentDocumentView.preparedSupplementaryViewIndex.removeAll()
        for view in self.contentDocumentView.subviews {
            view.removeFromSuperview()
        }
    }

    open override var scrollerStyle: NSScroller.Style {
        didSet {
//            log.debug("Scroller Style changed")
            self.reloadLayout(false)
        }
    }
    
    open override var wantsUpdateLayer: Bool { return true }
    
    open override func updateLayer() {
        self.layer?.backgroundColor = self.drawsBackground ? self.backgroundColor.cgColor : nil
    }
    
    public var leadingView: NSView? {
        didSet {
            if oldValue == leadingView { return }
            oldValue?.removeFromSuperview()
            if let v = leadingView {
                self.contentDocumentView.addSubview(v)
                
                self.contentDocumentView.addConstraints([
                    NSLayoutConstraint(item: self.contentDocumentView, attribute: .left, relatedBy: .equal,
                                       toItem: v, attribute: .left, multiplier: 1, constant: 0),
                    NSLayoutConstraint(item: self.contentDocumentView, attribute: .top, relatedBy: .equal,
                                       toItem: v, attribute: .top, multiplier: 1, constant: 0),
                    NSLayoutConstraint(item: self.contentDocumentView, attribute: .right, relatedBy: .equal,
                                       toItem: v, attribute: .right, multiplier: 1, constant: 0)
                    ])
                v.translatesAutoresizingMaskIntoConstraints = false
//                v.autoresizingMask.insert(.maxYMargin)
//                v.autoresizingMask.insert(.height)
                v.setContentHuggingPriority(NSLayoutConstraint.Priority(rawValue: 1000), for: .vertical)
                v.autoresizingMask.insert(.width)
//                v.autoresizingMask.insert(.height)
            }
        }
    }
    
    // MARK: - Registering reusable cells
    /*-------------------------------------------------------------------------------*/
    
    private var _cellClasses: [String: CollectionViewCell.Type] = [:]
    private var _cellNibs: [String: NSNib] = [:]
    
    private var _supplementaryViewClasses: [SupplementaryViewIdentifier: CollectionReusableView.Type] = [:]
    private var _supplementaryViewNibs: [SupplementaryViewIdentifier: NSNib] = [:]
    
    /**
     Register a class to be initialized when loading reusable cells

     - Parameter cellClass: A CollectionViewCell subclass
     - Parameter identifier: A reuse identifier to deque cells of this class

    */
    public func register(class cellClass: CollectionViewCell.Type, forCellWithReuseIdentifier identifier: String) {
        assert(cellClass.isSubclass(of: CollectionViewCell.self), "CollectionView: Registered cells views must be subclasses of CollectionViewCell")
        assert(!identifier.isEmpty, "CollectionView: Reuse identifier cannot be an empty or blank string")
        self._cellClasses[identifier] = cellClass
        self._cellNibs[identifier] = nil
    }
    
    /**
     Register a nib to be loaded as reusable cells

     - Parameter nib: The nib for the cell
     - Parameter identifier: A reuse identifier to deque cells from this nib
     
    */
    public func register(nib: NSNib, forCellWithReuseIdentifier identifier: String) {
        assert(!identifier.isEmpty, "CollectionView: Reuse identifier cannot be an empty or blank string")
        self._cellClasses[identifier] = nil
        self._cellNibs[identifier] = nib
    }
    
    /**
     Register a class to be initialized when loading reusable supplementary views

     - Parameter viewClass: A CollectionReusableview subclass
     - Parameter elementKind: The kind of element the class represents
     - Parameter identifier: A reuse identifier to deque views of this class

    */
    public func register(class viewClass: CollectionReusableView.Type, forSupplementaryViewOfKind kind: String, withReuseIdentifier identifier: String) {
        assert(viewClass.isSubclass(of: CollectionReusableView.self),
               "CollectionView: Registered supplementary views must be subclasses of CollectionReusableview")
        assert(!identifier.isEmpty, "CollectionView: Reuse identifier cannot be an empty or blank string")
        let id = SupplementaryViewIdentifier(kind: kind, reuseIdentifier: identifier)
        self._supplementaryViewClasses[id] = viewClass
        self._supplementaryViewNibs[id] = nil
        self._registeredSupplementaryViewKinds.insert(kind)
        self._allSupplementaryViewIdentifiers.insert(id)
    }
    
    /**
     Register a nib to be loaded as a supplementary view

     - Parameter nib: The nib for the view
     - Parameter elementKind: The kind of element this nib represents
     - Parameter identifier: A reuse identifier to deque views from this nib
     
     - Note: The nib must contain a single view whose class is set to CollectionReusableview.

    */
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
    private func _firstObjectOfClass(_ aClass: AnyClass, inNib: NSNib) -> NSView? {
        var foundObject: AnyObject?
        var topLevelObjects: NSArray?
        
        if inNib.instantiate(withOwner: self, topLevelObjects: &topLevelObjects), let objects = topLevelObjects {
            for obj in objects {
                if let o = obj as? NSView, o.isKind(of: aClass) {
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
    
    private var _reusableCells: [String: Set<CollectionViewCell>] = [:]
    private var _reusableSupplementaryView: [SupplementaryViewIdentifier: Set<CollectionReusableView>] = [:]
    
    /**
     Retrieve a cell for a given reuse identifier and index path. 
     
     If no reusable cell is available, one is created from the registered class/nib.

     - Parameter identifier: The reuse identifier
     - Parameter indexPath: The index path specifying the location of the supplementary view to load.

     - Returns: A valid CollectionReusableView

    */
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
        cell?.reuseIdentifier = identifier
        return cell!
    }
    
    /**
     Returns a reusable supplementary view located by its identifier and kind.

     - Parameter elementKind: The kind of supplementary view to retrieve. This value is defined by the layout object. This parameter must not be nil.
     - Parameter identifier: The reuse identifier for the specified view.
     - Parameter indexPath: The index path specifying the location of the cell to load

     - Returns: A valid CollectionViewCell

    */
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
        view?.reuseIdentifier = identifier
        return view!
    }
    
    final func enqueueCellForReuse(_ item: CollectionViewCell) {
        item.prepareForReuse()
        item.isHidden = true
//        item.indexPath = nil
        guard let id = item.reuseIdentifier else { return }
        if self._reusableCells[id] == nil {
            self._reusableCells[id] = []
        }
        self._reusableCells[id]?.insert(item)
    }
    
    final func enqueueSupplementaryViewForReuse(_ view: CollectionReusableView, withIdentifier: SupplementaryViewIdentifier) {
        view.prepareForReuse()
        view.isHidden = true
//        view.indexPath = nil
        let newID = SupplementaryViewIdentifier(kind: withIdentifier.kind, reuseIdentifier: view.reuseIdentifier ?? withIdentifier.reuseIdentifier)
        if self._reusableSupplementaryView[newID] == nil {
            self._reusableSupplementaryView[newID] = []
        }
        self._reusableSupplementaryView[newID]?.insert(view)
    }
    
    final func _loadCell(at indexPath: IndexPath) -> CollectionViewCell {
        let cell = self.cellForItem(at: indexPath) ?? self.dataSource?.collectionView(self, cellForItemAt: indexPath)
        precondition(cell != nil, "Unable to load cell for item at \(indexPath)")
        assert(cell!.collectionView != nil, "Attemp to load cell without using deque")
        return cell!
    }
    
    final func _loadSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> CollectionReusableView {
        let view = self.supplementaryView(forElementKind: elementKind, at: indexPath)
            ?? self.dataSource?.collectionView?(self, viewForSupplementaryElementOfKind: elementKind, at: indexPath)
        precondition(view != nil, "Failed to load supplementary view of kind \(elementKind) at index path \(indexPath)")
        assert(view!.collectionView != nil, "Attemp to load cell without using deque")
        return view!
    }
    
    // MARK: - Floating View
    /*-------------------------------------------------------------------------------*/
    let _floatingSupplementaryView = FloatingSupplementaryView(frame: NSRect.zero)
    
    /**
     A view atop the collection view used to display non-scrolling accessory views
     */
    public var  floatingContentView: NSView {
        return _floatingSupplementaryView
    }
    
    /**
     Adds the given view to the floating content view
     
     - Parameter view: The view to add
     
     */
    public func addAccessoryView(_ view: NSView) {
        self._floatingSupplementaryView.addSubview(view)
    }
    
    // MARK: - Data
    /*-------------------------------------------------------------------------------*/
    
    private var sections = [Int]()
//    private var storage = [[Item]]()
    
    /**
     Returns the number of sections displayed by the collection view.

     - Returns: The number of sections
     
    */
    public var numberOfSections: Int { return self.sections.count }
    
    /**
     Returns the number of items in the specified section.

     - Parameter section: The index of the section for which you want a count of the items.

     - Returns: The number of items in the specified section

    */
    public func numberOfItems(in section: Int) -> Int {
        return self.sections.object(at: section) ?? 0
    }
    
    /**
     Reloads all the data and views in the collection view
     */
    open func reloadData() {
        self.contentDocumentView.reset()
        
        self._reloadDataCounts()
        
        doLayoutPrep()
        self.delegate?.collectionViewDidReloadLayout?(self)
        setContentViewSize()
        self.reflectScrolledClipView(self.clipView!)
        
        self._selectedIndexPaths.formIntersection(self.allIndexPaths)
        self.contentDocumentView.prepareRect(_preperationRect, animated: false)
    }
    
    private func _reloadDataCounts() {
        self.sections = fetchDataCounts()
    }
    
    private func fetchDataCounts() -> [Int] {
        let sCount = self.dataSource?.numberOfSections(in: self) ?? 0
        var res = [Int]()
        for sIndex in 0..<sCount {
            res.append(self.dataSource?.collectionView(self, numberOfItemsInSection: sIndex) ?? 0)
        }
        return res
    }
    
    // MARK: - Layout
    /*-------------------------------------------------------------------------------*/
    
    /**
        The layout used to organize the collected view’s items.
     
     - Note: Assigning a new layout object to this property does **NOT** apply the layout to the collection view. Call `reloadData()` or `reloadLayout(_:)` to do so.
     */
    public var collectionViewLayout: CollectionViewLayout = CollectionViewLayout() {
        didSet {
            collectionViewLayout.collectionView = self
            self.hasHorizontalScroller = collectionViewLayout.scrollDirection == .horizontal
            self.hasVerticalScroller = collectionViewLayout.scrollDirection == .vertical
        }}
    
    /// The visible rect of the document view that is visible
    public var contentVisibleRect: CGRect { return self.documentVisibleRect }
    
    /// The total size of all items/views
    open override var contentSize: NSSize {
        return self.collectionViewLayout.collectionViewContentSize
    }
    
    /// The offset of the content view
    public var contentOffset: CGPoint {
        get { return self.contentVisibleRect.origin }
        set {
            self.isScrollEnabled = true
            self.clipView?.shouldAnimateOriginChange = false
            self.clipView?.scroll(to: newValue)
            self.reflectScrolledClipView(self.clipView!)
            self.contentDocumentView.prepareRect(self.contentVisibleRect)
            self.contentDocumentView.preparedRect = self.contentVisibleRect
        }
    }
    
    /**
     Force layout of all items, not just those in the visible content area
     
     - Note: This is not recommended for large data sets. It can be useful for smaller collection views to better manage transitions/animations.
     
     */
    public var prepareAll: Bool = false
    
    // Returns the rect to prepare based on prepareAll option
    private var _preperationRect: CGRect {
        return prepareAll
            ? self.contentDocumentView.frame
            : self.contentVisibleRect
    }
    
    // Used to track positioning during resize/layout
    private var _topIP: IndexPath?
    
    /**
     Returns the frame for the specified section
     
     - Parameter indexPath: The index path of the section for which you want the frame
     
     */
    open func frameForSection(at index: Int) -> CGRect? {
        return self.collectionViewLayout.rectForSection(index)
    }
    public func frameForSection(at indexPath: IndexPath) -> CGRect? {
        return self.collectionViewLayout.rectForSection(indexPath._section)
    }

    public final func layoutAttributesForItem(at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
        return self.collectionViewLayout.layoutAttributesForItem(at: indexPath)
    }
    
    @available(*, unavailable, renamed: "layoutAttributesForSupplementaryView(ofKind:at:)")
    public final func layoutAttributesForSupplementaryElement(ofKind kind: String, atIndexPath indexPath: IndexPath) -> CollectionViewLayoutAttributes? { return nil }
    
    public final func layoutAttributesForSupplementaryView(ofKind kind: String, at indexPath: IndexPath) -> CollectionViewLayoutAttributes? {
        return self.collectionViewLayout.layoutAttributesForSupplementaryView(ofKind: kind, at: indexPath)
    }
    
    /**
     Reload the data (section & item counts) when the collectionView bounds change. Defaults to false.
     
     - Note:
     This will only be applied if the layout is also invalidated via `shouldInvalidateLayout(forBoundsChange:)`
     
     - Discussion:
     Set to `true` if the number of sections or items per section can change depending on the collection view's size For example if you want to limit the size of a section but maintain item size, you can calculate the number of items that will fit in the section based on the size of the collection view and return that value in collectionView(_:numberOfItemsIn:) from the collection views data source.
     
     +----------+      +-----------------+
     |          |      |                 |
     |  +----+  |      |  +----+ +----+  |
     |  |    |  |      |  |    | |    |  |
     |  |    |  |      |  |    | |    |  |
     |  +----+  | +--> |  +----+ +----+  |
     |          |      |                 |
     +----------+      +-----------------+
     |Section 2 |      |Section 2        |
     +----------+      +-----------------+
     |          |      |                 |
     +----------+      +-----------------+
     
    */
    public var reloadDataOnBoundsChange: Bool = false
    
    private var _lastViewSize: CGSize = CGSize.zero
    private func setContentViewSize(_ animated: Bool = false) {
        let newSize = self.collectionViewLayout.collectionViewContentSize
        
        if animated {
            NSAnimationContext.runAnimationGroup({ (ctx) in
                ctx.duration = self.animationDuration
                contentDocumentView.animator().frame.size = newSize
            }, completionHandler: nil)
        }
        else {
            contentDocumentView.frame.size = newSize
            contentDocumentView.frame.origin.x = self.contentInsets.left
        }
    }
    
    open var needsLayoutReload: Bool = false {
        didSet {
            if needsLayoutReload { self.needsLayout = true }
        }
    }
    
    open override func layout() {
        self._floatingSupplementaryView.frame = self.bounds
        self.layoutLeadingViews()
        super.layout()
        if needsLayoutReload || self.collectionViewLayout.shouldInvalidateLayout(forBoundsChange: self.contentVisibleRect) {
            if reloadDataOnBoundsChange {
                self._reloadDataCounts()
            }
            doLayoutPrep()
            setContentViewSize()
            
            if let ip = _topIP {
                self._scrollItem(at: ip, to: .leading, animated: false, prepare: false, completion: nil)
            }
            self.reflectScrolledClipView(self.clipView!)
            self.contentDocumentView.prepareRect(_preperationRect, force: true)
            self.delegate?.collectionViewDidReloadLayout?(self)
        }
        else {
            self.contentDocumentView.prepareRect(_preperationRect, force: false)
        }
        self.needsLayoutReload = false
    }
    
    @available(*, unavailable, renamed: "reloadLayout(_:scrollPosition:completion:)")
    public func relayout(_ animated: Bool, scrollPosition: CollectionViewScrollPosition = .nearest, completion: AnimationCompletion? = nil) { }
    
    /**
     Reload the collection view layout and apply the updated frames to the cells/views.
     
     - parameter animated:       If the layout should be animated
     - parameter scrollPosition: Where (if any) the scroll position should be pinned
     */
    public func reloadLayout(_ animated: Bool, scrollPosition: CollectionViewScrollPosition = .nearest, completion: AnimationCompletion? = nil) {
        self._reloadLayout(animated, scrollPosition: scrollPosition, completion: completion, needsRecalculation: true)
    }
    
    private func doLayoutPrep() {
        if !self.inLiveResize {
            if self.collectionViewLayout.scrollDirection == .vertical {
                let ignore = self.leadingView?.bounds.size.height ?? self.contentInsets.top
                if contentVisibleRect.origin.y > ignore {
                    self._topIP = indexPathForFirstVisibleItem
                }
            }
            else {
                self._topIP = indexPathForFirstVisibleItem
            }
        }
        self.delegate?.collectionViewWillReloadLayout?(self)
        self.leadingView?.layoutSubtreeIfNeeded()
        self.collectionViewLayout.prepare()
    }
    
    private func layoutLeadingViews() {
        if let v = self.leadingView {
            v.frame.size.width = self.bounds.size.width - (self.contentInsets.left + self.contentInsets.right)
            v.frame.origin.x = 0
        }
//        if let v = self.leadingView {
//            v.frame.origin.x = self.contentInsets.left
//            v.frame.size.width = self.bounds.size.width - (self.contentInsets.left + self.contentInsets.right)
//        }
    }
    
    private func _reloadLayout(_ animated: Bool, scrollPosition: CollectionViewScrollPosition = .nearest, completion: AnimationCompletion?, needsRecalculation: Bool) {
        self.layoutLeadingViews()
        
        if needsRecalculation {
            doLayoutPrep()
        }
        let newContentSize = self.collectionViewLayout.collectionViewContentSize
        
        // If the size changed we need to do some extra prep
        let sizeChanged = newContentSize != _lastViewSize
        
        setContentViewSize(animated)
        
        struct ViewSpec {
            let view: CollectionReusableView
            let frame: CGRect
            let newIP: IndexPath
        }
        
        var viewSpecs = [ViewSpec]()
        if sizeChanged {
            for view in self.contentDocumentView.preparedCellIndex {
                let v = view.value
                if !v.isHidden, let attrs = v.attributes {
                    let newRect = self.convert(attrs.frame, from: v.superview)
                    viewSpecs.append(ViewSpec(view: v, frame: newRect, newIP: view.index))
                }
            }
        }
        
        for view in self.contentDocumentView.preparedSupplementaryViewIndex {
            let v = view.value
            if !view.value.isHidden, let attrs = v.attributes {
                let newRect = self.convert(attrs.frame, from: v.superview)
                viewSpecs.append(ViewSpec(view: v, frame: newRect, newIP: view.key.indexPath!))
                // absoluteCellFrames[v] = self.convert(attrs.frame, from: v.superview)
            }
        }
        
        // TODO: Get removed items from pending updates and adjust them
        if sizeChanged {
            if scrollPosition != .none, let ip = self._topIP,
                let rect = self.collectionViewLayout.scrollRectForItem(at: ip, atPosition: scrollPosition) ?? self.rectForItem(at: ip) {
                self._scrollRect(rect, to: scrollPosition, animated: false, prepare: false, completion: nil)
            }
            self.reflectScrolledClipView(self.clipView!)
        }
        
        for spec in viewSpecs {
            if let attrs = spec.view.attributes, attrs.representedElementCategory == CollectionElementCategory.supplementaryView {
                if validateIndexPath(spec.newIP),
                    let newAttrs = self.layoutAttributesForSupplementaryView(ofKind: attrs.representedElementKind!, at: spec.newIP) {
                    
                    if newAttrs.floating != attrs.floating {
                        spec.view.removeFromSuperview()
                        if newAttrs.floating {
                            self._floatingSupplementaryView.addSubview(spec.view)
                            spec.view.frame = self._floatingSupplementaryView.convert(spec.frame, from: self)
                        }
                        else {
                            self.contentDocumentView.addSubview(spec.view)
                            spec.view.frame = self.contentDocumentView.convert(spec.frame, from: self)
                        }
                    }
                    else if newAttrs.floating {
                        spec.view.frame = self._floatingSupplementaryView.convert(spec.frame, from: self)
                    }
                    else {
                        let cFrame = self.contentDocumentView.convert(spec.frame, from: self)
                        spec.view.frame = cFrame
                    }
                    // If the view is going back into the document view, let it fall through, it's the same as for cells
                    continue
                }
                
            }
            
            let cFrame = self.contentDocumentView.convert(spec.frame, from: self)
            spec.view.frame = cFrame
        }
        
        self.contentDocumentView.preparedRect = self._preperationRect
        self.contentDocumentView.prepareRect(self._preperationRect, animated: animated, force: true, completion: completion)
        self.delegate?.collectionViewDidReloadLayout?(self)
        
    }

    // MARK: - Live Resize
    /*-------------------------------------------------------------------------------*/
    private var _resizeStartBounds: CGRect = CGRect.zero
    
    open override func viewWillStartLiveResize() {
        self.horizontalScroller?.alphaValue = 0
        self.verticalScroller?.alphaValue = 0
        _resizeStartBounds = self.contentVisibleRect
        if self.collectionViewLayout.scrollDirection == .vertical {
            let ignore = self.leadingView?.bounds.size.height ?? self.contentInsets.top
            if contentVisibleRect.origin.y > ignore {
                _topIP = indexPathForFirstVisibleItem
            }
        }
        else {
            _topIP = indexPathForFirstVisibleItem
        }
    }
    
    open override func viewDidEndLiveResize() {
        self.horizontalScroller?.alphaValue = 1
        self.verticalScroller?.alphaValue = 1
        self.setContentViewSize()
        self.reflectScrolledClipView(self.clipView!)
        _topIP = nil
        self.delegate?.collectionViewDidEndLiveResize?(self)
        self.contentDocumentView.preparedRect = self._preperationRect
    }
    
    // MARK: - Scroll Handling
    /*-------------------------------------------------------------------------------*/
    override open class var isCompatibleWithResponsiveScrolling: Bool { return true }
    
    public var isScrollEnabled: Bool {
        set { self.clipView?.scrollEnabled = newValue }
        get { return self.clipView?.scrollEnabled ?? true }
    }
    
    /**
     Returns true if the collection view is currently scrolling
    */
    public internal(set) var isScrolling: Bool = false
    
    private var _previousOffset = CGPoint.zero
    private var _offsetMark = CACurrentMediaTime()
    
    /**
     Returns the current velocity of a scroll in points/second
    */
    public private(set) var scrollVelocity = CGPoint.zero
    
    /**
     Returns the peak valocity of a scroll during the last scrolling session
     
     ## Example Usage
     If your cells require complex loading that may slow scrolling performance, `peakScrollVelocity` can be used to determine if the cell content should be reduced or delayed until after the scrolling ends.
     
     For example in CollectionViewCell
     ```
     override func viewDidDisplay() {
        if self.collectionView?.isScrolling != true ||  (self.collectionView?.peakScrollVelocity.maxAbsVelocity ?? 0) < 200 {
            // load complex content
        }
        else {
            // Wait until we are done scrolling
        }
     }
     
     func loadContent() { Do complex loading }
     ```
     
     Then, in your collection view's delegate
     ```
     func collectionViewDidEndScrolling(_ collectionView: CollectionView, animated: Bool) {
        guard collectionView.peakScrollVelocity.maxAbsVelocity > 200 else { return }
        for ip in collectionView.indexPathsForVisibleItems {
            if let c = collectionView.cellForItem(at:ip) as? MyCellClass {
                c.loadContent
            }
        }
     }
     ```
     
    */
    public private(set) var peakScrollVelocity = CGPoint.zero
    
    @objc final func didScroll(_ notification: Notification) {
        let rect = _preperationRect
        self.contentDocumentView.prepareRect(rect)
        
        let _prev = self._previousOffset
        self._previousOffset = self.contentVisibleRect.origin
        let deltaY = _prev.y - self._previousOffset.y
        let deltaX = _prev.x - self._previousOffset.x
        
        self.scrollVelocity = CGPoint(x: deltaX, y: deltaY)
        
        self.peakScrollVelocity = peakScrollVelocity.maxVelocity(self.scrollVelocity)
        self._offsetMark = CACurrentMediaTime()
        self.delegate?.collectionViewDidScroll?(self)
    }
    
    @objc final func willBeginScroll(_ notification: Notification) {
        self.isScrolling = true
        self.delegate?.collectionViewWillBeginScrolling?(self, animated: false)
        self._previousOffset = self.contentVisibleRect.origin
        self.peakScrollVelocity = CGPoint.zero
        self.scrollVelocity = CGPoint.zero
    }
    
    @objc final func didEndScroll(_ notification: Notification) {
        self.isScrolling = false
        
        self.delegate?.collectionViewDidEndScrolling?(self, animated: false)
        self.scrollVelocity = CGPoint.zero
        self.peakScrollVelocity = CGPoint.zero
        
        if let point = self.window?.convertFromScreen(NSRect(origin: NSEvent.mouseLocation, size: CGSize.zero)).origin {
            let loc = self.contentDocumentView.convert(point, from: nil)
            if let ip = self.indexPathForHighlightedItem, let cell = self.cellForItem(at: ip) {
                cell.setHighlighted(cell.frame.contains(loc), animated: true)
            }
        
            if trackSectionHover && NSApp.isActive {
                self.delegate?.collectionView?(self, mouseMovedToSection: indexPathForSection(at: loc))
            }
        }
    }

    /**
     Returns the lowest index path of all visible items
     */
    open var indexPathsForVisibleSections: [IndexPath] {
        
        var ips = [IndexPath]()
        
        let visible = self.contentVisibleRect
        for idx in 0..<self.numberOfSections {
            if let rect = self.frameForSection(at: idx), visible.intersects(rect) {
                ips.append(IndexPath.for(section: idx))
            }
        }
        return ips
    }
    
    /**
     Returns the lowest index path of all visible items
    */
    open var indexPathForFirstVisibleItem: IndexPath? {
        if self.delegate?.collectionViewLayoutAnchor == nil {
            return  _indexPathForFirstVisibleItem
        }
        return self.delegate?.collectionViewLayoutAnchor?(self)
    }
    
    /**
     Same as indexPathForFirstVisibleItem but doesn't ask the delegate for a suggestion. This is a convenient variable to use in collectionViewLayoutAnchor(_:) but asking the delegate within is not possibe.
    */
    open var _indexPathForFirstVisibleItem: IndexPath? {
        var closest: (IndexPath, CGFloat)?
        for ip in self.contentDocumentView.preparedCellIndex.orderedIndexes {
            if let attributes = self.collectionViewLayout.layoutAttributesForItem(at: ip) {
                
                if contentVisibleRect.contains(attributes.frame) {
                    return ip
                }
                else {
                    let shared = contentVisibleRect.sharedArea(with: attributes.frame)
                    if closest == nil || closest!.1 < shared {
                        closest = (ip, shared)
                    }
                }
            }
        }
        return closest?.0
    }
    
    // MARK: - Batch Updates
    /*-------------------------------------------------------------------------------*/
    
    /// The duration of animations when performing animated layout changes
    public var animationDuration: TimeInterval = 0.4
    
	/**
	Perform multiple updates to be applied together

	- Parameter updates: A closure in which to apply the desired changes
	- Parameter completion: A closure to call when the animation finished

	*/
    public func performBatchUpdates(_ updates: (() -> Void), completion: AnimationCompletion?) {
        self.beginEditing()
        updates()
        self.endEditing(true, completion: completion)
    }
    
    // MARK: - Manipulating Sections
    /*-------------------------------------------------------------------------------*/
    
    public typealias SectionMove = (source: Int, destination: Int)
    
    public func reloadSupplementaryViews(in sections: IndexSet, animated: Bool) {
        
        var prepared = [Int: [(id: SupplementaryViewIdentifier, view: CollectionReusableView)]]()
        for supp in contentDocumentView.preparedSupplementaryViewIndex {
            guard let sec = supp.0.indexPath?._section, sections.contains(sec) else { continue }
            if prepared[sec] == nil { prepared[sec] = [(supp.key, supp.value)] }
            else { prepared[sec]?.append((supp.key, supp.value)) }
        }
        
        var updates = [ItemUpdate]()
        
        for item in prepared {
            for viewRef in item.value {
                let id = viewRef.id
                let oldView = viewRef.view
                contentDocumentView.preparedSupplementaryViewIndex.removeValue(forKey: id)
                updates.append(ItemUpdate(view: oldView, attrs: oldView.attributes!, type: .remove, identifier: id))
            }
        }
        self.contentDocumentView.pendingUpdates.append(contentsOf: updates)
    }
    
    public func reloadSections(_ sections: IndexSet, animated: Bool) {
        guard !sections.isEmpty else { return }
        self.beginEditing()
        self._updateContext.reloadSections.formUnion(sections)
        self.endEditing(animated)
    }
    
	/**
	Insert sections at the given indexes

	- Parameter sections: The sections to insert
	- Parameter animated: If the update should be animated

     - Note: If called within performBatchUpdate(_:completion:) sections should be the final indexes after other updates are applied
	*/
    public func insertSections(_ sections: IndexSet, animated: Bool) {
        guard !sections.isEmpty else { return }
        self.beginEditing()
        self._updateContext.sections.inserted.formUnion(sections)
        self.endEditing(animated)
    }
    
	/**
	Remove sections and their items

	- Parameter sections: The sections to delete
	- Parameter animated: If the update should be animated

     - Note: If called within performBatchUpdate(_:completion:) sections should be the index prior to any other updates
	*/
    public func deleteSections(_ sections: IndexSet, animated: Bool) {
        guard !sections.isEmpty else { return }
        self.beginEditing()
        self._updateContext.sections.deleted.formUnion(sections)
        self.endEditing(animated)
    }
    
    /**
     Move a section and its items
     
     - Parameter section: The source index of the section to move
     - Parameter newSection: The destination index to move the section to
     - Parameter animated: If the move should be animated
     
     - Note: If called within performBatchUpdate(_:completion:): 
     - Source should be the index prior to any other updates
     - Destination should be the final index after all other updates

	*/
    public func moveSection(_ section: Int, to newSection: Int, animated: Bool) {
        self.beginEditing()
        self._updateContext.sections.moved[section] = newSection
        self.endEditing(animated)
    }
    
    // MARK: - Manipulating items
    /*-------------------------------------------------------------------------------*/
    
    public typealias Move = (source: IndexPath, destination: IndexPath)
    
	/**
	Insert items at specific index paths

	- Parameter indexPaths: The index paths at which to insert items.
	- Parameter animated: If the insertion should be animated
     
	*/
    public func insertItems(at indexPaths: [IndexPath], animated: Bool) {
        guard !indexPaths.isEmpty else { return }
        self.beginEditing()
        self._updateContext.items.inserted.formUnion(indexPaths)

        self.endEditing(animated)
    }
    
    /**
     Deletes the items at the specified index paths.

     - Parameter indexPaths: The index paths for the items you want to delete
     - Parameter animated: If the updates should be animated

    */
    public func deleteItems(at indexPaths: [IndexPath], animated: Bool) {
        guard !indexPaths.isEmpty else { return }
        self.beginEditing()
        self._updateContext.items.deleted.formUnion(indexPaths)
        self.endEditing(animated)
    }
    
    /**
     Reload the items and the given index paths. 
     
     The cells will be reloaded, asking the data source for the cell to replace with.

     - Parameter indexPaths: The index paths for the items you want to reoad
     - Parameter animated: If the updates should be animated

    */
    public func reloadItems(at indexPaths: [IndexPath], animated: Bool) {
        guard !indexPaths.isEmpty else { return }
        self.beginEditing()
        self._updateContext.reloadedItems.formUnion(indexPaths)
        self.endEditing(animated)
    }
    
    /**
     Moves the item from it's current index path to another
     
     - Parameter indexPath: The index path for the item to move
     - Parameter destinationIndexPath: The index path to move the item to
     - Parameter animated: If the update should be animated

    */
    public func moveItem(at indexPath: IndexPath, to destinationIndexPath: IndexPath, animated: Bool) {
        self.beginEditing()
        self._updateContext.items.moved[indexPath] = destinationIndexPath
        self.endEditing(animated)
    }
    
    public func moveItems(_ moves: [Move], animated: Bool) {
        guard !moves.isEmpty else { return }
        self.beginEditing()
        for m in moves {
            self._updateContext.items.moved[m.source] = m.destination
        }
        self.endEditing(animated)
    }
    
    // MARK: - Internal Manipulation
    /*-------------------------------------------------------------------------------*/

    private struct ItemTracker {
        var inserted = Set<IndexPath>()
        var deleted = Set<IndexPath>()
        var moved = IndexedSet<IndexPath, IndexPath>()
        var isEmpty: Bool {
            return deleted.isEmpty && inserted.isEmpty && moved.isEmpty
        }
    }
    private struct SectionTracker {
        var deleted   = IndexSet() // Original Indexes for deleted sections
        var inserted  = IndexSet() // Destination Indexes for inserted sections
        var moved = IndexedSet<Int, Int>() // Source and Destination indexes for moved sections
        var isEmpty: Bool {
            return deleted.isEmpty && inserted.isEmpty && moved.isEmpty
        }
    }
    
    private class SectionValidator: Equatable, CustomStringConvertible {
        var source: Int?
        var target: Int?
        var count: Int = 0
        
        var estimatedCount: Int {
            guard self.target != nil else { return 0 }
            guard self.source != nil else { return count }
            return count + (inserted.count + movedIn.count) - (removed.count + movedOut.count)
        }
        var inserted = IndexSet()
        var removed = IndexSet()
        var movedOut = IndexSet()
        var movedIn = IndexSet()
        var moves = IndexedSet<Int, Int>()
        
        init(source: Int?, target: Int?, count: Int) {
            self.source = source
            self.target = target
            self.count = count
        }
        
        static func ==(lhs: CollectionView.SectionValidator, rhs: CollectionView.SectionValidator) -> Bool {
            return lhs.source == rhs.source && lhs.target == rhs.target
        }
        
        var description: String {
            return "Source: \(source ?? -1) Target: \(self.target ?? -1) Count: \(count) expected: \(estimatedCount)"
        }
    }
    
    private struct Section {

        var isInserted: Bool
        var final: [Int?]
        
        init(validator: SectionValidator) {
            // Inserted
            if validator.source == nil {
                self.isInserted = true
                self.final = []
            }
            else {
                self.isInserted = false
                
                let oldCount = validator.count
                let newCount = validator.estimatedCount
                let inserted = validator.inserted.union(validator.movedIn)
                var transferred = validator.removed.union(validator.movedOut)
                
                var temp = [Int?](repeatElement(nil, count: newCount))
                
                for i in inserted {
                    temp[i] = -1
                }
                for m in validator.moves {
                    transferred.insert(m.index)
                    temp[m.value] = m.index
                }
                
                var idx = 0
                func incrementInsert() {
                    while idx < temp.count - 1 && temp[idx] != nil {
                        idx += 1
                    }
                }
                for i in 0..<oldCount where !transferred.contains(i) {
                    incrementInsert()
                    temp[idx] = i
                }
                
                // Temp now has the source for each target index (inserted are -1)
                var destinations = [Int?](repeatElement(nil, count: oldCount))
                for (target, source) in temp.enumerated() where source! >= 0 {
                    destinations[source!] = target
                }
                self.final = destinations
            }
        }
        
        mutating func index(of previousIndex: Int) -> Int? {
            return final[previousIndex]
        }
    }
    
    struct Item {
        var source: Int?
        var target: Int?
    }
    
    private struct UpdateContext {
        var sections = SectionTracker()
        var items = ItemTracker()
        var reloadedItems = Set<IndexPath>() // Track reloaded items to reload after adjusting IPs
        var reloadSections = IndexSet()
        
        var updates = [ItemUpdate]()
        
        mutating func reset() {
            self.items = ItemTracker()
            self.sections = SectionTracker()
            updates.removeAll()
            reloadedItems.removeAll()
        }
        
        var isEmpty: Bool {
            return sections.isEmpty && items.isEmpty && reloadedItems.isEmpty && reloadSections.isEmpty
        }
    }
    
    private var _updateContext = UpdateContext()
    private var _editing = 0
    private var _sectionMap: [Int: Int] = [:]
    
    private func beginEditing() {
        if _editing == 0 {
            self._extendingStart = nil
            self._updateContext.reset()
        }
        _editing += 1
    }
    
    private func endEditing(_ animated: Bool, completion: AnimationCompletion? = nil) {
        
        precondition(_editing > 0, "Unbalanced calls to endEditing(_:). This is an internal error of CollectionView")
        if _editing > 1 {
            _editing -= 1
            return
        }
        _editing = 0
        
        guard !self._updateContext.isEmpty else {
            completion?(true)
            return
        }
        
        let oldData = self.sections
        self._reloadDataCounts()
        let newData = self.sections
        
        for idx in self._updateContext.reloadSections {
            // Reuse existing operation to reload, delete, and insert items in the section as needed
            precondition(!self._updateContext.sections.deleted.contains(idx), "Cannot delete section that is also being reloaded")
            let oldCount = oldData[idx]
            let newCount = newData[idx]
            let shared = min(oldCount, newCount)
            let update = Set(IndexPath.inRange(0..<shared, section: idx))
            self._updateContext.reloadedItems.formUnion(update)
            if oldCount > newCount {
                let delete = Set(IndexPath.inRange(shared..<oldCount, section: idx))
                self._updateContext.items.deleted.formUnion(delete)
            }
            else if oldCount < newCount {
                let insert = IndexPath.inRange(shared..<newCount, section: idx)
                self._updateContext.items.inserted.formUnion(insert)
            }
        }
        
        guard !self._updateContext.items.isEmpty || !self._updateContext.sections.isEmpty else {
            if !_updateContext.reloadedItems.isEmpty {
                for ip in _updateContext.reloadedItems {
                    guard let cell = self.contentDocumentView.preparedCellIndex[ip] else { continue }
                    self.contentDocumentView.preparedCellIndex[ip] = _prepareReplacementCell(for: cell, at: ip)
                }
                self.reloadLayout(animated, scrollPosition: .none, completion: completion)
            }
            else {
                completion?(true)
            }
            return
        }
        
        // Validate the section changes
        var sectionDelta = self._updateContext.sections.inserted.count - self._updateContext.sections.deleted.count
        precondition(newData.count - oldData.count == sectionDelta, "Invalid section changes. Had \(oldData.count) delta of \(sectionDelta) is \(oldData.count - sectionDelta) but expected \(newData.count)")
        
        var source = [SectionValidator]()
        var target = [SectionValidator?](repeatElement(nil, count: newData.count))
        
        // Populate source with existing data
        for s in oldData.enumerated() {
            source.append(SectionValidator(source: s.offset, target: nil, count: s.element))
        }
        
        // Populate target with inserted
        for s in _updateContext.sections.inserted {
            target[s] = SectionValidator(source: nil, target: s, count: newData[s])
        }
        
        // The things in source that we want to ignore beow
        var transferred = _updateContext.sections.deleted
        
        // Populate target with moved
        for m in _updateContext.sections.moved {
            transferred.insert(m.0)
            source[m.0].target = m.1
            target[m.1] = source[m.0]
        }
        
        // Insert the remaining sections from source that are carrying over (not deleted)
        // After this target should be fully populated
        var idx = 0
        func incrementInsert() {
            while idx < target.count && target[idx] != nil {
                idx += 1
            }
        }
        for section in source where !transferred.contains(section.source!) {
            incrementInsert()
            section.target = idx
            target[idx] = section
        }
        
        // Dispatch out the item changes to each section
        // target or source are used depending on the type of action and if it is refferring to a new index path or an old one
        for d in _updateContext.items.deleted {
            source[d._section].removed.insert(d._item)
        }
        for i in _updateContext.items.inserted {
            target[i._section]!.inserted.insert(i._item)
        }
        for m in _updateContext.items.moved {
            let s = source[m.0._section]
            let t = target[m.1._section]!
            if s == t {
                s.moves[m.0._item] = m.1._item
            }
            else {
                s.movedOut.insert(m.0._item)
                t.movedIn.insert(m.1._item)
            }
        }
 
        // Validate the final sections
        var final = target.map { (section) -> Section in
            guard let s = section else {
                preconditionFailure("CollectionView: missing section after updates")
            }
            precondition(s.target != nil, "Invalid target index for section \(s)")
            precondition(s.estimatedCount == newData[s.target!], "Invalid update: invalid number of items in section \(s.target!). The number of items contained in an existing section after the update \(s.estimatedCount) must be equal to the number of items contained in that section before the update \(s.count), plus or minus the number of items inserted or deleted from that section (\(s.inserted.count) inserted, \(s.removed.count) deleted) and plus or minus the number of items moved into or out of that section (\(s.movedIn.count) moved in, \(s.movedOut.count) moved out).")
            return Section(validator: s)
        }
        
        func section(for previousSection: Int) -> Int? {
            return source[previousSection].target
        }
        
        func indexPath(for previous: IndexPath) -> IndexPath? {
            if let ip = _updateContext.items.moved[previous] {
                return ip
            }
            guard let s = section(for: previous._section) else { return nil }
            guard let i = final[s] .index(of: previous._item) else { return nil }
            return IndexPath.for(item: i, section: s)
        }
        
        // Do the layout prep
        doLayoutPrep()

        // Update selections
        self._selectedIndexPaths = Set(self._selectedIndexPaths.compactMap { (ip) -> IndexPath? in
            return indexPath(for: ip)
        })
        
        // Update the supplementary views
        if self._updateContext.sections.isEmpty == false {
            var updateViewIndex = [SupplementaryViewIdentifier: CollectionReusableView]()
            for (id, view) in self.contentDocumentView.preparedSupplementaryViewIndex {
                guard let ip = id.indexPath else {
                    log.error("Collection View Error: A supplemenary view identifier has a nil indexPath when trying to adjust views")
                    continue
                }
                
                guard let newSection = section(for: ip._section) else {
                    // The section was deleted
                    if let attrs = view.attributes {
                        _updateContext.updates.append(ItemUpdate(view: view, attrs: attrs, type: .remove, identifier: id))
                    }
                    continue
                }
                if ip._section == newSection {
                    // No changes
                    updateViewIndex[id] = view
                }
                else {
                    let newIP = IndexPath.for(section: newSection)
                    let newID = id.copy(with: newIP)
                    updateViewIndex[newID] = view
                    _updateContext.updates.append(ItemUpdate(view: view, indexPath: newIP, type: .update, identifier: newID))
                }
            }
            self.contentDocumentView.preparedSupplementaryViewIndex = updateViewIndex
        }
        
        var updatedCellIndex = IndexedSet<IndexPath, CollectionViewCell>()
        for (currentIP, cell) in self.contentDocumentView.preparedCellIndex {
            
            guard let ip = indexPath(for: currentIP) else {
                _updateContext.updates.append(ItemUpdate(cell: cell, attrs: cell.attributes!, type: .remove))
                continue
            }
            
            let view = _updateContext.reloadedItems.contains(currentIP)
                ? _prepareReplacementCell(for: cell, at: ip)
                : cell
            
            updatedCellIndex[ip] = cell
            
            if ip != currentIP {
                _updateContext.updates.append(ItemUpdate(cell: view, indexPath: ip, type: .update))
            }
        }
        
        self.contentDocumentView.pendingUpdates = _updateContext.updates
        self.contentDocumentView.preparedCellIndex = updatedCellIndex
        self._reloadLayout(animated, scrollPosition: .none, completion: completion, needsRecalculation: false)
       
    }
    
    private func _prepareReplacementCell(for currentCell: CollectionViewCell, at indexPath: IndexPath) -> CollectionViewCell {
        defer {
            _ = self.contentDocumentView.preparedCellIndex.remove(currentCell)
            _ = self.contentDocumentView.preparedCellIndex.removeValue(for: indexPath)
        }
        
        guard let newCell = self.dataSource?.collectionView(self, cellForItemAt: indexPath) else {
            assertionFailure("For some reason collection view tried to load cells without a data source")
            return currentCell
        }
        precondition(newCell.collectionView != nil, "Attempt to load cell without using deque:")
        
        if newCell == currentCell {
            return newCell
        }
        
        let removal = ItemUpdate(cell: currentCell, attrs: currentCell.attributes!, type: .remove)
        self.contentDocumentView.removeItem(removal)
        
        if let a = currentCell.attributes?.copyWithIndexPath(indexPath) {
            newCell.apply(a, animated: false)
        }
        if newCell.superview == nil {
            self.contentDocumentView.addSubview(newCell)
        }
        newCell.selected = self._selectedIndexPaths.contains(indexPath)
        newCell.viewDidDisplay()
        return newCell
        
    }
    
    // MARK: - Mouse Tracking (section highlight)
    /*-------------------------------------------------------------------------------*/
    
    /**
     If true, the delegate's `collectionView(_:,mouseMovedToSection:)` will be notified when the cursor is within a section frame
    */
    public var trackSectionHover: Bool = false {
        didSet { self.addTracking() }
    }
    private var _trackingArea: NSTrackingArea?
    private func addTracking() {
        if let ta = _trackingArea {
            self.removeTrackingArea(ta)
        }
        if trackSectionHover {
            _trackingArea = NSTrackingArea(rect: self.bounds,
                                           options: [NSTrackingArea.Options.activeInActiveApp,
                                                     NSTrackingArea.Options.mouseEnteredAndExited,
                                                     NSTrackingArea.Options.mouseMoved],
                                           owner: self,
                                           userInfo: nil)
            self.addTrackingArea(_trackingArea!)
        }
    }
    open override func updateTrackingAreas() {
        self.addTracking()
    }
    
    open override func mouseExited(with theEvent: NSEvent) {
        if self.isScrolling || !trackSectionHover { return }
        let loc = self.contentDocumentView.convert(theEvent.locationInWindow, from: nil)
        self.delegate?.collectionView?(self, mouseMovedToSection: indexPathForSection(at: loc))
    }
    
    open override func mouseMoved(with theEvent: NSEvent) {
        super.mouseMoved(with: theEvent)
        if self.isScrolling || !trackSectionHover { return }
        let loc = self.contentDocumentView.convert(theEvent.locationInWindow, from: nil)
        self.delegate?.collectionView?(self, mouseMovedToSection: indexPathForSection(at: loc))
    }
    
    // MARK: - Mouse Up/Down
    /*-------------------------------------------------------------------------------*/
    
    override open var acceptsFirstResponder: Bool { return true }
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
    
    private func acceptClickEvent(_ event: NSEvent) -> (accept: Bool, itemSpecific: Bool) {
        guard let view = self.window?.contentView?.hitTest(event.locationInWindow), view.isDescendant(of: self) else {
            return (false, false)
        }
        if view.isDescendant(of: self._floatingSupplementaryView) { return (true, false) }
//        if view == self.clipView || view.isDescendant(of: self) { self.window?.makeFirstResponder(self) }
        return (true, true)
    }
    
    private var mouseDownIP: IndexPath?
    private var mouseDownLocation: CGPoint = CGPoint.zero
    open override func mouseDown(with theEvent: NSEvent) {
        
        self.mouseDownIP = nil
        let accept = acceptClickEvent(theEvent)
        guard accept.accept else {
            return
        }
        self.window?.makeFirstResponder(self)
        // super.mouseDown(theEvent) DONT DO THIS, it will consume the event and mouse up is not called
        mouseDownLocation = theEvent.locationInWindow
        let point = self.contentDocumentView.convert(theEvent.locationInWindow, from: nil)
        
        if accept.itemSpecific {
            self.mouseDownIP = self.indexPathForItem(at: point)
        }
        self.delegate?.collectionView?(self, mouseDownInItemAt: self.mouseDownIP, with: theEvent)
    }
    
    open override func mouseUp(with theEvent: NSEvent) {
        //        super.mouseUp(theEvent)
        
        if !self.draggedIPs.isEmpty {
            self.draggedIPs = []
            return
        }
        
        let point = self.contentDocumentView.convert(theEvent.locationInWindow, from: nil)
        let indexPath = self.indexPathForItem(at: point)
        self.delegate?.collectionView?(self, mouseUpInItemAt: indexPath, with: theEvent)
        
        guard self.acceptClickEvent(theEvent).accept == true else { return }
        
        // If we mouse down and move somewhere, ignore
        guard mouseDownIP == indexPath else { return }
        
        if theEvent.modifierFlags.contains(NSEvent.ModifierFlags.control) {
            self.rightMouseDown(with: theEvent)
            return
        }
        
        self._performSelection(at: indexPath, for: theEvent)
    }
    
    open override func rightMouseDown(with theEvent: NSEvent) {
        super.rightMouseDown(with: theEvent)
        
        let res = self.acceptClickEvent(theEvent)
        guard res.accept else { return }
        var ip: IndexPath?
        if res.itemSpecific {
            let point = self.contentDocumentView.convert(theEvent.locationInWindow, from: nil)
            ip = self.indexPathForItem(at: point)
        }
        self.delegate?.collectionView?(self, didRightClickItemAt: ip, with: theEvent)
    }
    
    public var keySelectInterval: TimeInterval = 0.08
    private var lastEventTime: TimeInterval?
    public fileprivate(set) var repeatKey: Bool = false
    
    open override func keyDown(with theEvent: NSEvent) {
        repeatKey = theEvent.isARepeat
        if Set([123, 124, 125, 126]).contains(Int(theEvent.keyCode)) {
            
            if theEvent.isARepeat && keySelectInterval > 0 {
                if let t = lastEventTime, (CACurrentMediaTime() - t) < keySelectInterval {
                    return
                }
                lastEventTime = CACurrentMediaTime()
            }
            else {
                lastEventTime = nil
            }
            let extend = selectionMode == .toggle || theEvent.modifierFlags.contains(NSEvent.ModifierFlags.shift)
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
    
    final func moveSelectionInDirection(_ direction: CollectionViewDirection, extendSelection: Bool) {
        guard let indexPath = (extendSelection ? _extendingEnd : _extendingStart) ?? self._selectedIndexPaths.first else { return }
        
        if let moveTo = self.collectionViewLayout.indexPathForNextItem(moving: direction, from: indexPath) {
            self._moveSelection(to: moveTo, extend: extendSelection, scrollPosition: .nearest, animated: true)
        }
    }
    
    // MARK: - Selection options
    /*-------------------------------------------------------------------------------*/
    
    /**
     If the collection view should allow selection of its items
    */
    public var allowsSelection: Bool = true
    
    /// Determine how item selections are managed
    ///
    /// - normal: Clicking an item selects the item and deselects others (given no modifier keys are used)
    /// - multi: Clicking an item will add it to the selection, clicking again will deselect it
    public enum SelectionMode {
        case `default`
        case toggle
    }
    
    /// Determines what happens when an item is clicked
    public var selectionMode: SelectionMode = .default
    
    /// Allows the selection of multiple items via modifier keys (command & shift) (default true)
    public var allowsMultipleSelection: Bool = true
    
    /// If true, clicking empty space will deselect all items (default true)
    public var allowsEmptySelection: Bool = true
    
    /// If true, programatic changes will be reported to the delegate (i.e. selections)
    public var notifyDelegate: Bool = false // swiftlint:disable:this weak_delegate
    
    /// If true, selecting an already selected item will notify the delegate (default true)
    public var repeatSelections: Bool = false
    
    // MARK: - Selections
    /*-------------------------------------------------------------------------------*/
  
    // Select
    private var _selectedIndexPaths = Set<IndexPath>()

    /**
     The index path of the highlighted item, if any
    */
    public internal(set) var indexPathForHighlightedItem: IndexPath? {
        didSet {
            if oldValue == indexPathForHighlightedItem { return }
            if let ip = oldValue, let cell = self.cellForItem(at: ip), cell.highlighted {
                cell.setHighlighted(false, animated: true)
            }
        }
    }
    
    /**
     Manually set the highlighted item reguardless of the cursor location

     - Parameter indexPath: The index path of the item to highlight
     - Parameter animated: If the change should be animated
     
     This can be use to adust the highlighted item in response to key events
    */
    public func highlightItem(at indexPath: IndexPath?, animated: Bool) {
        guard let ip = indexPath else {
            self.indexPathForHighlightedItem = nil
            return
        }
        if let cell = self.cellForItem(at: ip) {
            cell.setHighlighted(true, animated: animated)
        }
    }
    
    /**
     Returns the index paths for all selected items
    */
    public final var indexPathsForSelectedItems: Set<IndexPath> { return _selectedIndexPaths }
    
    /**
     Returns the index paths for all selected items ordered from first to last
     */
    public final var sortedIndexPathsForSelectedItems: [IndexPath] {
        return indexPathsForSelectedItems.sorted { (ip1, ip2) -> Bool in
            let before =  ip1._section < ip2._section || (ip1._section == ip2._section && ip1._item < ip2._item)
            return before
        }
    }
    
    /**
     Returns if the item at a given index path is selected

     - Parameter indexPath: The index path of the item to check
     
     - Returns: True if the item at indexPath is selected

    */
    public final func itemAtIndexPathIsSelected(_ indexPath: IndexPath) -> Bool {
        return _selectedIndexPaths.contains(indexPath)
    }
    
    // MARK: - Selecting Items
    /*-------------------------------------------------------------------------------*/
    
    /**
     Selects all items in the collection view

     - Parameter animated: If the selections should be animated
     
     - Note: The delegate will not be notified of the changes

    */
    public func selectAllItems(_ animated: Bool = true) {
        self.selectItems(at: self.allIndexPaths, animated: animated)
    }
    
    /**
     Select an item at a given index path
     
     - Parameter indexPath: The indexPath to select
     - Parameter animated: If the selections should be animated
     - Parameter scrollPosition: The position to scroll the selected item to
     
     - Note: The delegate will not be notified of the changes
     */
    public func selectItem(at indexPath: IndexPath, animated: Bool, scrollPosition: CollectionViewScrollPosition = .none) {
        self.selectItems(at: Set([indexPath]), animated: animated, scrollPosition: scrollPosition)
    }
    
    /**
     Select the items at the given index paths

     - Parameter indexPaths: The index paths of the items you want to select
     - Parameter animated: If the selections should be animated
     
     - Note: The delegate will not be notified of the changes

    */
    public func selectItems<C: Collection>(at indexPaths: C, animated: Bool, scrollPosition: CollectionViewScrollPosition = .none) where C.Element == IndexPath {
        self.selectItems(at: Set(indexPaths), animated: animated)
    }
    public func selectItems(at indexPaths: Set<IndexPath>, animated: Bool, scrollPosition: CollectionViewScrollPosition = .none) {
        guard !indexPaths.isEmpty else {
            self.deselectAllItems()
            return
        }
        self._performProgramaticSelection(for: indexPaths, animated: animated, scrollPosition: scrollPosition)
    }
    
    /**
     Deselect cells at given index paths
     
     - Parameter indexPaths: The index paths to deselect
     - Parameter animated: If the deselections should be animated
     
     - Note: The delegate will not be notified of the changes
     
     */
    public func deselectItems<C: Collection>(at indexPaths: C, animated: Bool) where C.Element == IndexPath {
        self.deselectItems(at: Set(indexPaths), animated: animated)
    }
    public func deselectItems(at indexPaths: Set<IndexPath>, animated: Bool) {
        self._deselectItems(at: indexPaths, animated: animated, notify: notifyDelegate)
    }
    
    /**
     Deselect all items in the collection view
     
     - Parameter animated: If the delselections should be animated
     
     - Note: The delegate will not be notified of the changes
     
     */
    public func deselectAllItems(_ animated: Bool = false) {
        self._deselectAllItems(animated, notify: notifyDelegate)
    }
    
    /**
     Deselect the item at a given index path
     
     - Parameter indexPath: The index path for the item to deselect
     - Parameter animated: If the deselection should be animated
     
     - Note: The delegate will not be notified of the changes
     
     */
    public func deselectItem(at indexPath: IndexPath, animated: Bool) {
        self._deselectItem(at: indexPath, animated: animated, notify: false)
    }
    
    private func _performProgramaticSelection(for indexPaths: Set<IndexPath>, animated: Bool, scrollPosition: CollectionViewScrollPosition) {
        self._extendingStart = nil
        self._selectItems(at: indexPaths, animated: animated, clear: true, scrollPosition: scrollPosition, notify: notifyDelegate)
    }
    
    // MARK: - Internal Selection Handling
    /*-------------------------------------------------------------------------------*/
    
    private func _selectItems(at indexPaths: Set<IndexPath>, animated: Bool, clear: Bool = false, scrollPosition: CollectionViewScrollPosition = .none, notify: Bool) {
        let needApproval = repeatSelections ? indexPaths : indexPaths.subtracting(self._selectedIndexPaths)
        
        var approved = needApproval
//        var deselect = self._selectedIndexPaths.removing(indexPaths)
        
        // Only check with delegate if we have ips to validate
        if !needApproval.isEmpty {
            approved = notify
                ? (self.delegate?.collectionView?(self, shouldSelectItemsAt: needApproval) ?? needApproval)
                : needApproval
        }
        
        if clear {
            let deselect = self._selectedIndexPaths.removing(indexPaths)
            self._deselectItems(at: deselect, animated: true, notify: notify)
        }
        guard !approved.isEmpty else { return }
        self._selectedIndexPaths.formUnion(approved)
        if scrollPosition != .none, let ip = approved.first {
            self.scrollItem(at: ip, to: scrollPosition, animated: animated, completion: nil)
        }
        for ip in approved {
            contentDocumentView.preparedCellIndex[ip]?.setSelected(true, animated: animated)
        }
        
        if notify {
            self.delegate?.collectionView?(self, didSelectItemsAt: approved)
        }
    }
    
    private func _deselectAllItems(_ animated: Bool, notify: Bool) {
        self._extendingStart = nil
        self._deselectItems(at: self._selectedIndexPaths, animated: animated, notify: notify)
    }
    private func _deselectItem(at indexPath: IndexPath, animated: Bool, notify: Bool) {
        self._deselectItems(at: Set([indexPath]), animated: animated, notify: notify)
    }
    private func _deselectItems(at indexPaths: Set<IndexPath>, animated: Bool, notify: Bool) {
        let valid = indexPaths.intersection(self._selectedIndexPaths)
        guard !valid.isEmpty else { return }
        let approved = notify
            ? (self.delegate?.collectionView?(self, shouldDeselectItemsAt: valid) ?? valid)
            : valid
        guard !approved.isEmpty else { return }
        self._selectedIndexPaths.subtract(approved)
        for ip in approved {
            contentDocumentView.preparedCellIndex[ip]?.setSelected(false, animated: animated)
        }
        if notify {
            self.delegate?.collectionView?(self, didDeselectItemsAt: approved)
        }
    }
    
//    private func _shouldSelectItems(_ indexPaths: Set<IndexPath>) -> Set<IndexPath> {
//
//    }
    
    // MARK: Special Selections
    /*-------------------------------------------------------------------------------*/
    
    private func _performSelection(at indexPath: IndexPath?, for clickEvent: NSEvent) {
        
        guard let ip = indexPath else {
            if allowsEmptySelection {
                self._deselectAllItems(true, notify: true)
            }
            if clickEvent.clickCount == 2 {
                self.delegate?.collectionView?(self, didDoubleClickItemAt: nil, with: clickEvent)
            }
            // Test
            return
        }
        
        // Shift - extend the selection
        if allowsMultipleSelection && clickEvent.modifierFlags.contains(NSEvent.ModifierFlags.shift) {
            self._moveSelection(to: ip, extend: true, scrollPosition: .nearest, animated: true)
        }
            
            // Toggle Mode (option) - toggle the item at indexPath
        else if self.selectionMode == .toggle || (allowsMultipleSelection && clickEvent.modifierFlags.contains(NSEvent.ModifierFlags.command)) {
            if self.itemAtIndexPathIsSelected(ip) {
                self._deselectItem(at: ip, animated: true, notify: true)
            }
            else {
                self._selectItems(at: Set([ip]), animated: true, notify: true)
                self._extendingStart = ip
            }
        }
            
            // Double click
        else if clickEvent.clickCount == 2 {
            self.delegate?.collectionView?(self, didDoubleClickItemAt: ip, with: clickEvent)
        }
            
            // Standard selection
        else {
            var de = self._selectedIndexPaths
            de.remove(ip)
            self._deselectItems(at: de, animated: true, notify: true)
            
            self._extendingStart = ip
            self._selectItems(at: Set([ip]), animated: true, notify: true)
        }
    }
    
    private var _extendingStart: IndexPath? {
        didSet { self._extendingEnd = nil }
    }
    private var _extendingEnd: IndexPath?
    
    private func _moveSelection(to indexPath: IndexPath, extend: Bool, scrollPosition: CollectionViewScrollPosition, animated: Bool) {
        
        var indexesToSelect = Set<IndexPath>()
        
        indexesToSelect.insert(indexPath)
        if extend  && self.allowsMultipleSelection {
            
            if let start = self._extendingStart {
                if let end = _extendingEnd {
                    if indexPath.isBetween(start, end: end) {
                        var de = self.indexPathsBetween(end, end: indexPath)
                        de.remove(indexPath)
                        self._deselectItems(at: de, animated: true, notify: true)
                        self._extendingEnd = indexPath
                        return
                    }
                    if (start < end) == (indexPath > end) {
                        indexesToSelect.formUnion(self.indexPathsBetween(end, end: indexPath))
                        self._extendingEnd = indexPath
                    }
                    else {
                        var des = self.indexPathsBetween(start, end: end)
                        des.remove(start)
                        self._deselectItems(at: des, animated: true, notify: true)
                        indexesToSelect.formUnion(self.indexPathsBetween(start, end: indexPath))
                        self._extendingEnd = indexPath
                    }
                }
                else {
                    indexesToSelect.formUnion(self.indexPathsBetween(start, end: indexPath))
                    self._extendingEnd = indexPath
                }
            }
            else {
                self._extendingStart = indexPath
            }
            self._selectItems(at: indexesToSelect, animated: true, clear: false, notify: true)
        }
        else {
            self._extendingStart = nil
            self._selectItems(at: indexesToSelect, animated: true, clear: true, notify: true)
        }
        
        self.scrollItem(at: indexPath, to: scrollPosition, animated: animated, completion: nil)
    }
    
    // MARK: - Internal
    /*-------------------------------------------------------------------------------*/
    private func validateIndexPath(_ indexPath: IndexPath) -> Bool {
        let itemCount = self.numberOfItems(in: indexPath._section)
        guard itemCount > 0 else { return false }
        return indexPath._section < self.numberOfSections && indexPath._item < itemCount
    }
    
    private func indexPathForSelectableItem(before indexPath: IndexPath) -> IndexPath? {
        if indexPath._item - 1 >= 0 {
            return IndexPath.for(item: indexPath._item - 1, section: indexPath._section)
        }
        else if indexPath._section - 1 >= 0 && self.numberOfSections > 0 {
            let numberOfItems = self.numberOfItems(in: indexPath._section - 1)
            let newIndexPath = IndexPath.for(item: numberOfItems - 1, section: indexPath._section - 1)
            if self.validateIndexPath(newIndexPath) { return newIndexPath }
        }
        return nil
    }
    
    private func indexPathForSelectableItem(after indexPath: IndexPath) -> IndexPath? {
        if indexPath._item + 1 >= numberOfItems(in: indexPath._section) {
            // Jump up to the next section
            let newIndexPath = IndexPath.for(item: 0, section: indexPath._section+1)
            if self.validateIndexPath(newIndexPath) { return newIndexPath; }
        }
        else {
            return IndexPath.for(item: indexPath._item + 1, section: indexPath._section)
        }
        return nil
    }
    
    func indexPathsBetween(_ start: IndexPath, end: IndexPath) -> Set<IndexPath> {
        var res = Set<IndexPath>()
        let _start = min(start, end)
        let _end = max(start, end)
        
        var next: IndexPath? =  _start
        while let ip = next, ip <= _end {
            res.insert(ip)
            next = self.indexPathForSelectableItem(after: ip)
        }
        return res
    }
    
    // MARK: - Cells & Index Paths
    /*-------------------------------------------------------------------------------*/
    
    /**
     Returns all index paths in the collection view
     
     - Note: This must be provided by the collectionViewLayout
     
    */
    internal final var allIndexPaths: OrderedSet<IndexPath> { return self.collectionViewLayout.allIndexPaths }
    
    /**
     Returns all visible cells in the collection view
    */
    public final var visibleCells: [CollectionViewCell] { return Array( self.contentDocumentView.preparedCellIndex.values) }
    
    /**
     Returns the index paths for all visible cells in the collection view
    */
    public final var indexPathsForVisibleItems: [IndexPath] { return Array(self.contentDocumentView.preparedCellIndex.indexes) }
    
    /**
     Returns true if the item at the index path is visible

     - Parameter indexPath: The index path of an item in the collection view

     - Returns: True if the item is visible

    */
    public final func itemAtIndexPathIsVisible(_ indexPath: IndexPath) -> Bool {
        if let frame = self.contentDocumentView.preparedCellIndex[indexPath]?.frame {
            return self.contentVisibleRect.intersects(frame)
        }
        return false
    }
    
    /**
     Returns the cell at a given index path if it is visible

     - Parameter indexPath: An index path of an item in the collection view
     
     - Returns: The cell at the indexpath, or nil if it is not visible

    */
    public final func cellForItem(at indexPath: IndexPath) -> CollectionViewCell? { return self.contentDocumentView.preparedCellIndex[indexPath] }
    
    /**
     Returns the index path for a cell in the collection view

     - Parameter cell: A cell in the collection view
     
     - Returns: The index path of the cell, or nill if it is not visible in the collection view

    */
    public final func indexPath(for cell: CollectionViewCell) -> IndexPath? { return self.contentDocumentView.preparedCellIndex.index(of: cell) }
    
    /**
     Returns a index path for the item at a given point

     - Parameter point: A point within the collection views contentVisibleRect
     
     - Returns: The index path of the item at point, if any

    */
    public func indexPathForItem(at point: CGPoint) -> IndexPath? {
        if self.numberOfSections == 0 { return nil }
        for sectionIndex in 0..<self.numberOfSections {
            guard let frame = self.frameForSection(at: sectionIndex), frame.contains(point) else { continue }
            let itemCount = self.numberOfItems(in: sectionIndex)
            
            for itemIndex in 0..<itemCount {
                let indexPath = IndexPath.for(item: itemIndex, section: sectionIndex)
                if let attributes = self.collectionViewLayout.layoutAttributesForItem(at: indexPath) {
                    if attributes.frame.contains(point) {
                        return indexPath
                    }
                }
            }
        }
        return nil
    }
    
    /**
     Returns the first index path within a given distance of a point

     - Parameter point: A point within the contentDocumentView's frame
     - Parameter radius: The distance around the point to check

     - Returns: The index path for a matching item or nil if no items were found
     
    */
    public func firstIndexPathForItem(near point: CGPoint, radius: CGFloat) -> IndexPath? {
        if self.numberOfSections == 0 { return nil }
        
        let rect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
        for sectionIndex in 0..<self.numberOfSections {
            guard let frame = self.frameForSection(at: sectionIndex), frame.intersects(rect) else { continue }
            let itemCount = self.numberOfItems(in: sectionIndex)
            
            for itemIndex in 0..<itemCount {
                let indexPath = IndexPath.for(item: itemIndex, section: sectionIndex)
                if let attributes = self.collectionViewLayout.layoutAttributesForItem(at: indexPath) {
                    if attributes.frame.intersects(rect) {
                        return indexPath
                    }
                }
            }
        }
        return nil
    }
    
    /**
     Returns the first index path found intersecting a given rect

     - Parameter rect: A rect within the contentDocumentView's frame

     - Returns: The index path for the matching item or nil if no items were found
     
    */
    public func firstIndexPathForItem(in rect: CGRect) -> IndexPath? {
        if self.numberOfSections == 0 { return nil }
        
        for sectionIndex in 0..<self.numberOfSections {
            guard let frame = self.frameForSection(at: sectionIndex), frame.intersects(rect) else { continue }
            let itemCount = self.numberOfItems(in: sectionIndex)
            for itemIndex in 0..<itemCount {
                let indexPath = IndexPath.for(item: itemIndex, section: sectionIndex)
                if let attributes = self.collectionViewLayout.layoutAttributesForItem(at: indexPath) {
                    if attributes.frame.intersects(rect) {
                        return indexPath
                    }
                }
            }
        }
        return nil
    }
    
    /**
     Returns all items intersecting a given rect

     - Parameter rect: A rect within the contentDocumentView's frame
     
     - Returns: The index paths for all items in the rect. Will be empty if no items were found

    */
    public func indexPathsForItems(in rect: CGRect) -> [IndexPath] {
        return self.collectionViewLayout.indexPathsForItems(in: rect)
    }
    
    internal final func rectForItem(at indexPath: IndexPath) -> CGRect? {
        if indexPath._section < self.numberOfSections {
            let attributes = self.collectionViewLayout.layoutAttributesForItem(at: indexPath)
            return attributes?.frame
        }
        return nil
    }
    
    // MARK: - Supplementary Views & Index Paths
    /*-------------------------------------------------------------------------------*/
    
    /**
     Returns the indexPath for the section that contains the given point

     - Parameter point: The point the section must contain
     
     - Returns: The index path for the section contianing the point

    */
    public final func indexPathForSection(at point: CGPoint) -> IndexPath? {
        for sectionIndex in 0..<self.numberOfSections {
            let rect =  self.collectionViewLayout.rectForSection(sectionIndex)
            if rect.contains(point) { return IndexPath.for(item: 0, section: sectionIndex) }
        }
        return nil
        
//            guard let sectionInfo = self.info.sections[sectionIndex] else { continue }
//            var frame = sectionInfo.frame
//            frame.origin.x = 0
//            frame.size.width = self.bounds.size.width
//            if frame.contains(point) {
//                
//            }
//        }
//        return nil
    }
    
    /**
     Returns all visible cells in the collection view
     */
    public final var visibleSupplementaryViews: [CollectionReusableView] {
        return Array(self.contentDocumentView.preparedSupplementaryViewIndex.values)
    }
    
    /**
     Returns the index path for a supplementary view

     - Parameter view: The supplementary view for which you want the index path
     
     - Returns: The index path for the view

    */
    public final func indexPath(forSupplementaryView view: CollectionReusableView) -> IndexPath? { return view.attributes?.indexPath }
    
    /**
     Returns the visible supplementary view of the given kind at indexPath
     
     - Parameter kind: The kind of the supplementary view
     - Parameter indexPath: The index path of the supplementary view
     
     - Returns: The view of kind at the given index path
     
     */
    public final func supplementaryViews(forElementKind kind: String, at indexPath: IndexPath) -> CollectionReusableView? {
        let id = SupplementaryViewIdentifier(kind: kind, reuseIdentifier: "", indexPath: indexPath)
        return self.contentDocumentView.preparedSupplementaryViewIndex[id]
    }
    
    /**
     Returns the visible supplementary view of the given kind at indexPath

     - Parameter kind: The kind of the supplementary view
     - Parameter indexPath: The index path of the supplementary view
     
     - Returns: The view of kind at the given index path

    */
    public final func supplementaryView(forElementKind kind: String, at indexPath: IndexPath) -> CollectionReusableView? {
        let id = SupplementaryViewIdentifier(kind: kind, reuseIdentifier: "", indexPath: indexPath)
        return self.contentDocumentView.preparedSupplementaryViewIndex[id]
    }
    
    internal final func _identifiersForSupplementaryViews(in rect: CGRect) -> Set<SupplementaryViewIdentifier> {
        var visibleIdentifiers = Set<SupplementaryViewIdentifier>()
        if rect.equalTo(CGRect.zero) { return [] }
        for section in 0..<self.numberOfSections {
            guard let frame = self.frameForSection(at: section), frame.intersects(rect) else { continue }
            
            for kind in self._registeredSupplementaryViewKinds {
                let ip = IndexPath.for(item: 0, section: section)
                if let attrs = self.collectionViewLayout.layoutAttributesForSupplementaryView(ofKind: kind, at: ip) {
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
    
    public  func cancelScrollAnimation() {
        self.clipView?.cancelScrollAnimation()
    }
    
    public func scrollToTop(animated: Bool = false, completion: AnimationCompletion? = nil) {
        self.scrollRect(CGRect(x: 0, y: self.contentInsets.top, width: 0, height: 0),
                        to: .leading,
                        animated: animated,
                        completion: completion)
    }
    
    /**
     Scroll an item into view

     - Parameter indexPath: The index path of the item to scroll to
     - Parameter scrollPosition: The position to scroll the item to within the visible frame
     - Parameter animated: If the scroll should be animated
     - Parameter completion: A closure to call on completion of the scroll

    */
    public func scrollItem(at indexPath: IndexPath, to scrollPosition: CollectionViewScrollPosition, animated: Bool, completion: AnimationCompletion?) {
        self._scrollItem(at: indexPath, to: scrollPosition, animated: animated, prepare: true, completion: completion)
    }
    
    public func _scrollItem(at indexPath: IndexPath, to scrollPosition: CollectionViewScrollPosition, animated: Bool, prepare: Bool, completion: AnimationCompletion?) {
        if self.numberOfItems(in: indexPath._section) < indexPath._item { return }
        
        if let shouldScroll = self.delegate?.collectionView?(self, shouldScrollToItemAt: indexPath), shouldScroll != true {
            completion?(false)
            return
        }
        
        guard let rect = self.collectionViewLayout.scrollRectForItem(at: indexPath,
                                                                     atPosition: scrollPosition) ?? self.rectForItem(at: indexPath) else {
            completion?(false)
            return
        }
        
        self.scrollRect(rect, to: scrollPosition, animated: animated, completion: { fin in
            completion?(fin)
            self.delegate?.collectionView?(self, didScrollToItemAt: indexPath)
        })

    }
    
    /**
     Scroll an given rect into view

     - Parameter aRect: The rect within the contentDocumentView to scroll to
     - Parameter scrollPosition: The position to scroll the rect to
     - Parameter animated: If the scroll should be animated
     - Parameter completion: A closure to call on completion of the scroll

    */
    public func scrollRect(_ aRect: CGRect, to scrollPosition: CollectionViewScrollPosition, animated: Bool, completion: AnimationCompletion?) {
        self._scrollRect(aRect, to: scrollPosition, animated: animated, prepare: true, completion: completion)
    }
    
    private func _scrollRect(_ aRect: CGRect, to scrollPosition: CollectionViewScrollPosition, animated: Bool, prepare: Bool, completion: AnimationCompletion?) {
        var rect = aRect.intersection(self.contentDocumentView.frame)
        
//        if rect.isEmpty {
//            completion?(false)
//            return
//        }
        
        let scrollDirection = collectionViewLayout.scrollDirection
        
        let visibleRect = self.contentVisibleRect
        switch scrollPosition {
        case .leading:
            // make the top of our rect flush with the top of the visible bounds
            rect.size.height = visibleRect.height - contentInsets.top
            rect.origin.y = aRect.origin.y - contentInsets.top
            
        case .centered:
            if self.collectionViewLayout.scrollDirection == .vertical {
                rect.origin.x = 0
                let y = rect.midY - (visibleRect.size.height/2)
                rect.origin.y = max(y, 0)
            }
            else {
                rect.size.width = self.bounds.size.width
            }
            
        case .trailing:
            // make the bottom of our rect flush with the bottom of the visible bounds
            let vHeight = self.contentDocumentView.visibleRect.size.height
            rect.origin.y = (aRect.origin.y + aRect.size.height) - vHeight
            rect.size.height = visibleRect.height
            
        case .none:
            // no scroll needed
            completion?(true)
            return
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
        }
        
        if scrollDirection == .vertical {
            rect.origin.x = 0
            rect.size.width = contentSize.width
        }
        else {
            rect.size.height = self.contentSize.height
        }
        
        if !animated && scrollPosition == .centered || scrollPosition == .leading {
            if contentSize.height < self.contentVisibleRect.size.height {
                rect.origin.y = 0
            }
            else if rect.origin.y > self.contentSize.height - self.frame.size.height {
                rect.origin.y = self.contentSize.height - self.frame.size.height + self.contentInsets.top
            }
        }
        if animated {
            self.delegate?.collectionViewWillBeginScrolling?(self, animated: true)
        }
        if animated && prepare {
            self.contentDocumentView.prepareRect(rect.union(visibleRect), force: false)
        }
        self.clipView?.scrollRectToVisible(rect, animated: animated, completion: completion)
        if !animated && prepare {
            self.contentDocumentView.prepareRect(self.contentVisibleRect, force: false)
        }
    }
    
    // MARK: - Dragging Source
    /*-------------------------------------------------------------------------------*/
    
    /**
     The index paths for items included in the currect dragging session
    */
    public var indexPathsForDraggingItems: [IndexPath] {
        return draggedIPs
    }
    
    private var draggedIPs: [IndexPath] = []
    public var isDragging: Bool = false
    
    override open func mouseDragged(with theEvent: NSEvent) {
        super.mouseDragged(with: theEvent)
        self.window?.makeFirstResponder(self)
        
        self.draggedIPs = []
        var items: [NSDraggingItem] = []
        
        guard let mouseDown = mouseDownIP else { return }
        guard self.acceptClickEvent(theEvent).itemSpecific else { return }
        
        guard theEvent.locationInWindow.distance(to: mouseDownLocation) > 5 else { return }
        
        if self.interactionDelegate?.collectionView?(self, shouldBeginDraggingAt: mouseDown, with: theEvent) != true { return }
        
        var ips = self.sortedIndexPathsForSelectedItems
        if let validated = self.interactionDelegate?.collectionView?(self, validateIndexPathsForDrag: ips) {
            ips = validated
        }
        self.draggedIPs = ips
        for indexPath in ips {
            let ip = indexPath
            
            if let writer = self.dataSource?.collectionView?(self, pasteboardWriterForItemAt: ip) {
                guard let rect = self.rectForItem(at: ip) else { continue }
                // The frame of the cell in relation to the document. This is where the dragging
                // image should start.
                
                let originalFrame = UnsafeMutablePointer<CGRect>.allocate(capacity: 1)
                let oFrame = self.convert( rect, from: self.documentView)
                originalFrame.initialize(to: oFrame)
                self.dataSource?.collectionView?(self, dragRectForItemAt: ip, withStartingRect: originalFrame)
                let frame = originalFrame.pointee
                
//                self.draggedIPs.append(ip)
                let item = NSDraggingItem(pasteboardWriter: writer)
                item.draggingFrame = frame
                
                originalFrame.deinitialize()
                originalFrame.deallocate(capacity: 1)
                
                if self.itemAtIndexPathIsVisible(ip) {
                    item.imageComponentsProvider = { () -> [NSDraggingImageComponent] in
                        
                        var image = self.dataSource?.collectionView?(self, dragContentsForItemAt: ip)
                        if image == nil, let cell = self.cellForItem(at: ip) {
                            
                            let rep = cell.bitmapImageRepForCachingDisplay(in: cell.bounds)!
                            cell.cacheDisplay(in: cell.bounds, to: rep)
                            
                            image = NSImage(size: cell.bounds.size)
                            image!.addRepresentation(rep)
                            
//                            image = NSImage(data: cell.dataWithPDF(inside: cell.bounds))
                        }
                        let comp = NSDraggingImageComponent(key: NSDraggingItem.ImageComponentKey.icon)
                        comp.contents = image
                        comp.frame = CGRect(origin: CGPoint.zero, size: frame.size)
                        return [comp]
                    }
                }
            
                items.append(item)
            }
        }
        
        if !items.isEmpty {
            self.isDragging = true
            let session = self.beginDraggingSession(with: items, event: theEvent, source: self)
            if items.count > 1 {
                session.draggingFormation = .stack
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
        
        if let p = self.window?.convertFromScreen(NSRect(origin: screenPoint, size: CGSize.zero)).origin {
            self.autoScroll(to: p)
        }
    }
    
    open func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        invalidateAutoscroll()
        self.mouseDownIP = nil
        delay(0.5) {
            self.isDragging = false
        }
        self.interactionDelegate?.collectionView?(self, draggingSession: session,
                                                  didEndAt: screenPoint,
                                                  with: operation,
                                                  draggedIndexPaths: self.draggedIPs)
    }
    
    // MARK: - Draggng Destination
    open override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if let operation = self.interactionDelegate?.collectionView?(self, dragEntered: sender) {
            return operation
        }
        return NSDragOperation()
    }
    open override func draggingExited(_ sender: NSDraggingInfo?) {
        invalidateAutoscroll()
        self.interactionDelegate?.collectionView?(self, dragExited: sender)
    }
    open override func draggingEnded(_ sender: NSDraggingInfo) {
        self.interactionDelegate?.collectionView?(self, dragEnded: sender)
    }
    open override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        if let operation = self.interactionDelegate?.collectionView?(self, dragUpdated: sender) {
            return operation
        }
        self.autoScroll(to: sender.draggingLocation())
        return sender.draggingSourceOperationMask()
    }
    open override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        self.isDragging = false
        if let perform = self.interactionDelegate?.collectionView?(self, performDragOperation: sender) {
            return perform
        }
        return false
    }
    
    public var isAutoscrollEnabled = false
    public var autoscrollSize: CGFloat = 15
    private var autoscrollTimer: Timer?
    
    func invalidateAutoscroll() {
        autoscrollTimer?.invalidate()
        autoscrollTimer = nil
    }
    
    @objc func autoscrollTimer(_ sender: Timer) {
        if let p = (sender.userInfo as? [String: Any])?["point"] as? CGPoint {
            autoScroll(to: p)
        }
    }
    
    func autoScroll(to dragPoint: CGPoint) {
        
        guard isAutoscrollEnabled  else { return }
        
        func valid() {
            if autoscrollTimer?.isValid != true {
                autoscrollTimer = Timer.scheduledTimer(timeInterval: 0.05,
                                                       target: self,
                                                       selector: #selector(autoscrollTimer(_:)),
                                                       userInfo: ["point": dragPoint],
                                                       repeats: true)
            }
        }
        
        let loc = self.convert(dragPoint, from: nil)
        let visible = self.visibleRect
        guard visible.contains(loc) else {
            invalidateAutoscroll()
            return
        }
        
        if loc.y > (self.bounds.size.height - self.contentInsets.bottom - autoscrollSize) {
            let cRect = self.contentVisibleRect
            let newRect = CGRect(x: cRect.origin.x, y: cRect.maxY + 50, width: cRect.size.width, height: 50)
            self.scrollRect(newRect, to: .trailing, animated: true, completion: nil)
            valid()
        }
        else if loc.y > self.contentInsets.top && loc.y < (self.contentInsets.top + autoscrollSize) {
            let cRect = self.contentVisibleRect
            let newRect = CGRect(x: cRect.origin.x, y: cRect.minY - 5, width: cRect.size.width, height: 5)
            self.scrollRect(newRect, to: .leading, animated: true, completion: nil)
            valid()
        }
        else {
            invalidateAutoscroll()
        }
    }
}

extension CollectionView {
    public var fillSize: CGSize {
        let w = self.bounds.size.width - self.contentInsets.width
        var h = self.bounds.size.height - self.contentInsets.height
        if let l = self.leadingView?.bounds.size.height {
            h -= l
        }
        return CGSize(width: w, height: h)
    }
}
