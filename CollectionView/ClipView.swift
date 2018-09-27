//
//  ClipView.swift
//  CollectionView
//
//  Created by Wesley Byrne on 3/30/16.
//  Copyright © 2016 Noun Project. All rights reserved.
//

//import Foundation
import AppKit

//typealias DisplayLinkCallback = @convention(block) ( CVDisplayLink!, UnsafePointer<CVTimeStamp>, UnsafePointer<CVTimeStamp>, CVOptionFlags, UnsafeMutablePointer<CVOptionFlags>, UnsafeMutablePointer<Void>)->Void

open class ClipView: NSClipView {
    
    static let DefaultDecelerationRate: CGFloat = 0.78
    
    var shouldAnimateOriginChange = false
    var destinationOrigin = CGPoint.zero
    var scrollView: NSScrollView? { return self.enclosingScrollView ?? self.superview as? NSScrollView }
    
    var scrollEnabled: Bool = true
    
    /**
     The rate of deceleration for animated scrolls. Higher is slower. default is 0.78
    */
    public var decelerationRate = DefaultDecelerationRate {
        didSet {
            if decelerationRate > 1 { self.decelerationRate = 1 }
            else if decelerationRate < 0 { self.decelerationRate = 0 }
        }
    }
    
    var completionBlock: AnimationCompletion?
    
    init(clipView: NSClipView) {
        super.init(frame: clipView.frame)
        self.backgroundColor = clipView.backgroundColor
        self.drawsBackground = clipView.drawsBackground
        self.setup()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setup()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    func setup() {
        self.wantsLayer = true
        
    }
    
    override open func viewWillMove(toWindow newWindow: NSWindow?) {
        if self.window != nil {
            NotificationCenter.default.removeObserver(self, name: NSWindow.didChangeScreenNotification,
                                                      object: self.window)
        }
        super.viewWillMove(toWindow: newWindow)
        if newWindow != nil {
            NotificationCenter.default.addObserver(self, selector: #selector(ClipView.updateCVDisplay(_:)),
                                                   name: NSWindow.didChangeScreenNotification,
                                                   object: newWindow)
        }
    }
    
//    open override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
//        var rect = proposedBounds
//        rect.origin.x = 50
//        return rect
//    }
    
    var _displayLink: CVDisplayLink?
    
    var displayLink: CVDisplayLink {
        if let link = _displayLink { return link }
        
        let linkCallback: CVDisplayLinkOutputCallback = {( displayLink, _, _, _, _, displayLinkContext) -> CVReturn in
            unsafeBitCast(displayLinkContext, to: ClipView.self).updateOrigin()
            return kCVReturnSuccess
        }
        var link: CVDisplayLink?
        CVDisplayLinkCreateWithActiveCGDisplays(&link)
        CVDisplayLinkSetOutputCallback(link!, linkCallback, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
        self._displayLink = link
        return link!
    }
    
    open override func mouseDown(with event: NSEvent) {
        self.cancelScrollAnimation()
        super.mouseDown(with: event)
    }
    
    @objc func updateCVDisplay(_ note: Notification) {
        
        guard self._displayLink != nil else { return }
        
        if let screen = self.window?.screen {
            let screenDictionary = screen.deviceDescription
            let screenID = screenDictionary[NSDeviceDescriptionKey("NSScreenNumber")] as! NSNumber
            let displayID = screenID.uint32Value
            CVDisplayLinkSetCurrentCGDisplay(displayLink, displayID)
        }
        else {
            CVDisplayLinkSetCurrentCGDisplay(displayLink, CGMainDisplayID())
        }
    }
    
    var manualScroll = false

    @discardableResult open func scrollRectToVisible(_ rect: CGRect, animated: Bool, completion: AnimationCompletion? = nil) -> Bool {
        
        manualScroll = false
        shouldAnimateOriginChange = animated
        if animated == false {
            
            // Calculate the point to scroll to to get make the rect visible
            var o = rect.origin
            o.y -= self.contentInsets.top
            self.scroll(to: o)
            completion?(true)
            return true
        }
        
        self.completionBlock = completion
        let success = super.scrollToVisible(rect)
        if !success {
            self.finishedScrolling(success)
        }
        return success
    }
    
    func finishedScrolling(_ success: Bool) {
        self.completionBlock?(success)
        self.completionBlock = nil
    }
    
    open override func scroll(to newOrigin: NSPoint) {
        if self.shouldAnimateOriginChange {
            self.shouldAnimateOriginChange = false
            if CVDisplayLinkIsRunning(self.displayLink) {
                self.destinationOrigin = newOrigin
                return
            }
            self.destinationOrigin = newOrigin
            self.beginScrolling()
        } else if self.scrollEnabled || manualScroll {
            // Otherwise, we stop any scrolling that is currently occurring (if needed) and let
            // super's implementation handle a normal scroll.
            
            super.scroll(to: newOrigin)
            self.cancelScrollAnimation()
            // Can't remember why this is here, it may be to cleanup if needed
//            if self._displayLink != nil && !manualScroll {
//                self.endScrolling()
//            }
        }
    }
    
    func cancelScrollAnimation() {
        self.destinationOrigin = self.bounds.origin
    }
    
    func updateOrigin() {
        
        var o = CGPoint.zero
        var integral = false
        var cancel = false
        DispatchQueue.main.sync {
            if self.window == nil {
                cancel = true
            }
            o = self.bounds.origin
            integral = self.window?.backingScaleFactor == 1
        }
        
        if cancel {
            self.endScrolling()
            return
        }
        
        let lastOrigin = o
        let deceleration = self.decelerationRate
        
        // Calculate the next origin on a basic ease-out curve.
        o.x = o.x * deceleration + self.destinationOrigin.x * (1 - self.decelerationRate)
        o.y = o.y * deceleration + self.destinationOrigin.y * (1 - self.decelerationRate)
        
        if integral {
            o = o.integral
        }
        
        // Calling -scrollToPoint: instead of manually adjusting the bounds lets us get the expected
        // overlay scroller behavior for free.
        DispatchQueue.main.async { 
            super.scroll(to: o)
            
            // Make this call so that we can force an update of the scroller positions.
            self.scrollView?.reflectScrolledClipView(self)
            NotificationCenter.default.post(name: NSScrollView.didLiveScrollNotification, object: self.scrollView)
        }
        
          //.postNotificationName(NSScrollViewDidLiveScrollNotification, object: self, userInfo: nil)
        
        if abs(o.x - lastOrigin.x) < 0.1 && abs(o.y - lastOrigin.y) < 0.1 {
            self.endScrolling()
            
            // Make sure we always finish out the animation with the actual coordinates
            DispatchQueue.main.async(execute: { 
                super.scroll(to: self.destinationOrigin)
                self.finishedScrolling(true)
                if let cv = self.scrollView as? CollectionView {
                    cv.delegate?.collectionViewDidEndScrolling?(cv, animated: true)
                }
            })
        }
    }
    
    func beginScrolling() {
        if CVDisplayLinkIsRunning(self.displayLink) { return }
        DispatchQueue.main.async {
            (self.scrollView as? CollectionView)?.isScrolling = true
        }
        CVDisplayLinkStart(self.displayLink)
    }
    
    func endScrolling() {
        manualScroll = false
        if !CVDisplayLinkIsRunning(self.displayLink) { return }
        DispatchQueue.main.async {
            (self.scrollView as? CollectionView)?.isScrolling = false
        }
        CVDisplayLinkStop(self.displayLink)
    }
    
}
