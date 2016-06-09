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
    
    internal var attributes : CBCollectionViewLayoutAttributes?
    
    public var backgroundColor: NSColor = NSColor.whiteColor() {
        didSet {
            self.layer?.backgroundColor = backgroundColor.CGColor
        }
    }
    
    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawPolicy.OnSetNeedsDisplay
    }
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawPolicy.OnSetNeedsDisplay
    }
    
    override public func prepareForReuse() {
        super.prepareForReuse()
    }
    
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
        
        return;
        if animated {
            
//            let animDict : [String:AnyObject] = [
//                NSViewAnimationTargetKey: self,
//                NSViewAnimationStartFrameKey : NSValue(rect: self.frame),
//                NSViewAnimationEndFrameKey : NSValue(rect: layoutAttributes.frame)
//            ]
//            
//            let anim = NSViewAnimation(duration: 1, animationCurve: NSAnimationCurve.EaseInOut)
//            anim.viewAnimations = [animDict]
//            anim.animationBlockingMode = NSAnimationBlockingMode.Nonblocking
//            
//            anim.startAnimation()
            
//            NSRunLoop
            
//            NSAnimationContext.beginGrouping()
//            NSAnimationContext.currentContext().duration = 1
//            self.animator().frame = layoutAttributes.frame
//            NSAnimationContext.endGrouping()
//            self.frame = layoutAttributes.frame
            
//            var fromPosition = self.frame.origin
//            var fromSize = self.bounds
            
//            if let pLayer = self.layer?.presentationLayer() as? CALayer {
//                fromPosition = pLayer.frame.origin
//                fromSize = pLayer.bounds
//            }
//            self.layer?.removeAnimationForKey("position")
//            let anim = CABasicAnimation(keyPath: "position")
//            anim.fromValue = NSValue(point: fromPosition)
//            anim.toValue = NSValue(point: layoutAttributes.frame.origin)
//            anim.duration = 1
//            self.layer?.addAnimation(anim, forKey: "position")
//            self.layer?.frame.origin = layoutAttributes.frame.origin
//            
//            self.layer?.removeAnimationForKey("bounds")
//            let sizeAnim = CABasicAnimation(keyPath: "bounds")
//            sizeAnim.fromValue = NSValue(rect: fromSize)
//            sizeAnim.toValue = NSValue(rect: layoutAttributes.bounds)
//            sizeAnim.duration = 1
//            self.layer?.addAnimation(sizeAnim, forKey: "bounds")
//            self.layer?.bounds = layoutAttributes.bounds
            

//
//            let sizeAnim = CABasicAnimation(keyPath: "size")
//            sizeAnim.toValue = NSValue(size: layoutAttributes.frame.size)
//            sizeAnim.duration = 1
//            self.layer?.addAnimation(sizeAnim, forKey: "size")
            
//            return;
            
            Swift.print("OLD: \(self.frame)  NEW: \(layoutAttributes.frame)")
            NSAnimationContext.runAnimationGroup({ (context) -> Void in
                context.duration = 1
                context.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
//                context.allowsImplicitAnimation = true
                self.animator().frame = layoutAttributes.frame
//                self.animator().alphaValue = layoutAttributes.alpha
//                self.layer?.zPosition = layoutAttributes.zIndex
//                self.animator().hidden = layoutAttributes.hidden
            }) { () -> Void in
                
            }
        }
        else {
            self.frame = layoutAttributes.frame
            self.alphaValue = layoutAttributes.alpha
            self.layer?.zPosition = layoutAttributes.zIndex
            self.hidden = layoutAttributes.hidden
        }
    }
    
    
    
}

// Will get to this later...
public class CBCollectionViewCell : CBCollectionReusableView {
    
    public override func acceptsFirstMouse(theEvent: NSEvent?) -> Bool { return true }
    
    private var wantsTracking = true
    
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
            self.collectionView?._indexPathForHighlightedItem = self.indexPath
        }
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        self.setHighlighted(false, animated: false)
    }
    
    var _trackingArea : NSTrackingArea?
    public var trackMouseMoved : Bool = false { didSet { self.updateTrackingAreas() }}
    
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
        var opts = [NSTrackingAreaOptions.MouseEnteredAndExited, NSTrackingAreaOptions.ActiveInKeyWindow, .InVisibleRect]
        if trackMouseMoved {
            opts.append(.MouseMoved)
        }
        _trackingArea = NSTrackingArea(rect: self.bounds, options: NSTrackingAreaOptions(opts), owner: self, userInfo: nil)
        self.addTrackingArea(_trackingArea!)
    }

    override public func mouseEntered(theEvent: NSEvent) {
        super.mouseEntered(theEvent)
        guard theEvent.type == NSEventType.MouseEntered && (theEvent.trackingArea?.owner as? CBCollectionViewCell) == self else { return }
        
        if let view = self.window?.contentView?.hitTest(theEvent.locationInWindow) {
            if view.isDescendantOf(self) {
                self.setHighlighted(true, animated: true)
            }
        }
    }
    
    override public func mouseExited(theEvent: NSEvent) {
        super.mouseExited(theEvent)
        guard theEvent.type == NSEventType.MouseExited && (theEvent.trackingArea?.owner as? CBCollectionViewCell) == self else { return }
        self.setHighlighted(false, animated: true)
    }
    
   
    
//    public override func mouseMoved(theEvent: NSEvent) {
//        super.mouseMoved(theEvent)
//        if self.highlighted == false {
//            self.setHighlighted(true, animated: false)
//        }
//    }
    
}
