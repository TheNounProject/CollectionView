
//
//  CBCollectionViewDocumentView.swift
//  Lingo
//
//  Created by Wesley Byrne on 3/30/16.
//  Copyright © 2016 The Noun Project. All rights reserved.
//

import Foundation



internal struct ItemUpdate {
    enum Type {
        case Insert
        case Remove
        case Update
    }
    
    let view : CBCollectionReusableView!
    let attrs : CBCollectionViewLayoutAttributes!
    let type : Type!
    var identifier : SupplementaryViewIdentifier?
    
    init(view: CBCollectionReusableView, attrs: CBCollectionViewLayoutAttributes, type: Type, identifier: SupplementaryViewIdentifier? = nil) {
        self.view = view
        self.attrs = attrs
        self.identifier = identifier
        self.type = type
    }
}



final public class CBCollectionViewDocumentView : NSView {

    public override var flipped : Bool { return true }
//    var isCompatibleWithResponsiveScrolling : Bool { return true }
    
    private weak var collectionView : CBCollectionView! {
        return self.superview!.superview as! CBCollectionView
    }
    
//    public override func prepareContentInRect(rect: NSRect) {
//        let _rect = self.prepareRect(rect, remove: true)
//        super.prepareContentInRect(_rect)
//    }
    

    
    var preparedRect = CGRectZero
    var preparedCellIndex : [NSIndexPath:CBCollectionViewCell] = [:]
    var preparedSupplementaryViewIndex : [SupplementaryViewIdentifier:CBCollectionReusableView] = [:]
    
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
        
        for v in self.subviews {
            if v is CBCollectionReusableView {
                v.removeFromSuperview()
            }
        }
        
        preparedSupplementaryViewIndex.removeAll()
        self.preparedRect = CGRectZero
    }

    
    private var extending : Bool = false
    
    func extendPreparedRect(amount: CGFloat) {
        if self.preparedRect.isEmpty { return }
        self.extending = true
        self.prepareRect(CGRectInset(preparedRect, -amount, -amount))
        self.extending = false
    }
    
    
    var pendingUpdates: [ItemUpdate] = []
    
    
    func prepareRect(rect: CGRect, animated: Bool = false, force: Bool = false) {
        
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
                view.applyLayoutAttributes(attrs, animated: false)
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
//        Swift.print("Modified : \(self.preparedRect)  Items: \(iRect)  Supps: \(sRect)")
        if !self.preparedRect.isEmpty && self.preparedRect.intersects(newRect) {
            newRect.unionInPlace(self.preparedRect)
        }
        self.preparedRect = newRect
        
        var updates = supps.updates
        updates.appendContentsOf(items.updates)
        self.applyUpdates(updates, animated: animated)
        
//        Swift.print("Prepared rect: \(CGRectGetMinY(_rect)) - \(CGRectGetMaxY(_rect))  old: \(CGRectGetMinY(previousPrepared)) - \(CGRectGetMaxY(previousPrepared))   New: \(CGRectGetMinY(preparedRect)) - \(CGRectGetMaxY(preparedRect)) :: Subviews:  \(self.subviews.count) :: \(date.timeIntervalSinceNow)")
//        self.ignoreRemoves = false
    }
    
    
    private func layoutItemsInRect(rect: CGRect, animated: Bool = false, forceAll: Bool = false) -> (rect: CGRect, updates: [ItemUpdate]) {
        var _rect = rect

        var updates = [ItemUpdate]()
        
        let oldIPs = Set(self.preparedCellIndex.keys)
        var inserted = self.collectionView.indexPathsForItemsInRect(rect)
        let removed = oldIPs.setByRemovingSubset(inserted)
        let updated = inserted.removeAllInSet(oldIPs)
        
        if !extending {
            var removedRect = CGRectZero
            for ip in removed {
                if let cell = self.collectionView.cellForItemAtIndexPath(ip) {
                    if removedRect.isEmpty { removedRect = cell.frame }
                    else { removedRect.unionInPlace(cell.frame) }
                    
                    self.preparedCellIndex[ip] = nil
                    cell.layer?.zPosition = 0
                    if animated  && !animating, let attrs =  self.collectionView.layoutAttributesForItemAtIndexPath(ip) ?? cell.attributes {
                        updates.append(ItemUpdate(view: cell, attrs: attrs, type: .Remove))
                    }
                    else {
                        self.collectionView.enqueueCellForReuse(cell)
                        self.collectionView.delegate?.collectionView?(self.collectionView, didEndDisplayingCell: cell, forItemAtIndexPath: ip)
                    }
                }
            }
            
            if !removedRect.isEmpty {
                //            Swift.print("Remove: \(removedRect)")
                if self.collectionView.collectionViewLayout.scrollDirection == .Vertical {
                    let edge = self.visibleRect.origin.y > removedRect.origin.y ? CGRectEdge.MinYEdge : CGRectEdge.MaxYEdge
                    self.preparedRect = CGRectSubtract(self.preparedRect, rect2: removedRect, edge: edge)
                }
                else {
                    
                }
            }
        }
        
        for ip in inserted {
            guard let attrs = self.collectionView.collectionViewLayout.layoutAttributesForItemAtIndexPath(ip) else { continue }
            guard let cell = preparedCellIndex[ip] ?? self.collectionView.dataSource?.collectionView(self.collectionView, cellForItemAtIndexPath: ip) else {
                "For some reason collection view tried to load cells without a data source"
                continue
            }
            assert(cell.collectionView != nil, "Attemp to load cell without using deque")
            
            cell.indexPath = ip
            
            cell.setSelected(self.collectionView.itemAtIndexPathIsSelected(cell.indexPath!), animated: false)
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
            updates.append(ItemUpdate(view: cell, attrs: attrs, type: .Insert))
            
            self.preparedCellIndex[ip] = cell
        }

        if forceAll {
            for ip in updated {
                if let attrs = self.collectionView.collectionViewLayout.layoutAttributesForItemAtIndexPath(ip),
                let cell = preparedCellIndex[ip] {
                    _rect = CGRectUnion(_rect, attrs.frame)
                    updates.append(ItemUpdate(view: cell, attrs: attrs, type: .Update))
                }
            }
        }

        return (_rect, updates)
    }
    
    
    private func layoutSupplementaryViewsInRect(rect: CGRect, animated: Bool = false, forceAll: Bool = false) -> (rect: CGRect, updates: [ItemUpdate]) {
        var _rect = rect
        
        var updates = [ItemUpdate]()
        
        let oldIdentifiers = Set(self.preparedSupplementaryViewIndex.keys)
        var inserted = self.collectionView._identifiersForSupplementaryViewsInRect(rect)
        let removed = oldIdentifiers.setByRemovingSubset(inserted)
        let updated = inserted.removeAllInSet(oldIdentifiers)
        
        if !extending {
            for identifier in removed {
                if let view = self.preparedSupplementaryViewIndex[identifier] {
                    self.preparedSupplementaryViewIndex[identifier] = nil
                    view.layer?.zPosition = -100
                    
                    if animated && !animating, let attrs = self.collectionView.collectionViewLayout.layoutAttributesForSupplementaryViewOfKind(identifier.kind, atIndexPath: identifier.indexPath!) {
                        updates.append(ItemUpdate(view: view, attrs: attrs, type: .Remove, identifier: identifier))
                    }
                    else {
                        self.collectionView.delegate?.collectionView?(self.collectionView, didEndDisplayingSupplementaryView: view, forElementOfKind: identifier.kind, atIndexPath: identifier.indexPath!)
                        self.collectionView.enqueueSupplementaryViewForReuse(view, withIdentifier: identifier)
                    }
                }
            }
        }
        
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
                updates.append(ItemUpdate(view: view, attrs: attrs, type: .Insert))
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
                updates.append(ItemUpdate(view: view, attrs: attrs, type: .Update))
            }
        }
        
        return (_rect, updates)
    }
    
    var animating = false
    var hasPendingAnimations : Bool = false
    var disableAnimationTimer : NSTimer?
    internal func applyUpdates(updates: [ItemUpdate], animated: Bool) {
        
        var _updates = updates
        _updates.appendContentsOf(pendingUpdates)
        pendingUpdates = []
        
        
        if animated && !animating {
            let mDelay = dispatch_time(DISPATCH_TIME_NOW, Int64(0.01 * Double(NSEC_PER_SEC)))
            self.animating = true
            dispatch_after(mDelay, dispatch_get_main_queue(), {
                var removals = [ItemUpdate]()
                NSAnimationContext.runAnimationGroup({ (context) -> Void in
                    context.duration = self.collectionView.animationDuration
                    context.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
                    //                    context.allowsImplicitAnimation = true
                    
                    for item in _updates {
                        if item.type == .Remove {
                            removals.append(item)
                            item.attrs.alpha = 0
                        }
                        item.view.applyLayoutAttributes(item.attrs, animated: true)
                        if item.type == .Insert {
                            item.view.viewDidDisplay()
                        }
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
            for item in _updates {
                if item.type == .Remove {
                    removeItem(item)
                }
                else {
                    item.view.applyLayoutAttributes(item.attrs, animated: false)
                    if item.type == .Insert {
                        item.view.viewDidDisplay()
                    }
                }
            }
        }
    }
    func enableAnimations() {
        animating = false
        disableAnimationTimer?.invalidate()
        disableAnimationTimer = nil
    }
    
    
    private func finishRemovals(removals: [ItemUpdate]) {
        for item in removals {
            removeItem(item)
        }
    }
    private func removeItem(item: ItemUpdate) {
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
    
}