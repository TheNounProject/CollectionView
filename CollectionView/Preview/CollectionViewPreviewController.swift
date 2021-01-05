//
//  File.swift
//  Lingo
//
//  Created by Wesley Byrne on 3/23/17.
//  Copyright © 2017 The Noun Project. All rights reserved.
//

import Foundation

/// a CollectionViewPreviewControllerDelegate is responsible for providing data to a CollectionViewPreviewController.
public protocol CollectionViewPreviewControllerDelegate: class {
    
    /// Asks the delegate for a cell to use to preview the item at indexPath
    ///
    /// CollectionViewPreviewCell provides a basic implementation of transitions and can be subclasses for custom transitions from and back to the source.
    ///
    /// - Parameter controller: The controller requesting the cell
    /// - Parameter indexPath: The indexpath of the item to represent
    ///
    /// - Returns: A collection view cell
    func collectionViewPreviewController(_ controller: CollectionViewPreviewController, cellForItemAt indexPath: IndexPath) -> CollectionViewCell
    
    /// Asks the delegate if the item at the specified index path should be included in the preview.
    ///
    /// If false, under the default usage the preview collection view will not attempt to render a cell for the item. You can safely assume that collectionViewPreviewController(_:cellForItemAt:) will not be called for these items.
    ///
    /// - Parameter controller: The controller requesting the information
    /// - Parameter indexPath: The index path of the item
    ///
    /// - Returns: True if the item can be previewed, false if not.
    func collectionViewPreviewController(_ controller: CollectionViewPreviewController, canPreviewItemAt indexPath: IndexPath) -> Bool
    
    /// Notifies the delegate that the preview controller will dismiss
    ///
    /// - Parameter controller:
    func collectionViewPreviewControllerWillDismiss(_ controller: CollectionViewPreviewController)
    
    func collectionViewPreview(_ controller: CollectionViewPreviewController, didMoveToItemAt indexPath: IndexPath)
}

extension CollectionViewPreviewControllerDelegate {
    func collectionViewPreview(_ controller: CollectionViewPreviewController, didMoveToItemAt indexPath: IndexPath) { }
}

class BackgroundView: NSView {
    var backgroundColor: NSColor?
    
    var useLayer: Bool = true { didSet { wantsLayer = useLayer }}
    
    override var wantsUpdateLayer: Bool { return useLayer }
    
    init(color: NSColor) {
        super.init(frame: CGRect.zero)
        self.backgroundColor = color
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func updateLayer() {
        super.updateLayer()
        self.layer?.backgroundColor = backgroundColor?.cgColor
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if !self.isHidden, let c = backgroundColor {
            NSGraphicsContext.saveGraphicsState()
            c.set()
            dirtyRect.fill()
            NSGraphicsContext.restoreGraphicsState()
        }
    }
}

internal class EventMonitor {
    fileprivate var local: Any?
    fileprivate let mask: NSEvent.EventTypeMask
    fileprivate let handler: ((NSEvent?) -> NSEvent?)
    
    public init(mask: NSEvent.EventTypeMask, handler: @escaping ((NSEvent?) -> NSEvent?)) {
        self.mask = mask
        self.handler = handler
    }
    
    deinit {
        stop()
    }
    
    open func start() {
        local = NSEvent.addLocalMonitorForEvents(matching: mask, handler: { [unowned self] (event) -> NSEvent? in
            return self.handler(event)
        })
    }
    
    open func stop() {
        if let l = local { NSEvent.removeMonitor(l) }
        local = nil
    }
}

/**
 An easy to use CollectionViewController that transitions from a source collection view.
 
 
### Presentation & Data
 
 The controller is presented from a source collection view. The data source of the source collection view is used to load data for the preview collection view. The preview controller will act as a proxy between the preview collection view and your source colleciton views data source.
 
 - Important: The data source for the collection view passed to present(in:) must conform to CollectionViewPreviewControllerDelegate
 
 
### Transitions
 
 The preview controller manages the transitions to and from the source and allows the preview cell to customize the transition.
 
 Although the The preview controller will accept any cell class, supporting transitions requires a small amount of additional setup.
 
 The simplest way to support transitions is to create your subclass from CollectionViewPreviewCell. CollectionViewPreviewCell will animate the frame of the cell from the source and back.
 
 For custom transitions, if you subclass CollectionViewPreviewCell you can simply override the the transition methods, otherwise conform your CollectionViewCell subclass and implement the methods yourself. See CollectionViewPreviewTransitionCell for more about how to implement custom transitions

 
*/
open class CollectionViewPreviewController: CollectionViewController, CollectionViewDelegatePreviewLayout {

    // MARK: - Delegate
    /*-------------------------------------------------------------------------------*/
    
    /// A delegate to provide data
    open weak var delegate: CollectionViewPreviewControllerDelegate?
    
    open override func loadView() {
        if self.nibName != nil { super.loadView() } else {
            self.view = NSView(frame: NSRect(origin: CGPoint.zero, size: CGSize(width: 100, height: 100)))
        }
        self.interactiveGestureEnabled = true
    }
    
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    fileprivate var eventMonitor: EventMonitor?
    
    // MARK: - Styling
    /*-------------------------------------------------------------------------------*/
    /// The background color of the view when the items are displayed
    open var backgroundColor: NSColor = NSColor.white {  didSet { overlay.backgroundColor = backgroundColor }}
    
    private var overlay = BackgroundView(color: NSColor.white)

    public var dismissGestureEnabled: Bool = false {
        didSet { dismissGesture?.isEnabled = dismissGestureEnabled }
    }
    private var dismissGesture: NSMagnificationGestureRecognizer?
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        let layout = CollectionViewPreviewLayout()
        collectionView.collectionViewLayout = layout
        collectionView.automaticallyAdjustsContentInsets = false
        collectionView.contentInsets = .zero
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.allowsEmptySelection = false
        collectionView.allowsMultipleSelection = false

        collectionView.horizontalScroller = nil
        collectionView.hasHorizontalScroller = false
        collectionView.verticalScrollElasticity = .none
        
        collectionView.animationDuration = 0.2
        collectionView.backgroundColor = NSColor.clear
        collectionView.verticalScrollElasticity = .none
        self.collectionView.clipView?.decelerationRate = 0.88
        
        self.view.acceptsTouchEvents = true
        overlay.useLayer = true
        self.view.addSubview(overlay, positioned: .below, relativeTo: nil)
        overlay.addConstraintsToMatchParent()
        
        let gesture = NSMagnificationGestureRecognizer(target: self,
                                                       action: #selector(CollectionViewPreviewController.magnificationGestureRecognized(_:)))
        self.view.addGestureRecognizer(gesture)
        gesture.isEnabled = self.dismissGestureEnabled
        self.dismissGesture = gesture
    }
    
    // MARK: - Source & Data
    /*-------------------------------------------------------------------------------*/
    
    /// The  collection view the receiver was presented from
    private(set) public var sourceCollectionView: CollectionView?
    
    /// The index path the receiver was presented from
    private(set) public var sourceIndexPath: IndexPath?
    
    /// The index path for the currently displayed item
    public var currentIndexPath: IndexPath? {
        return collectionView.indexPathsForSelectedItems.first ?? self.collectionView.indexPathForFirstVisibleItem
    }
    
    public var isEmpty: Bool {
        return self.collectionView.indexPathsForVisibleItems.isEmpty
    }
    
    open func reloadData() {
        self.collectionView.reloadData()
    }
    
    open override func keyUp(with event: NSEvent) {
        self.interpretKeyEvents([event])
    }
    open override func cancelOperation(_ sender: Any?) {
        self.dismiss(animated: true)
    }
    open override func insertText(_ insertString: Any) {
        
    }
    open override func doCommand(by selector: Selector) {
        
    }
    
    func startEventMonitor() {
        let events: NSEvent.EventTypeMask = [
            NSEvent.EventTypeMask.scrollWheel
            ]

        eventMonitor = EventMonitor(mask: events, handler: { (event) in
            guard let e = event, e.phase != [] else { return event }
            guard let v = self.view.window?.contentView?.hitTest(e.locationInWindow),
                v.isDescendant(of: self.view) else {
                return e
            }
            self.scrollWheel(with: e)
            return nil
        })
        eventMonitor?.start()
    }
    
    func stopEventMonitor() {
        eventMonitor?.stop()
        eventMonitor = nil
    }
    
    @objc func magnificationGestureRecognized(_ sender: NSMagnificationGestureRecognizer) {
        if sender.state == .began, sender.magnification < 0 {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - Transitions
    /*-------------------------------------------------------------------------------*/
    
    public var layoutConstraintConfiguration : ((_ container: NSViewController, _ controller: CollectionViewPreviewController) -> Void)?
    
    /// The duration of present/dismiss transitions
    open var transitionDuration: TimeInterval = 0.25
    
    /// Present the preview controller, transitioning from an item at indexPath in the source collectionView
    ///
    /// **Data Source**
    ///
    /// The DataSource of the preview collection view will the same as the provided source collection view.
    ///
    /// **Excluding items from preview**
    ///
    /// Because the preview collection view must share a data source with it's source, it can be useful to keep some items displayed in the source from being previewed. See `collectionViewPreviewController(_:canPreviewItemAt:)` in CollectionViewPreviewControllerDelegate
    ///
    /// - Parameter controller: The ViewController to present in
    /// - Parameter sourceCollectionView: A collectionView to transition from
    /// - Parameter indexPath: The index path of the item to transition with
    /// - Parameter completion: A block to call when the transition is complete
    open func present(in controller: NSViewController, source sourceCollectionView: CollectionView, indexPath: IndexPath, completion: AnimationCompletion? = nil) {
        
        self.delegate = sourceCollectionView.delegate as? CollectionViewPreviewControllerDelegate
            ?? controller as? CollectionViewPreviewControllerDelegate
        
        // swiftlint:disable:next line_length
        assert(self.delegate != nil, "Developer Error: When presenting CollectionViewPreviewController, controller or sourceCollectionView's delegate must conform to CollectionViewPreviewController")
        
        self.sourceCollectionView = sourceCollectionView
        self.sourceIndexPath = indexPath
        
        self.overlay.alphaValue = 0
        
        controller.addChild(self)
        controller.view.addSubview(self.view)
        if let config = self.layoutConstraintConfiguration {
            config(controller, self)
        } else {
            self.view.addConstraintsToMatchParent()
        }
        
        self.collectionView.frame = self.view.bounds
        self.collectionView.layoutSubtreeIfNeeded()
        self.collectionView.reloadData()
        
        self.collectionView.isScrollEnabled = true
        self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .none)
        self.collectionView.scrollItem(at: indexPath, to: .centered, animated: false, completion: nil)
        self.collectionView.isScrollEnabled = false
        
        self.startEventMonitor()
        
        guard let cell = self.collectionView.cellForItem(at: indexPath),
            let attrs = self.collectionView.layoutAttributesForItem(at: indexPath) else {
                self.overlay.alphaValue = 1
                self.view.window?.makeFirstResponder(self.collectionView)
                self.collectionView.isScrollEnabled = true
                completion?(true)
                return
        }
        
        let trans = cell as? CollectionViewPreviewTransitionCell
        trans?.prepareForTransition(fromItemAt: indexPath, in: sourceCollectionView, to: attrs)
        
        DispatchQueue.main.async {
            NSAnimationContext.runAnimationGroup({ [unowned self] (context) -> Void in
                context.duration = self.transitionDuration
                context.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
                context.allowsImplicitAnimation = true
                
                trans?.transition(fromItemAt: indexPath, in: sourceCollectionView, to: attrs)

            }) {
                completion?(true)
                trans?.finishTransition(fromItemAt: indexPath, in: sourceCollectionView)
                self.collectionView.isScrollEnabled = true
            }
            self.overlay.animator().alphaValue = 1
        }
        self.view.window?.makeFirstResponder(self.collectionView)
    }
    
    /// Dismiss the preview controller, transitioning the current item back to its source
    ///
    /// - Parameter animated: If the dismiss should be animated
    /// - Parameter completion: A block to call when the tranision is complete
    open func dismiss(animated: Bool, completion: AnimationCompletion? = nil) {
        self.delegate?.collectionViewPreviewControllerWillDismiss(self)
        self.collectionView.isScrollEnabled = false
        
        let ips = self.collectionView.indexPathsForVisibleItems.filter {
            if let cell = self.collectionView.cellForItem(at: $0) {
                return collectionView.contentVisibleRect.intersects(cell.frame)
            }
            return false
        }
        if animated, let sourceCV = self.sourceCollectionView, !ips.isEmpty {
            for ip in ips {
                let cell = self.collectionView.cellForItem(at: ip)
                let trans = cell as? CollectionViewPreviewTransitionCell
                trans?.prepareForTransition(toItemAt: ip, in: sourceCV)
                
                NSAnimationContext.runAnimationGroup({ (context) in
                    context.duration = self.transitionDuration
                    context.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
                    context.allowsImplicitAnimation = true
                    
                    trans?.transition(toItemAt: ip, in: sourceCV)
                    self.overlay.animator().alphaValue = 0
                }) {
                    self.stopEventMonitor()
                    completion?(true)
                    trans?.finishTransition(toItemAt: ip, in: sourceCV)
                    self.view.removeFromSuperview()
                    self.removeFromParent()
                }
            }
        } else {
            self.removeFromParent()
            self.view.removeFromSuperview()
            self.stopEventMonitor()
            completion?(true)
        }
    }
    
    open override func numberOfSections(in collectionView: CollectionView) -> Int {
        return sourceCollectionView?.numberOfSections ?? 0
    }
    
    open override func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int {
        return sourceCollectionView?.numberOfItems(in: section) ?? 0
    }
    
    open func previewLayout(_ layout: CollectionViewPreviewLayout, canPreviewItemAt indexPath: IndexPath) -> Bool {
        return delegate?.collectionViewPreviewController(self, canPreviewItemAt: indexPath) ?? true
    }
    
    open override func collectionView(_ collectionView: CollectionView, cellForItemAt indexPath: IndexPath) -> CollectionViewCell {
        let cell = self.delegate?.collectionViewPreviewController(self, cellForItemAt: indexPath)
        precondition(cell != nil, "CollectionViewPreviewController was unable to load a cell for item at \(indexPath)")
        return cell!
    }
    
    open func collectionView(_ collectionView: CollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        if let ip = indexPaths.first {
            self.delegate?.collectionViewPreview(self, didMoveToItemAt: ip)
        }
    }
    
    // MARK: - Interactive Gesture
    /*-------------------------------------------------------------------------------*/
    public var interactiveGestureEnabled: Bool {
        set { self.view.acceptsTouchEvents = newValue }
        get { return self.view.acceptsTouchEvents }
    }
    open override func wantsScrollEventsForSwipeTracking(on axis: NSEvent.GestureAxis) -> Bool {
        return axis == .horizontal
    }
    
    open override func scrollWheel(with event: NSEvent) {
        guard event.type == .scrollWheel, event.phase == .began else { return }
        
        // If the scroll doesn't stop off horizontal, track it to consume the event
        // but then cancel as soon as it ends
        guard self.collectionView.isScrollEnabled, abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) else {
            event.trackSwipeEvent(options: [], dampenAmountThresholdMin: 0, max: 0) { (_, phase, _, stop) in
                if phase == .cancelled || phase == .ended {
                    stop.pointee = true
                }
            }
            return
        }
        
        guard let ip = self.currentIndexPath else { return }
        
        let start = self.collectionView.contentOffset.x
        let adjust = (self.collectionView.collectionViewLayout as? CollectionViewPreviewLayout)?.interItemSpacing ?? 8
        var maxUp = self.collectionView.contentVisibleRect.width + adjust
        var maxDown = self.collectionView.contentVisibleRect.width + adjust
        let next = self.collectionView.collectionViewLayout.indexPathForNextItem(moving: .right, from: ip)
        let prev = self.collectionView.collectionViewLayout.indexPathForNextItem(moving: .left, from: ip)
        
        if let ip = next, let attrs = self.collectionView.layoutAttributesForItem(at: ip) {
            maxUp = attrs.frame.minX - start
        }
        if let ip = prev, let attrs = self.collectionView.layoutAttributesForItem(at: ip) {
            maxDown = start - attrs.frame.minX
        }
        
        event.trackSwipeEvent(options: [.clampGestureAmount],
                              dampenAmountThresholdMin: next == nil ? 0 : -0.5,
                              max: prev == nil ? 0 : 0.5) { (delta, phase, _, stop) in
                                if phase == .cancelled {
                                    stop.pointee = true
                                    self.collectionView.scrollItem(at: ip, to: .centered, animated: true, completion: nil)
                                    return
                                } else if phase == .ended {
                                    if delta < 0, let ip = next {
                                        self.collectionView.selectItem(at: ip, animated: true, scrollPosition: .centered)
                                        self.delegate?.collectionViewPreview(self, didMoveToItemAt: ip)
                                        stop.pointee = true
                                        return
                                    } else if delta >= 0, let ip = prev {
                                        self.collectionView.selectItem(at: ip, animated: true, scrollPosition: .centered)
                                        self.delegate?.collectionViewPreview(self, didMoveToItemAt: ip)
                                        stop.pointee = true
                                        return
                                    }
                                }
                                
                                let newX = -delta * (delta < 0 ? maxUp : maxDown)
                                let offset = start + newX
                                self.collectionView.contentOffset.x = offset
        }
    }
}
