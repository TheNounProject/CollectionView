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
    func numberOfSections(in collectionView: CollectionView) -> Int
    func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int
    func collectionView(_ collectionView: CollectionView, cellForItemAt indexPath: IndexPath) -> CollectionViewCell
    @objc optional func collectionView(_ collectionView: CollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> CollectionReusableView
    @objc optional func collectionView(_ collectionView: CollectionView, pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting?
    @objc optional func collectionView(_ collectionView: CollectionView, dragContentsForItemAt indexPath: IndexPath) -> NSImage?
    @objc optional func collectionView(_ collectionView: CollectionView, dragRectForItemAt indexPath: IndexPath, withStartingRect rect: UnsafeMutablePointer<CGRect>)
}
@objc public protocol CollectionViewDelegate {
    
    @objc optional func collectionViewWillReloadData(_ collectionView: CollectionView)
    @objc optional func collectionViewDidReloadData(_ collectionView: CollectionView)
    @objc optional func collectionView(_ collectionView: CollectionView, didChangeFirstResponderStatus firstResponder: Bool)
    
    @objc optional func collectionView(_ collectionView: CollectionView, mouseMovedToSection indexPath: IndexPath?)
    
    @objc optional func collectionView(_ collectionView: CollectionView, mouseDownInItemAt indexPath: IndexPath?, with event: NSEvent)
    @objc optional func collectionView(_ collectionView: CollectionView, mouseUpInItemAt indexPath: IndexPath?, with event: NSEvent)
    
    @objc optional func collectionView(_ collectionView: CollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool
    
    @objc optional func collectionView(_ collectionView: CollectionView, shouldSelectItemAt indexPath: IndexPath, with event: NSEvent?) -> Bool
    @objc optional func collectionView(_ collectionView: CollectionView, didSelectItemAt indexPath: IndexPath)
    
    @objc optional func collectionView(_ collectionView: CollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool
    @objc optional func collectionView(_ collectionView: CollectionView, didDeselectItemAt indexPath: IndexPath)
    
    @objc optional func collectionView(_ collectionView: CollectionView, didChangePressure pressure: CGFloat, forItemAt indexPath: IndexPath)
    
    @objc optional func collectionView(_ collectionView: CollectionView, didDoubleClickItemAt indexPath: IndexPath, with event: NSEvent)
    @objc optional func collectionView(_ collectionView: CollectionView, didRightClickItemAt indexPath: IndexPath, with event: NSEvent)
    
    @objc optional func collectionView(_ collectionView: CollectionView, shouldScrollToItemAt indexPath: IndexPath) -> Bool
    @objc optional func collectionViewLayoutAnchor(_ collectionView: CollectionView) -> IndexPath?
    @objc optional func collectionView(_ collectionView: CollectionView, didScrollToItemAt indexPath: IndexPath)
    
    @objc optional func collectionView(_ collectionView: CollectionView, willDisplayCell cell:CollectionViewCell, forItemAt indexPath: IndexPath)
    @objc optional func collectionView(_ collectionView: CollectionView, willDisplaySupplementaryView view:CollectionReusableView, ofElementKind elementKind: String, at indexPath: IndexPath)
    @objc optional func collectionView(_ collectionView: CollectionView, didEndDisplayingCell cell: CollectionViewCell, forItemAt indexPath: IndexPath)
    @objc optional func collectionView(_ collectionView: CollectionView, didEndDisplayingSupplementaryView view: CollectionReusableView, ofElementKind elementKind: String, at indexPath: IndexPath)
    
    @objc optional func collectionViewDidEndLiveResize(_ collectionView: CollectionView)
    
    @objc optional func collectionViewDidScroll(_ collectionView: CollectionView)
    @objc optional func collectionViewWillBeginScrolling(_ collectionView: CollectionView)
    @objc optional func collectionViewDidEndScrolling(_ collectionView: CollectionView, animated: Bool)
}

@objc public protocol CollectionViewInteractionDelegate : CollectionViewDelegate {
    @objc optional func collectionView(_ collectionView: CollectionView, shouldBeginDraggingAt indexPath: IndexPath, with event: NSEvent) ->Bool
    @objc optional func collectionView(_ collectionView: CollectionView, draggingSession session: NSDraggingSession, willBeginAt point: NSPoint)
    @objc optional func collectionView(_ collectionView: CollectionView, draggingSession session: NSDraggingSession, didEndAt screenPoint: NSPoint, with operation: NSDragOperation, draggedIndexPaths: [IndexPath])
    @objc optional func collectionView(_ collectionView: CollectionView, draggingSession session: NSDraggingSession, didMoveTo point: NSPoint)
    
    @objc optional func collectionView(_ collectionView: CollectionView, dragEntered dragInfo: NSDraggingInfo) -> NSDragOperation
    @objc optional func collectionView(_ collectionView: CollectionView, dragUpdated dragInfo: NSDraggingInfo) -> NSDragOperation
    @objc optional func collectionView(_ collectionView: CollectionView, dragExited dragInfo: NSDraggingInfo?)
    @objc optional func collectionView(_ collectionView: CollectionView, dragEnded dragInfo: NSDraggingInfo?)
    @objc optional func collectionView(_ collectionView: CollectionView, performDragOperation dragInfo: NSDraggingInfo) -> Bool
}

