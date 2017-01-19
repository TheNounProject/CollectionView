//
//  Protocols.swift
//  CollectionView
//
//  Created by Wesley Byrne on 9/1/16.
//  Copyright © 2016 Noun Project. All rights reserved.
//

import Foundation

// test


@objc public protocol CollectionViewDataSource {
    func numberOfSectionsInCollectionView(_ collectionView: CollectionView) -> Int
    func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int
    func collectionView(_ collectionView: CollectionView, cellForItemAtIndexPath indexPath: IndexPath) -> CollectionViewCell
    @objc optional func collectionView(_ collectionView: CollectionView, viewForSupplementaryElementOfKind kind: String, forIndexPath indexPath: IndexPath) -> CollectionReusableView
    @objc optional func collectionView(_ collectionView: CollectionView, pasteboardWriterForItemAtIndexPath indexPath: IndexPath) -> NSPasteboardWriting?
    @objc optional func collectionView(_ collectionView: CollectionView, dragContentsForItemAtIndexPath indexPath: IndexPath) -> NSImage?
    @objc optional func collectionView(_ collectionView: CollectionView, dragRectForItemAtIndexPath indexPath: IndexPath, withStartingRect rect: UnsafeMutablePointer<CGRect>)
}
@objc public protocol CollectionViewDelegate {
    
    @objc optional func collectionViewWillReloadData(_ collectionView: CollectionView)
    @objc optional func collectionViewDidReloadData(_ collectionView: CollectionView)
    @objc optional func collectionView(_ collectionView: CollectionView, didChangeFirstResponderStatus firstResponder: Bool)
    
    @objc optional func collectionView(_ collectionView: CollectionView, mouseMovedToSection indexPath: IndexPath?)
    
    @objc optional func collectionView(_ collectionView: CollectionView, mouseDownInItemAtIndexPath indexPath: IndexPath?, withEvent: NSEvent)
    @objc optional func collectionView(_ collectionView: CollectionView, mouseUpInItemAtIndexPath indexPath: IndexPath?, withEvent: NSEvent)
    @objc optional func collectionView(_ collectionView: CollectionView, didDoubleClickItemAtIndexPath indexPath: IndexPath, withEvent: NSEvent)
    
    @objc optional func collectionView(_ collectionView: CollectionView, shouldHighlightItemAtIndexPath indexPath: IndexPath) -> Bool
    @objc optional func collectionView(_ collectionView: CollectionView, shouldSelectItemAtIndexPath indexPath: IndexPath, withEvent: NSEvent?) -> Bool
    @objc optional func collectionView(_ collectionView: CollectionView, pressureChanged pressure: CGFloat, forItemAt indexPath: IndexPath)
    @objc optional func collectionView(_ collectionView: CollectionView, didSelectItemAtIndexPath indexPath: IndexPath)
    @objc optional func collectionView(_ collectionView: CollectionView, shouldDeselectItemAtIndexPath indexPath: IndexPath) -> Bool
    @objc optional func collectionView(_ collectionView: CollectionView, didDeselectItemAtIndexPath indexPath: IndexPath)
    
    @objc optional func collectionView(_ collectionView: CollectionView, didRightClickItemAtIndexPath indexPath: IndexPath, withEvent: NSEvent)
    
    @objc optional func collectionView(_ collectionView: CollectionView, shouldScrollToItemAtIndexPath indexPath: IndexPath) -> Bool
    @objc optional func collectionViewLayoutAnchor(_ collectionView: CollectionView) -> IndexPath?
    @objc optional func collectionView(_ collectionView: CollectionView, didScrollToItemAtIndexPath indexPath: IndexPath)
    
    @objc optional func collectionView(_ collectionView: CollectionView, willDisplayCell cell:CollectionViewCell, forItemAtIndexPath indexPath: IndexPath)
    @objc optional func collectionView(_ collectionView: CollectionView, willDisplaySupplementaryView view:CollectionReusableView, forElementKind elementKind: String, atIndexPath indexPath: IndexPath)
    @objc optional func collectionView(_ collectionView: CollectionView, didEndDisplayingCell cell: CollectionViewCell, forItemAtIndexPath indexPath: IndexPath)
    @objc optional func collectionView(_ collectionView: CollectionView, didEndDisplayingSupplementaryView view: CollectionReusableView, forElementOfKind elementKind: String, atIndexPath indexPath: IndexPath)
    
    @objc optional func collectionViewDidEndLiveResize(_ collectionView: CollectionView)
    
    @objc optional func collectionViewDidScroll(_ collectionView: CollectionView)
    @objc optional func collectionViewWillBeginScrolling(_ collectionView: CollectionView)
    @objc optional func collectionViewDidEndScrolling(_ collectionView: CollectionView, animated: Bool)
}

@objc public protocol CollectionViewInteractionDelegate : CollectionViewDelegate {
    @objc optional func collectionView(_ collectionView: CollectionView, shouldBeginDraggingAtIndexPath indexPath: IndexPath, withEvent event: NSEvent) ->Bool
    @objc optional func collectionView(_ collectionView: CollectionView, draggingSession session: NSDraggingSession, willBeginAtPoint point: NSPoint)
    @objc optional func collectionView(_ collectionView: CollectionView, draggingSession session: NSDraggingSession, enedAtPoint screenPoint: NSPoint, withOperation operation: NSDragOperation, draggedIndexPaths: [IndexPath])
    @objc optional func collectionView(_ collectionView: CollectionView, draggingSession session: NSDraggingSession, didMoveToPoint point: NSPoint)
    
    @objc optional func collectionView(_ collectionView: CollectionView, dragEntered dragInfo: NSDraggingInfo) -> NSDragOperation
    @objc optional func collectionView(_ collectionView: CollectionView, dragUpdated dragInfo: NSDraggingInfo) -> NSDragOperation
    @objc optional func collectionView(_ collectionView: CollectionView, dragExited dragInfo: NSDraggingInfo?)
    @objc optional func collectionView(_ collectionView: CollectionView, dragEnded dragInfo: NSDraggingInfo?)
    @objc optional func collectionView(_ collectionView: CollectionView, performDragOperation dragInfo: NSDraggingInfo) -> Bool
}

