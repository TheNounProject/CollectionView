//
//  CBScrollView.swift
//  CBCollectionView
//
//  Created by Wesley Byrne on 9/1/16.
//  Copyright © 2016 Noun Project. All rights reserved.
//

import Foundation


public class CBScrollView : NSScrollView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.swapClipView()
    }
    public override var flipped : Bool { return true }
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.swapClipView()
    }
    public var clipView : CBClipView? {
        return self.contentView as? CBClipView
    }
    
    func swapClipView() {
        if self.contentView.isKindOfClass(CBClipView) { return }
        let docView = self.documentView
        let clipView = CBClipView(frame: self.contentView.frame)
        clipView.drawsBackground = self.drawsBackground
        self.contentView = clipView
        self.documentView = docView
    }
}

class FloatingSupplementaryView : NSView {
    override var flipped : Bool { return true }
    internal override func hitTest(aPoint: NSPoint) -> NSView? {
        for view in self.subviews {
            if view.frame.contains(aPoint){
                return super.hitTest(aPoint)
            }
        }
        return nil
    }
}