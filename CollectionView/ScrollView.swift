//
//  ScrollView.swift
//  CollectionView
//
//  Created by Wesley Byrne on 9/1/16.
//  Copyright © 2016 Noun Project. All rights reserved.
//

import Foundation

open class ScrollView: NSScrollView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.swapClipView()
    }
    open override var isFlipped: Bool { return true }
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.swapClipView()
    }
    open var clipView: ClipView? {
        return self.contentView as? ClipView
    }
    
    func swapClipView() {
        if self.contentView.isKind(of: ClipView.self) { return }
        let docView = self.documentView
        let clipView = ClipView(frame: self.contentView.frame)
        clipView.drawsBackground = self.drawsBackground
        clipView.backgroundColor = self.backgroundColor
        self.contentView = clipView
        self.documentView = docView
    }
}

class FloatingSupplementaryView: NSView {
    override var isFlipped: Bool { return true }
    internal override func hitTest(_ aPoint: NSPoint) -> NSView? {
        for view in self.subviews where view.frame.contains(aPoint) {
            return super.hitTest(aPoint)
        }
        return nil
    }
}
