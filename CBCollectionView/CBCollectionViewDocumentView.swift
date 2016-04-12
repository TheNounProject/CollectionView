
//
//  CBCollectionViewDocumentView.swift
//  Lingo
//
//  Created by Wesley Byrne on 3/30/16.
//  Copyright © 2016 The Noun Project. All rights reserved.
//

import Foundation


public class CBCollectionViewDocumentView : NSView {

    public override var flipped : Bool { return true }
//    var isCompatibleWithResponsiveScrolling : Bool { return true }
    
    var collectionView : CBCollectionView! {
        return self.superview!.superview as! CBCollectionView
    }
    
//    public override func prepareContentInRect(rect: NSRect) {
//        let _rect = self.prepareRect(rect, remove: true)
//        super.prepareContentInRect(_rect)
//    }
    
    var preparedRect = CGRectZero
    var preparedCellIndex : [NSIndexPath:CBCollectionViewCell] = [:]
    var preparedSupplementaryViewIndex : [SupplementaryViewIdentifier:CBCollectionReusableView] = [:]
    
    public override func layout() {
        super.layout()
    }
    
    func reset() {
        for cell in preparedCellIndex {
            cell.1.hidden = true
            cell.1._indexPath = nil
            cell.1.removeFromSuperview()
            self.collectionView.enqueueCellForReuse(cell.1)
            self.collectionView.delegate?.collectionView?(self.collectionView, didEndDisplayingCell: cell.1, forItemAtIndexPath: cell.0)
        }
        preparedCellIndex.removeAll()
        for view in preparedSupplementaryViewIndex {
            view.1.hidden = true
            view.1._indexPath = nil
            view.1.removeFromSuperviewWithoutNeedingDisplay()
            let id = view.0
            self.collectionView.enqueueSupplementaryViewForReuse(view.1, withIdentifier: id)
            self.collectionView.delegate?.collectionView?(self.collectionView, didEndDisplayingSupplementaryView: view.1, forElementOfKind: id.kind, atIndexPath: id.indexPath!)
        }
        preparedSupplementaryViewIndex.removeAll()
        self.preparedRect = CGRectZero
    }
    
    
    func relayout(animated: Bool) {
        
        
        
    }
    
    func prepareRect(rect: CGRect, force: Bool = false) {
        
        let _rect = CGRectIntersection(rect, CGRect(origin: CGPointZero, size: self.frame.size))
        
        if !force && !CGRectIsEmpty(self.preparedRect) && self.preparedRect.contains(_rect) {
            
            for id in self.preparedSupplementaryViewIndex {
                let view = id.1
                guard let ip = id.0.indexPath, let attrs = self.collectionView.layoutAttributesForSupplementaryElementOfKind(id.0.kind, atIndexPath: ip) else { continue }
                if attrs.floating == true {
                    if view.superview != self.collectionView._floatingSupplementaryView {
                        view.removeFromSuperview()
                        self.collectionView._floatingSupplementaryView.addSubview(view)
                    }
                    attrs.frame = self.collectionView._floatingSupplementaryView.convertRect(attrs.frame, fromView: self)
                }
                else if view.superview == self.collectionView._floatingSupplementaryView {
                    view.removeFromSuperview()
                    self.collectionView.contentDocumentView.addSubview(view)
                }
                self._applyLayoutAttributes(attrs, toItem: view, animated: false)
            }
//            Swift.print("Not laying out because we're good!")
            return
        }
        
        var date = NSDate()
        let previousPrepared = self.preparedRect

        let sRect = self.layoutSupplementaryViewsInRect(_rect, forceAll: force)
        let iRect = self.layoutItemsInRect(_rect, forceAll: force)
        
        var newRect = sRect.union(iRect)
        if !self.preparedRect.isEmpty {
            newRect.unionInPlace(self.preparedRect)
        }
        self.preparedRect = newRect
        Swift.print("Prepared rect: \(CGRectGetMinY(_rect)) - \(CGRectGetMaxY(_rect))  old: \(CGRectGetMinY(previousPrepared)) - \(CGRectGetMaxY(previousPrepared))   New: \(CGRectGetMinY(preparedRect)) - \(CGRectGetMaxY(preparedRect)) :: \(date.timeIntervalSinceNow)  :: Subviews:  \(self.subviews.count)")
    }
    
    func layoutItemsInRect(rect: CGRect, animated: Bool = false, forceAll: Bool = false) -> CGRect {
        
        var _rect = rect
        
        let oldIPs = Set(self.preparedCellIndex.keys)
        var inserted = self.collectionView.indexPathsForItemsInRect(rect)
        let removed = oldIPs.setByRemovingSubset(inserted)
        let updated = inserted.removeAllInSet(oldIPs)
        
//        Swift.print("insert: \(inserted.count)   removed: \(removed.count)    updated: \(updated.count)")
        
        var removedRect = CGRectZero
        for ip in removed {
            if let cell = self.collectionView.cellForItemAtIndexPath(ip) {
                if removedRect.isEmpty { removedRect = cell.frame }
                else { removedRect.unionInPlace(cell.frame) }
                
                self.preparedCellIndex[ip] = nil
                if animated {
                    NSAnimationContext.runAnimationGroup({ (context) -> Void in
                        context.duration = 0.5
                        context.allowsImplicitAnimation = true
                        cell.hidden = true
                        }) { () -> Void in
                            cell._indexPath = nil
                            self.collectionView.enqueueCellForReuse(cell)
                            self.collectionView.delegate?.collectionView?(self.collectionView, didEndDisplayingCell: cell, forItemAtIndexPath: ip)
                    }
                }
                else {
                    cell.hidden = true
                    cell._indexPath = nil
                    self.collectionView.enqueueCellForReuse(cell)
                    self.collectionView.delegate?.collectionView?(self.collectionView, didEndDisplayingCell: cell, forItemAtIndexPath: ip)
                }
            }
        }
        
        if  !removedRect.isEmpty {
            if self.collectionView.collectionViewLayout.scrollDirection == .Vertical {
                let edge = self.visibleRect.origin.y > removedRect.origin.y ? CGRectEdge.MinYEdge : CGRectEdge.MaxYEdge
                self.preparedRect = CGRectSubtract(self.preparedRect, rect2: removedRect, edge: edge)
            }
            else {
                
            }
        }
        
        for ip in inserted {
            guard let attrs = self.collectionView.collectionViewLayout.layoutAttributesForItemAtIndexPath(ip) else { continue }
            guard let cell = preparedCellIndex[ip] ?? self.collectionView.dataSource?.collectionView(self.collectionView, cellForItemAtIndexPath: ip) else {
                "For some reason collection view tried to load cells without a data source"
                continue
            }
            cell._indexPath = ip
            _rect = CGRectUnion(_rect, CGRectInset(attrs.frame, -1, -1))
            
            self.collectionView.delegate?.collectionView?(self.collectionView, willDisplayCell: cell, forItemAtIndexPath: ip)
            if cell.superview == nil {
                self.addSubview(cell)
            }
            if animated {
                self._applyLayoutAttributes(attrs, toItem: cell, animated: false)
                cell.hidden = true
                cell.frame = attrs.frame
            }
            self._applyLayoutAttributes(attrs, toItem: cell, animated: animated)
            cell.setSelected(self.collectionView.itemAtIndexPathIsSelected(cell._indexPath!), animated: false)
            self.preparedCellIndex[ip] = cell
        }
        if forceAll {
            for ip in updated {
                if let attrs = self.collectionView.collectionViewLayout.layoutAttributesForItemAtIndexPath(ip) {
                    let cell = preparedCellIndex[ip]
                    cell?._indexPath = ip
                    _rect = CGRectUnion(_rect, attrs.frame)
                    self._applyLayoutAttributes(attrs, toItem: cell, animated: animated)
                    cell?.selected = self.collectionView.itemAtIndexPathIsSelected(ip)
                }
            }
        }
        return _rect
    }
    
    
    func layoutSupplementaryViewsInRect(rect: CGRect, animated: Bool = false, forceAll: Bool = false) -> CGRect {
        
        var _rect = rect
        
        let oldIdentifiers = Set(self.preparedSupplementaryViewIndex.keys)
        var inserted = self.collectionView._identifiersForSupplementaryViewsInRect(rect)
        let removed = oldIdentifiers.setByRemovingSubset(inserted)
        let updated = inserted.removeAllInSet(oldIdentifiers)
        
        var removedRect = CGRectZero
        for identifier in removed {
            if let view = self.preparedSupplementaryViewIndex[identifier] {
                if let attrs = view.attributes where !attrs.floating {
                    if removedRect.isEmpty { removedRect = attrs.frame }
                    else { removedRect.unionInPlace(attrs.frame) }
                }
                self.preparedSupplementaryViewIndex[identifier] = nil
                if animated {
                    NSAnimationContext.runAnimationGroup({ (context) -> Void in
                        context.duration = 0.5
                        context.allowsImplicitAnimation = true
                        view.hidden = true
                        }) { () -> Void in
                            view._indexPath = nil
                            self.collectionView.delegate?.collectionView?(self.collectionView, didEndDisplayingSupplementaryView: view, forElementOfKind: identifier.kind, atIndexPath: identifier.indexPath!)
                            self.collectionView.enqueueSupplementaryViewForReuse(view, withIdentifier: identifier)
                    }
                }
                else {
                    view.hidden = true
                    view._indexPath = nil
                    self.collectionView.delegate?.collectionView?(self.collectionView, didEndDisplayingSupplementaryView: view, forElementOfKind: identifier.kind, atIndexPath: identifier.indexPath!)
                    self.collectionView.enqueueSupplementaryViewForReuse(view, withIdentifier: identifier)
                }
            }
        }
        
        if  !removedRect.isEmpty {
            if self.collectionView.collectionViewLayout.scrollDirection == .Vertical {
                let edge = self.visibleRect.origin.y > removedRect.origin.y ? CGRectEdge.MinYEdge : CGRectEdge.MaxYEdge
                self.preparedRect = CGRectSubtract(self.preparedRect, rect2: removedRect, edge: edge)
            }
            else {
                
            }
        }
        
        
        for identifier in inserted {
            
            if let view = self.collectionView.dataSource?.collectionView?(self.collectionView, viewForSupplementaryElementOfKind: identifier.kind, forIndexPath: identifier.indexPath!) {
                
                guard let attrs = self.collectionView.collectionViewLayout.layoutAttributesForSupplementaryViewOfKind(identifier.kind, atIndexPath: identifier.indexPath!)
                    else { continue }
                _rect = CGRectUnion(_rect, attrs.frame)
                view._indexPath = identifier.indexPath
                
                self.collectionView.delegate?.collectionView?(self.collectionView, willDisplaySupplementaryView: view, forElementKind: identifier.kind, atIndexPath: identifier.indexPath!)
                if view.superview == nil {
                    if attrs.floating == true {
                        self.collectionView._floatingSupplementaryView.addSubview(view)
                    }
                    else {
                        self.addSubview(view)
                        
                    }
                }
                if view.superview == self.collectionView._floatingSupplementaryView{
                    attrs.frame = self.collectionView._floatingSupplementaryView.convertRect(attrs.frame, fromView: self)
                }
                if animated {
                    view.hidden = true
                    view.frame = attrs.frame
                }
//                if !attrs.floating {
//                    _rect.unionInPlace(attrs.frame)
//                }
                self._applyLayoutAttributes(attrs, toItem: view, animated: animated)
                self.preparedSupplementaryViewIndex[identifier] = view
            }
        }
        
        for id in updated {
            if let cell = preparedSupplementaryViewIndex[id],
                let attrs = self.collectionView.collectionViewLayout.layoutAttributesForSupplementaryViewOfKind(id.kind, atIndexPath: id.indexPath!) {
                _rect = CGRectUnion(_rect, attrs.frame)
                
                if attrs.floating == true {
                    if cell.superview != self.collectionView._floatingSupplementaryView {
                        cell.removeFromSuperview()
                        self.collectionView._floatingSupplementaryView.addSubview(cell)
                    }
                    attrs.frame = self.collectionView._floatingSupplementaryView.convertRect(attrs.frame, fromView: self)
                }
                else if cell.superview == self.collectionView._floatingSupplementaryView {
                    cell.removeFromSuperview()
                    self.collectionView.contentDocumentView.addSubview(cell)
                }
                
//                if !attrs.floating {
//                _rect.unionInPlace(attrs.frame)
//                }
                self._applyLayoutAttributes(attrs, toItem: cell, animated: animated)
            }
        }
        return _rect
    }
    
    
    private func _applyLayoutAttributes(attributes: CBCollectionViewLayoutAttributes?, toItem : CBCollectionReusableView?, animated: Bool) {
        
        if toItem == nil || attributes == nil { return }
        
        if attributes?.floating == false && animated {
            NSAnimationContext.runAnimationGroup({ (context) -> Void in
                context.duration = 0.5
                context.allowsImplicitAnimation = true
                toItem?.applyLayoutAttributes(attributes!, animated: true)
                }) { () -> Void in
                    
            }
        }
        else {
            toItem!.applyLayoutAttributes(attributes!, animated: false)
        }
        
    }

    
}