
//
//  CollectionViewDocumentView.swift
//  Lingo
//
//  Created by Wesley Byrne on 3/30/16.
//  Copyright © 2016 The Noun Project. All rights reserved.
//

import Foundation


extension Set {
  
    mutating func insertOverwrite(_ element: Element) {
        self.remove(element)
        self.insert(element)
    }
    
    mutating func formUnionOverwrite<S : Sequence where S.Iterator.Element == Element>(_ other: S) {
        self.subtracting(other)
        self.formUnion(other)
    }
    
    func unionOverwrite<S : Sequence where S.Iterator.Element == Element>(_ other: S) -> Set<Element> {
        var new = self.subtracting(other)
        return new.union(other)
    }
    
}



internal struct ItemUpdate : Hashable {
    enum `Type` {
        case insert
        case remove
        case update
    }
    
    let view : CollectionReusableView
    let attrs : CollectionViewLayoutAttributes
    let type : Type
    var identifier : SupplementaryViewIdentifier?
    
    var hashValue: Int {
        return view.hashValue
    }
    
    init(view: CollectionReusableView, attrs: CollectionViewLayoutAttributes, type: Type, identifier: SupplementaryViewIdentifier? = nil) {
        self.view = view
        self.attrs = attrs
        self.identifier = identifier
        self.type = type
    }
    
    static func ==(lhs: ItemUpdate, rhs: ItemUpdate) -> Bool {
        return lhs.view == rhs.view
    }
}

class SectionInfo : Hashable {
    let id = UUID()
    var index: Int = 0
    var _cellMap = [CollectionViewCell:Int]()
    var _cells = [CollectionViewCell]()
    
    
    // Hashable
    var hashValue: Int { return id.hashValue }
    static func ==(lhs: SectionInfo, rhs: SectionInfo) -> Bool {
        return lhs.id == rhs.id
    }
    
    
}

final public class CollectionViewDocumentView : NSView {

    public override var isFlipped : Bool { return true }
    
//    override public class func isCompatibleWithResponsiveScrolling() -> Bool { return true }
    
    fileprivate var collectionView : CollectionView {
        return self.superview!.superview as! CollectionView
    }
    
    public override func adjustScroll(_ newVisible: NSRect) -> NSRect {
//        super.adjustScroll(newVisible)
//        if self.collectionView.isScrolling == false {
//            
//        }
//        var rect = newVisible
//        rect.origin.x = 5 * rect.origin.x.truncatingRemainder(dividingBy: 5)
//        rect.origin.y = 5 * rect.origin.y.truncatingRemainder(dividingBy: 5)
        
//        Swift.print("Adjust scroll: \(rect)")
        return newVisible
    }
    
    var preparedRect = CGRect.zero
    
    
//    var _cellMap = [CollectionViewCell:SectionInfo]()
//    var _cellMap : [CollectionViewCell:Int]
//    var _sectionMap : [SectionInfo:Int]
//    var _sections = [SectionInfo]()
    
    
    var preparedCellIndex = [IndexPath:CollectionViewCell]()
    var preparedSupplementaryViewIndex = [SupplementaryViewIdentifier:CollectionReusableView]()
    
    func reset() {
        
        for cell in preparedCellIndex {
            cell.1.removeFromSuperview()
            self.collectionView.enqueueCellForReuse(cell.1)
            self.collectionView.delegate?.collectionView?(self.collectionView, didEndDisplayingCell: cell.1, forItemAt: cell.0)
        }
        preparedCellIndex.removeAll()
        for view in preparedSupplementaryViewIndex {
            view.1.removeFromSuperview()
            let id = view.0
            self.collectionView.enqueueSupplementaryViewForReuse(view.1, withIdentifier: id)
            self.collectionView.delegate?.collectionView?(self.collectionView, didEndDisplayingSupplementaryView: view.1, ofElementKind: id.kind, at: id.indexPath!)
        }
        
        for v in self.subviews {
            if v is CollectionReusableView {
                v.removeFromSuperview()
            }
        }
        
        preparedSupplementaryViewIndex.removeAll()
        self.preparedRect = CGRect.zero
    }

    
    fileprivate var extending : Bool = false
    
    func extendPreparedRect(_ amount: CGFloat) {
        if self.preparedRect.isEmpty { return }
        self.extending = true
        self.prepareRect(preparedRect.insetBy(dx: -amount, dy: -amount), completion: nil)
        self.extending = false
    }
    
    
    var pendingUpdates: [ItemUpdate] = []
    
    
    func prepareRect(_ rect: CGRect, animated: Bool = false, force: Bool = false, completion: AnimationCompletion? = nil) {
        
        let _rect = rect.intersection(CGRect(origin: CGPoint.zero, size: self.frame.size))
        
        if !force && !self.preparedRect.isEmpty && self.preparedRect.contains(_rect) {
            
            for id in self.preparedSupplementaryViewIndex {
                let view = id.1
                guard let ip = id.0.indexPath, let attrs = self.collectionView.layoutAttributesForSupplementaryElement(ofKind: id.0.kind, atIndexPath: ip) else { continue }
                if attrs.floating == true {
                    if view.superview != self.collectionView._floatingSupplementaryView {
                        view.removeFromSuperview()
                        self.collectionView._floatingSupplementaryView.addSubview(view)
                    }
                    attrs.frame = self.collectionView._floatingSupplementaryView.convert(attrs.frame, from: self)
                }
                else if view.superview == self.collectionView._floatingSupplementaryView {
                    view.removeFromSuperview()
                    self.collectionView.contentDocumentView.addSubview(view)
                }
                view.applyLayoutAttributes(attrs, animated: false)
            }
            completion?(true)
            return
        }
        
        let supps = self.layoutSupplementaryViewsInRect(_rect, animated: animated, forceAll: force)
        let items = self.layoutItemsInRect(_rect, animated: animated, forceAll: force)
        let sRect = supps.rect
        let iRect = items.rect
        
        var newRect = sRect.union(iRect)
//        Swift.print("Modified : \(self.preparedRect)  Items: \(iRect)  Supps: \(sRect)")
        if !self.preparedRect.isEmpty && self.preparedRect.intersects(newRect) {
            newRect = newRect.union(self.preparedRect)
        }
        self.preparedRect = newRect
        
        var updates = Set<ItemUpdate>(supps.updates)
        updates.formUnionOverwrite(items.updates)
        self.applyUpdates(updates, animated: animated, completion: completion)
        
//        Swift.print("Prepared rect: \(CGRectGetMinY(_rect)) - \(CGRectGetMaxY(_rect))  old: \(CGRectGetMinY(previousPrepared)) - \(CGRectGetMaxY(previousPrepared))   New: \(CGRectGetMinY(preparedRect)) - \(CGRectGetMaxY(preparedRect)) :: Subviews:  \(self.subviews.count) :: \(date.timeIntervalSinceNow)")
//        self.ignoreRemoves = false
    }
    
    
    fileprivate func layoutItemsInRect(_ rect: CGRect, animated: Bool = false, forceAll: Bool = false) -> (rect: CGRect, updates: [ItemUpdate]) {
        var _rect = rect

        var updates = [ItemUpdate]()
        
        let oldIPs = Set(self.preparedCellIndex.keys)
        var inserted = self.collectionView.indexPathsForItems(in: rect)
        let removed = oldIPs.removingSet(inserted)
        let updated = inserted.removeSet(oldIPs)
        
        if !extending {
            var removedRect = CGRect.zero
            for ip in removed {
                if let cell = self.collectionView.cellForItem(at: ip) {
                    if removedRect.isEmpty { removedRect = cell.frame }
                    else { removedRect = removedRect.union(cell.frame) }
                    
                    self.preparedCellIndex[ip] = nil
                    cell.layer?.zPosition = 0
                    if animated  && !animating, let attrs =  self.collectionView.layoutAttributesForItem(at: ip) ?? cell.attributes {
                        updates.append(ItemUpdate(view: cell, attrs: attrs, type: .remove))
                    }
                    else {
                        self.collectionView.enqueueCellForReuse(cell)
                        self.collectionView.delegate?.collectionView?(self.collectionView, didEndDisplayingCell: cell, forItemAt: ip)
                    }
                }
            }
            
            if !removedRect.isEmpty {
                //            Swift.print("Remove: \(removedRect)")
                if self.collectionView.collectionViewLayout.scrollDirection == .vertical {
                    let edge = self.visibleRect.origin.y > removedRect.origin.y ? CGRectEdge.minYEdge : CGRectEdge.maxYEdge
                    self.preparedRect = CGRectSubtract(self.preparedRect, rect2: removedRect, edge: edge)
                }
                else {
                    let edge = self.visibleRect.origin.x > removedRect.origin.x ? CGRectEdge.minXEdge : CGRectEdge.maxXEdge
                    self.preparedRect = CGRectSubtract(self.preparedRect, rect2: removedRect, edge: edge)
                }
            }
        }
        
        for ip in inserted {
            guard let attrs = self.collectionView.collectionViewLayout.layoutAttributesForItem(at: ip) else { continue }
            guard let cell = preparedCellIndex[ip] ?? self.collectionView.dataSource?.collectionView(self.collectionView, cellForItemAt: ip) else {
                debugPrint("For some reason collection view tried to load cells without a data source")
                continue
            }
            assert(cell.collectionView != nil, "Attemp to load cell without using deque")
            
            cell.indexPath = ip
            
            cell.setSelected(self.collectionView.itemAtIndexPathIsSelected(cell.indexPath!), animated: false)
            _rect = _rect.union(attrs.frame.insetBy(dx: -1, dy: -1) )
            
            self.collectionView.delegate?.collectionView?(self.collectionView, willDisplayCell: cell, forItemAt: ip)
            if cell.superview == nil {
                self.addSubview(cell)
            }
            if animated {
                cell.applyLayoutAttributes(attrs, animated: false)
                cell.isHidden = true
                cell.alphaValue = 0
            }
            updates.append(ItemUpdate(view: cell, attrs: attrs, type: .insert))
            
            self.preparedCellIndex[ip] = cell
        }

        if forceAll {
            for ip in updated {
                if let attrs = self.collectionView.collectionViewLayout.layoutAttributesForItem(at: ip),
                let cell = preparedCellIndex[ip] {
                    _rect = _rect.union(attrs.frame)
                    updates.append(ItemUpdate(view: cell, attrs: attrs, type: .update))
                }
            }
        }

        return (_rect, updates)
    }
    
    
    fileprivate func layoutSupplementaryViewsInRect(_ rect: CGRect, animated: Bool = false, forceAll: Bool = false) -> (rect: CGRect, updates: [ItemUpdate]) {
        var _rect = rect
        
        var updates = [ItemUpdate]()
        
        let oldIdentifiers = Set(self.preparedSupplementaryViewIndex.keys)
        var inserted = self.collectionView._identifiersForSupplementaryViews(in: rect)
        let removed = oldIdentifiers.removingSet(inserted)
        let updated = inserted.removeSet(oldIdentifiers)
        
        if !extending {
            for identifier in removed {
                if let view = self.preparedSupplementaryViewIndex[identifier] {
                    self.preparedSupplementaryViewIndex[identifier] = nil
                    view.layer?.zPosition = -100
                    
                    if animated && !animating, let attrs = self.collectionView.collectionViewLayout.layoutAttributesForSupplementaryView(ofKind: identifier.kind, atIndexPath: identifier.indexPath!) {
                        updates.append(ItemUpdate(view: view, attrs: attrs, type: .remove, identifier: identifier))
                    }
                    else {
                        self.collectionView.delegate?.collectionView?(self.collectionView, didEndDisplayingSupplementaryView: view, ofElementKind: identifier.kind, at: identifier.indexPath!)
                        self.collectionView.enqueueSupplementaryViewForReuse(view, withIdentifier: identifier)
                    }
                }
            }
        }
        
        for identifier in inserted {
            
            if let view = self.preparedSupplementaryViewIndex[identifier] ?? self.collectionView.dataSource?.collectionView?(self.collectionView, viewForSupplementaryElementOfKind: identifier.kind, at: identifier.indexPath!) {
                
                assert(view.collectionView != nil, "Attempt to insert a view without using deque:")
                
                guard let attrs = self.collectionView.collectionViewLayout.layoutAttributesForSupplementaryView(ofKind: identifier.kind, atIndexPath: identifier.indexPath!)
                    else { continue }
                _rect = _rect.union(attrs.frame)
                
                self.collectionView.delegate?.collectionView?(self.collectionView, willDisplaySupplementaryView: view, ofElementKind: identifier.kind, at: identifier.indexPath!)
                if view.superview == nil {
                    if attrs.floating == true {
                        self.collectionView._floatingSupplementaryView.addSubview(view)
                    }
                    else {
                        self.addSubview(view)
                    }
                }
                if view.superview == self.collectionView._floatingSupplementaryView{
                    attrs.frame = self.collectionView._floatingSupplementaryView.convert(attrs.frame, from: self)
                }
                if animated {
                    view.isHidden = true
                    view.frame = attrs.frame
                }
                updates.append(ItemUpdate(view: view, attrs: attrs, type: .insert))
                self.preparedSupplementaryViewIndex[identifier] = view
            }
        }
        
        for id in updated {
            if let view = preparedSupplementaryViewIndex[id],
                let attrs = self.collectionView.collectionViewLayout.layoutAttributesForSupplementaryView(ofKind: id.kind, atIndexPath: id.indexPath!) {
                _rect = _rect.union(attrs.frame)
                
                if attrs.floating == true {
                    if view.superview != self.collectionView._floatingSupplementaryView {
                        view.removeFromSuperview()
                        self.collectionView._floatingSupplementaryView.addSubview(view)
                    }
                    attrs.frame = self.collectionView._floatingSupplementaryView.convert(attrs.frame, from: self)
                }
                else if view.superview == self.collectionView._floatingSupplementaryView {
                    view.removeFromSuperview()
                    self.collectionView.contentDocumentView.addSubview(view)
                }
                updates.append(ItemUpdate(view: view, attrs: attrs, type: .update))
            }
        }
        
        return (_rect, updates)
    }
    
    var animating = false
    var hasPendingAnimations : Bool = false
    var disableAnimationTimer : Timer?
    internal func applyUpdates(_ updates: Set<ItemUpdate>, animated: Bool, completion: AnimationCompletion?) {
        
        var _updates = updates
        _updates.formUnionOverwrite(pendingUpdates)
        pendingUpdates = []
        
        
        if animated && !animating {
            let _animDuration = self.collectionView.animationDuration
            
            NSGraphicsContext.current()?.flushGraphics()
            
            // let mDelay = DispatchTime.now() + Double(Int64(0.01 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            self.animating = true
            // DispatchQueue.main.asyncAfter(deadline: mDelay, execute: {
                var removals = [ItemUpdate]()
                NSAnimationContext.runAnimationGroup({ (context) -> Void in
                    context.duration = _animDuration
                    context.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
                    
                    for item in _updates {
                        if item.type == .remove {
                            removals.append(item)
                            item.attrs.alpha = 0
                        }
                        item.view.applyLayoutAttributes(item.attrs, animated: true)
                        if item.type == .insert {
                            item.view.viewDidDisplay()
                        }
                    }
                }) { () -> Void in
                    if self.disableAnimationTimer == nil {
                        self.animating = false
                    }
                    self.finishRemovals(removals)
                    completion?(true)
                }
            // })
        }
        else {
            if animated {
                disableAnimationTimer?.invalidate()
                disableAnimationTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(enableAnimations), userInfo: nil, repeats: false)
                animating = true
            }
            for item in _updates {
                if item.type == .remove {
                    removeItem(item)
                }
                else {
                    item.view.applyLayoutAttributes(item.attrs, animated: false)
                    if item.type == .insert {
                        item.view.viewDidDisplay()
                    }
                }
            }
            completion?(!animated)
        }
    }
    func enableAnimations() {
        animating = false
        disableAnimationTimer?.invalidate()
        disableAnimationTimer = nil
    }
    
    
    fileprivate func finishRemovals(_ removals: [ItemUpdate]) {
        for item in removals {
            removeItem(item)
        }
    }
    fileprivate func removeItem(_ item: ItemUpdate) {
        if let cell = item.view as? CollectionViewCell {
            self.collectionView.delegate?.collectionView?(self.collectionView, didEndDisplayingCell: cell, forItemAt: cell.indexPath!)
            self.collectionView.enqueueCellForReuse(cell)
        }
        else if let id = item.identifier {
            self.collectionView.delegate?.collectionView?(self.collectionView, didEndDisplayingSupplementaryView: item.view, ofElementKind: id.kind, at: id.indexPath!)
            self.collectionView.enqueueSupplementaryViewForReuse(item.view, withIdentifier: id)
        }
        else {
            Swift.print("Invalid item for removal")
        }
    }
    
}
