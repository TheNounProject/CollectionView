//
//  CBCollectionViewCells.swift
//  Lingo
//
//  Created by Wesley Byrne on 1/29/16.
//  Copyright © 2016 The Noun Project. All rights reserved.
//

import Foundation



public class CBCollectionReusableView : NSView {
    
    public internal(set) var indexPath: NSIndexPath?
    public internal(set) var reuseIdentifier: String?
    public internal(set) weak var collectionView : CBCollectionView?
    public internal(set) var reused : Bool = false
    
    internal var attributes : CBCollectionViewLayoutAttributes?
    
    public var backgroundColor: NSColor?
    
    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawPolicy.OnSetNeedsDisplay
    }
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsLayer = true
        self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawPolicy.OnSetNeedsDisplay
    }
    
    override public func prepareForReuse() {
        self.reused = true
        super.prepareForReuse()
    }
    public func viewWillDisplay() { }
    public func viewDidDisplay() { }
    
    public func applyLayoutAttributes(layoutAttributes: CBCollectionViewLayoutAttributes, animated: Bool) {

        if animated {
            self.animator().frame = layoutAttributes.frame
            self.animator().alphaValue = layoutAttributes.alpha
            self.layer?.zPosition = layoutAttributes.zIndex
            self.animator().hidden = layoutAttributes.hidden
        }
        else {
            self.frame = layoutAttributes.frame
            self.alphaValue = layoutAttributes.alpha
            self.layer?.zPosition = layoutAttributes.zIndex
            self.hidden = layoutAttributes.hidden
        }
        
        self.attributes = layoutAttributes
    }
    
    public override func updateLayer() {
        self.layer?.backgroundColor = self.backgroundColor?.CGColor
    }
    
    public override func drawRect(dirtyRect: NSRect) {
        
        if let c = self.backgroundColor {
            NSGraphicsContext.saveGraphicsState()
            c.setFill()
            NSRectFill(dirtyRect)
            NSGraphicsContext.restoreGraphicsState()
        }
        super.drawRect(dirtyRect)
    }
    
    
    
}

public class CBCollectionViewCell : CBCollectionReusableView {
    
    public override func acceptsFirstMouse(theEvent: NSEvent?) -> Bool { return true }
    
    private var wantsTracking = true
    public var trackingOptions = [NSTrackingAreaOptions.MouseEnteredAndExited, NSTrackingAreaOptions.ActiveInKeyWindow, .InVisibleRect, .EnabledDuringMouseDrag]
    
    private var _selected: Bool = false
    private var _highlighted : Bool = false
    public var highlighted: Bool {
        get { return _highlighted }
        set { self.setHighlighted(newValue, animated: false) }
    }
    public var selected : Bool {
        set { self.setSelected(newValue, animated: false) }
        get { return self._selected }
    }
    
    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public func setSelected(selected: Bool, animated: Bool = true) {
        self._selected = selected
    }
    
    public func setHighlighted(highlighted: Bool, animated: Bool) {
        self._highlighted = highlighted
        if highlighted {
            self.collectionView?.indexPathForHighlightedItem = self.indexPath
        }
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        self.setSelected(false, animated: false)
        self.setHighlighted(false, animated: false)
    }
    
    
    var _trackingArea : NSTrackingArea?
    public var trackMouseMoved : Bool = false {
        didSet {
            if trackMouseMoved == oldValue { return }
            let idx = trackingOptions.indexOf(.MouseMoved)
            if trackMouseMoved && idx == nil {
                trackingOptions.append(.MouseMoved)
            }
            else if !trackMouseMoved, let i = idx {
                trackingOptions.removeAtIndex(i)
            }
            self.updateTrackingAreas()
        }
    }
    
    public func disableTracking() {
        self.wantsTracking = false
        self.updateTrackingAreas()
    }
    
    public func enableTracking() {
        self.wantsTracking = true
        self.updateTrackingAreas()
    }
    
    public override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let ta = self._trackingArea { self.removeTrackingArea(ta) }
        if self.wantsTracking == false { return }
        _trackingArea = NSTrackingArea(rect: self.bounds, options: NSTrackingAreaOptions(trackingOptions), owner: self, userInfo: nil)
        self.addTrackingArea(_trackingArea!)
    }
    
    override public func mouseEntered(theEvent: NSEvent) {
        
        guard let window = self.window else { return }
        let mLoc = window.convertRectFromScreen(NSRect(origin: NSEvent.mouseLocation(), size: CGSizeZero)).origin
        if !self.bounds.contains(self.convertPoint(mLoc, fromView: nil)) { return }
        
        guard let cv = self.collectionView, let ip = self.indexPath else { return }
        guard theEvent.type == NSEventType.MouseEntered && (theEvent.trackingArea?.owner as? CBCollectionViewCell) == self else { return }
        
        if let view = self.window?.contentView?.hitTest(theEvent.locationInWindow) {
            if view.isDescendantOf(self) {
                if let h = cv.delegate?.collectionView?(cv, shouldHighlightItemAtIndexPath: ip) where h == false { return }
                super.mouseEntered(theEvent)
                self.setHighlighted(true, animated: true)
            }
        }
    }
    
    override public func mouseExited(theEvent: NSEvent) {
        super.mouseExited(theEvent)
        guard theEvent.type == NSEventType.MouseExited && (theEvent.trackingArea?.owner as? CBCollectionViewCell) == self else { return }
        self.setHighlighted(false, animated: true)
    }
    
}
