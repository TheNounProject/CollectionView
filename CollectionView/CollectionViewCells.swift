//
//  CollectionViewCells.swift
//  Lingo
//
//  Created by Wesley Byrne on 1/29/16.
//  Copyright © 2016 The Noun Project. All rights reserved.
//

import Foundation


/**
 The CollectionReusableView class defines the behavior for all cells and supplementary views presented by a collection view. Reusable views are so named because the collection view places them on a reuse queue rather than deleting them when they are scrolled out of the visible bounds. Such a view can then be retrieved and repurposed for a different set of content.
*/
open class CollectionReusableView : NSView {
    


    
    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawPolicy.onSetNeedsDisplay
    }
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsLayer = true
        self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawPolicy.onSetNeedsDisplay
    }
    
    
    // MARK: - Reuse
    /*-------------------------------------------------------------------------------*/
    
    /// A string that identifies the purpose of the view.
    open internal(set) var reuseIdentifier: String?
    
    /// The collection view the view was dequed in
    open internal(set) weak var collectionView : CollectionView?
    
    /// True if the view has been dequed from the reuse pool
    open internal(set) var reused : Bool = false
    
    // MARK: - Lifecycle
    /*-------------------------------------------------------------------------------*/
    
    /// Performs any clean up necessary to prepare the view for use again.
    override open func prepareForReuse() {
        self.reused = true
//        super.prepareForReuse()
    }
    
    /// Called just before the view is added to the collection view
    open func viewWillDisplay() { }
    /// Called just after the view was added to the collection view
    open func viewDidDisplay() { }
    
    
    @available(*, unavailable, renamed: "apply(_:animated:)")
    public func applyLayoutAttributes(_ layoutAttributes: CollectionViewLayoutAttributes, animated: Bool) { }
    
    /**
     Applies the specified layout attributes to the view.

     - Parameter layoutAttributes: The layout attributes to apply
     - Parameter animated: If the collection view is performing an animated update while applying these attributes

    */
    
    
    
    
    
    // MARK: - Attributes
    /*-------------------------------------------------------------------------------*/
    internal var attributes : CollectionViewLayoutAttributes?
    
    /// The background color of the cell
    open var backgroundColor: NSColor? { didSet { self.needsDisplay = true }}
    
    open func apply(_ layoutAttributes: CollectionViewLayoutAttributes, animated: Bool) {

        if animated {
            self.animator().frame = layoutAttributes.frame
            self.animator().alphaValue = layoutAttributes.alpha
            self.layer?.zPosition = layoutAttributes.zIndex
            self.animator().isHidden = layoutAttributes.hidden
        }
        else {
            self.frame = layoutAttributes.frame
            self.alphaValue = layoutAttributes.alpha
            self.layer?.zPosition = layoutAttributes.zIndex
            self.isHidden = layoutAttributes.hidden
        }
        
        self.attributes = layoutAttributes
    }
    
    open var useMask: Bool = false
    
    open override func updateLayer() {
        super.updateLayer()
        self.layer?.backgroundColor = self.backgroundColor?.cgColor
        if useMask {
            let l = CALayer()
            l.backgroundColor = NSColor.white.cgColor
            l.frame = self.bounds
            l.cornerRadius = self.layer!.cornerRadius
            self.layer?.mask = l
        }
    }
    
    open override func draw(_ dirtyRect: NSRect) {
        
        if let c = self.backgroundColor {
            NSGraphicsContext.saveGraphicsState()
            c.setFill()
            NSRectFill(dirtyRect)
            NSGraphicsContext.restoreGraphicsState()
        }
        super.draw(dirtyRect)
    }
    
    
    
    // MARK: - Mouse Tracking
    /*-------------------------------------------------------------------------------*/
    
    fileprivate var wantsTracking = false
    open var trackingOptions = [NSTrackingAreaOptions.mouseEnteredAndExited, NSTrackingAreaOptions.activeInKeyWindow, .inVisibleRect, .enabledDuringMouseDrag]
    var _trackingArea : NSTrackingArea?
    open var trackMouseMoved : Bool = false {
        didSet {
            if trackMouseMoved == oldValue { return }
            let idx = trackingOptions.index(of: .mouseMoved)
            if trackMouseMoved && idx == nil {
                trackingOptions.append(.mouseMoved)
            }
            else if !trackMouseMoved, let i = idx {
                trackingOptions.remove(at: i)
            }
            self.updateTrackingAreas()
        }
    }
    
    
    
    /// Disable tracking (used for highlighting in cells) for this view
    open func disableTracking() {
        self.wantsTracking = false
        self.updateTrackingAreas()
    }
    /// Enable tracking for this view (called by default for cells)
    open func enableTracking() {
        self.wantsTracking = true
        self.updateTrackingAreas()
    }
    
    open override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let ta = self._trackingArea { self.removeTrackingArea(ta) }
        if self.wantsTracking == false { return }
        _trackingArea = NSTrackingArea(rect: self.bounds, options: NSTrackingAreaOptions(trackingOptions), owner: self, userInfo: nil)
        self.addTrackingArea(_trackingArea!)
    }
    
    
}



/**
 A CollectionViewCell object presents the content for a single data item when that item is within the collection view’s visible bounds. You can use this class as-is or subclass it to add additional properties and methods. The layout and presentation of cells is managed by the collection view and its corresponding layout object.
*/
open class CollectionViewCell : CollectionReusableView {
    
    open override func acceptsFirstMouse(for theEvent: NSEvent?) -> Bool { return true }
    
    

    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsTracking = true
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsTracking = true
    }
    
    
    // MARK: - State
    /*-------------------------------------------------------------------------------*/
    
    fileprivate var _selected: Bool = false
    fileprivate var _highlighted : Bool = false
    
    /// The highlight state of the cell.
    public var highlighted: Bool {
        get { return _highlighted }
        set { self.setHighlighted(newValue, animated: false) }
    }
    
    /// The selection state of the cell.
    public var selected : Bool {
        set { self.setSelected(newValue, animated: false) }
        get { return self._selected }
    }
    
    
    open func setSelected(_ selected: Bool, animated: Bool = true) {
        self._selected = selected
    }
    
    open func setHighlighted(_ highlighted: Bool, animated: Bool) {
        self._highlighted = highlighted
        if highlighted {
            self.collectionView?.indexPathForHighlightedItem = self.attributes?.indexPath
        }
    }
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        self.setSelected(false, animated: false)
        self.setHighlighted(false, animated: false)
    }
    
    override open func mouseEntered(with theEvent: NSEvent) {
        
        // Validate self and the event
        guard let cv = self.collectionView, let ip = self.attributes?.indexPath else { return }
        guard theEvent.type == NSEventType.mouseEntered && (theEvent.trackingArea?.owner as? CollectionViewCell) == self else { return }
        
        // Make sure the event is inside self
        guard let window = self.window else { return }
        let mLoc = window.convertFromScreen(NSRect(origin: NSEvent.mouseLocation(), size: CGSize.zero)).origin
        if !self.bounds.contains(self.convert(mLoc, from: nil)) { return }
        
        // Ignore the event if an interaction enabled view is over this cell
        if let view = self.window?.contentView?.hitTest(theEvent.locationInWindow) {
            if view.isDescendant(of: self) {
                if let h = cv.delegate?.collectionView?(cv, shouldHighlightItemAt: ip) , h == false { return }
                super.mouseEntered(with: theEvent)
                self.setHighlighted(true, animated: true)
            }
        }
    }
    
    override open func mouseExited(with theEvent: NSEvent) {
        super.mouseExited(with: theEvent)
        guard theEvent.type == NSEventType.mouseExited && (theEvent.trackingArea?.owner as? CollectionViewCell) == self else { return }
        self.setHighlighted(false, animated: true)
    }
    
    
    
    // MARK: - Registration & Reuse Helpers
    /*-------------------------------------------------------------------------------*/
    
    /// Provide a reuse identifier for all cells of this class, defaults to the class name
    open class var defaultReuseIdentifier : String { return self.className() }
    
    
    
    /**
     Register a CollectionViewCell subclass to a collection view using the class's defaultReuseIdentifier
     
     - Parameter collectionView: The collection view to register the class in
     
     */
    open class func register(in collectionView: CollectionView) {
        let id = defaultReuseIdentifier
        collectionView.register(class: self, forCellWithReuseIdentifier: id)
    }
    
    /**
     Deque a cell of this class from a collection view. Uses defaultReuseIdentifier
     
     - Parameter indexPath: The indexPath to deque the cell for
     - Parameter collectionView: The collection view to deque the cell from
     
     - Returns: A valid CollectionViewCell
     
     */
    open class func deque(for indexPath: IndexPath, in collectionView: CollectionView) -> CollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: defaultReuseIdentifier, for: indexPath)
    }
    
}

