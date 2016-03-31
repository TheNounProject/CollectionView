//
//  CBCollectionViewCells.swift
//  Lingo
//
//  Created by Wesley Byrne on 1/29/16.
//  Copyright © 2016 The Noun Project. All rights reserved.
//

import Foundation


public class CBCollectionReusableView : NSView {
    
    public internal(set) var _indexPath: NSIndexPath?
    public internal(set) var reuseIdentifier: String?
    
    private var attributes : CBCollectionViewLayoutAttributes?
    
    public var backgroundColor: NSColor = NSColor.whiteColor() {
        didSet {
            self.layer?.backgroundColor = backgroundColor.CGColor
        }
    }
    
    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
//        self.canDrawSubviewsIntoLayer = true
    }
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsLayer = true
        self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawPolicy.OnSetNeedsDisplay
//        self.canDrawSubviewsIntoLayer = true
    }
    
    override public func prepareForReuse() {
        super.prepareForReuse()
    }
    
    public func applyLayoutAttributes(layoutAttributes: CBCollectionViewLayoutAttributes, animated: Bool = false) {
        self.frame = layoutAttributes.frame
        self.alphaValue = layoutAttributes.alpha
        self.layer?.zPosition = layoutAttributes.zIndex
        self.hidden = layoutAttributes.hidden
//        self.needsDisplay = true
    }
    
    
    
}

// Will get to this later...
public class CBCollectionViewCell : CBCollectionReusableView {
    
    public override func acceptsFirstMouse(theEvent: NSEvent?) -> Bool { return true }
    
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
//        self.wantsLayer = true
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public func setSelected(selected: Bool, animated: Bool = true) {
        self._selected = selected
    }
    
    public func setHighlighted(highlighted: Bool, animated: Bool) {
        self._highlighted = highlighted
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        self.setHighlighted(false, animated: false)
    }
    
    var _trackingArea : NSTrackingArea?
    public var trackMouseMoved : Bool = false { didSet { self.enableTracking() }}
    
    public override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        self.enableTracking()
    }
    
    public func disableTracking() {
        if let tArea = self._trackingArea {
            self.removeTrackingArea(tArea)
        }
    }
    public func enableTracking() {
        if let ta = self._trackingArea { self.removeTrackingArea(ta) }
        var opts = [NSTrackingAreaOptions.MouseEnteredAndExited, NSTrackingAreaOptions.ActiveInKeyWindow, .InVisibleRect]
        if trackMouseMoved {
            opts.append(.MouseMoved)
        }
        _trackingArea = NSTrackingArea(rect: self.bounds, options: NSTrackingAreaOptions(opts), owner: self, userInfo: nil)
        self.addTrackingArea(_trackingArea!)
    }
    
    override public func mouseEntered(theEvent: NSEvent) {
        super.mouseEntered(theEvent)
        if let view = self.window?.contentView?.hitTest(theEvent.locationInWindow) {
            if view.isDescendantOf(self) {
                self.setHighlighted(true, animated: true)
            }
        }
        
    }
    
    override public func mouseExited(theEvent: NSEvent) {
        super.mouseExited(theEvent)
        self.setHighlighted(false, animated: true)
    }
    
   
    
//    public override func mouseMoved(theEvent: NSEvent) {
//        super.mouseMoved(theEvent)
//        if self.highlighted == false {
//            self.setHighlighted(true, animated: false)
//        }
//    }
    
}
