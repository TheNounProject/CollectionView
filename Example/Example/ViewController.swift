//
//  ViewController.swift
//  ResultsController
//
//  Created by Wesley Byrne on 1/12/17.
//  Copyright © 2017 WCB Media. All rights reserved.
//

import Cocoa
import CollectionView


extension Int {
    
    static func random(in range: ClosedRange<Int>) -> Int {
        let min = range.lowerBound
        let max = range.upperBound
        return Int(arc4random_uniform(UInt32(1 + max - min))) + min
    }
}

extension MutableCollection where Indices.Iterator.Element == Index {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        
        for (firstUnshuffled , unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: IndexDistance = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            guard d != 0 else { continue }
            let i = index(firstUnshuffled, offsetBy: d)
            swap(&self[firstUnshuffled], &self[i])
        }
    }
}

extension Sequence {
    /// Returns an array with the contents of this sequence, shuffled.
    func shuffled() -> [Iterator.Element] {
        var result = Array(self)
        result.shuffle()
        return result
    }
}

extension Array {
    
    
    func random() -> Element? {
        guard self.count > 0 else { return nil }
        let idx = Int.random(in: 0...self.count - 1)
        return self[idx]
    }
}



class ViewController: CollectionViewController, ResultsControllerDelegate, BasicHeaderDelegate, CollectionViewDelegateColumnLayout, CollectionViewDelegateFlowLayout, CollectionViewPreviewControllerDelegate {

    var relational: Bool = false
    
    let fetchedResultsController = FetchedResultsController<NSNumber, Child>(context: AppDelegate.current.managedObjectContext, request: NSFetchRequest<Child>(entityName: "Child"))
    let relationalResultsController = RelationalResultsController(context: AppDelegate.current.managedObjectContext,
                                                                                 request: NSFetchRequest<Child>(entityName: "Child"),
                                                                                 sectionRequest: NSFetchRequest<Parent>(entityName: "Parent"),
                                                                                 sectionKeyPath: "parent")
    
    
    var resultsController : ResultsController {
        return relational ? relationalResultsController : fetchedResultsController
    }
    
    
    var listLayout = CollectionViewListLayout()
    var gridLayout = CollectionViewFlowLayout()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.animationDuration = 0.8

        let creationSort = NSSortDescriptor(key: "created", ascending: true)
        fetchedResultsController.fetchRequest.sortDescriptors = [creationSort]
        fetchedResultsController.delegate = self
        
        try! resultsController.performFetch()
        
        relationalResultsController.fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "displayOrder", ascending: true)
        ]
        relationalResultsController.sectionFetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "displayOrder", ascending: true)
        ]
        
        relationalResultsController.sectionKeyPath = "parent"
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        listLayout.itemHeight = 36
        listLayout.headerHeight = 36
        
        collectionView.collectionViewLayout = listLayout
        
        
        // The default way of registering cells
        collectionView.register(nib: NSNib(nibNamed: "GridCell", bundle: nil)!, forCellWithReuseIdentifier: "GridCell")
        
        // A shortcut way to register cells
        ListCell.register(collectionView)
        BasicHeaderView.register(collectionView)
        
        
        // Reload to get started
        collectionView.reloadData()
        
        
        if let t = self.test {
            let moc = AppDelegate.current.managedObjectContext
            
            let cReq = NSFetchRequest<Child>(entityName: "Child")
            for c in try! moc.fetch(cReq) {
                moc.delete(c)
            }
            
            let pReq = NSFetchRequest<Parent>(entityName: "Parent")
            for p in try! moc.fetch(pReq) {
                moc.delete(p)
            }
            
            for t in t.core {
                let p = Parent.create(withChild: false)
                for _ in 0..<t.count {
                    _ = p.createChild()
                }
            }
        }
        
    }
    
    
    
    
    
    // MARK: - Actions
    /*-------------------------------------------------------------------------------*/
    
    
    @IBAction func toggleGroupStyle(_ sender: AnyObject?) {
        
        guard let selector = self.view.window?.toolbar?.items.first?.view as? NSSegmentedControl else {
            return
        }
        selector.selectedSegment = selector.selectedSegment == 0 ? 1 : 0
        groupSelectorChanged(sender)
    }
    
    @IBAction func groupSelectorChanged(_ sender: Any?) {
        guard let selector = self.view.window?.toolbar?.items.first?.view as? NSSegmentedControl else {
            return
        }
        
        let r = selector.selectedSegment == 1
        guard r != relational else { return }
        
        relational = !relational
        try? resultsController.performFetch()
        
        self.fetchedResultsController.delegate = relational ? nil : self
        self.relationalResultsController.delegate = relational ? self : nil
        
        self.collectionView.reloadData()
    }
    
    
    
    struct Test {
        var core : [[IndexPath?]] = [
            [
                nil,
                IndexPath.for(item: 6, section: 1),
                IndexPath.for(item: 3, section: 0),
                IndexPath.for(item: 1, section: 1),
                IndexPath.for(item: 4, section: 0),
                IndexPath.for(item: 5, section: 0),
                IndexPath.for(item: 0, section: 1),
                IndexPath.for(item: 1, section: 0),
                IndexPath.for(item: 3, section: 1),
                IndexPath.for(item: 5, section: 1),
                nil,
                nil,
                ],
            [
                IndexPath.for(item: 7, section: 0),
                IndexPath.for(item: 2, section: 0),
                nil,
                IndexPath.for(item: 6, section: 0),
                nil,
                IndexPath.for(item: 2, section: 1),
                nil
            ]
        ]
        
        var inserts : [IndexPath] = [
            IndexPath.for(item: 0, section: 0),
            IndexPath.for(item: 4, section: 1)
        ]
        
    }
    
    var test : Test?
    
//    var tests : [[IndexPath?]] = [
//        [
//            nil,
//            IndexPath.for(item: 6, section: 1),
//            IndexPath.for(item: 3, section: 0),
//            IndexPath.for(item: 1, section: 1),
//            IndexPath.for(item: 4, section: 0),
//            IndexPath.for(item: 5, section: 0),
//            IndexPath.for(item: 0, section: 1),
//            IndexPath.for(item: 1, section: 0),
//            IndexPath.for(item: 3, section: 1),
//            IndexPath.for(item: 5, section: 1),
//            nil,
//            nil,
//            ],
//        [
//            IndexPath.for(item: 7, section: 0),
//            IndexPath.for(item: 2, section: 0),
//            nil,
//            IndexPath.for(item: 6, section: 0),
//            nil,
//            IndexPath.for(item: 2, section: 1),
//            nil
//        ]
//    ]
    
//    var inserts : [IndexPath] = [
//        IndexPath.for(item: 0, section: 0),
//        IndexPath.for(item: 4, section: 1)
//    ]
    
    
    @IBAction func radomize(_ sender: Any?) {
        
        guard relational else { return }
        
        var num = self.relationalResultsController.numberOfSections
        
        for section in self.relationalResultsController.sections {
            guard let p = section.object as? Parent else { continue }
            p.displayOrder = NSNumber(value: num)
            num -= 1
        }
        
        return;
        
        
        if let t = test {
            for (idx, section) in self.relationalResultsController.sections.enumerated() {
                let test = t.core[idx]
                
                for (cIdx, _c) in section.objects.enumerated() {
                    let child = _c as! Child
                    
                    if let ip = test[cIdx] {
                        if ip._section != idx {
                            child.parent = self.relationalResultsController._object(forSectionAt: ip)
                        }
                        child.displayOrder = NSNumber(value: ip._item)
                    }
                    else {
                        child.managedObjectContext?.delete(child)
                    }
                }
            }
            
            for ip in t.inserts {
                if let p = relationalResultsController._object(forSectionAt: ip) {
                    let c = p.createChild()
                    c.displayOrder = NSNumber(value: ip._item)
                }
            }
            return
        }
        
        
        let sections = relationalResultsController.sections
        
        var parents = [Parent:[Child]]()
        for s in sections {
            if let p = s.object as? Parent {
                parents[p] = [Child]()
            }
        }
        
        for section in sections {
            for item in section.objects {
                let c = item as! Child
                if let p = sections.random()?.object as? Parent {
                    
                    // Delete randomly
                    if Int.random(in: 0...20) % 5 == 0 {
                        c.managedObjectContext?.delete(c)
                        continue
                    }
                    
                    c.parent = p
                    parents[p]?.append(c)
                    
                    if Int.random(in: 0...20) % 3 == 0 {
                        let newC = p.createChild()
                        parents[p]?.append(newC)
                    }
                    
                    
                }
            }
        }
        
        
        for parentSet in parents {
        
            var sectionIndexes = [Int](0..<parentSet.value.count)
            sectionIndexes.shuffle()
            
            for (idx, child) in parentSet.value.enumerated() {
                child.displayOrder = NSNumber(value: sectionIndexes[idx])
            }
        }
 
    }
    
    
    func repeatBlock(_ count: Int, block: ()->Void) {
            for _ in 0..<count {
                block()
            }
    }
    
    
    @IBAction func addChild(_ sender: AnyObject?) {
        
        let count = NSApp.currentEvent?.modifierFlags.contains(.option) == true ? 5 : 1
        repeatBlock(count) { 
            _ = Child.createOrphan()
        }
    }
    
    @IBAction func addParent(_ sender: AnyObject?) {
        let count = NSApp.currentEvent?.modifierFlags.contains(.option) == true ? 5 : 1
        repeatBlock(count) {
            _ = Parent.create()
        }
    }
    
    
    @IBAction func toggleLayout(_ sender: AnyObject?) {
        
        if self.collectionView.collectionViewLayout is CollectionViewListLayout {
            self.collectionView.collectionViewLayout = self.gridLayout
        }
        else {
            self.collectionView.collectionViewLayout = self.listLayout
        }
        self.collectionView.reloadData()
    }
    
    
    @IBAction func refresh(_ sender: AnyObject?) {
        do {
            try self.resultsController.performFetch()
            collectionView.reloadData()
        }
        catch let err {
            let alert = NSAlert()
            alert.messageText = "Error"
            alert.informativeText = "Error code: \(err)"
            alert.addButton(withTitle: "Okay")
            alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
        }
    }
    
    @IBAction func reload(_ sender: AnyObject?) {
        collectionView.reloadData()
    }
    
    func delete(_ sender: Any?) {
        for ip in collectionView.indexPathsForSelectedItems {
            if let item = resultsController.object(at: ip) as? NSManagedObject {
                item.managedObjectContext?.delete(item)
            }
        }
    }
    
    
    // Basic Header View delegate (+ button)
    func basicHeaderView(_ view: BasicHeaderView, didSelectButton button: IconButton) {
        
        guard let ip = collectionView.indexPath(forSupplementaryView: view) else { return }
        guard  let section = self.resultsController.sectionInfo(forSectionAt: ip)?.object as? Parent else { return }
        
        let flags = NSApp.currentEvent?.modifierFlags
        
        
        
        
        if flags?.contains(.control) == true {
            let moc = section.managedObjectContext
            if flags?.contains(.option) == true {
                for child in section.children {
                    moc?.delete(child)
                }
            }
            moc?.delete(section)
            
        }
        else if flags?.contains(.shift) == true {
            
            if self.resultsController.numberOfSections > 1 && flags?.contains(.command) == true {
                
                var other = ip._section == self.resultsController.numberOfSections - 1
                    ? IndexPath.for(section: ip._section - 1)
                    : IndexPath.for(section: ip._section + 1)
                
                let p2 = resultsController.sectionInfo(forSectionAt: other)?.object  as! Parent
                let temp = p2.displayOrder
                p2.displayOrder = section.displayOrder
                section.displayOrder = temp
                return
            }
            
            
            let newParent = Parent.create()
            var order = section.displayOrder.intValue
            newParent.displayOrder = NSNumber(value: order)
            
            order += 1
            for idx in ip._section..<resultsController.numberOfSections {
                if let p = resultsController.sectionInfo(forSectionAt: IndexPath.for(section: idx))?.object as? Parent {
                    p.displayOrder = NSNumber(value: order)
                    
                }
                order += 1
            }
        }
        else {
            let count = flags?.contains(.option) == true ? 100 : 1
            repeatBlock(count) {
                _ = section.createChild()
            }
        }
    }
    
    
    
    
    
    // MARK: - Collection View Data Source
    /*-------------------------------------------------------------------------------*/
    
    override func numberOfSections(in collectionView: CollectionView) -> Int {
        return resultsController.numberOfSections
    }
    
    override func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int {
        return resultsController.numberOfObjects(in: section)
    }
    
    func collectionView(_ collectionView: CollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> CollectionReusableView {
        
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "BasicHeaderView", for: indexPath) as! BasicHeaderView
        
        let str = resultsController.sectionName(forSectionAt: indexPath)
        view.titleLabel.font = NSFont.boldSystemFont(ofSize: 14)
        view.titleLabel.stringValue = str
        
        view.titleInset = 16
        view.drawBorder = true
        view.accessoryButton.setIcon(.add, animated: false)
        view.delegate = self
        view.accessoryButton.isHidden = !relational || relationalResultsController.object(forSectionAt: indexPath) == nil
        
        return view
    }
    
    override func collectionView(_ collectionView: CollectionView, cellForItemAt indexPath: IndexPath) -> CollectionViewCell {
        
        
        let child = resultsController.object(at: indexPath) as! Child
        
        if collectionView.collectionViewLayout is CollectionViewFlowLayout {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GridCell", for: indexPath) as! GridCell
            
            cell.setup(with: child)
            return cell
        }
                
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ListCell", for: indexPath) as! ListCell
        cell.restingBackgroundColor = NSColor(white: 0.98, alpha: 1)
        cell.highlightedBackgroundColor = NSColor(white: 0.95, alpha: 1)
        cell.selectedBackgroundColor = NSColor(white: 0.95, alpha: 1)
       
        if !cell.reused {
            cell.inset = 16
            cell.style = .split
            cell.titleLabel.font = NSFont.systemFont(ofSize: 12, weight: NSFontWeightThin)
        }
        
//        cell.titleLabel.bind("stringValue", to: child, withKeyPath: "displayOrder", options: nil)
        cell.detailLabel.stringValue = "\(child.idString) \(child.dateString) -- \(indexPath)"
        
        return cell
    }
    
    
    
    func collectionView(_ collectionView: CollectionView, gridLayout: CollectionViewFlowLayout, styleForItemAt indexPath: IndexPath) -> CollectionViewFlowLayout.ItemStyle {
        
        if indexPath._item % 20 == 0 {
            return .span(CGSize(width: collectionView.frame.size.width, height: 50))
        }
        
        let item = resultsController.object(at: indexPath) as! Child
        
        let displaySize = (CGFloat(Int(item.second.floatValue/3 + 1)))
        
        let size : CGFloat = 100 // (displaySize * (30 + (displaySize * 15))) + 80
        return .flow(CGSize(width: size  + (50 * CGFloat(indexPath._item % 5)), height: size))
    }
    
    func collectionView(_ collectionView: CollectionView, flowLayout collectionViewLayout: CollectionViewFlowLayout, insetsForSectionAt section: Int) -> EdgeInsets {
        return EdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    }
    
    func collectionView(_ collectionView: CollectionView, flowLayout collectionViewLayout: CollectionViewFlowLayout, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    func collectionView(_ collectionView: CollectionView, flowLayout collectionViewLayout: CollectionViewFlowLayout, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    
    // MARK: - Layout Delegate
    /*-------------------------------------------------------------------------------*/
    
    
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, numberOfColumnsInSection section: Int) -> Int {
        let f = Float(self.view.frame.size.width/150)
        return Int(floor(f))
    }


    // MARK: - Collection View Delegate
    /*-------------------------------------------------------------------------------*/
    
    func collectionView(_ collectionView: CollectionView, didSelectItemAt indexPath: IndexPath) {
        
        
    }
    
    
    
    var _rightClicked : IndexPath?
    func collectionView(_ collectionView: CollectionView, didRightClickItemAt indexPath: IndexPath, with event: NSEvent) {
        
        guard self.relational else { return }
        
        _rightClicked = nil
        
        guard self.resultsController.object(at: indexPath) is Child,
            let cell = collectionView.cellForItem(at: indexPath) else {
            return
        }
        _rightClicked = indexPath
        
        let menu = NSMenu()
        menu.autoenablesItems = false
        
        let layout = collectionView.collectionViewLayout
        
        let front = menu.addItem(withTitle: "Move to front", action: #selector(moveItemToFront(_:)), keyEquivalent: "")
        let end = menu.addItem(withTitle: "Move to end", action: #selector(moveItemToEnd(_:)), keyEquivalent: "")
        
        front.isEnabled = indexPath._item > 0
        end.isEnabled = indexPath._item < resultsController.numberOfObjects(in: indexPath._section)
        
        menu.addItem(NSMenuItem.separator())
        
        let left = menu.addItem(withTitle: "Move Left", action: #selector(moveItemLeft(_:)), keyEquivalent: "")
        let right = menu.addItem(withTitle: "Move Right", action: #selector(moveItemRight(_:)), keyEquivalent: "")
        let up = menu.addItem(withTitle: "Move Up", action: #selector(moveItemUp(_:)), keyEquivalent: "")
        let down = menu.addItem(withTitle: "Move Down", action: #selector(moveItemDown(_:)), keyEquivalent: "")
        
        left.isEnabled = layout.indexPathForNextItem(moving: .left, from: indexPath) != nil
        right.isEnabled = layout.indexPathForNextItem(moving: .right, from: indexPath) != nil
        up.isEnabled = layout.indexPathForNextItem(moving: .up, from: indexPath) != nil
        down.isEnabled = layout.indexPathForNextItem(moving: .down, from: indexPath) != nil
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Insert Before", action: #selector(insertBefore(_:)), keyEquivalent: "")
        menu.addItem(withTitle: "Insert After", action: #selector(insertAfter(_:)), keyEquivalent: "")
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Delete", action: #selector(deleteItem(_:)), keyEquivalent: "")
        
        let loc = cell.convert(event.locationInWindow, from: nil)
        menu.popUp(positioning: nil, at: loc, in: cell)
    }
    
    
    func moveItemToFront(_ sender: Any?) {
        guard let ip = _rightClicked, let item = resultsController.object(at: ip) as? Child else { return }
        guard let first = resultsController.object(at: ip.sectionCopy) as? Child, first != item else { return }
        item.displayOrder = NSNumber(value: first.displayOrder.intValue - 10)
    }
    func moveItemToEnd(_ sender: Any?) {
        guard let ip = _rightClicked, let item = resultsController.object(at: ip) as? Child else { return }
        let endIP = IndexPath.for(item: resultsController.numberOfObjects(in: ip._section) - 1, section: ip._section)
        guard let last = resultsController.object(at: endIP) as? Child, last != item else { return }
        item.displayOrder = NSNumber(value: last.displayOrder.intValue + 10)
    }
    
    func insertBefore(_ sender: Any?) {
        insertItem(before: true)
    }
    
    func insertAfter(_ sender: Any?) {
        insertItem(before: false)
    }
    
    func insertItem(before: Bool) {
        guard let source = _rightClicked,
            let child = self.resultsController.object(at: source) as? Child,
            let parent = child.parent else {
                return
        }
        
        let new = Child.createOrphan()
        new.parent = parent
        let adjust = before ? 0 : 1
        let insert = child.displayOrder.intValue + adjust
        new.displayOrder = NSNumber(value: insert)
        
        let start = before ? source._item : source._item + 1
        
        for idx in start..<resultsController.numberOfObjects(in: source._section) {
            (resultsController.object(at: IndexPath.for(item: idx, section: source._section)) as? Child)?.displayOrder = NSNumber(value: idx + 1)
        }
    }
    
    func deleteItem(_ sender: Any?) {
        guard let source = _rightClicked,
            let child = self.resultsController.object(at: source) as? Child else {
                return
        }
        child.managedObjectContext?.delete(child)
    }
    
    func moveItemLeft(_ sender: Any?) { moveItem(in: .left) }
    func moveItemRight(_ sender: Any?) { moveItem(in: .right) }
    func moveItemUp(_ sender: Any?) { self.moveItem(in: .up) }
    func moveItemDown(_ sender: Any?) { moveItem(in: .down) }
    
    func moveItem(in direction : CollectionViewDirection, count: Int? = nil) {
        guard let source = _rightClicked,
            let child = self.resultsController.object(at: source) as? Child else {
                return
        }
        
        var destination = source
        let count = count ?? (NSApp.currentEvent?.modifierFlags.contains(.option) == true ? 2 : 1)
        
        for _ in 0..<count {
            if let _possible = collectionView.collectionViewLayout.indexPathForNextItem(moving: direction, from: destination) {
                destination = _possible
            }
            else { break }
        }
        
        guard destination != source else {
            print("Cannot move item \(direction)")
            return
        }
        
        if source._section == destination._section {
            let start = min(source._item, destination._item)
            let end = max(source._item, destination._item)
            
//            let adjust = source._item < destination._item ? -1 : 1
            
            let s = source._item
            let d = destination._item
            
            for idx in start...end {

                guard idx != source._item else { continue }
                let ip = IndexPath.for(item: idx, section: source._section)
                if let child = resultsController.object(at: ip) as? Child {
                    var adjust = 0
                    if idx > s  && idx <= d { // -1
                        adjust = -1
                    }
                    else if idx < s && idx >= d { // +1
                        adjust = +1
                    }
                    child.displayOrder = NSNumber(value: idx + adjust)
                }
            }
        }
        else {
            child.parent = self.resultsController.sectionInfo(forSectionAt: destination)?.object as? Parent
            
            for idx in source._item..<resultsController.numberOfObjects(in: source._section) {
                let ip = IndexPath.for(item: idx, section: source._section)
                if let child = resultsController.object(at: ip) as? Child {
                    child.displayOrder = NSNumber(value: idx - 1)
                }
            }
            for idx in destination._item..<resultsController.numberOfObjects(in: destination._section) {
                let ip = IndexPath.for(item: idx, section: destination._section)
                if let child = resultsController.object(at: ip) as? Child {
                    child.displayOrder = NSNumber(value: idx + 1)
                }
            }
        }
        child.displayOrder = NSNumber(value: destination._item)

        // Swapping
//        if let previous = self.resultsController.object(at: next) as? Child {
//            if next._section != indexPath._section {
//                let tParent = child.parent
//                child.parent = previous.parent
//                previous.parent = tParent
//            }
//            
//            let temp = child.displayOrder
//            child.displayOrder = previous.displayOrder
//            previous.displayOrder = temp
//        }
        
        
    }
    

    
    
    
    lazy var previewController : CollectionViewPreviewController = {
        let controller =  CollectionViewPreviewController()
        GridCell.register(in: controller.collectionView)
        return controller
    }()
    
    var isPreviewing = false
    
    @IBAction func togglePreview(_ sender: AnyObject) {
        if isPreviewing {
            closePreview()
        }
        else if let ip = collectionView.indexPathsForSelectedItems.first {
            enterPreview(for: ip)
        }
    }
    
    func enterPreview(for indexPath: IndexPath) {
        if isPreviewing { return }

        // If you need to restrict which items can be previewed
//        let isItemPreviewable: Bool = true
//        if !isItemPreviewable { return }
        
        self.isPreviewing = true
        self.previewController.present(in: self, source: self.collectionView, indexPath: indexPath)
    }
    
    func closePreview(animated: Bool = true) {
        if !isPreviewing { return }
        isPreviewing = false
        
        // Scrolls the source collection view to the item that was being previewed
        if let final = self.previewController.currentIndexPath, let source = self.previewController.sourceIndexPath  {
            if final != source && !self.collectionView.itemAtIndexPathIsVisible(final) {
                self.collectionView.scrollItem(at:final, to: .centered, animated: false, completion: nil)
            }
            self.collectionView.deselectAllItems()
            self.collectionView.selectItem(at: final, animated: false, scrollPosition: .nearest)
        }
        
        self.previewController.dismiss(animated: true)
        self.view.window?.makeFirstResponder(self.collectionView)
    }
    
    func collectionViewPreviewController(_ controller: CollectionViewPreviewController, canPreviewItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionViewPreviewController(_ controller: CollectionViewPreviewController, cellForItemAt indexPath: IndexPath) -> CollectionViewCell {
        
        let child = resultsController.object(at: indexPath) as! Child
        let cell = GridCell.deque(for: indexPath, in: controller.collectionView) as! GridCell
        
        cell.setup(with: child)
        return cell
    }
    
    


    // MARK: - ResultsController
    /*-------------------------------------------------------------------------------*/
    // This implementation uses a number of helpers that make tracking and applying changes
    // reported by the results controller easy to manage.
    
    var changes = ResultsChangeSet()
    
    func controllerWillChangeContent(controller: ResultsController) {
        changes.removeAll()
    }
    
    func controller(_ controller: ResultsController, didChangeObject object: Any, at indexPath: IndexPath?, for changeType: ResultsControllerChangeType) {
        changes.addChange(forItemAt: indexPath, with: changeType)
    }
    
    func controller(_ controller: ResultsController, didChangeSection section: ResultsControllerSectionInfo, at indexPath: IndexPath?, for changeType: ResultsControllerChangeType) {
        changes.addChange(forSectionAt: indexPath, with: changeType)
    }
    
    func controllerDidChangeContent(controller: ResultsController) {

        // This is a helper to apply all the item and section changes.
        // See documentation for ChangeSets for more info
        collectionView.applyChanges(from: changes)
    }
    
    
    

}

