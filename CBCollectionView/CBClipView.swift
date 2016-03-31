//
//  CBClipView.swift
//  CBCollectionView
//
//  Created by Wesley Byrne on 3/30/16.
//  Copyright © 2016 Noun Project. All rights reserved.
//

import Foundation
import AppKit

let CBClipViewDecelerationRate : CGFloat = 0.78
//typealias DisplayLinkCallback = @convention(block) ( CVDisplayLink!, UnsafePointer<CVTimeStamp>, UnsafePointer<CVTimeStamp>, CVOptionFlags, UnsafeMutablePointer<CVOptionFlags>, UnsafeMutablePointer<Void>)->Void

public typealias CBScrollCompletion = (finished: Bool)->Void

public class CBClipView : NSClipView {
    
    var shouldAnimateOriginChange = false
    var destinationOrigin = CGPointZero
    var scrollView : NSScrollView { return self.enclosingScrollView ?? self.superview as! NSScrollView }
    
    public var decelerationRate = CBClipViewDecelerationRate {
        didSet {
            if decelerationRate > 1 { self.decelerationRate = 1 }
            else if decelerationRate < 0 { self.decelerationRate = 0 }
        }
    }
    
    var completionBlock : CBScrollCompletion?
    
    var isCompatibleWithResponsiveScrolling : Bool { return true }
    
    init(clipView: NSClipView) {
        super.init(frame: clipView.frame)
        self.backgroundColor = clipView.backgroundColor
        self.drawsBackground = clipView.drawsBackground
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override public func viewWillMoveToWindow(newWindow: NSWindow?) {
        if (self.window != nil) {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: NSWindowDidChangeScreenNotification, object: self.window)
        }
        super.viewWillMoveToWindow(newWindow)
        
        if (newWindow != nil) {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateCVDisplay:", name: NSWindowDidChangeScreenNotification, object: newWindow)
        }
    }
    
    lazy var displayLink : CVDisplayLinkRef = {
        func linkCallback(displayLink: CVDisplayLink,
            _ inNow: UnsafePointer<CVTimeStamp>,
            _ inOutputTime: UnsafePointer<CVTimeStamp>,
            _ flagsIn: CVOptionFlags,
            _ flagsOut: UnsafeMutablePointer<CVOptionFlags>,
            _ displayLinkContext: UnsafeMutablePointer<Void>) -> CVReturn {
                unsafeBitCast(displayLinkContext, CBClipView.self).updateOrigin()
                return kCVReturnSuccess
        }
        
        var link : CVDisplayLinkRef?
        CVDisplayLinkCreateWithActiveCGDisplays(&link)
        CVDisplayLinkSetOutputCallback(link!, linkCallback, UnsafeMutablePointer<Void>(unsafeAddressOf(self)))
        return link!
    }()
    
    func updateCVDisplay(note: NSNotification) {
        if let screen = self.window?.screen {
            let screenDictionary = screen.deviceDescription
            let screenID = screenDictionary["NSScreenNumber"] as! NSNumber
            let displayID = screenID.unsignedIntValue
            CVDisplayLinkSetCurrentCGDisplay(displayLink, displayID)
        }
        else {
            CVDisplayLinkSetCurrentCGDisplay(displayLink, CGMainDisplayID())
        }
    }
    

    public func scrollRectToVisible(aRect: NSRect, animated: Bool) -> Bool {
        self.shouldAnimateOriginChange = animated
        return super.scrollRectToVisible(aRect)
    }
    
    public func scrollRectToVisible(rect: CGRect, animated: Bool, completion: CBScrollCompletion?) -> Bool {
        self.completionBlock = completion
        let success = self.scrollRectToVisible(rect, animated: animated)
        if !animated || !success {
            self.finishedScrolling(success)
        }
        return success
    }
    
    func finishedScrolling(success: Bool) {
        self.completionBlock?(finished: success)
        self.completionBlock = nil;
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
        
        // Calling -scrollToPoint: instead of manually adjusting the bounds lets us get the expected
        // overlay scroller behavior for free.
        super.scrollToPoint(o)
        
        // Make this call so that we can force an update of the scroller positions.
        self.scrollView.reflectScrolledClipView(self)
        
        NSNotificationCenter.defaultCenter().postNotificationName(NSScrollViewDidLiveScrollNotification, object: self, userInfo: nil)
        
        if ((fabs(o.x - lastOrigin.x) < 0.1 && fabs(o.y - lastOrigin.y) < 0.1)) {
            self.endScrolling()
            
            // Make sure we always finish out the animation with the actual coordinates
            self.scrollToPoint(o)
            self.finishedScrolling(true)
        }
    }
    
    func beginScrolling() {
        if CVDisplayLinkIsRunning(self.displayLink) { return }
        CVDisplayLinkStart(self.displayLink)
    }
    
    func endScrolling() {
        if !CVDisplayLinkIsRunning(self.displayLink) { return }
        CVDisplayLinkStop(self.displayLink)
    }
    
    
    
    
    
    
    
}