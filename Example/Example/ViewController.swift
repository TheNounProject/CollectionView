//
//  ViewController.swift
//  ResultsController
//
//  Created by Wesley Byrne on 1/12/17.
//  Copyright © 2017 WCB Media. All rights reserved.
//

import Cocoa
import CollectionView

class ViewController: NSViewController, ResultsControllerDelegate, CollectionViewDelegate, CollectionViewDataSource, BasicHeaderDelegate{

    @IBOutlet weak var collectionView: CollectionView!
    var relational: Bool = false
    
    let fetchedResultsController = FetchedResultsController<String, Child>(context: AppDelegate.current.managedObjectContext)
    let relationalResultsController = RelationalResultsController<Parent, Child>(context: AppDelegate.current.managedObjectContext, sectionKeyPath: "parent")
    
    
    var resultsController : ResultsController {
        return relational ? relationalResultsController : fetchedResultsController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let req = NSFetchRequest<Child>(entityName: "Child")
        
        let creationSort = NSSortDescriptor(key: "created", ascending: true)
        
        req.sortDescriptors = [creationSort]
        fetchedResultsController.sectionKeyPath = "minute"
        fetchedResultsController.fetchRequest = req
        fetchedResultsController.delegate = self
        
        try! resultsController.performFetch()
        
        let childRequest = NSFetchRequest<Child>(entityName: "Child")
        let parentRequest = NSFetchRequest<Parent>(entityName: "Parent")
        
        childRequest.sortDescriptors = [NSSortDescriptor(key: "displayOrder", ascending: true)]
        parentRequest.sortDescriptors = [NSSortDescriptor(key: "displayOrder", ascending: true)]
        
        relationalResultsController.sectionKeyPath = "parent"
        relationalResultsController.fetchRequest = childRequest
        relationalResultsController.sectionFetchRequest = parentRequest
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        let layout = CollectionViewListLayout()
        layout.itemHeight = 36
        layout.headerHeight = 36
        collectionView.collectionViewLayout = layout
        
        ListCell.register(collectionView)
        BasicHeaderView.register(collectionView)
        
        collectionView.reloadData()
    }
    
    @IBAction func toggleGroupStyle(_ sender: AnyObject?) {
        relational = !relational
        try? resultsController.performFetch()
        
        self.fetchedResultsController.delegate = relational ? nil : self
        self.relationalResultsController.delegate = relational ? self : nil
        
        self.collectionView.reloadData()
    }
    
    
    @IBAction func addParent(_ sender: AnyObject?) {
        Parent.create()
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
    
    
    
    func numberOfSectionsInCollectionView(_ collectionView: CollectionView) -> Int {
        return resultsController.numberOfSections()
    }
    
    
    func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int {
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
        view.accessoryButton.isHidden = !relational
        
        return view
    }
    

    
    func basicHeaderView(_ view: BasicHeaderView, didSelectButton button: IconButton) {
        
        guard let ip = collectionView.indexPathForSupplementaryView(view) else { return }
        guard  let section = self.resultsController.object(for: ip) as? Parent else { return }
        
        if NSApp.currentEvent?.modifierFlags.contains(.option) == true {
            section.managedObjectContext?.delete(section)
        }
        else if NSApp.currentEvent?.modifierFlags.contains(.shift) == true {
            
            let newParent = Parent.create()
            var order = section.displayOrder.intValue
            newParent.displayOrder = NSNumber(value: order)
            
            order += 1
            for idx in ip._section..<resultsController.numberOfSections() {
                if let p = resultsController.object(for: IndexPath.for(section: idx)) as? Parent {
                    p.displayOrder = NSNumber(value: order)
                    
                }
                order += 1
            }
        }
        else {
            _ = section.createChild()
        }
        
        
    }
    
    func collectionView(_ collectionView: CollectionView, cellForItemAt indexPath: IndexPath) -> CollectionViewCell {
        
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ListCell", for: indexPath) as! ListCell
        cell.restingBackgroundColor = NSColor(white: 0.98, alpha: 1)
        cell.highlightedBackgroundColor = NSColor(white: 0.95, alpha: 1)
        cell.selectedBackgroundColor = NSColor(white: 0.95, alpha: 1)
       
        if !cell.reused {
            cell.inset = 16
            cell.style = .basic
            cell.titleLabel.font = NSFont.systemFont(ofSize: 12, weight: NSFontWeightThin)
            
        }
        
        let child = resultsController.object(at: indexPath) as! Child

        cell.titleLabel.stringValue = "\(indexPath._item) - \(child.displayDescription)"
        
        return cell
        
    }
    
    
    func delete(_ sender: Any?) {
        for ip in collectionView.indexPathsForSelectedItems {
            if let item = resultsController.object(at: ip) {
                item.managedObjectContext?.delete(item)
            }
        }
    }
    
    func collectionView(_ collectionView: CollectionView, didSelectItemAt indexPath: IndexPath) {
        
        
        
    }
    
    
    var _rightClicked : IndexPath?
    func collectionView(_ collectionView: CollectionView, didRightClickItemAt indexPath: IndexPath, withEvent: NSEvent) {
        _rightClicked = nil
        guard self.resultsController.object(at: indexPath) is Child,
            let cell = collectionView.cellForItem(at: indexPath) else {
            return
        }
        _rightClicked = indexPath
        
        let menu = NSMenu()
        menu.autoenablesItems = false
        let upItem = menu.addItem(withTitle: "Move Up", action: #selector(moveItemUp(_:)), keyEquivalent: "")
        let downItem = menu.addItem(withTitle: "Move Down", action: #selector(moveItemDown(_:)), keyEquivalent: "")

        upItem.isEnabled = indexPath._item > 0
        downItem.isEnabled = indexPath._item < collectionView.numberOfItems(in: indexPath._section) - 1
        
        let loc = cell.convert(withEvent.locationInWindow, from: nil)
        menu.popUp(positioning: nil, at: loc, in: cell)
    }
    
    
    func moveItemUp(_ sender: Any?) {
        
        guard let indexPath = _rightClicked,
            let child = self.resultsController.object(at: indexPath) as? Child else {
            return
        }
        
        guard indexPath._item > 0 else {
            print("Cannot move item up - it is already first")
            return
        }
        let newIP = IndexPath.for(item: indexPath._item - 1, section: indexPath._section)
        if let previous = self.resultsController.object(at: newIP) as? Child {
            let temp = child.displayOrder
            child.displayOrder = previous.displayOrder
            previous.displayOrder = temp
        }
    }

    func moveItemDown(_ sender: Any?) {
        
        guard let indexPath = _rightClicked,
            let child = self.resultsController.object(at: indexPath) as? Child else {
                return
        }
        
        guard indexPath._item < collectionView.numberOfItems(in: indexPath._section) - 1 else {
            print("Cannot move item down - it is already last")
            return
        }
        let newIP = IndexPath.for(item: indexPath._item + 1, section: indexPath._section)
        if let previous = self.resultsController.object(at: newIP) as? Child {
            let temp = child.displayOrder
            child.displayOrder = previous.displayOrder
            previous.displayOrder = temp
        }

        
    }



    // MARK: - ResultsController
    /*-------------------------------------------------------------------------------*/
    
    var _inserts = Set<IndexPath>()
    var _deletes = Set<IndexPath>()
    var _updates = Set<IndexPath>()
    var _moves = [IndexPath: IndexPath]()
    
    var _sectionInserts = IndexSet()
    var _sectionDeletes = IndexSet()
    var _sectionUpdates = IndexSet()
    var _sectionMoves = [Int: Int]()
    
    func controllerWillChangeContent(controller: ResultsController) {
        _inserts.removeAll()
        _deletes.removeAll()
        _updates.removeAll()
        _moves.removeAll()
        _sectionInserts.removeAll()
        _sectionDeletes.removeAll()
    }
    
    func controller(_ controller: ResultsController, didChangeObject object: NSManagedObject, at indexPath: IndexPath?, for changeType: ResultsControllerChangeType) {
        
        switch changeType {
        case .delete:
            _deletes.insert(indexPath!)
            
        case .update:
            _updates.insert(indexPath!)
            
        case let .move(newIndexPath):
            _moves[indexPath!] = newIndexPath
            
        case let .insert(newIndexPath):
            _inserts.insert(newIndexPath)
        }
    }
    
    func controller(_ controller: ResultsController, didChangeSection section: ResultsControllerSection, at indexPath: IndexPath?, for changeType: ResultsControllerChangeType) {
        
        switch changeType {
        case .delete:
            _sectionDeletes.insert(indexPath!._section)
            
        case .update:
            _sectionUpdates.insert(indexPath!._section)
            break;
            
        case let .move(newIndexPath):
            _sectionMoves[indexPath!._section] = newIndexPath._section
            
        case let .insert(newIndexPath):
            _sectionInserts.insert(newIndexPath._section)
        }
        
    }
    
    func controllerDidChangeContent(controller: ResultsController) {
        
        collectionView.performBatchUpdates({ 
            
            self.collectionView.deleteSections(_sectionDeletes, animated: true)
            self.collectionView.insertSections(_sectionInserts, animated: true)
            
            self.collectionView.reloadSupplementaryViews(in: _sectionUpdates, animated: true)
            
            self.collectionView.insertItems(at: Array(_inserts), animated: true)
            self.collectionView.deleteItems(at: Array(_deletes), animated: true)
//            self.collectionView.reloadItems(at: Array(_updates), animated: true)
            
            for move in _moves {
                self.collectionView.moveItem(at: move.key, to: move.value, animated: true)
            }
            
        }, completion: nil)
        
        
    }
    
    
    

}

