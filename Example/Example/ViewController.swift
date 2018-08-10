//
//  ViewController.swift
//  ResultsController
//
//  Created by Wesley Byrne on 1/12/17.
//  Copyright © 2017 WCB Media. All rights reserved.
//

import Cocoa
import CollectionView

class ViewController: CollectionViewController, ResultsControllerDelegate, BasicHeaderDelegate, CollectionViewDelegateColumnLayout, CollectionViewDelegateFlowLayout, CollectionViewPreviewControllerDelegate {

    var relational: Bool = false
    
    let fetchedResultsController = FetchedResultsController<NSNumber, Child>(context: AppDelegate.current.managedObjectContext, request: NSFetchRequest<Child>(entityName: "Child"))
    let relationalResultsController = RelationalResultsController(context: AppDelegate.current.managedObjectContext,
                                                                                 request: NSFetchRequest<Child>(entityName: "Child"),
                                                                                 sectionRequest: NSFetchRequest<Parent>(entityName: "Parent"),
                                                                                 sectionKeyPath: \Child.parent2)
    
    var resultsController: ResultsController {
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
        
//        try! resultsController.performFetch()
        
        relationalResultsController.fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "displayOrder", ascending: true)
        ]
        relationalResultsController.sectionFetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "displayOrder", ascending: true)
        ]
        
        relationalResultsController.sortDescriptors = [SortDescriptor(\Child.displayOrder)]
        relationalResultsController.sectionSortDescriptors = [SortDescriptor(\Parent.displayOrder)]
        
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
    
    struct Test {
        var core: [[IndexPath?]] = [
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
                nil
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
        
        var inserts: [IndexPath] = [
            IndexPath.for(item: 0, section: 0),
            IndexPath.for(item: 4, section: 1)
        ]
        
    }
    
    var test: Test?
    
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
    
    @IBAction func refresh(_ sender: AnyObject?) {
        do {
            try self.content.performFetch()
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
    
    func controller(_ controller: ResultsController, didChangeSection section: SectionInfo, at indexPath: IndexPath?, for changeType: ResultsControllerChangeType) {
        changes.addChange(forSectionAt: indexPath, with: changeType)
    }
    
    func controllerDidChangeContent(controller: ResultsController) {

        // This is a helper to apply all the item and section changes.
        // See documentation for ChangeSets for more info
        collectionView.applyChanges(from: changes)
    }

}
