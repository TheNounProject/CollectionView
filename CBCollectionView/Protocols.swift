//
//  Protocols.swift
//  CBCollectionView
//
//  Created by Wesley Byrne on 9/1/16.
//  Copyright © 2016 Noun Project. All rights reserved.
//

import Foundation




@objc public protocol CBCollectionViewDataSource {
    func numberOfSectionsInCollectionView(_ collectionView: CBCollectionView) -> Int
    func collectionView(_ collectionView: CBCollectionView, numberOfItemsInSection section: Int) -> Int
    func collectionView(_ collectionView: CBCollectionView, cellForItemAtIndexPath indexPath: IndexPath) -> CBCollectionViewCell
    @objc optional func collectionView(_ collectionView: CBCollectionView, viewForSupplementaryElementOfKind kind: String, forIndexPath indexPath: IndexPath) -> CBCollectionReusableView
    @objc optional func collectionView(_ collectionView: CBCollectionView, pasteboardWriterForItemAtIndexPath indexPath: IndexPath) -> NSPasteboardWriting?
    @objc optional func collectionView(_ collectionView: CBCollectionView, dragContentsForItemAtIndexPath indexPath: IndexPath) -> NSImage?
    @objc optional func collectionView(_ collectionView: CBCollectionView, dragRectForItemAtIndexPath indexPath: IndexPath, withStartingRect rect: UnsafeMutablePointer<CGRect>)
}
@objc public protocol CBCollectionViewDelegate {
    
    @objc optional func collectionViewWillReloadData(_ collectionView: CBCollectionView)
    @objc optional func collectionViewDidReloadData(_ collectionView: CBCollectionView)
    @objc optional func collectionView(_ collectionView: CBCollectionView, didChangeFirstResponderStatus firstResponder: Bool)
    
    @objc optional func collectionView(_ collectionView: CBCollectionView, mouseMovedToSection indexPath: IndexPath?)
    
    @objc optional func collectionView(_ collectionView: CBCollectionView, mouseDownInItemAtIndexPath indexPath: IndexPath?, withEvent: NSEvent)
    @objc optional func collectionView(_ collectionView: CBCollectionView, mouseUpInItemAtIndexPath indexPath: IndexPath?, withEvent: NSEvent)
    @objc optional func collectionView(_ collectionView: CBCollectionView, didDoubleClickItemAtIndexPath indexPath: IndexPath, withEvent: NSEvent)
    
    @objc optional func collectionView(_ collectionView: CBCollectionView, shouldHighlightItemAtIndexPath indexPath: IndexPath) -> Bool
    @objc optional func collectionView(_ collectionView: CBCollectionView, shouldSelectItemAtIndexPath indexPath: IndexPath, withEvent: NSEvent?) -> Bool
    @objc optional func collectionView(_ collectionView: CBCollectionView, pressureChanged pressure: CGFloat, forItemAt indexPath: IndexPath)
    @objc optional func collectionView(_ collectionView: CBCollectionView, didSelectItemAtIndexPath indexPath: IndexPath)
    @objc optional func collectionView(_ collectionView: CBCollectionView, shouldDeselectItemAtIndexPath indexPath: IndexPath) -> Bool
    @objc optional func collectionView(_ collectionView: CBCollectionView, didDeselectItemAtIndexPath indexPath: IndexPath)
    
    @objc optional func collectionView(_ collectionView: CBCollectionView, didRightClickItemAtIndexPath indexPath: IndexPath, withEvent: NSEvent)
    
    @objc optional func collectionView(_ collectionView: CBCollectionView, shouldScrollToItemAtIndexPath indexPath: IndexPath) -> Bool
    @objc optional func collectionViewLayoutAnchor(_ collectionView: CBCollectionView) -> IndexPath?
    @objc optional func collectionView(_ collectionView: CBCollectionView, didScrollToItemAtIndexPath indexPath: IndexPath)
    
    @objc optional func collectionView(_ collectionView: CBCollectionView, willDisplayCell cell:CBCollectionViewCell, forItemAtIndexPath indexPath: IndexPath)
    @objc optional func collectionView(_ collectionView: CBCollectionView, willDisplaySupplementaryView view:CBCollectionReusableView, forElementKind elementKind: String, atIndexPath indexPath: IndexPath)
    @objc optional func collectionView(_ collectionView: CBCollectionView, didEndDisplayingCell cell: CBCollectionViewCell, forItemAtIndexPath indexPath: IndexPath)
    @objc optional func collectionView(_ collectionView: CBCollectionView, didEndDisplayingSupplementaryView view: CBCollectionReusableView, forElementOfKind elementKind: String, atIndexPath indexPath: IndexPath)
    
    @objc optional func collectionViewDidEndLiveResize(_ collectionView: CBCollectionView)
    
    @objc optional func collectionViewDidScroll(_ collectionView: CBCollectionView)
    @objc optional func collectionViewWillBeginScrolling(_ collectionView: CBCollectionView)
    @objc optional func collectionViewDidEndScrolling(_ collectionView: CBCollectionView, animated: Bool)
}

@objc public protocol CBCollectionViewInteractionDelegate : CBCollectionViewDelegate {
    @objc optional func collectionView(_ collectionView: CBCollectionView, shouldBeginDraggingAtIndexPath indexPath: IndexPath, withEvent event: NSEvent) ->Bool
    @objc optional func collectionView(_ collectionView: CBCollectionView, draggingSession session: NSDraggingSession, willBeginAtPoint point: NSPoint)
    @objc optional func collectionView(_ collectionView: CBCollectionView, draggingSession session: NSDraggingSession, enedAtPoint screenPoint: NSPoint, withOperation operation: NSDragOperation, draggedIndexPaths: [IndexPath])
    @objc optional func collectionView(_ collectionView: CBCollectionView, draggingSession session: NSDraggingSession, didMoveToPoint point: NSPoint)
    
    @objc optional func collectionView(_ collectionView: CBCollectionView, dragEntered dragInfo: NSDraggingInfo) -> NSDragOperation
    @objc optional func collectionView(_ collectionView: CBCollectionView, dragUpdated dragInfo: NSDraggingInfo) -> NSDragOperation
    @objc optional func collectionView(_ collectionView: CBCollectionView, dragExited dragInfo: NSDraggingInfo?)
    @objc optional func collectionView(_ collectionView: CBCollectionView, dragEnded dragInfo: NSDraggingInfo?)
    @objc optional func collectionView(_ collectionView: CBCollectionView, performDragOperation dragInfo: NSDraggingInfo) -> Bool
}

