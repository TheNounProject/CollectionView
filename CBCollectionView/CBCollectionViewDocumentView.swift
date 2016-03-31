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
    
    public override func prepareContentInRect(rect: NSRect) {
        Swift.print("Prepare content in rect: \(rect) - \(self.visibleRect)")
        super.prepareContentInRect(self.prepareRect(rect, remove: true))
    }
    
    var preparedRect = CGRectZero
    var preparedCellIndex : [NSIndexPath:CBCollectionViewCell] = [:]
    var preparedSupplementaryViewIndex : [SupplementaryViewIdentifier:CBCollectionReusableView] = [:]
    
    
    func reset() {
        self.preparedContentRect = self.visibleRect
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
            view.1.removeFromSuperview()
            let id = view.0
            self.collectionView.enqueueSupplementaryViewForReuse(view.1, withIdentifier: id)
            self.collectionView.delegate?.collectionView?(self.collectionView, didEndDisplayingSupplementaryView: view.1, forElementOfKind: id.kind, atIndexPath: id.indexPath!)
        }
        preparedSupplementaryViewIndex.removeAll()
        self.preparedRect = CGRectZero
    }
    
    
    func relayout(animated: Bool) {
        
        
    }
    
    
    func prepareRect(rect: CGRect, remove: Bool = false) -> NSRect {
        
        if remove == false && CGRectInset(self.preparedRect, 0, -1).contains(rect) { return self.preparedContentRect }

        let totalRect = CGRectUnion(rect, self.preparedRect)
        var finalRect = remove ? rect : self.preparedRect
        
        
        
        
        let d = NSDate()
        if let attrs = self.collectionView.collectionViewLayout.layoutAttributesForElementsInRect(totalRect) {
            for attr in attrs {
                if attr.representedElementCategory == .SupplementaryView {
                    
                    
                    continue
                }
                else {
                    finalRect.unionInPlace(attr.frame)
                    
                    // Cell is prepared, if not in the rect remove it
                    if let cell = self.preparedCellIndex[attr.indexPath] {
                        if !attr.frame.intersects(rect) {
                            cell.hidden = true
                            cell._indexPath = nil
                            cell.removeFromSuperview()
                            self.collectionView.enqueueCellForReuse(cell)
                            self.preparedCellIndex[attr.indexPath] = nil
                            self.collectionView.delegate?.collectionView?(self.collectionView, didEndDisplayingCell: cell, forItemAtIndexPath: attr.indexPath)
                        }
                        else {
                            self._applyLayoutAttributes(attr, toItem: cell, animated: false)
                        }
                    }
                    else {
                        guard let cell = self.collectionView.dataSource?.collectionView(self.collectionView, cellForItemAtIndexPath: attr.indexPath) else {
                            "For some reason collection view tried to load cells without a data source"
                            continue
                        }
                        cell._indexPath = attr.indexPath
                        
                        self.collectionView.delegate?.collectionView?(self.collectionView, willDisplayCell: cell, forItemAtIndexPath: attr.indexPath)
                        if cell.superview == nil {
                            self.addSubview(cell)
                        }
//                        if animated {
//                            self._applyLayoutAttributes(attrs, toItem: cell, animated: false)
//                            cell.hidden = true
//                            //                if let a = attrs?.frame { cell.frame = f }
//                        }
                        self._applyLayoutAttributes(attr, toItem: cell, animated: false)
                        cell.setSelected(self.collectionView._selectedIndexPaths.contains(cell._indexPath!), animated: false)
                        self.preparedCellIndex[attr.indexPath] = cell
                    }
                }
            }
        }
        else {
            return rect
        }
        Swift.print(d.timeIntervalSinceNow)
        
        self.preparedRect = finalRect
        return rect
    }
    
    
    func layoutItemsInRect(rect: CGRect, animated: Bool = false, forceAll: Bool = false) {
        
        /*
        let oldIPs = Set(self.preparedCellIndex.keys)
        var inserted = self.indexPathsForItemsInRect(self.documentVisibleRect)
        let removed = oldIPs.setByRemovingSubset(inserted)
        let updated = inserted.removeAllInSet(oldIPs)
        
        for ip in removed {
            if let cell = self.cellForItemAtIndexPath(ip) {
                self._visibleCellIndex[ip] = nil
                if animated {
                    NSAnimationContext.runAnimationGroup({ (context) -> Void in
                        context.duration = 0.5
                        context.allowsImplicitAnimation = true
                        cell.hidden = true
                        }) { () -> Void in
                            cell._indexPath = nil
                            self.enqueueCellForReuse(cell)
                            self.delegate?.collectionView?(self, didEndDisplayingCell: cell, forItemAtIndexPath: ip)
                    }
                }
                else {
                    cell.hidden = true
                    cell._indexPath = nil
                    self.enqueueCellForReuse(cell)
                    self.delegate?.collectionView?(self, didEndDisplayingCell: cell, forItemAtIndexPath: ip)
                }
            }
        }
        
        for ip in inserted {
            guard let cell = _visibleCellIndex[ip] ?? self.dataSource?.collectionView(self, cellForItemAtIndexPath: ip) else {
                "For some reason collection view tried to load cells without a data source"
                return
            }
            cell._indexPath = ip
            let attrs = self.collectionViewLayout.layoutAttributesForItemAtIndexPath(ip)
            
            self.delegate?.collectionView?(self, willDisplayCell: cell, forItemAtIndexPath: ip)
            if cell.superview == nil {
                self.contentDocumentView.addSubview(cell)
            }
            if animated {
                self._applyLayoutAttributes(attrs, toItem: cell, animated: false)
                cell.hidden = true
                //                if let a = attrs?.frame { cell.frame = f }
            }
            self._applyLayoutAttributes(attrs, toItem: cell, animated: animated)
            cell.setSelected(self._selectedIndexPaths.contains(cell._indexPath!), animated: false)
            self._visibleCellIndex[ip] = cell
        }
        if forceAll {
            for ip in updated {
                let cell = _visibleCellIndex[ip]
                cell?._indexPath = ip
                let attrs = self.collectionViewLayout.layoutAttributesForItemAtIndexPath(ip)
                self._applyLayoutAttributes(attrs, toItem: cell, animated: animated)
                cell?.selected = self._selectedIndexPaths.contains(ip)
            }
        }
        */
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