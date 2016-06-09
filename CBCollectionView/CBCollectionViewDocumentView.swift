
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
    
    weak var collectionView : CBCollectionView! {
        return self.superview!.superview as! CBCollectionView
    }
    
//    public override func prepareContentInRect(rect: NSRect) {
//        let _rect = self.prepareRect(rect, remove: true)
//        super.prepareContentInRect(_rect)
//    }
    
    struct ItemUpdate {
        let view : CBCollectionReusableView!
        let attrs : CBCollectionViewLayoutAttributes!
        var identifier : SupplementaryViewIdentifier?
        var removal : Bool = false
        init(view: CBCollectionReusableView, attrs: CBCollectionViewLayoutAttributes, removal: Bool = false, identifier: SupplementaryViewIdentifier? = nil) {
            self.view = view
            self.attrs = attrs
            self.identifier = identifier
            self.removal = removal
        }
    }
    
    
    var preparedRect = CGRectZero
    var preparedCellIndex : [NSIndexPath:CBCollectionViewCell] = [:]
    var preparedSupplementaryViewIndex : [SupplementaryViewIdentifier:CBCollectionReusableView] = [:]
    
    public override func layout() {
        super.layout()
    }
    
    func reset() {
        for cell in preparedCellIndex {
            cell.1.removeFromSuperview()
            self.collectionView.enqueueCellForReuse(cell.1)
            self.collectionView.delegate?.collectionView?(self.collectionView, didEndDisplayingCell: cell.1, forItemAtIndexPath: cell.0)
        }
        preparedCellIndex.removeAll()
        for view in preparedSupplementaryViewIndex {
            view.1.removeFromSuperview()
            let id = view.0
            self.collectionView.enqueueSupplementaryViewForReuse(view.1, withIdentifier: id)
            self.collectionView.delegate?.collectionView?(self.collectionView, didEndDisplayingSupplementaryView: view.1, forElementOfKind: id.kind, atIndexPath: id.indexPath!)
        }
        preparedSupplementaryViewIndex.removeAll()
        self.preparedRect = CGRectZero
    }
    
    
//    var ignoreRemoves = false
    
    func relayout(animated: Bool) {
        
        
    }
    
    
    
    func prepareRect(rect: CGRect, animated: Bool = false, force: Bool = false) {
        
        let _rect = CGRectIntersection(rect, CGRect(origin: CGPointZero, size: self.frame.size))
        
        if rect.size.height > 5000 {
            Swift.print("GIANT")
        }
        
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
                    view.applyLayoutAttributes(attrs, animated: false)
                }
                else if view.superview == self.collectionView._floatingSupplementaryView {
                    view.removeFromSuperview()
                    self.collectionView.contentDocumentView.addSubview(view)
                    view.applyLayoutAttributes(attrs, animated: false)
                }
            }
            return
        }
        
        var date = NSDate()
        let previousPrepared = self.preparedRect
        
        let supps = self.layoutSupplementaryViewsInRect(_rect, animated: animated, forceAll: force)
        let items = self.layoutItemsInRect(_rect, animated: animated, forceAll: force)
        let sRect = supps.rect
        let iRect = items.rect
        
        var newRect = sRect.union(iRect)
        if !self.preparedRect.isEmpty {
            newRect.unionInPlace(self.preparedRect)
        }
        self.preparedRect = newRect
        
        var updates = supps.updates
        updates.appendContentsOf(items.updates)
        self.applyUpdates(updates, animated: animated)
        
        Swift.print("Prepared rect: \(CGRectGetMinY(_rect)) - \(CGRectGetMaxY(_rect))  old: \(CGRectGetMinY(previousPrepared)) - \(CGRectGetMaxY(previousPrepared))   New: \(CGRectGetMinY(preparedRect)) - \(CGRectGetMaxY(preparedRect)) :: Subviews:  \(self.subviews.count) :: \(date.timeIntervalSinceNow)")
//        self.ignoreRemoves = false
    }
    
    
    func layoutItemsInRect(rect: CGRect, animated: Bool = false, forceAll: Bool = false) -> (rect: CGRect, updates: [ItemUpdate]) {
        var _rect = rect
        
//        var date = NSDate()
//        var prepTime : NSTimeInterval = 0
//        var removeTime : NSTimeInterval = 0
//        var insertTime : NSTimeInterval = 0
//        var updateTime : NSTimeInterval = 0
        
        var updates = [ItemUpdate]()
        
        let oldIPs = Set(self.preparedCellIndex.keys)
        var inserted = self.collectionView.indexPathsForItemsInRect(rect)
        let removed = oldIPs.setByRemovingSubset(inserted)
        let updated = inserted.removeAllInSet(oldIPs)
        
//        prepTime = date.timeIntervalSinceNow
//        date = NSDate()
        
//        var removals = [ItemUpdate]()
            var removedRect = CGRectZero
            for ip in removed {
                if let cell = self.collectionView.cellForItemAtIndexPath(ip) {
                    if removedRect.isEmpty { removedRect = cell.frame }
                    else { removedRect.unionInPlace(cell.frame) }
                    
                    self.preparedCellIndex[ip] = nil
                    cell.layer?.zPosition = -100
                    if animated  && !animating, let attrs =  self.collectionView.layoutAttributesForItemAtIndexPath(ip) {
                        updates.append(ItemUpdate(view: cell, attrs: attrs, removal: true))
                    
//                        let mDelay = dispatch_time(DISPATCH_TIME_NOW, Int64(0.001 * Double(NSEC_PER_SEC)))
//                        dispatch_after(mDelay, dispatch_get_main_queue(), {
//                            NSAnimationContext.runAnimationGroup({ (context) -> Void in
//                                context.duration = 0.4
//                                if let f = attrs?.frame {
//                                    cell.animator().frame = f
//                                }
//                            }) { () -> Void in
//                                self.collectionView.enqueueCellForReuse(cell)
//                                self.collectionView.delegate?.collectionView?(self.collectionView, didEndDisplayingCell: cell, forItemAtIndexPath: ip)
//                            }
//                        })
                    }
                    else {
                        self.collectionView.enqueueCellForReuse(cell)
                        self.collectionView.delegate?.collectionView?(self.collectionView, didEndDisplayingCell: cell, forItemAtIndexPath: ip)
                    }
                }
        }
//        self.animateRemovedItems(removals)
        
        if !removedRect.isEmpty {
            if self.collectionView.collectionViewLayout.scrollDirection == .Vertical {
                    let edge = self.visibleRect.origin.y > removedRect.origin.y ? CGRectEdge.MinYEdge : CGRectEdge.MaxYEdge
                    self.preparedRect = CGRectSubtract(self.preparedRect, rect2: removedRect, edge: edge)
                }
                else {
                    
                }
            }
        
//        removeTime = date.timeIntervalSinceNow
//        date = NSDate()
        
        for ip in inserted {
            guard let attrs = self.collectionView.collectionViewLayout.layoutAttributesForItemAtIndexPath(ip) else { continue }
            guard let cell = preparedCellIndex[ip] ?? self.collectionView.dataSource?.collectionView(self.collectionView, cellForItemAtIndexPath: ip) else {
                "For some reason collection view tried to load cells without a data source"
                continue
            }
            assert(cell.collectionView != nil, "Attemp to load cell without using deque")
            
            cell.indexPath = ip
            _rect = CGRectUnion(_rect, CGRectInset(attrs.frame, -1, -1) )
            
            self.collectionView.delegate?.collectionView?(self.collectionView, willDisplayCell: cell, forItemAtIndexPath: ip)
            if cell.superview == nil {
                self.addSubview(cell)
            }
            if animated {
                cell.applyLayoutAttributes(attrs, animated: false)
                cell.hidden = true
                cell.alphaValue = 0
            }
            updates.append(ItemUpdate(view: cell, attrs: attrs))
            cell.setSelected(self.collectionView.itemAtIndexPathIsSelected(cell.indexPath!), animated: false)
            self.preparedCellIndex[ip] = cell
        }
        
//        insertTime = date.timeIntervalSinceNow
//        date = NSDate()
        
        if forceAll {
            for ip in updated {
                if let attrs = self.collectionView.collectionViewLayout.layoutAttributesForItemAtIndexPath(ip),
                let cell = preparedCellIndex[ip] {
                    _rect = CGRectUnion(_rect, attrs.frame)
                    updates.append(ItemUpdate(view: cell, attrs: attrs))
                    cell.selected = self.collectionView.itemAtIndexPathIsSelected(ip)
                }
            }
        }

        
//        updateTime = date.timeIntervalSinceNow
//        Swift.print("prep: \(prepTime ) removed: \(removed.count) in \(removeTime)   inserted: \(inserted.count) in \(insertTime)    updated: \(updated.count) in \(updateTime)")
        
        return (_rect, updates)
    }
    
    
    func layoutSupplementaryViewsInRect(rect: CGRect, animated: Bool = false, forceAll: Bool = false) -> (rect: CGRect, updates: [ItemUpdate]) {
        var _rect = rect
        
        var updates = [ItemUpdate]()
        
        let oldIdentifiers = Set(self.preparedSupplementaryViewIndex.keys)
        var inserted = self.collectionView._identifiersForSupplementaryViewsInRect(rect)
        let removed = oldIdentifiers.setByRemovingSubset(inserted)
        let updated = inserted.removeAllInSet(oldIdentifiers)
        
//        var removals = [ItemUpdate]()
            for identifier in removed {
                if let view = self.preparedSupplementaryViewIndex[identifier] {
                    self.preparedSupplementaryViewIndex[identifier] = nil
                    view.layer?.zPosition = -100
                    
                    if animated && !animating, let attrs = self.collectionView.collectionViewLayout.layoutAttributesForSupplementaryViewOfKind(identifier.kind, atIndexPath: identifier.indexPath!) {
                        updates.append(ItemUpdate(view: view, attrs: attrs, removal: true, identifier: identifier))
                    }
                    else {
                        self.collectionView.delegate?.collectionView?(self.collectionView, didEndDisplayingSupplementaryView: view, forElementOfKind: identifier.kind, atIndexPath: identifier.indexPath!)
                        self.collectionView.enqueueSupplementaryViewForReuse(view, withIdentifier: identifier)
                    }
                }
        }
//        self.animateRemovedItems(removals)
        
        
        for identifier in inserted {
            
            if let view = self.preparedSupplementaryViewIndex[identifier] ?? self.collectionView.dataSource?.collectionView?(self.collectionView, viewForSupplementaryElementOfKind: identifier.kind, forIndexPath: identifier.indexPath!) {
                
                assert(view.collectionView != nil, "Attempt to insert a view without using deque:")
                
                guard let attrs = self.collectionView.collectionViewLayout.layoutAttributesForSupplementaryViewOfKind(identifier.kind, atIndexPath: identifier.indexPath!)
                    else { continue }
                _rect = CGRectUnion(_rect, attrs.frame)
                
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
                updates.append(ItemUpdate(view: view, attrs: attrs))
//                self._applyLayoutAttributes(attrs, toItem: view, animated: animated)
                self.preparedSupplementaryViewIndex[identifier] = view
            }
        }
        
        for id in updated {
            if let view = preparedSupplementaryViewIndex[id],
                let attrs = self.collectionView.collectionViewLayout.layoutAttributesForSupplementaryViewOfKind(id.kind, atIndexPath: id.indexPath!) {
                _rect = CGRectUnion(_rect, attrs.frame)
                
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
                
                updates.append(ItemUpdate(view: view, attrs: attrs))
//                updates[view] = attrs
//                self._applyLayoutAttributes(attrs, toItem: cell, animated: animated)
            }
        }
        
        
//        if animated && !animating {
//            let mDelay = dispatch_time(DISPATCH_TIME_NOW, Int64(0.001 * Double(NSEC_PER_SEC)))
//            dispatch_after(mDelay, dispatch_get_main_queue(), {
//                NSAnimationContext.runAnimationGroup({ (context) -> Void in
//                    context.duration = 0.4
//                    context.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
//                    //                    context.allowsImplicitAnimation = true
//                    for item in updates {
//                        item.0.applyLayoutAttributes(item.1, animated: true)
//                    }
//                    //                self.animator().frame = layoutAttributes.frame
//                    //                self.animator().alphaValue = layoutAttributes.alpha
//                    //                self.layer?.zPosition = layoutAttributes.zIndex
//                    //                self.animator().hidden = layoutAttributes.hidden
//                }) { () -> Void in
//                    
//                }
//            })
//        }
//        else {
//            for item in updates {
//                item.0.applyLayoutAttributes(item.1, animated: false)
//            }
//        }
        
        
        return (_rect, updates)
    }
    
    var animating = false
    var disableAnimationTimer : NSTimer?
    func applyUpdates(updates: [ItemUpdate], animated: Bool) {
        
        if animated && !animating {
            let mDelay = dispatch_time(DISPATCH_TIME_NOW, Int64(0.01 * Double(NSEC_PER_SEC)))
            self.animating = true
            dispatch_after(mDelay, dispatch_get_main_queue(), {
                var removals = [ItemUpdate]()
                NSAnimationContext.runAnimationGroup({ (context) -> Void in
                    context.duration = 0.4
                    context.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
                    //                    context.allowsImplicitAnimation = true
                    for item in updates {
                        if item.removal {
                            removals.append(item)
                            item.attrs.alpha = 0
                        }
                        item.view.applyLayoutAttributes(item.attrs, animated: true)
                    }
                }) { () -> Void in
                    if self.disableAnimationTimer == nil {
                        self.animating = false
                    }
                    self.finishRemovals(removals)
                }
            })
        }
        else {
            if animated {
                disableAnimationTimer?.invalidate()
                disableAnimationTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(enableAnimations), userInfo: nil, repeats: false)
                animating = true
            }
            for item in updates {
                if item.removal {
                    removeItem(item)
                }
                else {
                    item.view.applyLayoutAttributes(item.attrs, animated: false)
                }
            }
        }
    }
    func enableAnimations() {
        animating = false
        disableAnimationTimer?.invalidate()
        disableAnimationTimer = nil
    }
    
    
    func finishRemovals(removals: [ItemUpdate]) {
        for item in removals {
            removeItem(item)
        }
    }
    func removeItem(item: ItemUpdate) {
        if let cell = item.view as? CBCollectionViewCell {
            self.collectionView.delegate?.collectionView?(self.collectionView, didEndDisplayingCell: cell, forItemAtIndexPath: cell.indexPath!)
            self.collectionView.enqueueCellForReuse(cell)
        }
        else if let id = item.identifier {
            self.collectionView.delegate?.collectionView?(self.collectionView, didEndDisplayingSupplementaryView: item.view, forElementOfKind: id.kind, atIndexPath: id.indexPath!)
            self.collectionView.enqueueSupplementaryViewForReuse(item.view, withIdentifier: id)
        }
        else {
            Swift.print("Invalid item for removal")
        }
    }
    
//    private func animateRemovedItems(removals : [ItemUpdate]) {
//        
//        if removals.count > 0 {
//            let mDelay = dispatch_time(DISPATCH_TIME_NOW, Int64(0.01 * Double(NSEC_PER_SEC)))
//            dispatch_after(mDelay, dispatch_get_main_queue(), {
//                NSAnimationContext.runAnimationGroup({ (context) -> Void in
//                    context.duration = 0.4
//                    context.allowsImplicitAnimation = true
//                    for item in removals {
//                        item.attrs.hidden = true
//                        item.view.applyLayoutAttributes(item.attrs, animated: true)
////                        item.view.animator().frame = item.attrs.frame
////                        item.view.animator().hidden = true
//                    }
//                }) { () -> Void in
//                   
//                }
//            })
//        }
//        
//    }
    
//    private func _applyLayoutAttributes(attributes: CBCollectionViewLayoutAttributes?, toItem : CBCollectionReusableView?, animated: Bool) {
//        
//        if toItem == nil || attributes == nil { return }
//        toItem!.applyLayoutAttributes(attributes!, animated: animated)
//        
//        
//        return;
//        if attributes?.floating == false && animated {
//            NSAnimationContext.beginGrouping()
//            
//            NSAnimationContext.runAnimationGroup({ (context) -> Void in
//                context.duration = 5
//                context.allowsImplicitAnimation = true
//                toItem?.applyLayoutAttributes(attributes!, animated: true)
//                }) { () -> Void in
//                    
//            }
//        }
//        else {
//            toItem!.applyLayoutAttributes(attributes!, animated: false)
//        }
//        
//    }

    
}