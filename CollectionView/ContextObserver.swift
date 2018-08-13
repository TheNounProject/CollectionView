//
//  EntityObserver.swift
//  CollectionView
//
//  Created by Wesley Byrne on 8/8/18.
//  Copyright © 2018 Noun Project. All rights reserved.
//

import Foundation
import CoreData

open class ContextObserver {
    
    public var wait: Bool = true
    public var managedObjectContext: NSManagedObjectContext {
        didSet {
            if oldValue != managedObjectContext {
                self.unregister()
            }
        }
    }
    public init(context: NSManagedObjectContext) {
        self.managedObjectContext = context
    }
    open func shouldRegister() -> Bool {
        return true
    }

    private var _registered: Bool = false
    public func register() {
        guard !_registered, shouldRegister() else { return }
        self._registered = true
        ManagedObjectContextObservationCoordinator.shared.add(context: self.managedObjectContext)
        NotificationCenter.default.addObserver(self, selector: #selector(handleChangeNotification(_:)),
                                               name: ManagedObjectContextObservationCoordinator.Notification.name,
                                               object: self.managedObjectContext)
    }
    
    public func unregister() {
        guard _registered else { return }
        self._registered = false
        ManagedObjectContextObservationCoordinator.shared.remove(context: self.managedObjectContext)
        NotificationCenter.default.removeObserver(self,
                                                  name: ManagedObjectContextObservationCoordinator.Notification.name,
                                                  object: self.managedObjectContext)
    }
    
    open func process( _ changes: [NSEntityDescription: (inserted: Set<NSManagedObject>, deleted: Set<NSManagedObject>, updated: Set<NSManagedObject>)]) {
        
    }
    @objc func handleChangeNotification(_ notification: Notification) {
        guard let changes = notification.userInfo?[ManagedObjectContextObservationCoordinator.Notification.changeSetKey]
            as? [NSEntityDescription: ManagedObjectContextObservationCoordinator.EntityChangeSet] else {
            return
        }
        func run() {
            self.process(changes.mapValues {
                return (inserted: $0.inserted, deleted: $0.deleted, updated: $0.updated)
                }
            )
        }
        if wait {
            self.managedObjectContext.performAndWait { run() }
        }
        else {
            self.managedObjectContext.perform { run() }
        }
    }
}
