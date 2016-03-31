
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
    var isCompatibleWithResponsiveScrolling : Bool { return true }
    
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
        prepareCount = 0
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
        self.preparedContentRect = self.visibleRect
    }
    
    
    func relayout(animated: Bool) {
        
        
    }
    
    var prepareCount = 0
    
    
     
    
    func prepareRect(rect: CGRect, remove: Bool = false) {
        
        let d = NSDate()
        
        
        var _rect = rect
        if self.preparedRect.contains(rect) {
            Swift.print("Not laying out because we're good!")
            return
        }
        Swift.print("New rect, doing layout")
        
        _rect = self.layoutItemsInRect(_rect)
        
        
        self.preparedRect = _rect
        
        /*
        var addIn = CGRectSubtract(rect, rect2: self.preparedRect, horizontal: false)
        
        var final = rect
        var updated = 0
        
        if let attrs = self.collectionView.collectionViewLayout.layoutAttributesForElementsInRect(addIn) where attrs.count > 0 {
            updated += attrs.count
            for attr in attrs {
                final = CGRectUnion(rect, attr.frame)
                guard let cell = self.preparedCellIndex[attr.indexPath] ?? self.collectionView.dataSource?.collectionView(self.collectionView, cellForItemAtIndexPath: attr.indexPath) else {
                    "For some reason collection view tried to load cells without a data source"
                    continue
                }
                cell._indexPath = attr.indexPath
                
                self.collectionView.delegate?.collectionView?(self.collectionView, willDisplayCell: cell, forItemAtIndexPath: attr.indexPath)
                if cell.superview == nil {
                    self.addSubview(cell)
                }
                self._applyLayoutAttributes(attr, toItem: cell, animated: false)
                cell.setSelected(self.collectionView._selectedIndexPaths.contains(cell._indexPath!), animated: false)
                self.preparedCellIndex[attr.indexPath] = cell
            }
        }
        var removeIn = CGRectSubtract(self.preparedRect, rect2: final, horizontal: false)
        if let attrs = self.collectionView.collectionViewLayout.layoutAttributesForElementsInRect(removeIn) where attrs.count > 0 {
            updated += attrs.count
            for attr in attrs {
                if !self.visibleRect.intersects(attr.frame), let cell = self.preparedCellIndex[attr.indexPath] {
                    cell.hidden = true
                    cell._indexPath = nil
                    cell.removeFromSuperview()
                    self.collectionView.enqueueCellForReuse(cell)
                    self.preparedCellIndex[attr.indexPath] = nil
                    self.collectionView.delegate?.collectionView?(self.collectionView, didEndDisplayingCell: cell, forItemAtIndexPath: attr.indexPath)
                }
            }
        }
        Swift.print("remove: \(removeIn)  added: \(addIn)")
        
        self.preparedRect = final ?? self.preparedRect
        Swift.print("\(self.prepareCount) - \(-d.timeIntervalSinceNow) - \(self.preparedRect) -- \(updated)")
        prepareCount++
        
        return self.preparedRect
*/
        
    }
    
    
    func layoutItemsInRect(rect: CGRect, animated: Bool = false, forceAll: Bool = false) -> CGRect {
        
        var _rect = rect
        
        let oldIPs = Set(self.preparedCellIndex.keys)
        var inserted = self.collectionView.indexPathsForItemsInRect(rect)
        let removed = oldIPs.setByRemovingSubset(inserted)
        let updated = inserted.removeAllInSet(oldIPs)
        
        for ip in removed {
            if let cell = self.collectionView.cellForItemAtIndexPath(ip) {
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
        
        for ip in inserted {
            guard let attrs = self.collectionView.collectionViewLayout.layoutAttributesForItemAtIndexPath(ip) else { continue }
            guard let cell = preparedCellIndex[ip] ?? self.collectionView.dataSource?.collectionView(self.collectionView, cellForItemAtIndexPath: ip) else {
                "For some reason collection view tried to load cells without a data source"
                continue
            }
            cell._indexPath = ip
            _rect = CGRectUnion(_rect, attrs.frame)
            
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
                let cell = preparedCellIndex[ip]
                cell?._indexPath = ip
                let attrs = self.collectionView.collectionViewLayout.layoutAttributesForItemAtIndexPath(ip)
                self._applyLayoutAttributes(attrs, toItem: cell, animated: animated)
                cell?.selected = self.collectionView.itemAtIndexPathIsSelected(ip)
            }
        }
        return _rect
    }
    
    
    func _layoutSupplementaryViews(animated: Bool = false, forceAll: Bool = false) {
        /*
        let oldIdentifiers = Set(self.preparedSupplementaryViewIndex.keys)
        var inserted = self.collectionView._identifiersForSupplementaryViewsInRect(self.visibleRect)
        let removed = oldIdentifiers.setByRemovingSubset(inserted)
        let updated = inserted.removeAllInSet(oldIdentifiers)
        
        for identifier in removed {
            if let view = self._visibleSupplementaryViewIndex[identifier] {
                self._visibleSupplementaryViewIndex[identifier] = nil
                if animated {
                    NSAnimationContext.runAnimationGroup({ (context) -> Void in
                        context.duration = 0.5
                        context.allowsImplicitAnimation = true
                        view.hidden = true
                        }) { () -> Void in
                            view._indexPath = nil
                            self.delegate?.collectionView?(self, didEndDisplayingSupplementaryView: view, forElementOfKind: identifier.kind, atIndexPath: identifier.indexPath!)
                            self.enqueueSupplementaryViewForReuse(view, withIdentifier: identifier)
                    }
                }
                else {
                    view.hidden = true
                    view._indexPath = nil
                    self.delegate?.collectionView?(self, didEndDisplayingSupplementaryView: view, forElementOfKind: identifier.kind, atIndexPath: identifier.indexPath!)
                    self.enqueueSupplementaryViewForReuse(view, withIdentifier: identifier)
                }
            }
        }
        
        for identifier in inserted {
            if let view = self.dataSource?.collectionView?(self, viewForSupplementaryElementOfKind: identifier.kind, forIndexPath: identifier.indexPath!) {
                let attrs = self.collectionViewLayout.layoutAttributesForSupplementaryViewOfKind(identifier.kind, atIndexPath: identifier.indexPath!)
                view._indexPath = identifier.indexPath
                
                self.delegate?.collectionView?(self, willDisplaySupplementaryView: view, forElementKind: identifier.kind, atIndexPath: identifier.indexPath!)
                if view.superview == nil {
                    if attrs?.floating == true {
                        self._floatingSupplementaryView.addSubview(view)
                    }
                    else {
                        self.contentDocumentView.addSubview(view)
                    }
                }
                if view.superview == self._floatingSupplementaryView, let a = attrs {
                    a.frame = self._floatingSupplementaryView.convertRect(a.frame, fromView: self.contentDocumentView)
                }
                if animated {
                    view.hidden = true
                    if let f = attrs?.frame { view.frame = f }
                }
                self._applyLayoutAttributes(attrs, toItem: view, animated: animated)
                self._visibleSupplementaryViewIndex[identifier] = view
            }
        }
        
        for id in updated {
            if let cell = _visibleSupplementaryViewIndex[id],
                let attrs = self.collectionViewLayout.layoutAttributesForSupplementaryViewOfKind(id.kind, atIndexPath: id.indexPath!) {
                    
                    if attrs.floating == true {
                        if cell.superview != self._floatingSupplementaryView {
                            cell.removeFromSuperview()
                            self._floatingSupplementaryView.addSubview(cell)
                        }
                        attrs.frame = self._floatingSupplementaryView.convertRect(attrs.frame, fromView: self.contentDocumentView)
                    }
                    else if cell.superview == self._floatingSupplementaryView {
                        cell.removeFromSuperview()
                        self.contentDocumentView.addSubview(cell)
                    }
                    
                    self._applyLayoutAttributes(attrs, toItem: cell, animated: animated)
            }
        }
        */
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