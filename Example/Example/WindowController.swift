//
//  WindowController.swift
//  Example
//
//  Created by Wesley Byrne on 2/22/18.
//  Copyright © 2018 Noun Project. All rights reserved.
//

import Foundation
import AppKit
import CollectionView

class WindowController : NSWindowController {
    
    
    
    
    override func windowDidLoad() {
        super.windowDidLoad()

        fetchedController.view.frame.size = self.window!.frame.size
        self.contentViewController = fetchedController
    }
    
    lazy var fetchedController : FetchedController = {
        return FetchedController()
    }()
    lazy var relationalController : RelationalController = {
        return RelationalController()
    }()
    
    
    @IBAction func radomize(_ sender: Any?) {
    /*
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
 */
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

    
    @IBAction func groupSelectorChanged(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            fetchedController.view.frame.size = self.window!.frame.size
            self.fetchedController.content.setSectionKeyPath(nil)
            self.fetchedController.reload(nil)
            self.contentViewController = fetchedController
        }
        else if sender.selectedSegment == 1 {
            fetchedController.view.frame.size = self.window!.frame.size
            self.fetchedController.content.setSectionKeyPath(\Child.second)
            self.fetchedController.reload(nil)
            self.contentViewController = fetchedController
        }
        else {
            relationalController.view.frame.size = self.window!.frame.size
            self.relationalController.reload(nil)
            self.contentViewController = relationalController
        }
    }
    
}




class BaseController : CollectionViewController, ResultsControllerDelegate, CollectionViewDelegateFlowLayout, CollectionViewDelegateListLayout {
    
    var listLayout = CollectionViewListLayout()
    var gridLayout = CollectionViewFlowLayout()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.contentInsets.top = 70
        
        listLayout.itemHeight = 36
        listLayout.headerHeight = 36
        collectionView.collectionViewLayout = listLayout
        
        // The default way of registering cells
        collectionView.register(nib: NSNib(nibNamed: NSNib.Name(rawValue: "GridCell"), bundle: nil)!, forCellWithReuseIdentifier: "GridCell")
        
        // A shortcut way to register cells
        ListCell.register(collectionView)
        BasicHeaderView.register(collectionView)
    }
    
    
    @IBAction func toggleLayout(_ sender: AnyObject?) {
        let control = self.view.window?.toolbar?.items[0].view as? NSSegmentedControl
        if self.collectionView.collectionViewLayout is CollectionViewListLayout {
            self.collectionView.collectionViewLayout = self.gridLayout
            control?.setSelected(true, forSegment: 1)
        }
        else {
            self.collectionView.collectionViewLayout = self.listLayout
            control?.setSelected(true, forSegment: 0)
        }
        self.collectionView.reloadData()
    }
    
    @IBAction func layoutSelectorChanged(_ sender: NSSegmentedControl) {
        self.collectionView.collectionViewLayout = sender.selectedSegment == 0
            ? self.listLayout
            : self.gridLayout
        self.collectionView.reloadData()
    }
    
    
    func child(at indexPath: IndexPath) -> Child? {
        return nil
    }
    
    @IBAction func delete(_ sender: Any) {
        let moc = AppDelegate.current.managedObjectContext
        for ip in self.collectionView.indexPathsForSelectedItems {
            if let c = child(at: ip) {
                moc.delete(c)
            }
        }
    }
    
    
    
    
    @IBAction func refresh(_ sender: AnyObject?) {
        collectionView.reloadData()
    }
    
    @IBAction func reload(_ sender: AnyObject?) {
        collectionView.reloadData()
    }
    
    
    
    // MARK: - Results Controller Delegate
    /*-------------------------------------------------------------------------------*/
    
    var changes = ResultsChangeSet()
    func controllerWillChangeContent(controller: ResultsController) {
        changes.removeAll()
    }
    
    func controller(_ controller: ResultsController, didChangeObject object: Any, at indexPath: IndexPath?, for changeType: ResultsControllerChangeType) {
        changes.addChange(forItemAt: indexPath, with: changeType)
    }
    
    func controller(_ controller: ResultsController, didChangeSection section: Any, at indexPath: IndexPath?, for changeType: ResultsControllerChangeType) {
        changes.addChange(forSectionAt: indexPath, with: changeType)
    }
    
    func controllerDidChangeContent(controller: ResultsController) {
        collectionView.applyChanges(from: changes)
    }
    
    
    // MARK: - List Layout Delegate
    /*-------------------------------------------------------------------------------*/
    
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, heightForItemAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    
    
    // MARK: - FlowLayout Delegate
    /*-------------------------------------------------------------------------------*/
    
    func collectionView(_ collectionView: CollectionView, flowLayout: CollectionViewFlowLayout, styleForItemAt indexPath: IndexPath) -> CollectionViewFlowLayout.ItemStyle {
        
        // Randomly apply a style
        if indexPath._item % 20 == 0 {
            return .span(CGSize(width: collectionView.frame.size.width, height: 50))
        }
        let size : CGFloat = 180
        return .flow(CGSize(width: size  + (50 * CGFloat(indexPath._item % 5)), height: size))
    }
    
    func collectionView(_ collectionView: CollectionView, flowLayout collectionViewLayout: CollectionViewFlowLayout, rowTransformForSectionAt section: Int) -> CollectionViewFlowLayout.RowTransform {
        return .none
    }
    
    func collectionView(_ collectionView: CollectionView, flowLayout collectionViewLayout: CollectionViewFlowLayout, insetsForSectionAt section: Int) -> NSEdgeInsets {
        return NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    }
    
    func collectionView(_ collectionView: CollectionView, flowLayout collectionViewLayout: CollectionViewFlowLayout, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    
    func collectionView(_ collectionView: CollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> CollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "BasicHeaderView", for: indexPath) as! BasicHeaderView
        
        view.titleLabel.font = NSFont.boldSystemFont(ofSize: 14)
        
        view.titleInset = 16
        view.drawBorder = true
        view.accessoryButton.setIcon(.add, animated: false)
        view.accessoryButton.isHidden = true
        
        return view
    }
    
    
    
    func cellFor(child: Child, at indexPath: IndexPath, in collectionView: CollectionView) -> CollectionViewCell {
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
            cell.titleLabel.font = NSFont.systemFont(ofSize: 12, weight: NSFont.Weight.thin)
        }
        
        //        cell.titleLabel.bind("stringValue", to: child, withKeyPath: "displayOrder", options: nil)
        cell.detailLabel.stringValue = "\(child.idString) \(child.dateString) -- \(indexPath)"
        return cell
    }
    
    // MARK: - Collection View Delegate
    /*-------------------------------------------------------------------------------*/
    
    func collectionView(_ collectionView: CollectionView, didSelectItemAt indexPath: IndexPath) {
        
        
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
//        let child = content.object(at: indexPath) as! Child
        let cell = GridCell.deque(for: indexPath, in: controller.collectionView) as! GridCell
//        cell.setup(with: child)
        return cell
    }
    
    func collectionViewPreviewControllerWillDismiss(_ controller: CollectionViewPreviewController) {
        
    }
    
    func collectionViewPreview(_ controller: CollectionViewPreviewController, didMoveToItemAt indexPath: IndexPath) {
        
    }
    
    

    
}


