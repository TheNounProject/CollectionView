//
//  Protocols.swift
//  CBCollectionView
//
//  Created by Wesley Byrne on 9/1/16.
//  Copyright © 2016 Noun Project. All rights reserved.
//

import Foundation




@objc public protocol CBCollectionViewDataSource {
    func numberOfSectionsInCollectionView(collectionView: CBCollectionView) -> Int
    func collectionView(collectionView: CBCollectionView, numberOfItemsInSection section: Int) -> Int
    func collectionView(collectionView: CBCollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> CBCollectionViewCell!
    optional func collectionView(collectionView: CBCollectionView, viewForSupplementaryElementOfKind kind: String, forIndexPath indexPath: NSIndexPath) -> CBCollectionReusableView
    optional func collectionView(collectionView: CBCollectionView, pasteboardWriterForItemAtIndexPath indexPath: NSIndexPath) -> NSPasteboardWriting?
    optional func collectionView(collectionView: CBCollectionView, dragContentsForItemAtIndexPath indexPath: NSIndexPath) -> NSImage?
    optional func collectionView(collectionView: CBCollectionView, dragRectForItemAtIndexPath indexPath: NSIndexPath, withStartingRect rect: UnsafeMutablePointer<CGRect>)
}
@objc public protocol CBCollectionViewDelegate {
    
    optional func collectionViewDidReloadData(collectionView: CBCollectionView)
    optional func collectionView(collectionView: CBCollectionView, didChangeFirstResponderStatus firstResponder: Bool)
    
    optional func collectionView(collectionView: CBCollectionView, mouseMovedToSection indexPath: NSIndexPath?)
    
    optional func collectionView(collectionView: CBCollectionView, mouseDownInItemAtIndexPath indexPath: NSIndexPath?, withEvent: NSEvent)
    optional func collectionView(collectionView: CBCollectionView, mouseUpInItemAtIndexPath indexPath: NSIndexPath?, withEvent: NSEvent)
    optional func collectionView(collectionView: CBCollectionView, didDoubleClickItemAtIndexPath indexPath: NSIndexPath, withEvent: NSEvent)
    
    optional func collectionView(collectionView: CBCollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool
    optional func collectionView(collectionView: CBCollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath, withEvent: NSEvent?) -> Bool
    optional func collectionView(collectionView: CBCollectionView, pressureChanged pressure: CGFloat, forItemAt indexPath: NSIndexPath)
    optional func collectionView(collectionView: CBCollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    optional func collectionView(collectionView: CBCollectionView, shouldDeselectItemAtIndexPath indexPath: NSIndexPath) -> Bool
    optional func collectionView(collectionView: CBCollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath)
    
    optional func collectionView(collectionView: CBCollectionView, didRightClickItemAtIndexPath indexPath: NSIndexPath, withEvent: NSEvent)
    
    optional func collectionView(collectionView: CBCollectionView, shouldScrollToItemAtIndexPath indexPath: NSIndexPath) -> Bool
    optional func collectionViewLayoutAnchor(collectionView: CBCollectionView) -> NSIndexPath?
    optional func collectionView(collectionView: CBCollectionView, didScrollToItemAtIndexPath indexPath: NSIndexPath)
    
    optional func collectionView(collectionView: CBCollectionView, willDisplayCell cell:CBCollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath)
    optional func collectionView(collectionView: CBCollectionView, willDisplaySupplementaryView view:CBCollectionReusableView, forElementKind elementKind: String, atIndexPath indexPath: NSIndexPath)
    optional func collectionView(collectionView: CBCollectionView, didEndDisplayingCell cell: CBCollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath)
    optional func collectionView(collectionView: CBCollectionView, didEndDisplayingSupplementaryView view: CBCollectionReusableView, forElementOfKind elementKind: String, atIndexPath indexPath: NSIndexPath)
    
    optional func collectionViewDidEndLiveResize(collectionView: CBCollectionView)
    
    optional func collectionViewDidScroll(collectionView: CBCollectionView)
    optional func collectionViewWillBeginScrolling(collectionView: CBCollectionView)
    optional func collectionViewDidEndScrolling(collectionView: CBCollectionView, animated: Bool)
}

@objc public protocol CBCollectionViewInteractionDelegate : CBCollectionViewDelegate {
    optional func collectionView(collectionView: CBCollectionView, shouldBeginDraggingAtIndexPath indexPath: NSIndexPath, withEvent event: NSEvent) ->Bool
    optional func collectionView(collectionView: CBCollectionView, draggingSession session: NSDraggingSession, willBeginAtPoint point: NSPoint)
    optional func collectionView(collectionView: CBCollectionView, draggingSession session: NSDraggingSession, enedAtPoint screenPoint: NSPoint, withOperation operation: NSDragOperation, draggedIndexPaths: [NSIndexPath])
    optional func collectionView(collectionView: CBCollectionView, draggingSession session: NSDraggingSession, didMoveToPoint point: NSPoint)
    
    optional func collectionView(collectionView: CBCollectionView, dragEntered dragInfo: NSDraggingInfo) -> NSDragOperation
    optional func collectionView(collectionView: CBCollectionView, dragUpdated dragInfo: NSDraggingInfo) -> NSDragOperation
    optional func collectionView(collectionView: CBCollectionView, dragExited dragInfo: NSDraggingInfo?)
    optional func collectionView(collectionView: CBCollectionView, dragEnded dragInfo: NSDraggingInfo?)
    optional func collectionView(collectionView: CBCollectionView, performDragOperation dragInfo: NSDraggingInfo) -> Bool
}

