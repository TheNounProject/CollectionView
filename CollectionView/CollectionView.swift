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

/**
 A highliy customizable collection view with cell reuse, animated updates, and custom layouts
 
 The content of the collection view is determined by it's CollectionViewLayout. Inlcuded layouts:
 
 - CollectionViewColumnLayout
 - CollectionViewListLayout
 - CollectionViewFlowLayout

 
*/
open class CollectionView : ScrollView, NSDraggingSource {
    
    
    open override var mouseDownCanMoveWindow: Bool { return true }
    
    // MARK: - Data Source & Delegate
    
    
    
    /// The object that acts as the delegate to the collection view
    public weak var delegate : CollectionViewDelegate?
    
    /// The object that provides data for the collection view
    public weak var dataSource : CollectionViewDataSource?
    
    private weak var interactionDelegate : CollectionViewDragDelegate? {
        return self.delegate as? CollectionViewDragDelegate
    }
    
    
    /**
     The content view in which all cells and views are displayed
    */
    public var contentDocumentView : CollectionViewDocumentView {
        return self.documentView as! CollectionViewDocumentView
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
    
    private func setup() {
        
        collectionViewLayout.collectionView = self
        self.wantsLayer = true
        let dView = CollectionViewDocumentView()
        dView.wantsLayer = true
        self.documentView = dView
        self.hasVerticalScroller = true
        self.scrollsDynamically = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(CollectionView.didScroll(_:)), name: NSNotification.Name.NSScrollViewDidLiveScroll, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(CollectionView.willBeginScroll(_:)), name: NSNotification.Name.NSScrollViewWillStartLiveScroll, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(CollectionView.didEndScroll(_:)), name: NSNotification.Name.NSScrollViewDidEndLiveScroll, object: self)

        self.addSubview(_floatingSupplementaryView, positioned: .above, relativeTo: self.clipView!)
        self._floatingSupplementaryView.wantsLayer = true
        if #available(OSX 10.12, *) {
            self._floatingSupplementaryView.addConstraintsToMatchParent()
        } else {
            _floatingSupplementaryView.frame = self.bounds
        }
    }
    
    deinit {
        self.delegate = nil
        self.dataSource = nil
        NotificationCenter.default.removeObserver(self)
        self._reusableCells.removeAll()
        self._reusableSupplementaryView.removeAll()
        self._updateContext.reset()
        self._pendingCellMap.removeAll()
        self._finalizedCellMap.removeAll()
        self._finalizedViewMap.removeAll()
        self.contentDocumentView.preparedCellIndex.removeAll()
        self.contentDocumentView.preparedSupplementaryViewIndex.removeAll()
        for view in self.contentDocumentView.subviews {
            view.removeFromSuperview()
        }
    }

    open override var scrollerStyle: NSScrollerStyle {
        didSet {
//            log.debug("Scroller Style changed")
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
    
    private var _cellClasses : [String:CollectionViewCell.Type] = [:]
    private var _cellNibs : [String:NSNib] = [:]
    
    private var _supplementaryViewClasses : [SupplementaryViewIdentifier:CollectionReusableView.Type] = [:]
    private var _supplementaryViewNibs : [SupplementaryViewIdentifier:NSNib] = [:]
    
    
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
        assert(viewClass.isSubclass(of: CollectionReusableView.self), "CollectionView: Registered supplementary views must be subclasses of CollectionReusableview")
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
    
    private var _reusableCells : [String:Set<CollectionViewCell>] = [:]
    private var _reusableSupplementaryView : [SupplementaryViewIdentifier:Set<CollectionReusableView>] = [:]
    
    
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
        else {
            cell?.prepareForReuse()
        }
        cell?.reuseIdentifier = identifier
//        cell?.indexPath = indexPath
        
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
        else {
            view?.prepareForReuse()
        }
        view?.reuseIdentifier = identifier
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
    
    
    
    
    // MARK: - Floating View
    /*-------------------------------------------------------------------------------*/
    let _floatingSupplementaryView = FloatingSupplementaryView(frame: NSZeroRect)
    
    
    
    /**
     A view atop the collection view used to display non-scrolling accessory views
     */
    public var  floatingContentView : NSView {
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
//    fileprivate var info : CollectionViewInfo!
    
    private var sections = [Int:Int]()
    
    
    /**
     Returns the number of sections displayed by the collection view.

     - Returns: The number of sections
     
    */
    public var numberOfSections : Int { return self.sections.count }
    
    
    /**
     Returns the number of items in the specified section.

     - Parameter section: The index of the section for which you want a count of the items.

     - Returns: The number of items in the specified section

    */
    public func numberOfItems(in section: Int) -> Int {
        return self.sections[section] ?? 0
    }
    
    
    
    
    
    /**
     Reloads all the data and views in the collection view
     */
    open func reloadData() {
        self.contentDocumentView.reset()
        
        self._reloadDataCounts()
        
        doLayoutPrep()
        
        contentDocumentView.frame.size = self.collectionViewLayout.collectionViewContentSize
        self.reflectScrolledClipView(self.clipView!)
        
        self._selectedIndexPaths.formIntersection(self.allIndexPaths)
        self.contentDocumentView.prepareRect(_preperationRect, animated: false)
        
        self.delegate?.collectionViewDidReloadLayout?(self)
    }

    
    private func _reloadDataCounts() {
        self.sections = [:]
        let sCount = self.dataSource?.numberOfSections(in: self) ?? 0
        for sIndex in 0..<sCount {
            self.sections[sIndex] = self.dataSource?.collectionView(self, numberOfItemsInSection: sIndex) ?? 0
        }
    }
    
    
    // MARK: - Layout
    /*-------------------------------------------------------------------------------*/
    
    
    
    /**
        The layout used to organize the collected view’s items.
     
     - Note: Assigning a new layout object to this property does **NOT** apply the layout to the collection view. Call `reloadData()` or `reloadLayout(_:)` to do so.
     */
    public var collectionViewLayout : CollectionViewLayout = CollectionViewLayout() {
        didSet {
            collectionViewLayout.collectionView = self
            self.hasHorizontalScroller = collectionViewLayout.scrollDirection == .horizontal
            self.hasVerticalScroller = collectionViewLayout.scrollDirection == .vertical
        }}
    
    
    /// The visible rect of the document view that is visible
    public var contentVisibleRect : CGRect { return self.documentVisibleRect }
    
    
    /// The total size of all items/views
    open override var contentSize: NSSize {
        return self.collectionViewLayout.collectionViewContentSize
    }
    
    /// The offset of the content view
    public var contentOffset : CGPoint {
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
    
    /**
     Force layout of all items, not just those in the visible content area
     
     - Note: This is not recommended for large data sets. It can be useful for smaller collection views to better manage transitions/animations.
     
     */
    public var prepareAll : Bool = false
    
    // Returns the rect to prepare based on prepareAll option
    private var _preperationRect : CGRect {
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
    public final func layoutAttributesForSupplementaryElement(ofKind kind: String, atIndexPath indexPath: IndexPath) -> CollectionViewLayoutAttributes?  { return nil }
    
    public final func layoutAttributesForSupplementaryView(ofKind kind: String, at indexPath: IndexPath) -> CollectionViewLayoutAttributes?  {
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
    public var reloadDataOnBoundsChange : Bool = false

    
    private var _lastViewSize: CGSize = CGSize.zero
    private func setContentViewSize() {
        var newSize = self.collectionViewLayout.collectionViewContentSize
        var contain = self.frame.size
        contain.width -= (contentInsets.left + contentInsets.right)
        contain.height -= (contentInsets.top + contentInsets.bottom)
        _lastViewSize = newSize
        
        if newSize.width < contain.width  {
            newSize.width = contain.width
        }
        if newSize.height < contain.height {
            newSize.height = contain.height
        }
        contentDocumentView.frame.size = newSize
    }
    
    open override func layout() {
        
        if #available(OSX 10.12, *) {
            // Do nothing
        }
        else {
            _floatingSupplementaryView.frame = self.bounds
        }
        
        super.layout()
        
        if self.collectionViewLayout.shouldInvalidateLayout(forBoundsChange: self.contentVisibleRect) {
            if reloadDataOnBoundsChange {
                self._reloadDataCounts()
            }
            doLayoutPrep()
            setContentViewSize()
            
            if let ip = _topIP, var rect = self.collectionViewLayout.scrollRectForItem(at: ip, atPosition: CollectionViewScrollPosition.leading) {
                self._scrollItem(at: ip, to: .leading, animated: false, prepare: false, completion: nil)
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
            self.contentDocumentView.prepareRect(_preperationRect, force: true)
            self.delegate?.collectionViewDidReloadLayout?(self)
        }
        else {
            self.contentDocumentView.prepareRect(_preperationRect, force: false)
        }
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
            self._topIP = self.indexPathForFirstVisibleItem
        }
        self.delegate?.collectionViewWillReloadLayout?(self)
        self.collectionViewLayout.prepare()
    }
    
    private func _reloadLayout(_ animated: Bool, scrollPosition: CollectionViewScrollPosition = .nearest, completion: AnimationCompletion?, needsRecalculation: Bool) {
    
        
        if needsRecalculation {
            doLayoutPrep()
        }
        let newContentSize = self.collectionViewLayout.collectionViewContentSize
        
        
        // If the size changed we need to do some extra prep
        let sizeChanged = newContentSize != _lastViewSize
        
        setContentViewSize()
        
        struct ViewSpec {
            let view: CollectionReusableView
            let frame : CGRect
            let newIP : IndexPath
        }
        
        // var absoluteCellFrames = [CollectionReusableView:CGRect]()
        var viewSpecs = [ViewSpec]()
        if sizeChanged {
            for view in self.contentDocumentView.preparedCellIndex {
                if !view.value.isHidden, let v = view.value as? CollectionReusableView, let attrs = v.attributes {
                    let newRect = self.convert(attrs.frame, from: v.superview)
                    viewSpecs.append(ViewSpec(view: v, frame: newRect, newIP: view.index))
                    // absoluteCellFrames[v] = self.convert(attrs.frame, from: v.superview)
                }
            }
            /*
            for view in self.floatingContentView.subviews {
                if !view.isHidden, let v = view as? CollectionReusableView, let attrs = v.attributes {
                    absoluteCellFrames[v] = self.convert(attrs.frame, from: v.superview)
                }
            }
             */
        }
        
            for view in self.contentDocumentView.preparedSupplementaryViewIndex {
                let v = view.value
                if !view.value.isHidden, let attrs = v.attributes {
                    let newRect = self.convert(attrs.frame, from: v.superview)
                    viewSpecs.append(ViewSpec(view: v, frame: newRect, newIP: view.key.indexPath!))
                    // absoluteCellFrames[v] = self.convert(attrs.frame, from: v.superview)
                }
            }
        
        
        
        
        
        if sizeChanged {
            if scrollPosition != .none, let ip = self._topIP,
                let rect = self.collectionViewLayout.scrollRectForItem(at: ip, atPosition: scrollPosition) ?? self.rectForItem(at: ip) {
                self._scrollRect(rect, to: scrollPosition, animated: false, prepare: false, completion: nil)
            }
            self.reflectScrolledClipView(self.clipView!)
        }
        
        for spec in viewSpecs {
            if let attrs = spec.view.attributes , attrs.representedElementCategory == CollectionElementCategory.supplementaryView {
                if validateIndexPath(spec.newIP), let newAttrs = self.layoutAttributesForSupplementaryView(ofKind: attrs.representedElementKind!, at: spec.newIP) {
                    
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
    private var _resizeStartBounds : CGRect = CGRect.zero
    open override func viewWillStartLiveResize() {
        _resizeStartBounds = self.contentVisibleRect
        _topIP = indexPathForFirstVisibleItem
    }
    
    open override func viewDidEndLiveResize() {
        _topIP = nil
        self.delegate?.collectionViewDidEndLiveResize?(self)
    }

    
    // MARK: - Scroll Handling
    /*-------------------------------------------------------------------------------*/
    override open class func isCompatibleWithResponsiveScrolling() -> Bool { return true }
    
    public var isScrollEnabled : Bool {
        set { self.clipView?.scrollEnabled = newValue }
        get { return self.clipView?.scrollEnabled ?? true }
    }
    
    
    /**
     Returns true if the collection view is currently scrolling
    */
    public internal(set) var isScrolling : Bool = false
    
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
    
    
    final func didScroll(_ notification: Notification) {
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
    
    final func willBeginScroll(_ notification: Notification) {
        self.isScrolling = true
        self.delegate?.collectionViewWillBeginScrolling?(self)
        self._previousOffset = self.contentVisibleRect.origin
        self.peakScrollVelocity = CGPoint.zero
        self.scrollVelocity = CGPoint.zero
    }
    
    final func didEndScroll(_ notification: Notification) {
        self.isScrolling = false
        
        self.delegate?.collectionViewDidEndScrolling?(self, animated: true)
        self.scrollVelocity = CGPoint.zero
        self.peakScrollVelocity = CGPoint.zero
        
        if trackSectionHover && NSApp.isActive, let point = self.window?.convertFromScreen(NSRect(origin: NSEvent.mouseLocation(), size: CGSize.zero)).origin {
            let loc = self.contentDocumentView.convert(point, from: nil)
            self.delegate?.collectionView?(self, mouseMovedToSection: indexPathForSection(at: loc))
        }
    }

    

    /**
     Returns the lowest index path of all visible items
     */
    open var indexPathsForVisibleSections : [IndexPath] {
        
        var ips = [IndexPath]()
        
        var visible = self.contentVisibleRect
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
    open var indexPathForFirstVisibleItem : IndexPath? {
        if let ip = self.delegate?.collectionViewLayoutAnchor?(self) {
            return ip
        }
       return _indexPathForFirstVisibleItem
    }
    
    
    /**
     Same as indexPathForFirstVisibleItem but doesn't ask the delegate for a suggestion. This is a convenient variable to use in collectionViewLayoutAnchor(_:) but asking the delegate within is not possibe.
    */
    open var _indexPathForFirstVisibleItem : IndexPath? {
        var closest : (IndexPath, CGFloat)?
        for ip in self.contentDocumentView.preparedCellIndex.orderedIndexes {
            if let attributes = self.collectionViewLayout.layoutAttributesForItem(at: ip) {
                
                if (contentVisibleRect.contains(attributes.frame)) {
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
    public func performBatchUpdates(_ updates: (()->Void), completion: AnimationCompletion?) {
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
    
    
	/**
	Insert sections at the given indexes

	- Parameter sections: The sections to insert
	- Parameter animated: If the update should be animated

     - Note: If called within performBatchUpdate(_:completion:) sections should be the final indexes after other updates are applied
	*/
    public func insertSections(_ sections: IndexSet, animated: Bool) {
        guard sections.count > 0 else { return }
        self.beginEditing()
        self._updateContext.insertedSections.formUnion(sections)
        self.endEditing(animated)
    }
    
	/**
	Remove sections and their items

	- Parameter sections: The sections to delete
	- Parameter animated: If the update should be animated

     - Note: If called within performBatchUpdate(_:completion:) sections should be the index prior to any other updates
	*/
    public func deleteSections(_ sections: IndexSet, animated: Bool) {
        guard sections.count > 0 else { return }
        self.beginEditing()
        self._updateContext.deletedSections.formUnion(sections)
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
        self._updateContext.movedSections[section] = newSection
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
        guard indexPaths.count > 0 else { return }
        self.beginEditing()
        self._updateContext.insertedItems.formUnion(indexPaths)
//        self._insertItems(at: indexPaths)
        self.endEditing(animated)
    }
    
    
    /**
     Deletes the items at the specified index paths.

     - Parameter indexPaths: The index paths for the items you want to delete
     - Parameter animated: If the updates should be animated

    */
    public func deleteItems(at indexPaths: [IndexPath], animated: Bool) {
        guard indexPaths.count > 0 else { return }
        self.beginEditing()
        self._updateContext.deletedItems.formUnion(indexPaths)
        self.endEditing(animated)
    }
    
    
    /**
     Reload the items and the given index paths. 
     
     The cells will be reloaded, asking the data source for the cell to replace with.

     - Parameter indexPaths: The index paths for the items you want to reoad
     - Parameter animated: If the updates should be animated

    */
    public func reloadItems(at indexPaths: [IndexPath], animated: Bool) {
        guard indexPaths.count > 0 else { return }
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
    public func moveItem(at indexPath : IndexPath, to destinationIndexPath: IndexPath, animated: Bool) {
        self.beginEditing()
        self._updateContext.movedItems[indexPath] = destinationIndexPath
        self.endEditing(animated)
    }
    
    public func moveItems(_ moves: [Move], animated: Bool) {
        guard moves.count > 0 else { return }
        self.beginEditing()
        for m in moves {
            self._updateContext.movedItems[m.source] = m.destination
        }
        self.endEditing(animated)
    }
    
    
    
    // MARK: - Internal Manipulation
    /*-------------------------------------------------------------------------------*/
    
    private struct UpdateContext {
        
        var updates = [ItemUpdate]()
        
        var insertedItems = Set<IndexPath>()
        var deletedItems = Set<IndexPath>()
        var movedItems = IndexedSet<IndexPath, IndexPath>()
        
        var deletedSections   = IndexSet() // Original Indexes for deleted sections
        var insertedSections  = IndexSet() // Destination Indexes for inserted sections
        var movedSections = IndexedSet<Int, Int>() // Source and Destination indexes for moved sections
        
        var reloadedItems = Set<IndexPath>() // Track reloaded items to reload after adjusting IPs
        
        mutating func reset() {
            
            insertedItems.removeAll()
            deletedItems.removeAll()
            movedItems.removeAll()
            
            updates.removeAll()
            deletedSections.removeAll()
            insertedSections.removeAll()
            movedSections.removeAll()

            reloadedItems.removeAll()
        }
        
    }
    
    
    struct ShiftSet {
        var storage : [Int]
        
        var _map = [Int:Int]()
        var locked = IndexSet()
        var open = IndexSet()
        
        init(count: Int) {
            storage = [Int](repeatElement(0, count: count + 1))
        }
        init(count: Int, remove: Int) {
            self.init(count: count)
            self.remove(at: remove)
        }
        init(count: Int, insert: Int) {
            self.init(count: count)
            self.insert(at: insert)
        }
        init(count: Int, move from: Int, to: Int) {
            self.init(count: count)
            self.move(from, to: to)
        }
        
        mutating func ensureStorage(capacity: Int) {
            if capacity >= storage.count {
                let new = [Int](repeating: 0, count: 1 + (capacity - storage.count))
                storage.append(contentsOf: new)
            }
        }
        
        mutating func move(_ from: Int, to: Int) {
            _map[from] = to
            
            ensureStorage(capacity: from)
            storage[from] -= 1
            let t = to > from ? to + 1 : to
            ensureStorage(capacity: t)
            storage[t] += 1
            locked.insert(to)
            open.insert(from)
            
        }
        mutating func insert(at value: Int) {
            ensureStorage(capacity: value)
            storage[value] += 1
            locked.insert(value)
        }
        mutating func remove(at value: Int) {
            ensureStorage(capacity: value)
            storage[value] -= 1
            _map[value] = -1
            open.insert(value)
        }
        
        
        private var _populatedMap: [Int:Int]?
        mutating func populateMap(count: Int) -> [Int:Int] {
            
            var cursor: Int = 0
            var adjust : Int = 0
            
            if let m = _populatedMap { return m }
            
//            log.debug(storage)
            for idx in 0..<max(storage.count, count) {
                if _map[idx] != nil {
                    continue
                }
                
                let isLocked = locked.contains(idx + adjust)
                if adjust < 0 && cursor >= idx && isLocked == false {
                    _map[idx] = idx + adjust
                    open.insert(idx)
                    locked.insert(idx + adjust)
                    continue
                }
                if let f = open.subtracting(locked).first, f <= idx, !locked.contains(f) {
                    _map[idx] = f
                    open.insert(idx)
                    locked.insert(f)
                    continue
                }
                while cursor < storage.count && (cursor <= idx || locked.contains(idx + adjust)) {
                    let val = storage[cursor]
                    adjust += val
                    cursor += 1
                }
                _map[idx] = idx + adjust
                open.insert(idx)
                locked.insert(idx + adjust)
            }
            _populatedMap = _map
            return _map
        }
    }

    
    
    
    
    
    private var _finalizedCellMap = IndexedSet<IndexPath, CollectionViewCell>()
    private var _pendingCellMap = IndexedSet<IndexPath, CollectionViewCell>()
    private var _finalizedViewMap = IndexedSet<SupplementaryViewIdentifier, CollectionReusableView>()
    
    private var _updateSelections : Set<IndexPath>?
    private var _updateContext = UpdateContext()
    private var _editing = 0
    private var _sectionMap: [Int:Int] = [:]

    
    var sectionShift = ShiftSet(count: 0)
    var itemShifts = [Int:ShiftSet]()
    
    
    private func beginEditing() {
        if _editing == 0 {
            
//            log.debug("BEGIN EDITING: *************************************")
            
//            log.debug("Cell Index: \(self.contentDocumentView.preparedCellIndex)")
//            log.debug("Cell Index: \(self.contentDocumentView.preparedCellIndex.orderedLog())")
            
            self.itemShifts.removeAll()
            self._firstSelection = nil
            
            self._updateContext.reset()
            self._finalizedCellMap.removeAll()
            self._finalizedViewMap.removeAll()
            self._pendingCellMap.removeAll()
            self._updateSelections = Set<IndexPath>()
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
        
        sectionShift = ShiftSet(count: self.numberOfSections)
        
        let oldDataCounts = self.sections
        
        self._reloadDataCounts()
        doLayoutPrep()
        
        // Section shifting
        if _updateContext.insertedSections.count > 0 {
            for insert in _updateContext.insertedSections {
                sectionShift.insert(at: insert)
            }
        }
        if _updateContext.deletedSections.count > 0 {
            for d in _updateContext.deletedSections {
                sectionShift.remove(at: d)
            }
        }
        if _updateContext.movedSections.count > 0 {
            for m in _updateContext.movedSections {
                sectionShift.move(m.index, to: m.value)
            }
        }
        var sectionMap = sectionShift.populateMap(count: self.numberOfSections)
        
        
        func countIn(section: Int) -> Int {
            return max(oldDataCounts[section] ?? 0, self.numberOfItems(in: section))
        }
        
        // Item shifting
        for ip in _updateContext.deletedItems {
            let s = sectionMap[ip._section] ?? ip._section
            if itemShifts[s] == nil {
                itemShifts[s] = ShiftSet(count: countIn(section: s), remove: ip._item)
            }
            else {
                itemShifts[s]?.remove(at: ip._item)
            }
            
            self._selectedIndexPaths.remove(ip)
            if let cell = self.cellForItem(at: ip) {
                _updateContext.updates.append(ItemUpdate(cell: cell, attrs: cell.attributes!, type: .remove))
                contentDocumentView.preparedCellIndex.removeValue(for: ip)
            }
        }
        for ip in _updateContext.insertedItems {
            if itemShifts[ip._section] == nil {
                itemShifts[ip._section] = ShiftSet(count: countIn(section: ip._section), insert: ip._item)
            }
            else {
                itemShifts[ip._section]?.insert(at: ip._item)
            }
        }
        for ip in _updateContext.movedItems {
            let from = ip.index
            let to = ip.value
            
            let aFrom = sectionMap[from._section] ?? -1
            if to._section == aFrom {
                if itemShifts[to._section] == nil {
                    itemShifts[to._section] = ShiftSet(count:  countIn(section: to._section), move: from._item, to: to._item)
                }
                else {
                    itemShifts[to._section]?.move(from._item, to: to._item)
                }
            }
            else {
                if itemShifts[aFrom] == nil {
                    itemShifts[aFrom] = ShiftSet(count: countIn(section: aFrom), remove: from._item)
                }
                else {
                    itemShifts[aFrom]?.remove(at: from._item)
                }
                if itemShifts[to._section] == nil {
                    itemShifts[to._section] = ShiftSet(count: countIn(section: to._section), insert: to._item)
                }
                else {
                    itemShifts[to._section]?.insert(at: to._item)
                }
            }
            
            if itemAtIndexPathIsSelected(from) {
                _selectedIndexPaths.remove(from)
                _updateSelections?.insert(to)
            }
            if let cell = self.cellForItem(at: from) {
                _updateContext.updates.append(ItemUpdate(cell: cell, indexPath: to, type: .update))
                contentDocumentView.preparedCellIndex.removeValue(for: from)
                _finalizedCellMap.insert(cell, with: to)
            }
        }
        
        var newCellIndex = _finalizedCellMap
        var newViewIndex = _finalizedViewMap
        
        var checked = Set<Int>()
        
        var viewsNeedingAdjustment = IndexedSet<SupplementaryViewIdentifier, CollectionReusableView>(self.contentDocumentView.preparedSupplementaryViewIndex).ordered()
        
        let preps = self.contentDocumentView.preparedCellIndex.ordered()

        for stale in viewsNeedingAdjustment {
            guard let ip = stale.index.indexPath else {
                log.error("Collection View Error: A supplemenary view identifier has a nil indexPath when trying to adjust views")
                continue
            }
            
            let adjusted = sectionMap[ip._section] ?? ip._section
            if adjusted < 0 {
                //Deleted section
                if let attrs = stale.value.attributes {
                    _updateContext.updates.append(ItemUpdate(view: stale.value, attrs: attrs, type: .remove, identifier: stale.index))
                }
                continue
            }
            
            let adjustedIP = IndexPath.for(section: adjusted)
            
            if adjustedIP._section > self.numberOfSections {
                log.error("⚠️ Invalid section adjustment from \(ip._section) to \(adjusted)")
            }
            
            let newID = stale.index.copy(with: adjustedIP)
            
            // TODO: Not sure if this actually needs to happen, it will just be reset below
            let view = stale.value
            self.contentDocumentView.preparedSupplementaryViewIndex.removeValue(forKey: stale.index)
            newViewIndex[newID] = view
            
            if adjustedIP != ip {
                _updateContext.updates.append(ItemUpdate(view: view, indexPath: adjustedIP, type: .update, identifier: newID))
            }
        }
        
        
        func adjustCells(in indexedSet: [IndexedSet<IndexPath, CollectionViewCell>.Iterator.Element], checkSections: Bool) {
            
            for stale in indexedSet {
                
                var adjusted = stale.index

                let s = { () -> Int in
                    if let v = sectionMap[adjusted._section] { return v }
                    let n = sectionMap.count
                    sectionMap[n] = n
                    return n
                }()
                
                // The section was deleted
                if s < 0 {
                    if let attrs = stale.value.attributes {
                        _updateContext.updates.append(ItemUpdate(cell: stale.value, attrs: attrs, type: .remove))
                    }
                    continue
                }
                
                if let i = itemShifts[s]?.populateMap(count: self.numberOfItems(in: s))[adjusted._item] {
                    adjusted = IndexPath.for(item: i, section: s)
                }
                else {
                    adjusted = adjusted.with(section: s)
                }
                
                
                let numSections = self.numberOfSections
                if adjusted._section > numSections - 1 {
                    log.error("⚠️ Invalid indexpath adjustment from \(stale.index)  -- \(adjusted). Section \(adjusted._section) is greater than or equal the number of sections in the collection view (\(numSections))")
                }
                let numItems = self.numberOfItems(in: adjusted._section) - 1
                if adjusted._item > numItems {
                    log.error("⚠️ Invalid indexpath adjustment from \(stale.index)  -- \(adjusted). Item (\(adjusted._item)) is greater than or equal the number of items in the section \((numItems))")
                }
                
                if self._selectedIndexPaths.remove(stale.index) != nil {
                    _updateSelections?.insert(adjusted)
                }
                
                var view = _updateContext.reloadedItems.contains(stale.index)
                    ? _prepareReplacementCell(for: stale.value, at: adjusted)
                    : stale.value
                
                // TODO: Not sure if this actually needs to happen, it will just be reset below
                self.contentDocumentView.preparedCellIndex.remove(view)
                newCellIndex[adjusted] = view
                
                if adjusted != stale.index {
                    _updateContext.updates.append(ItemUpdate(cell: view, indexPath: adjusted, type: .update))
                }
            }
        }

        
        adjustCells(in: preps , checkSections: viewsNeedingAdjustment.count > 0)
        adjustCells(in: _pendingCellMap.ordered(), checkSections: false)
        
        for selection in self._selectedIndexPaths {
            guard let s = sectionMap[selection._section], s >= 0 else { continue }
            if let item = itemShifts[s]?._map[selection._item] {
                if item >= 0 {
                    _updateSelections?.insert(IndexPath.for(item: item, section: s))
                }
            }
            else {
                _updateSelections?.insert(selection.with(section: s))
            }
        }
        
        self._selectedIndexPaths = _updateSelections!
        self.contentDocumentView.pendingUpdates = _updateContext.updates
        self.contentDocumentView.preparedCellIndex = newCellIndex
        self.contentDocumentView.preparedSupplementaryViewIndex = newViewIndex.dictionary
        self._reloadLayout(animated, scrollPosition: .none, completion: completion, needsRecalculation: false)
        
    }
    
    
    
    private func _prepareReplacementCell(for currentCell: CollectionViewCell, at indexPath: IndexPath) -> CollectionViewCell {
        
//        log.debug("Preparing replacment cell for item at: \(indexPath)")
        
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
        precondition(newCell.collectionView != nil, "Attempt to load cell without using deque:")
        self.contentDocumentView.preparedCellIndex.removeValue(for: indexPath)
        
//        log.debug("Loaded replacement cell \(newCell)")
        
        if newCell == currentCell {
            return newCell
        }
        
        let removal = ItemUpdate(cell: currentCell, attrs: currentCell.attributes!, type: .remove)
        self.contentDocumentView.removeItem(removal)
//        log.debug("Remove replaced cell \(currentCell.attributes!.indexPath)")
        
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
    public var trackSectionHover : Bool = false {
        didSet { self.addTracking() }
    }
    private var _trackingArea : NSTrackingArea?
    private func addTracking() {
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

    
    private func acceptClickEvent(_ event: NSEvent) -> (accept: Bool, itemSpecific: Bool) {
        guard let view = self.window?.contentView?.hitTest(event.locationInWindow), view.isDescendant(of: self) else {
            return (false, false)
        }
        if view.isDescendant(of: self._floatingSupplementaryView) { return (true, false) }
//        if view == self.clipView || view.isDescendant(of: self) { self.window?.makeFirstResponder(self) }
        return (true, true)
    }
    
    private var mouseDownIP: IndexPath?
    private var mouseDownLocation : CGPoint = CGPoint.zero
    open override func mouseDown(with theEvent: NSEvent) {
        
        self.mouseDownIP = nil
        let accept = acceptClickEvent(theEvent)
        guard accept.accept else {
            return
        }
        self.window?.makeFirstResponder(self)
        //        self.nextResponder?.mouseDown(theEvent)
        // super.mouseDown(theEvent) DONT DO THIS, it will consume the event and mouse up is not called
        mouseDownLocation = theEvent.locationInWindow
        let point = self.contentView.convert(theEvent.locationInWindow, from: nil)
        
        if accept.itemSpecific {
            self.mouseDownIP = self.indexPathForItem(at: point)
        }
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
        
        guard self.acceptClickEvent(theEvent).accept == true else { return }
        
        if mouseDownIP == nil && allowsEmptySelection {
            self._deselectAllItems(true, notify: true)
        }
        
        if theEvent.modifierFlags.contains(NSEventModifierFlags.control) {
            self.rightMouseDown(with: theEvent)
            return
        }
        
        guard let ip = indexPath , ip == mouseDownIP else {
            if theEvent.clickCount == 2 {
                self.delegate?.collectionView?(self, didDoubleClickItemAt: nil, with: theEvent)
            }
            return
        }
        
        
        if allowsMultipleSelection && theEvent.modifierFlags.contains(NSEventModifierFlags.shift) {
            self._selectItem(at: ip, atScrollPosition: .nearest, animated: true, selectionType: .extending)
        }
        else if allowsMultipleSelection && theEvent.modifierFlags.contains(NSEventModifierFlags.command) {
            if self._selectedIndexPaths.contains(ip) {
                if self._selectedIndexPaths.count == 1 { return }
                self._deselectItem(at: ip, animated: true, notifyDelegate: true)
            }
            else {
                self._selectItem(at: ip, animated: true, with: theEvent, notifyDelegate: true)
            }
        }
        else if theEvent.clickCount == 2 {
            self.delegate?.collectionView?(self, didDoubleClickItemAt: ip, with: theEvent)
        }
        else if self.selectionMode == .multi {
            if self.itemAtIndexPathIsSelected(ip) {
            self._deselectItem(at: ip, animated: true, notifyDelegate: true)
            }
            else {
                self._selectItem(at: ip, animated: true, scrollPosition: .none, with: theEvent, clear: false, notifyDelegate: true)
            }
        }
        else {
            self._selectItem(at: ip, animated: true, scrollPosition: .none, with: theEvent, clear: true)
        }
    }
    
    open override func rightMouseDown(with theEvent: NSEvent) {
        super.rightMouseDown(with: theEvent)
        
        let res = self.acceptClickEvent(theEvent)
        guard res.accept else { return }
        var ip : IndexPath?
        if res.itemSpecific {
            let point = self.contentView.convert(theEvent.locationInWindow, from: nil)
            ip = self.indexPathForItem(at: point)
        }
        self.delegate?.collectionView?(self, didRightClickItemAt: ip, with: theEvent)
    }
    
    final func moveSelectionInDirection(_ direction: CollectionViewDirection, extendSelection: Bool) {
        guard let indexPath = (extendSelection ? _lastSelection : _firstSelection) ?? self._selectedIndexPaths.first else { return }
        if let moveTo = self.collectionViewLayout.indexPathForNextItem(moving: direction, from: indexPath) {
            if let move = self.delegate?.collectionView?(self, shouldSelectItemAt: moveTo, with: NSApp.currentEvent) , move != true { return }
            self._selectItem(at: moveTo, atScrollPosition: .nearest, animated: true, selectionType: extendSelection ? .extending : .single)
        }
    }
    
    public var keySelectInterval: TimeInterval = 0.08
    private var lastEventTime : TimeInterval?
    public fileprivate(set) var repeatKey : Bool = false
    
    open override func keyDown(with theEvent: NSEvent) {
        repeatKey = theEvent.isARepeat
        if Set([123,124,125,126]).contains(theEvent.keyCode) {
            
            if theEvent.isARepeat && keySelectInterval > 0 {
                if let t = lastEventTime , (CACurrentMediaTime() - t) < keySelectInterval {
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
    
    
    /**
     If the collection view should allow selection of its items
    */
    public var allowsSelection: Bool = true
    
    
    /// Determin how item selections are managed
    ///
    /// - normal: Clicking an item selects the item and deselects others (given no modifier keys are used)
    /// - multi: Clicking an item will add it to the selection, clicking again will deselect it
    public enum SelectionMode {
        case `default`
        case multi
    }
    
    /// Determines what happens when an item is clicked
    public var selectionMode: SelectionMode = .default
    
    /// allows the selection of multiple items via modifier keys (command & shift)
    public var allowsMultipleSelection: Bool = true
    
    /// If true, clicking empty space will deselect all items
    public var allowsEmptySelection: Bool = true
    
    
    
    
    // MARK: - Selections
    /*-------------------------------------------------------------------------------*/
    
    
  
    // Select
    private var _firstSelection : IndexPath?
    private var _lastSelection : IndexPath?
    private var _selectedIndexPaths = Set<IndexPath>()
    

    /**
     The index path of the highlighted item, if any
    */
    public internal(set) var indexPathForHighlightedItem: IndexPath? {
        didSet {
            if oldValue == indexPathForHighlightedItem { return }
            if let ip = oldValue, let cell = self.cellForItem(at: ip) , cell.highlighted {
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
    public final var indexPathsForSelectedItems : Set<IndexPath> { return _selectedIndexPaths }
    
    /**
     Returns the index paths for all selected items ordered from first to last
     */
    public final var sortedIndexPathsForSelectedItems : [IndexPath] {
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
    
    
    /**
     Selects all items in the collection view

     - Parameter animated: If the selections should be animated
     
     - Note: The delegate is not notified of any selections

    */
    public func selectAllItems(_ animated: Bool = true) {
        self.selectItems(at: self.contentDocumentView.preparedCellIndex.indexes, animated: animated)
    }

    
    /**
     Select the items at the given index paths

     - Parameter indexPaths: The index paths of the items you want to select
     - Parameter animated: If the selections should be animated
     
     - Note: The delegate is not notified of the selections

    */
    public func selectItems(at indexPaths: [IndexPath], animated: Bool) {
        for ip in indexPaths { self._selectItem(at: ip, animated: animated, scrollPosition: .none, with: nil, notifyDelegate: false) }
    }
    
	/**
	Select items

	- Parameter indexPath: The description of the indexPath to select, or nil to deselect all.
	- Parameter animated: If the selections be animated
	- Parameter scrollPosition: The position to scroll the selected item to
     
     - Note: The delegate will not notified of the selection

	*/
    public func selectItem(at indexPath: IndexPath?, animated: Bool, scrollPosition: CollectionViewScrollPosition = .none) {
        self._selectItem(at: indexPath, animated: animated, scrollPosition: scrollPosition, with: nil, notifyDelegate: false)
    }
    
    private func _selectItem(at indexPath: IndexPath?, animated: Bool, scrollPosition: CollectionViewScrollPosition = .none, with event: NSEvent?, clear: Bool = false, notifyDelegate: Bool = true) {
        guard let indexPath = indexPath else {
            self.deselectAllItems(animated)
            return
        }
        
        if indexPath._section >= self.numberOfSections || indexPath._item >= self.numberOfItems(in: indexPath._section) { return }
        
        if !self.allowsSelection { return }
        if let shouldSelect = self.delegate?.collectionView?(self, shouldSelectItemAt: indexPath, with: event) , !shouldSelect { return }
        
        if clear {
            self.deselectAllItems()
        }
        
        if self.selectionMode != .multi && self.allowsMultipleSelection == false {
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
    private func _selectItem(at indexPath: IndexPath,
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
    
    /**
     Deselect cells at given index paths
     
     - Parameter indexPaths: The index paths to deselect
     - Parameter animated: If the deselections should be animated
     
     - Note: The delegate will not notified of the selections
     
     */
    public func deselectItems(at indexPaths: [IndexPath], animated: Bool) {
        for ip in indexPaths { self._deselectItem(at: ip, animated: animated, notifyDelegate: false) }
    }
    
    
    /**
     Deselect all items in the collection view

     - Parameter animated: If the delselections should be animated
     
     - Note: The delegate will not notified of the selections

    */
    public func deselectAllItems(_ animated: Bool = false) {
        self._deselectAllItems(animated, notify: false)
    }
    
    
    /**
     Deselect the item at a given index path

     - Parameter indexPath: The index path for the item to deselect
     - Parameter animated: If the deselection should be animated
     
     - Note: The delegate will not notified of the selections

    */
    public func deselectItem(at indexPath: IndexPath, animated: Bool) {
        self._deselectItem(at: indexPath, animated: animated, notifyDelegate: false)
    }
    
    private func _deselectAllItems(_ animated: Bool, notify: Bool) {
        let anIP = self._selectedIndexPaths.first
        self._lastSelection = nil
        
        let ips = self._selectedIndexPaths.intersection(Set(self.indexPathsForVisibleItems))
        
        for ip in ips { self._deselectItem(at: ip, animated: animated, notifyDelegate: false) }
        self._selectedIndexPaths.removeAll()
        if notify, let ip = anIP {
            self.delegate?.collectionView?(self, didDeselectItemAt: ip)
        }
    }
    
    private func _deselectItem(at indexPath: IndexPath, animated: Bool, notifyDelegate : Bool = true) {
        if let deselect = self.delegate?.collectionView?(self, shouldDeselectItemAt: indexPath) , !deselect { return }
        contentDocumentView.preparedCellIndex[indexPath]?.setSelected(false, animated: true)
        self._selectedIndexPaths.remove(indexPath)
        if notifyDelegate {
            self.delegate?.collectionView?(self, didDeselectItemAt: indexPath)
        }
    }
    
    
    
    // MARK: - Internal
    /*-------------------------------------------------------------------------------*/
    private func validateIndexPath(_ indexPath: IndexPath) -> Bool {
        let itemCount = self.numberOfItems(in: indexPath._section)
        guard itemCount > 0 else { return false }
        return indexPath._section < self.numberOfSections && indexPath._item < itemCount
    }
    
    private func indexPathForSelectableItem(before indexPath: IndexPath) -> IndexPath?{
        if (indexPath._item - 1 >= 0) {
            return IndexPath.for(item: indexPath._item - 1, section: indexPath._section)
        }
        else if indexPath._section - 1 >= 0 && self.numberOfSections > 0 {
            let numberOfItems = self.numberOfItems(in: indexPath._section - 1)
            let newIndexPath = IndexPath.for(item: numberOfItems - 1, section: indexPath._section - 1)
            if self.validateIndexPath(newIndexPath) { return newIndexPath }
        }
        return nil;
    }
    
    private func indexPathForSelectableItem(after indexPath: IndexPath) -> IndexPath? {
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
    
    

    
    // MARK: - Cells & Index Paths
    /*-------------------------------------------------------------------------------*/
    
    
    /**
     Returns all index paths in the collection view
     
     - Note: This must be provided by the collectionViewLayout
     
    */
    internal final var allIndexPaths : OrderedSet<IndexPath> { return self.collectionViewLayout.allIndexPaths }
    
    
    
    /**
     Returns all visible cells in the collection view
    */
    public final var visibleCells : [CollectionViewCell]  { return Array( self.contentDocumentView.preparedCellIndex.values) }
    
    
    
    
    /**
     Returns the index paths for all visible cells in the collection view
    */
    public final var indexPathsForVisibleItems : [IndexPath]  { return Array(self.contentDocumentView.preparedCellIndex.indexes) }
    
    
    
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
    public final func cellForItem(at indexPath: IndexPath) -> CollectionViewCell?  { return self.contentDocumentView.preparedCellIndex[indexPath] }
    
    
    /**
     Returns the index path for a cell in the collection view

     - Parameter cell: A cell in the collection view
     
     - Returns: The index path of the cell, or nill if it is not visible in the collection view

    */
    public final func indexPath(for cell: CollectionViewCell) -> IndexPath?  { return self.contentDocumentView.preparedCellIndex.index(of: cell) }
    
    
    /**
     Returns a index path for the item at a given point

     - Parameter point: A point within the collection views contentVisibleRect
     
     - Returns: The index path of the item at point, if any

    */
    public func indexPathForItem(at point: CGPoint) -> IndexPath?  {
        if self.numberOfSections == 0 { return nil }
        for sectionIndex in 0..<self.numberOfSections {
            guard let frame = self.frameForSection(at: sectionIndex), frame.contains(point) else { continue }
            let itemCount = self.numberOfItems(in: sectionIndex)
            
            for itemIndex in 0..<itemCount {
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
    
    
    /**
     Returns the first index path within a given distance of a point

     - Parameter point: A point within the contentDocumentView's frame
     - Parameter radius: The distance around the point to check

     - Returns: The index path for a matching item or nil if no items were found
     
    */
    public func firstIndexPathForItem(near point: CGPoint, radius: CGFloat) -> IndexPath?  {
        if self.numberOfSections == 0 { return nil }
        
        let rect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
        for sectionIndex in 0..<self.numberOfSections {
            guard let frame = self.frameForSection(at: sectionIndex), frame.intersects(rect) else { continue }
            let itemCount = self.numberOfItems(in: sectionIndex)
            
            for itemIndex in 0..<itemCount {
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
    
    
    /**
     Returns the first index path found intersecting a given rect

     - Parameter rect: A rect within the contentDocumentView's frame

     - Returns: The index path for the matching item or nil if no items were found
     
    */
    public func firstIndexPathForItem(in rect: CGRect) -> IndexPath?  {
        if self.numberOfSections == 0 { return nil }
        
        for sectionIndex in 0..<self.numberOfSections {
            guard let frame = self.frameForSection(at: sectionIndex), frame.intersects(rect) else { continue }
            let itemCount = self.numberOfItems(in: sectionIndex)
            for itemIndex in 0..<itemCount {
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
            let attributes = self.collectionViewLayout.layoutAttributesForItem(at: indexPath);
            return attributes?.frame;
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
            if rect.contains(point) { return IndexPath.for(item:0, section: sectionIndex) }
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
    public final var visibleSupplementaryViews : [CollectionReusableView]  { return Array( self.contentDocumentView.preparedSupplementaryViewIndex.values) }
    
    
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
                let ip = IndexPath.for(item:0, section: section)
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
                let y = rect.midY - (visibleRect.size.height/2)
                rect.origin.y = max(y, 0)
            }
            else {
                rect.size.width = self.bounds.size.width
            }
            break;
        case .trailing:
            // make the bottom of our rect flush with the bottom of the visible bounds
            let vHeight = self.contentDocumentView.visibleRect.size.height
            rect.origin.y = (aRect.origin.y + aRect.size.height) - vHeight
            rect.size.height = visibleRect.height;
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
            
            if rect.origin.y < visibleRect .origin.y {
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
        
        if animated || prepare {
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
    public var indexPathsForDraggingItems : [IndexPath] {
        return draggedIPs
    }
    
    private var draggedIPs : [IndexPath] = []
    public var isDragging : Bool = false
    
    override open func mouseDragged(with theEvent: NSEvent) {
        super.mouseDragged(with: theEvent)
        self.window?.makeFirstResponder(self)
        
        self.draggedIPs = []
        var items : [NSDraggingItem] = []
        
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
            var ip = indexPath
            
//            let selections = self.indexPathsForSelectedItems
//            if selections.count == 0 { return }
//            else if selections.count == 1 && mouseDown != ip {
//                self.deselectItem(at: ip, animated: true)
//                ip = mouseDown
//                self.selectItem(at: ip, animated: true)
//            }
            
            
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
                
//                self.draggedIPs.append(ip)
                let item = NSDraggingItem(pasteboardWriter: writer)
                item.draggingFrame = frame
                
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
            self.isDragging = true
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
        self.interactionDelegate?.collectionView?(self, draggingSession: session, didEndAt: screenPoint, with: operation, draggedIndexPaths: self.draggedIPs)
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
    open override func draggingEnded(_ sender: NSDraggingInfo?) {
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
    public var autoscrollSize : CGFloat = 15
    private var autoscrollTimer : Timer?
    
    func invalidateAutoscroll() {
        autoscrollTimer?.invalidate()
        autoscrollTimer = nil
    }
    
    func autoscrollTimer(_ sender: Timer) {
        if let p = (sender.userInfo as? [String:Any])?["point"] as? CGPoint {
            autoScroll(to: p)
        }
    }
    
    func autoScroll(to dragPoint: CGPoint) {
        
        guard isAutoscrollEnabled  else { return }
        
        func valid() {
            if autoscrollTimer?.isValid != true {
                autoscrollTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(autoscrollTimer(_:)), userInfo: ["point":dragPoint], repeats: true)
            }
        }
        
        let loc = self.convert(dragPoint, from: nil)
        let visible = self.visibleRect
        guard visible.contains(loc) else {
            invalidateAutoscroll()
            return
        }
        
//        log.debug("Auto scroll \(loc) in \(visible)")
        if loc.y > (self.bounds.size.height - self.contentInsets.bottom - autoscrollSize) {
//            log.debug("Dragging autoscroll: Down")
            var cRect = self.contentVisibleRect
            let newRect = CGRect(x: cRect.origin.x, y: cRect.maxY + 50, width: cRect.size.width, height: 50)
            self.scrollRect(newRect, to: .trailing, animated: true, completion: nil)
            valid()
        }
        else if loc.y > self.contentInsets.top && loc.y < (self.contentInsets.top + autoscrollSize) {
//            log.debug("Dragging autoscroll: Up")
            
            var cRect = self.contentVisibleRect
            let newRect = CGRect(x: cRect.origin.x, y: cRect.minY - 5, width: cRect.size.width, height: 5)
            self.scrollRect(newRect, to: .leading, animated: true, completion: nil)
            valid()
        }
        else {
            invalidateAutoscroll()
        }
    }
    
    
    
}

