//
//  CBClipView.swift
//  CBCollectionView
//
//  Created by Wesley Byrne on 3/30/16.
//  Copyright © 2016 Noun Project. All rights reserved.
//

import Foundation
import AppKit
import QuartzCore
import Quartz

let CBClipViewDecelerationRate : CGFloat = 0.78
//typealias DisplayLinkCallback = @convention(block) ( CVDisplayLink!, UnsafePointer<CVTimeStamp>, UnsafePointer<CVTimeStamp>, CVOptionFlags, UnsafeMutablePointer<CVOptionFlags>, UnsafeMutablePointer<Void>)->Void

open class CBClipView : NSClipView {
    
    var shouldAnimateOriginChange = false
    var destinationOrigin = CGPoint.zero
    var scrollView : NSScrollView { return self.enclosingScrollView ?? self.superview as! NSScrollView }
    
    var scrollEnabled : Bool = true
    
    open var decelerationRate = CBClipViewDecelerationRate {
        didSet {
            if decelerationRate > 1 { self.decelerationRate = 1 }
            else if decelerationRate < 0 { self.decelerationRate = 0 }
        }
    }
    
    var completionBlock : CBAnimationCompletion?
    
    init(clipView: NSClipView) {
        super.init(frame: clipView.frame)
        self.backgroundColor = clipView.backgroundColor
        self.drawsBackground = clipView.drawsBackground
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsLayer = true
    }
    
    override open func viewWillMove(toWindow newWindow: NSWindow?) {
        if (self.window != nil) {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSWindowDidChangeScreen, object: self.window)
        }
        super.viewWillMove(toWindow: newWindow)
        if (newWindow != nil) {
            NotificationCenter.default.addObserver(self, selector: #selector(CBClipView.updateCVDisplay(_:)), name: NSNotification.Name.NSWindowDidChangeScreen, object: newWindow)
        }
    }
    
    lazy var displayLink : CVDisplayLink = {
        
        var linkCallback : CVDisplayLinkOutputCallback = {( displayLink, _, _, _, _, displayLinkContext) -> CVReturn in
            unsafeBitCast(displayLinkContext, to: CBClipView.self).updateOrigin()
            return kCVReturnSuccess
        }
        
        var link : CVDisplayLink?
        CVDisplayLinkCreateWithActiveCGDisplays(&link)
        CVDisplayLinkSetOutputCallback(link!, linkCallback, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
        return link!
    }()
    
    

    
    func updateCVDisplay(_ note: Notification) {
        if let screen = self.window?.screen {
            let screenDictionary = screen.deviceDescription
            let screenID = screenDictionary["NSScreenNumber"] as! NSNumber
            let displayID = screenID.uint32Value
            CVDisplayLinkSetCurrentCGDisplay(displayLink, displayID)
        }
        else {
            CVDisplayLinkSetCurrentCGDisplay(displayLink, CGMainDisplayID())
        }
    }
    
    var manualScroll = false
    open func scrollRectToVisible(_ aRect: NSRect, animated: Bool) -> Bool {
        manualScroll = true
        self.shouldAnimateOriginChange = animated
        return super.scrollToVisible(aRect)
    }
    
    open func scrollRectToVisible(_ rect: CGRect, animated: Bool, completion: CBAnimationCompletion?) -> Bool {
        manualScroll = true
        self.completionBlock = completion
        let success = self.scrollRectToVisible(rect, animated: animated)
        if !animated || !success {
            self.finishedScrolling(success)
        }
        return success
    }
    
    func finishedScrolling(_ success: Bool) {
        self.completionBlock?(success)
        self.completionBlock = nil;
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
            self.endScrolling()
            super.scroll(to: newOrigin)
        }
    }
    
    func updateOrigin() {
        if self.window == nil {
            self.endScrolling()
            return
        }
        
        var o = self.bounds.origin;
        let lastOrigin = o;
        let deceleration = self.decelerationRate;
        
        // Calculate the next origin on a basic ease-out curve.
        o.x = o.x * deceleration + self.destinationOrigin.x * (1 - self.decelerationRate);
        o.y = o.y * deceleration + self.destinationOrigin.y * (1 - self.decelerationRate);
        
        if self.window?.backingScaleFactor == 1 {
            o = o.integral
        }
        
        // Calling -scrollToPoint: instead of manually adjusting the bounds lets us get the expected
        // overlay scroller behavior for free.
        DispatchQueue.main.async { 
            super.scroll(to: o)
            
            if let cv = self.scrollView as? CBCollectionView {
                cv.delegate?.collectionViewDidScroll?(cv)
            }
            // Make this call so that we can force an update of the scroller positions.
            self.scrollView.reflectScrolledClipView(self)
        }
        
//        NSNotificationCenter.defaultCenter().postNotificationName(NSScrollViewDidLiveScrollNotification, object: self, userInfo: nil)
        
        if ((fabs(o.x - lastOrigin.x) < 0.1 && fabs(o.y - lastOrigin.y) < 0.1)) {
            self.endScrolling()
            
            // Make sure we always finish out the animation with the actual coordinates
            DispatchQueue.main.async(execute: { 
                self.scroll(to: o)
                self.finishedScrolling(true)
                if let cv = self.scrollView as? CBCollectionView {
                    cv.delegate?.collectionViewDidEndScrolling?(cv, animated: true)
                }
            })
        }
    }
    
    func beginScrolling() {
        if CVDisplayLinkIsRunning(self.displayLink) { return }
        (self.scrollView as? CBCollectionView)?.scrolling = true
        CVDisplayLinkStart(self.displayLink)
    }
    
    func endScrolling() {
        manualScroll = false
        if !CVDisplayLinkIsRunning(self.displayLink) { return }
        (self.scrollView as? CBCollectionView)?.scrolling = false
        CVDisplayLinkStop(self.displayLink)
    }
    
    
    
    
    
    
    
}
