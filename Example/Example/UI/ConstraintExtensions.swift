//
//  ConstraintExtensions.swift
//  Lingo
//
//  Created by Wesley Byrne on 1/12/17.
//  Copyright © 2017 The Noun Project. All rights reserved.
//

import Foundation
import AppKit

public extension NSView {
    
    /**
     Add NSLayoutContraints to the reciever to match it'parent optionally provided insets for each side. If the view does not have a superview, no constraints are added.
     
     - parameter insets: Insets to apply to the constraints for Top, Right, Bottom, and Left.
     - returns: The Top, Right, Bottom, and Top constraint added to the view.
     */
    @discardableResult func addConstraintsToMatchParent(_ insets: NSEdgeInsets? = nil) -> (top: NSLayoutConstraint, right: NSLayoutConstraint, bottom: NSLayoutConstraint, left: NSLayoutConstraint)? {
        if let sv = self.superview {
            let top = NSLayoutConstraint(item: sv, attribute: .top, relatedBy: .equal,
                                         toItem: self, attribute: .top, multiplier: 1,
                                         constant: insets == nil ? 0 : -insets!.top)
            let right = NSLayoutConstraint(item: sv, attribute: .right, relatedBy: .equal,
                                           toItem: self, attribute: .right, multiplier: 1,
                                           constant: insets?.right ?? 0)
            let bottom = NSLayoutConstraint(item: sv, attribute: .bottom, relatedBy: .equal,
                                            toItem: self, attribute: .bottom, multiplier: 1,
                                            constant: insets?.bottom ?? 0)
            let left = NSLayoutConstraint(item: sv, attribute: .left, relatedBy: .equal,
                                          toItem: self, attribute: .left, multiplier: 1,
                                          constant: insets == nil ? 0 : -insets!.left)
            sv.addConstraints([top, bottom, right, left])
            self.translatesAutoresizingMaskIntoConstraints = false
            return (top, right, bottom, left)
        }
        else {
            debugPrint("Toolkit Warning: Attempt to add contraints to match parent but the view had not superview.")
        }
        return nil
    }
    
    typealias ParentConstraints = (left: NSLayoutConstraint?, top: NSLayoutConstraint?, right: NSLayoutConstraint?, bottom: NSLayoutConstraint?)
    func addConstraintsToParent(_ left: CGFloat? = nil, top: CGFloat? = nil, right: CGFloat? = nil, bottom: CGFloat? = nil) -> ParentConstraints {
        
        var response: ParentConstraints = (nil, nil, nil, nil)
        
        guard let sv = self.superview else {
            debugPrint("Toolkit Warning: Attempt to add contraints to match parent but the view had not superview.")
            return response
        }
        
        if let t = top {
            let c = NSLayoutConstraint(item: sv, attribute: .top, relatedBy: .equal,
                                       toItem: self, attribute: .top, multiplier: 1, constant: -t)
            sv.addConstraint(c)
            response.top = c
        }
        if let b = bottom {
            let c = NSLayoutConstraint(item: sv, attribute: .bottom, relatedBy: .equal,
                                       toItem: self, attribute: .bottom, multiplier: 1, constant: b)
            sv.addConstraint(c)
            response.bottom = c
        }
        if let r = right {
            let c = NSLayoutConstraint(item: sv, attribute: .right, relatedBy: .equal,
                                       toItem: self, attribute: .right, multiplier: 1, constant: r)
            sv.addConstraint(c)
            response.right = c
        }
        if let l = left {
            let c = NSLayoutConstraint(item: sv, attribute: .left, relatedBy: .equal,
                                       toItem: self, attribute: .left, multiplier: 1, constant: -l)
            sv.addConstraint(c)
            response.left = c
        }
        self.translatesAutoresizingMaskIntoConstraints = false
        return response
    }
    
    func addConstraintsToVerticalCenter(_ offset: CGFloat, left: CGFloat? = nil, right: CGFloat? = nil) {
        if let sv = self.superview {
            let centerY = NSLayoutConstraint(item: sv, attribute: .centerY, relatedBy: .equal,
                                             toItem: self, attribute: .centerY, multiplier: 1, constant: offset)
            sv.addConstraint(centerY)
            
            if let r = right {
                let rightConstraint = NSLayoutConstraint(item: sv, attribute: .right, relatedBy: .equal,
                                                         toItem: self, attribute: .right, multiplier: 1, constant: r)
                sv.addConstraint(rightConstraint)
            }
            if let l = left {
                let leftConstraint = NSLayoutConstraint(item: sv, attribute: .left, relatedBy: .equal,
                                                        toItem: self, attribute: .left, multiplier: 1, constant: -l)
                sv.addConstraint(leftConstraint)
            }
            self.translatesAutoresizingMaskIntoConstraints = false
        }
        else {
            debugPrint("Toolkit Warning: Attempt to add contraints to match parent but the view had not superview.")
        }
    }
    
    @discardableResult func addCenterConstraints(_ horizontalOffset: CGFloat = 0, verticalOffset: CGFloat = 0) -> (horizontal: NSLayoutConstraint, vertical: NSLayoutConstraint)? {
        if let sv = self.superview {
            let centerY = NSLayoutConstraint(item: sv, attribute: .centerY, relatedBy: .equal,
                                             toItem: self, attribute: .centerY, multiplier: 1, constant: verticalOffset)
            let centerX = NSLayoutConstraint(item: sv, attribute: .centerX, relatedBy: .equal,
                                             toItem: self, attribute: .centerX, multiplier: 1, constant: horizontalOffset)
            
            sv.addConstraints([centerY, centerX])
            self.translatesAutoresizingMaskIntoConstraints = false
            return (centerX, centerX)
        }
        else {
            debugPrint("Toolkit Warning: Attempt to add contraints to match parent but the view had not superview.")
            return nil
        }
    }
    
    @discardableResult func addSizeConstraints(_ size: NSSize) -> (width: NSLayoutConstraint?, height: NSLayoutConstraint?) {
        var width: NSLayoutConstraint?
        var height: NSLayoutConstraint?
        
        if size.width > 0 {
            width = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal,
                                       toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: size.width)
            self.addConstraint(width!)
        }
        if size.height > 0 {
            height = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal,
                                        toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: size.height)
            self.addConstraint(height!)
        }
        return (width, height)
    }
}
