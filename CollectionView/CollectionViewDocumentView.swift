
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
    
    mutating func formUnionOverwrite<S : Sequence>(_ other: S) where S.Iterator.Element == Element {
        self.subtract(other)
        self.formUnion(other)
    }
    
    func unionOverwrite<S : Sequence>(_ other: S) -> Set<Element> where S.Iterator.Element == Element {
        let new = self.subtracting(other)
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
    let _attrs : CollectionViewLayoutAttributes?
    let indexPath : IndexPath
    let type : Type
    let identifier : SupplementaryViewIdentifier?
    
    fileprivate var attrs : CollectionViewLayoutAttributes {
        if let a = _attrs { return a }
        
        guard let cv = self.view.collectionView else {
            preconditionFailure("CollectionView Error: A view was returned without using a deque() method.")
        }
        var a : CollectionViewLayoutAttributes?
        if let id = identifier {
            a = cv.layoutAttributesForSupplementaryView(ofKind: id.kind, at: indexPath)
        }
        else if view is CollectionViewCell {
            a = cv.layoutAttributesForItem(at: indexPath)
        }
        a = a ?? view.attributes
        precondition(a != nil, "Internal error: unable to find layout attributes for view at \(indexPath)")
        return a!
    }
    
    var hashValue: Int {
        return view.hashValue
    }
    
    init(cell: CollectionViewCell, attrs: CollectionViewLayoutAttributes, type: Type) {
        self.view = cell
        self._attrs = attrs
        self.indexPath = attrs.indexPath
        self.identifier = nil
        self.type = type
    }
    init(cell: CollectionViewCell, indexPath: IndexPath, type: Type) {
        precondition(type != .remove, "Internal CollectionView Error: Cannot use UpdateItem(cell:indexPath:type:) for type remove")
        self.view = cell
        self._attrs = nil
        self.indexPath = indexPath
        self.identifier = nil
        self.type = type
    }
    init(view: CollectionReusableView, attrs: CollectionViewLayoutAttributes, type: Type, identifier: SupplementaryViewIdentifier) {
        self.view = view
        self._attrs = attrs
        self.indexPath = attrs.indexPath
        self.identifier = identifier
        self.type = type
    }
    init(view: CollectionReusableView, indexPath: IndexPath, type: Type, identifier: SupplementaryViewIdentifier) {
        precondition(type != .remove, "Internal CollectionView Error: Cannot use UpdateItem(view:indexPath:type:identifier) for type remove")
        self.view = view
        self._attrs = nil
        self.indexPath = indexPath
        self.identifier = identifier
        self.type = type
    }
    
    static func ==(lhs: ItemUpdate, rhs: ItemUpdate) -> Bool {
        return lhs.view == rhs.view
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
    
    
    var preparedCellIndex = IndexedSet<IndexPath,CollectionViewCell>()
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
            
            for _view in self.preparedSupplementaryViewIndex {
                let view = _view.1
                let id = _view.0
                guard let ip = id.indexPath, var attrs = self.collectionView.layoutAttributesForSupplementaryView(ofKind: id.kind, at: ip) else { continue }
                
                guard attrs.frame.intersects(self.preparedRect) else {
                    self.collectionView.delegate?.collectionView?(self.collectionView, didEndDisplayingSupplementaryView: view, ofElementKind: id.kind, at: ip)
                    self.preparedSupplementaryViewIndex[id] = nil
                    self.collectionView.enqueueSupplementaryViewForReuse(view, withIdentifier: id)
                    continue
                }
                
                if attrs.floating == true {
                    if view.superview != self.collectionView._floatingSupplementaryView {
                        view.removeFromSuperview()
                        self.collectionView._floatingSupplementaryView.addSubview(view)
                    }
                    attrs = attrs.copy()
                    attrs.frame = self.collectionView._floatingSupplementaryView.convert(attrs.frame, from: self)
                    view.apply(attrs, animated: false)
                }
                else if view.superview == self.collectionView._floatingSupplementaryView {
                    view.removeFromSuperview()
                    self.collectionView.contentDocumentView.addSubview(view)
                    view.apply(attrs, animated: false)
                }
            }
            completion?(true)
            return
        }
        
        let supps = self.layoutSupplementaryViewsInRect(_rect, animated: animated, forceAll: force)
        let items = self.layoutItemsInRect(_rect, animated: animated, forceAll: force)
        let sRect = supps.rect
        let iRect = items.rect
        
        var newRect = sRect.union(iRect)
        if !self.preparedRect.isEmpty && self.preparedRect.intersects(newRect) {
            newRect = newRect.union(self.preparedRect)
        }
        self.preparedRect = newRect
        
        var updates = Set<ItemUpdate>(supps.updates)
        updates.formUnion(pendingUpdates)
        updates.formUnionOverwrite(items.updates)

        pendingUpdates.removeAll()
        
        self.applyUpdates(updates, animated: animated, completion: completion)
    }
    
    
    fileprivate func layoutItemsInRect(_ rect: CGRect, animated: Bool = false, forceAll: Bool = false) -> (rect: CGRect, updates: [ItemUpdate]) {
        var _rect = rect

        var updates = [ItemUpdate]()
        
        let oldIPs = self.preparedCellIndex.indexSet
        var inserted = Set(self.collectionView.indexPathsForItems(in: rect))
        let removed = oldIPs.removing(inserted)
        let updated = inserted.remove(oldIPs)
        
        if !extending {
            var removedRect = CGRect.zero
            for ip in removed {
                if let cell = self.collectionView.cellForItem(at: ip) {
                    if removedRect.isEmpty { removedRect = cell.frame }
                    else { removedRect = removedRect.union(cell.frame) }
                    
                    cell.layer?.zPosition = 0
                    if animated  && !animating, let attrs = self.collectionView.layoutAttributesForItem(at: ip) ?? cell.attributes {
                        updates.append(ItemUpdate(cell: cell, attrs: attrs, type: .remove))
                    }
                    else {
                        self.collectionView.enqueueCellForReuse(cell)
                        self.collectionView.delegate?.collectionView?(self.collectionView, didEndDisplayingCell: cell, forItemAt: ip)
                    }
                    self.preparedCellIndex[ip] = nil
                }
            }
            
            if !removedRect.isEmpty {
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
            guard let cell =  preparedCellIndex[ip] ?? self.collectionView.dataSource?.collectionView(self.collectionView, cellForItemAt: ip) else {
                debugPrint("For some reason collection view tried to load cells without a data source")
                continue
            }
            assert(cell.collectionView != nil, "Attemp to load cell without using deque")
            
//            cell.indexPath = ip
            
            cell.setSelected(self.collectionView.itemAtIndexPathIsSelected(ip), animated: false)
            _rect = _rect.union(attrs.frame.insetBy(dx: -1, dy: -1) )
            
            self.collectionView.delegate?.collectionView?(self.collectionView, willDisplayCell: cell, forItemAt: ip)
            cell.viewWillDisplay()
            if cell.superview == nil {
                self.addSubview(cell)
            }
            if animated {
                cell.apply(attrs, animated: false)
                cell.isHidden = true
                cell.alphaValue = 0
            }
            updates.append(ItemUpdate(cell: cell, attrs: attrs, type: .insert))
            
            self.preparedCellIndex[ip] = cell
        }

        if forceAll {
            for ip in updated {
                if let attrs = self.collectionView.collectionViewLayout.layoutAttributesForItem(at: ip),
                let cell = preparedCellIndex[ip] {
                    _rect = _rect.union(attrs.frame)
                    updates.append(ItemUpdate(cell: cell, attrs: attrs, type: .update))
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
        let removed = oldIdentifiers.removing(inserted)
        let updated = inserted.remove(oldIdentifiers)
        
        if !extending {
            for identifier in removed {
                if let view = self.preparedSupplementaryViewIndex[identifier] {
                    view.layer?.zPosition = -100
                    
                    if animated && !animating, var attrs = self.collectionView.collectionViewLayout.layoutAttributesForSupplementaryView(ofKind: identifier.kind, at: identifier.indexPath!) ?? view.attributes {
                        if attrs.floating == true {
                            if view.superview != self.collectionView._floatingSupplementaryView {
                                view.removeFromSuperview()
                                self.collectionView._floatingSupplementaryView.addSubview(view)
                            }
                            attrs = attrs.copy()
                            attrs.frame = self.collectionView._floatingSupplementaryView.convert(attrs.frame, from: self)
                        }
                        else if view.superview == self.collectionView._floatingSupplementaryView {
                            view.removeFromSuperview()
                            self.collectionView.contentDocumentView.addSubview(view)
                        }
                        updates.append(ItemUpdate(view: view, attrs: attrs, type: .remove, identifier: identifier))
                    }
                    else {
                        self.collectionView.delegate?.collectionView?(self.collectionView, didEndDisplayingSupplementaryView: view, ofElementKind: identifier.kind, at: identifier.indexPath!)
                        self.collectionView.enqueueSupplementaryViewForReuse(view, withIdentifier: identifier)
                    }
                    self.preparedSupplementaryViewIndex[identifier] = nil
                }
            }
        }
        
        for identifier in inserted {
            
            if let view = self.preparedSupplementaryViewIndex[identifier] ?? self.collectionView.dataSource?.collectionView?(self.collectionView, viewForSupplementaryElementOfKind: identifier.kind, at: identifier.indexPath!) {
                
                assert(view.collectionView != nil, "Attempt to insert a view without using deque:")
                
                guard var attrs = self.collectionView.collectionViewLayout.layoutAttributesForSupplementaryView(ofKind: identifier.kind, at: identifier.indexPath!)
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
                    attrs = attrs.copy()
                    attrs.frame = self.collectionView._floatingSupplementaryView.convert(attrs.frame, from: self)
                }
                if animated {
                    view.isHidden = true
                    view.frame = attrs.frame
                }
                updates.append(ItemUpdate(view: view, attrs: attrs, type: .insert, identifier: identifier))
                self.preparedSupplementaryViewIndex[identifier] = view
            }
        }
        
        for id in updated {
            if let view = preparedSupplementaryViewIndex[id],
                var attrs = self.collectionView.collectionViewLayout.layoutAttributesForSupplementaryView(ofKind: id.kind, at: id.indexPath!) {
                _rect = _rect.union(attrs.frame)
                
                if attrs.floating == true {
                    if view.superview != self.collectionView._floatingSupplementaryView {
                        view.removeFromSuperview()
                        self.collectionView._floatingSupplementaryView.addSubview(view)
                    }
                    attrs = attrs.copy()
                    attrs.frame = self.collectionView._floatingSupplementaryView.convert(attrs.frame, from: self)
                }
                else if view.superview == self.collectionView._floatingSupplementaryView {
                    view.removeFromSuperview()
                    self.collectionView.contentDocumentView.addSubview(view)
                }
//                log.debug(attrs)
                updates.append(ItemUpdate(view: view, attrs: attrs, type: .update, identifier: id))
            }
        }
        
        return (_rect, updates)
    }
    
    var animating = false
    var hasPendingAnimations : Bool = false
    var disableAnimationTimer : Timer?
    internal func applyUpdates(_ updates: Set<ItemUpdate>, animated: Bool, completion: AnimationCompletion?) {
        
        let _updates = updates
//        for u in _updates {
//            log.debug("\(u.view.attributes?.indexPath.description ?? "[?, ?]") - \(u.type) - is view\(u.view)")
//        }
        
        if animated && !animating {
            let _animDuration = self.collectionView.animationDuration
            
            self.animating = true
            
            // Dispatch to allow frame changes from reloadLayout() to apply before 
            // beginning the animations
            DispatchQueue.main.async { [unowned self] in
                var removals = [ItemUpdate]()
                NSAnimationContext.runAnimationGroup({ (context) -> Void in
                    context.duration = _animDuration
                    context.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
                    
                    for item in _updates {
                        var attrs = item.attrs
                        if item.type == .remove {
                            removals.append(item)
                            attrs = attrs.copy()
                            attrs.alpha = 0
                        }
                        item.view.apply(attrs, animated: true)
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
             }
        }
        else {
            if animated {
                disableAnimationTimer?.invalidate()
                disableAnimationTimer = Timer.scheduledTimer(timeInterval: collectionView.animationDuration, target: self, selector: #selector(enableAnimations), userInfo: nil, repeats: false)
                animating = true
            }
            for item in _updates {
                if item.type == .remove {
                    removeItem(item)
                }
                else  {
                    let attrs = item.attrs
                    item.view.apply(attrs, animated: false)
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
    func removeItem(_ item: ItemUpdate) {
        if let cell = item.view as? CollectionViewCell {
            self.collectionView.delegate?.collectionView?(self.collectionView, didEndDisplayingCell: cell, forItemAt: cell.attributes!.indexPath)
            self.collectionView.enqueueCellForReuse(cell)
        }
        else if let id = item.identifier {
            self.collectionView.delegate?.collectionView?(self.collectionView, didEndDisplayingSupplementaryView: item.view, ofElementKind: id.kind, at: id.indexPath!)
            self.collectionView.enqueueSupplementaryViewForReuse(item.view, withIdentifier: id)
        }
        else {
            log.error("Invalid item for removal")
        }
    }
    
}
