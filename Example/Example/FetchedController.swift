//
//  FetchedController.swift
//  Example
//
//  Created by Wesley Byrne on 2/22/18.
//  Copyright © 2018 Noun Project. All rights reserved.
//

import Foundation
import CoreData
import CollectionView

class FetchedController : BaseController {
    
    let content = FetchedResultsController<NSNumber, Child>(context: AppDelegate.current.managedObjectContext,
                                                            request: NSFetchRequest<Child>(entityName: "Child"))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        content.setSectionKeyPath(\Child.second)
        let creationSort = NSSortDescriptor(key: "created", ascending: true)
        content.fetchRequest.sortDescriptors = [creationSort]
        content.sortDescriptors = [SortDescriptor(\Child.created)]
        content.sectionSortDescriptors = [SortDescriptor<NSNumber>.ascending]
        content.delegate = self
        self.reload(nil)
    }
    
    override func child(at indexPath: IndexPath) -> Child? {
        return content.object(at: indexPath)
    }
    
    override func reload(_ sender: AnyObject?) {
        do {
            try self.content.performFetch()
            super.reload(sender)
        }
        catch let err {
            let alert = NSAlert()
            alert.messageText = "Error"
            alert.informativeText = "Error code: \(err)"
            alert.addButton(withTitle: "Okay")
            alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
        }
    }
    
    override func numberOfSections(in collectionView: CollectionView) -> Int {
        return content.numberOfSections
    }
    
    override func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int {
        return content.numberOfObjects(in: section)
    }
    
    override func collectionView(_ collectionView: CollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> CollectionReusableView {
        let view = super.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath) as! BasicHeaderView
        let name = content.sectionName(forSectionAt: indexPath)
        view.titleLabel.stringValue = name
        view.accessoryButton.isHidden = true
        return view
    }
    
    override func collectionView(_ collectionView: CollectionView, cellForItemAt indexPath: IndexPath) -> CollectionViewCell {
        return super.cellFor(child: content.object(at: indexPath)!, at: indexPath, in: collectionView)
    }
    
}
