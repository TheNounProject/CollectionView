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

class WindowController: NSWindowController {
    
    override func windowDidLoad() {
        super.windowDidLoad()

        fetchedController.view.frame.size = self.window!.frame.size
        self.contentViewController = fetchedController
    }
    
    lazy var fetchedController: FetchedController = {
        return FetchedController()
    }()
    lazy var relationalController: RelationalController = {
        return RelationalController()
    }()
    
    @IBAction func radomize(_ sender: Any?) {
        
        let moc = AppDelegate.current.managedObjectContext
        let parents = (try! moc.fetch(Parent.fetchRequest()) as! [Parent]).shuffled()
        var children = (try! moc.fetch(Child.fetchRequest()) as! [Child]).shuffled()
        let _children = children
        
        if children.count > 0 {
            let removed = children.sample(0.2)
            for del in removed {
                moc.delete(del)
            }
            for _ in 0..<removed.count {
                let c = Child.create()
                children.append(c)
            }
        }
        
        let childrentPerParent = Int(ceil(Double(children.count)/Double(parents.count)))
        for parent in parents {
            var _n = 0
            while _n < childrentPerParent, children.count > 0 {
                let child = children.removeLast()
                child.parent = parent
                child.displayOrder = NSNumber(value: _n)
                _n += 1
            }
        }
        
        for p in parents.enumerated() {
            p.element.displayOrder = NSNumber(value: p.offset)
        }
        
        AppDelegate.current.saveAction(nil)
    }
    
    @IBAction func addChild(_ sender: AnyObject?) {
        let count = NSApp.currentEvent?.modifierFlags.contains(.option) == true ? 5 : 1
        repeatBlock(count) {
            _ = Child.create()
        }
    }
    
    @IBAction func addParent(_ sender: AnyObject?) {
        let count = NSApp.currentEvent?.modifierFlags.contains(.option) == true ? 5 : 1
        repeatBlock(count) {
            _ = Parent.create()
        }
    }
    
    @IBAction func groupSelectorChanged(_ sender: NSSegmentedControl) {
        
        var layout: BaseController.Layout = {
            let idx = (self.window?.toolbar?.items[0].view as? NSSegmentedControl)?.selectedSegment ?? 0
            switch idx {
            case 1: return .flow
            case 2: return .column
            default: return .list
            }
        }()
        
        if sender.selectedSegment == 0 {
            fetchedController.view.frame.size = self.window!.frame.size
            self.fetchedController.content.setSectionKeyPath(nil)
            self.fetchedController.setLayout(type: layout)
            self.fetchedController.reload(nil)
            self.contentViewController = fetchedController
        }
        else if sender.selectedSegment == 1 {
            fetchedController.view.frame.size = self.window!.frame.size
            self.fetchedController.content.setSectionKeyPath(\Child.second)
            self.fetchedController.setLayout(type: layout)
            self.fetchedController.reload(nil)
            self.contentViewController = fetchedController
        }
        else {
            relationalController.view.frame.size = self.window!.frame.size
            self.relationalController.setLayout(type: layout)
            self.relationalController.reload(nil)
            self.contentViewController = relationalController
        }
    }
    
}

class BaseController: CollectionViewController, CollectionViewDelegateFlowLayout, CollectionViewDelegateListLayout, CollectionViewPreviewControllerDelegate, CollectionViewDelegateColumnLayout {
    
    enum Layout {
        case list, flow, column
    }
    
    lazy var listLayout: CollectionViewListLayout = {
        let layout = CollectionViewListLayout()
        layout.itemHeight = 40
        layout.headerHeight = 50
        return layout
    }()
    lazy var flowLayout: CollectionViewFlowLayout = {
        let layout = CollectionViewFlowLayout()
        layout.defaultSectionInsets = NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        layout.defaultHeaderHeight = 50
        layout.defaultRowTransform = .none
        return layout
    }()
    lazy var columnLayout: CollectionViewColumnLayout = {
        let layout = CollectionViewColumnLayout()
        layout.layoutStrategy = .shortestFirst
        return layout
    }()
    
    var provider: CollectionViewProvider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.contentInsets.top = 70
        collectionView.collectionViewLayout = listLayout
        
        // The default way of registering cells
        collectionView.register(nib: NSNib(nibNamed: NSNib.Name(rawValue: "GridCell"), bundle: nil)!, forCellWithReuseIdentifier: "GridCell")
        
        // A shortcut way to register cells
        collectionView.register(class: ListCell.self,
                                forCellWithReuseIdentifier: "EmptyCell")
        ListCell.register(in: collectionView)
        BasicHeaderView.register(collectionView)
    }
    
    @IBAction func toggleLayout(_ sender: AnyObject?) {
        let control = self.view.window?.toolbar?.items[0].view as? NSSegmentedControl
        if self.collectionView.collectionViewLayout is CollectionViewListLayout {
            self.collectionView.collectionViewLayout = self.flowLayout
            control?.setSelected(true, forSegment: 1)
        }
        else {
            self.collectionView.collectionViewLayout = self.listLayout
            control?.setSelected(true, forSegment: 0)
        }
        self.collectionView.reloadData()
    }
    
    @IBAction func layoutSelectorChanged(_ sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 1: setLayout(type: .flow)
        case 2: setLayout(type: .column)
        default: setLayout(type: .list)
        }
        self.collectionView.reloadData()
    }
    
    func setLayout(type: Layout) {
        let layout: CollectionViewLayout = {
            switch type {
            case .list: return self.listLayout
            case .flow: return self.flowLayout
            case .column: return self.columnLayout
            }
        }()
        self.collectionView.collectionViewLayout = layout
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
    
//    var changes = CollectionViewProvider()
//    func controllerWillChangeContent(controller: ResultsController) {
//        changes.prepareForUpdates()
//    }
//
//    func controller(_ controller: ResultsController, didChangeObject object: Any, at indexPath: IndexPath?, for changeType: ResultsControllerChangeType) {
//        changes.addChange(forItemAt: indexPath, with: changeType)
//    }
//
//    func controller(_ controller: ResultsController, didChangeSection section: Any, at indexPath: IndexPath?, for changeType: ResultsControllerChangeType) {
//        changes.addChange(forSectionAt: indexPath, with: changeType)
//    }
//
//    func controllerDidChangeContent(controller: ResultsController) {
//        collectionView.applyChanges(from: changes)
//    }
    
    override func numberOfSections(in collectionView: CollectionView) -> Int {
        return provider.numberOfSections
    }
    
    override func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int {
        return provider.numberOfItems(in: section)
    }
    
    // MARK: - FlowLayout Delegate
    /*-------------------------------------------------------------------------------*/
    
    func collectionView(_ collectionView: CollectionView, flowLayout: CollectionViewFlowLayout, styleForItemAt indexPath: IndexPath) -> CollectionViewFlowLayout.ItemStyle {
        
        if provider.showEmptyState {
            return .span(collectionView.fillSize)
        }
        if provider.showEmptySection(at: indexPath) {
            return .span(CGSize(width: collectionView.bounds.size.width, height: 200))
        }
        let child = self.child(at: indexPath)!
        let variance = child.variable.intValue
        
        // semi-Randomly apply a style
        if (variance * 2) % 20  == 0 {
            return .span(CGSize(width: collectionView.frame.size.width, height: 50))
        }
        let size: CGFloat = 150
        let multiplier = CGFloat(variance % 5)
        return .flow(CGSize(width: size  + (50 * multiplier), height: size))
    }
    
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, heightForItemAt indexPath: IndexPath) -> CGFloat {
        if provider.showEmptyState {
            return collectionView.fillSize.height
        }
        if provider.showEmptySection(at: indexPath) {
            return 200
        }
        
        if collectionViewLayout is CollectionViewColumnLayout {
            let child = self.child(at: indexPath)!
            let variance = child.variable.intValue
            let size: CGFloat = 150
            let multiplier = CGFloat(variance % 5)
            return  size + (50 * multiplier)
        }
        
        return 50
    }
    
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, heightForHeaderInSection section: Int) -> CGFloat {
        if provider.showEmptyState {
            return 0
        }
        return 50
    }
    
    func collectionView(_ collectionView: CollectionView, flowLayout collectionViewLayout: CollectionViewFlowLayout, heightForHeaderInSection section: Int) -> CGFloat {
        return self.collectionView(collectionView, layout: collectionViewLayout, heightForHeaderInSection: section)
    }
    
    // MARK: - Column Layout
    /*-------------------------------------------------------------------------------*/
    
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, numberOfColumnsInSection section: Int) -> Int {
        if provider.showEmptyState {
            return 1
        }
        if provider.showEmptySection(at: IndexPath.for(section: section)) {
            return 1
        }
        return Int(collectionView.frame.size.width / 200)
        
    }
    
    // MARK: - Data Source
    /*-------------------------------------------------------------------------------*/
    
    func collectionView(_ collectionView: CollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> CollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "BasicHeaderView", for: indexPath) as! BasicHeaderView
        
        view.titleLabel.font = NSFont.boldSystemFont(ofSize: 14)
        
        view.titleInset = 16
        view.drawBorder = true
        view.accessoryButton.setIcon(.add, animated: false)
        view.accessoryButton.isHidden = true
        
        return view
    }
    
    override func collectionView(_ collectionView: CollectionView, cellForItemAt indexPath: IndexPath) -> CollectionViewCell {
        
        // If no child,
        guard let child = self.child(at: indexPath) else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmptyCell", for: indexPath) as! ListCell
            cell.style = .basic
            cell.titleLabel.alignment = .center
            cell.titleLabel.textColor = NSColor.lightGray
            cell.titleLabel.font = NSFont.boldSystemFont(ofSize: 24)
            cell.disableHighlight = true
            cell.titleLabel.stringValue = provider.showEmptyState ? "No data" : "Empty Section"
            return cell
        }
        
        if collectionView.collectionViewLayout is CollectionViewListLayout {
            let cell = ListCell.deque(for: indexPath, in: collectionView) as! ListCell
            
            if !cell.reused {
                cell.restingBackgroundColor = NSColor.controlBackgroundColor // NSColor(white: 0.98, alpha: 1)
                cell.highlightedBackgroundColor = NSColor.windowBackgroundColor
                // NSColor(white: 0.95, alpha: 1)
                //            cell.selectedBackgroundColor = NSColor.selectedContentBackgroundColor // NSColor(white: 0.95, alpha: 1)
                cell.inset = 16
                cell.style = .split
                cell.titleLabel.font = NSFont.systemFont(ofSize: 12, weight: NSFont.Weight.thin)
                cell.titleLabel.stringValue = ""
            }
            
            cell.detailLabel.stringValue = "\(child.name) \(indexPath)"
            return cell
        }
        
        let cell = GridCell.deque(for: indexPath, in: collectionView) as! GridCell
        cell.setup(with: child)
        return cell
        
    }
    
    // MARK: - Collection View Delegate
    /*-------------------------------------------------------------------------------*/
    
    func collectionView(_ collectionView: CollectionView, shouldSelectItemsAt indexPaths: Set<IndexPath>) -> Set<IndexPath> {
        return indexPaths.filter({ (ip) -> Bool in
            return self.child(at: ip) != nil
        })
    }
    
    func collectionView(_ collectionView: CollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
    // MARK: - Preview
    /*-------------------------------------------------------------------------------*/
    
    lazy var previewController: CollectionViewPreviewController = {
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
        guard self.child(at: indexPath) != nil else { return }
        
        self.isPreviewing = true
        self.previewController.present(in: self, source: self.collectionView, indexPath: indexPath)
    }
    
    func closePreview(animated: Bool = true) {
        if !isPreviewing { return }
        isPreviewing = false
        
        // Scrolls the source collection view to the item that was being previewed
        if let final = self.previewController.currentIndexPath, let source = self.previewController.sourceIndexPath {
            if final != source && !self.collectionView.itemAtIndexPathIsVisible(final) {
                self.collectionView.scrollItem(at: final, to: .centered, animated: false, completion: nil)
            }
            self.collectionView.deselectAllItems()
            self.collectionView.selectItem(at: final, animated: false, scrollPosition: .nearest)
        }
        
        self.previewController.dismiss(animated: true)
        self.view.window?.makeFirstResponder(self.collectionView)
    }
    
    func collectionViewPreviewController(_ controller: CollectionViewPreviewController, canPreviewItemAt indexPath: IndexPath) -> Bool {
        return self.child(at: indexPath) != nil
    }
    
    func collectionViewPreviewController(_ controller: CollectionViewPreviewController, cellForItemAt indexPath: IndexPath) -> CollectionViewCell {
        let child = self.child(at: indexPath)!
        let cell = GridCell.deque(for: indexPath, in: controller.collectionView) as! GridCell
        cell.setup(with: child)
        return cell
    }
    
    func collectionViewPreviewControllerWillDismiss(_ controller: CollectionViewPreviewController) {
        
    }
    
    func collectionViewPreview(_ controller: CollectionViewPreviewController, didMoveToItemAt indexPath: IndexPath) {
        
    }
    
}

extension BaseController: CollectionViewDragDelegate {
    
    func collectionView(_ collectionView: CollectionView, shouldBeginDraggingAt indexPath: IndexPath, with event: NSEvent) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: CollectionView, pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {
        return NSPasteboardItem()
    }
    
    func collectionView(_ collectionView: CollectionView, performDragOperation dragInfo: NSDraggingInfo) -> Bool {
        return false
    }
    
}
