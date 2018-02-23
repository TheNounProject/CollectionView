//
//  RelationalController.swift
//  Example
//
//  Created by Wesley Byrne on 2/22/18.
//  Copyright © 2018 Noun Project. All rights reserved.
//

import Foundation
import CollectionView


class RelationalController : BaseController, BasicHeaderDelegate {
    
    let content = RelationalResultsController(context: AppDelegate.current.managedObjectContext,
                                                                  request: NSFetchRequest<Child>(entityName: "Child"),
                                                                  sectionRequest: NSFetchRequest<Parent>(entityName: "Parent"),
                                                                  sectionKeyPath: \Child.parent)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        content.delegate = self
        content.fetchRequest.sortDescriptors = [NSSortDescriptor(key: "displayOrder", ascending: true)]
        content.sectionFetchRequest.sortDescriptors = [NSSortDescriptor(key: "displayOrder", ascending: true)]
        
        content.sortDescriptors = [SortDescriptor(\Child.displayOrder)]
        content.sectionSortDescriptors = [SortDescriptor(\Parent.displayOrder)]
        
        collectionView.reloadData()
    }
    
    override func child(at indexPath: IndexPath) -> Child? {
        return content.object(at: indexPath)
    }
    
    override func numberOfSections(in collectionView: CollectionView) -> Int {
        return content.numberOfSections
    }
    
    override func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int {
        return content.numberOfObjects(in: section)
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
    
    
    // MARK: - Header views
    /*-------------------------------------------------------------------------------*/
    
    override func collectionView(_ collectionView: CollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> CollectionReusableView {
        let view = super.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath) as! BasicHeaderView
        let name = content.sectionName(forSectionAt: indexPath)
        view.delegate = self
        view.titleLabel.stringValue = name
        view.accessoryButton.setIcon(.hamburger, animated: false)
        view.accessoryButton.isHidden = self.content.object(forSectionAt: indexPath) == nil
        return view
    }
    
    // Basic Header View delegate (+ button)
    func basicHeaderView(_ view: BasicHeaderView, didSelectButton button: IconButton) {
        
        guard let ip = collectionView.indexPath(forSupplementaryView: view) else { return }
        guard  let section = self.content.object(forSectionAt: ip) else { return }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem.separator())
        
        
        if ip._section > 0 {
            menu.addItem(ActionMenuItem(title: "↑ Move Up", handler: { (_) in
                let prev = self.content.object(forSectionAt: IndexPath.for(section: ip._section - 1))!
                let dest = prev.displayOrder
                prev.displayOrder = section.displayOrder
                section.displayOrder = dest
            }))
        }
        if ip._section < self.content.numberOfSections - 1 {
            menu.addItem(ActionMenuItem(title: "↓ Move Down", handler: { (_) in
                let next = self.content.object(forSectionAt: IndexPath.for(section: ip._section + 1))!
                let dest = next.displayOrder
                next.displayOrder = section.displayOrder
                section.displayOrder = dest
            }))
        }
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(ActionMenuItem(title: "Append 1 Item", handler: { (_) in
            _ = section.createChild()
        }))
        menu.addItem(ActionMenuItem(title: "Append 10 Items", handler: { (_) in
            repeatBlock(10) {
                _ = section.createChild()
            }
        }))
        menu.addItem(ActionMenuItem(title: "Append 100 Items", handler: { (_) in
            repeatBlock(100) {
                _ = section.createChild()
            }
        }))
        
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(ActionMenuItem(title: "Insert Section", handler: { (_) in
            let newParent = Parent.create()
            let order = section.displayOrder.intValue
            newParent.displayOrder = NSNumber(value: order)
        }))
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(ActionMenuItem(title: "Remove Items", handler: { (_) in
            let moc = section.managedObjectContext
            for child in section.children {
                moc?.delete(child)
            }
        }))
        menu.addItem(ActionMenuItem(title: "Remove Section", handler: { (_) in
            let moc = section.managedObjectContext
            moc?.delete(section)
        }))
        
        menu.popUp(positioning: nil, at: view.accessoryButton.frame.origin, in: view)
    }
    
    
    
    
    override func collectionView(_ collectionView: CollectionView, cellForItemAt indexPath: IndexPath) -> CollectionViewCell {
        return super.cellFor(child: content.object(at: indexPath)!, at: indexPath, in: collectionView)
    }
    
    
    func collectionView(_ collectionView: CollectionView, didRightClickItemAt indexPath: IndexPath?, with event: NSEvent) {
        guard let indexPath = indexPath,
            let _ = self.content.object(at: indexPath),
            let cell = collectionView.cellForItem(at: indexPath) else {
                return
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem.separator())
        menu.addItem(ActionMenuItem(title: "Insert Before", handler: { (_) in
            self.insertItem(at: indexPath, before: true)
        }))
        menu.addItem(ActionMenuItem(title: "Insert After", handler: { (_) in
            self.insertItem(at: indexPath, before: false)
        }))
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(ActionMenuItem(title: "Delete Item", handler: { (_) in
            self.deleteItem(at: indexPath)
        }))
        let loc = cell.convert(event.locationInWindow, from: nil)
        menu.popUp(positioning: nil, at: loc, in: cell)
    }
    
    
    func insertItem(at indexPath: IndexPath, before: Bool) {
        guard let child = self.content.object(at: indexPath),
            let parent = child.parent else { return }
        
        let new = Child.createOrphan()
        new.parent = parent
        let adjust = before ? 0 : 1
        let insert = child.displayOrder.intValue + adjust
        new.displayOrder = NSNumber(value: insert)
        
        let start = before ? indexPath._item : indexPath._item + 1
        
        for idx in start..<content.numberOfObjects(in: indexPath._section) {
            content.object(at: IndexPath.for(item: idx, section: indexPath._section))?.displayOrder = NSNumber(value: idx + 1)
        }
    }
    
    func deleteItem(at indexPath: IndexPath) {
        guard let child = self.content.object(at: indexPath) else {
            return
        }
        child.managedObjectContext?.delete(child)
    }
    
    
}
