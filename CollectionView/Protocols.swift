//
//  Protocols.swift
//  CollectionView
//
//  Created by Wesley Byrne on 9/1/16.
//  Copyright © 2016 Noun Project. All rights reserved.
//

import Foundation


/**
 The CollectionViewDataSource is responsible for providing the data and views required by a collection view
 
 # Overview
 
 At a minimum, all data source objects must implement the numberOfSections(in:), collectionView(_:numberOfItemsInSection:) and collectionView(_:cellForItemAt:) methods. These methods are responsible for returning the number of items in the collection view along with the items themselves.
*/
@objc public protocol CollectionViewDataSource {
    
    
    // MARK: - Getting Item and Section Metrics

    /*-------------------------------------------------------------------------------*/
    
    /**
     Asks your data source for the number of sections in the collectin view

     - Parameter collectionView: The collection view requesting this information.
     
     - Returns: The number of sections in collectionView.

    */
    func numberOfSections(in collectionView: CollectionView) -> Int
    
    /**
     Asks your data source object for the number of items in the specified section.

     - Parameter collectionView: The collection view requesting this information.
     - Parameter section: An index number identifying a section in collectionView. This index value is 0-based.
     
     - Returns: The number of items in the specified section

    */
    func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int
 
    
    
    
    // MARK: - Getting Views for Items
    /*-------------------------------------------------------------------------------*/
    
    
    
    
    /**
     Asks your data source object for the cell that corresponds to the specified item in the collection view.

     - Parameter collectionView: The collection view requesting this information.
     - Parameter indexPath: The index path that specifies the location of the item.
     
     - Returns: A configured cell object. You must not return nil from this method.
     
     # Discussion
     Your implementation of this method is responsible for creating, configuring, and returning the appropriate cell for the given item. You do this by calling the dequeueReusableCell(withReuseIdentifier:for:) method of the collection view and passing the reuse identifier that corresponds to the cell type you want. That method always returns a valid cell object. Upon receiving the cell, you should set any properties that correspond to the data of the corresponding item, perform any additional needed configuration, and return the cell.
     You do not need to set the location of the cell inside the collection view’s bounds. The collection view sets the location of each cell automatically using the layout attributes provided by its layout object.

    */
    func collectionView(_ collectionView: CollectionView, cellForItemAt indexPath: IndexPath) -> CollectionViewCell
    
 
    /**
     Asks your data source object to provide a supplementary view to display in the collection view.

     - Parameter collectionView: The collection view requesting this information.
     - Parameter kind: The kind of supplementary view to provide. The value of this string is defined by the layout object that supports the supplementary view.
     - Parameter indexPath: The index path that specifies the location of the new supplementary view.
     
     - Returns: A configured supplementary view object. You must not return nil from this method.
     
     # Discussion
     Your implementation of this method is responsible for creating, configuring, and returning the appropriate supplementary view that is being requested. You do this by calling the dequeueReusableSupplementaryView(ofKind:withReuseIdentifier:for:) method of the collection view and passing the information that corresponds to the view you want. That method always returns a valid view object. Upon receiving the view, you should set any properties that correspond to the data you want to display, perform any additional needed configuration, and return the view.
     You do not need to set the location of the supplementary view inside the collection view’s bounds. The collection view sets the location of each view using the layout attributes provided by its layout object.

    */
    @objc optional func collectionView(_ collectionView: CollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> CollectionReusableView
    
    
    
    // MARK: - Dragging Items
    /*-------------------------------------------------------------------------------*/
    
    
    /**
     Asks your data source for a pasteboard writing for the item at the specified index path

     - Parameter collectionView: The collection view requesting this information.
     - Parameter indexPath: The index path of the item to represent with the pasteboard writer
     
     - Returns: An object adoption NSPasteboardWriting to represent the item, or nil

    */
    @objc optional func collectionView(_ collectionView: CollectionView, pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting?
    
    /**
     Asks the data source for the drag contents for the item at the specified index path

     - Parameter collectionView: The collection view requesting this information.
     - Parameter indexPath: The index path of the item to represent
     
     - Returns: An NSImage to display when dragging the item
     
     - Note: If nil is returned, a snapshot of the cell will be used. To disable dragging for an item return false for shouldStartDragging or remove the index path during validation

    */
    @objc optional func collectionView(_ collectionView: CollectionView, dragContentsForItemAt indexPath: IndexPath) -> NSImage?
    
    /**
     Tells the data source the current rect of the item being dragging, allowing for adjustment.

     - Parameter collectionView: The collection view requesting this information.
     - Parameter indexPath: The index path of the item being dragged
     - Parameter rect: The current rect of the item

    */
    @objc optional func collectionView(_ collectionView: CollectionView, dragRectForItemAt indexPath: IndexPath, withStartingRect rect: UnsafeMutablePointer<CGRect>)
}



/**
 The CollectionViewDelegate protocol defines methods that allow you to manage the status, selection, highlighting, and scrolling of items in a collection view and to perform actions on those items. The methods of this protocol are all optional.
*/
@objc public protocol CollectionViewDelegate {
    
    
    // MARK: - Reloading Data
    /*-------------------------------------------------------------------------------*/
    
    
    /**
     Tells the delegate that the collection view will reload it's data

     - Parameter collectionView: The collection view that will reload

    */
//    @objc optional func collectionViewWillReloadData(_ collectionView: CollectionView)
    
    
    /**
     Tells the delegate that is completed reloading it's data

     - Parameter collectionView: The collection view that was reloaded

    */
//    @objc optional func collectionViewDidReloadData(_ collectionView: CollectionView)
    
    @objc optional func collectionViewWillReloadLayout(_ collectionView: CollectionView)
    
    @objc optional func collectionViewDidReloadLayout(_ collectionView: CollectionView)
    
    // MARK: - First Responder
    /*-------------------------------------------------------------------------------*/
    
    
    /**
     Tells the delegate that the collection view became or resigned first responder

     - Parameter collectionView: The collection view changing status
     - Parameter firstResponder: True if the collection view is first responder

    */
    @objc optional func collectionView(_ collectionView: CollectionView, didChangeFirstResponderStatus firstResponder: Bool)
    
    // MARK: - Mouse Tracking
    /*-------------------------------------------------------------------------------*/
    
    
    /**
     Tells the delegate that the mouse moved into a section

     - Parameter collectionView: The collection view notifying you of the event
     - Parameter indexPath: the index path of the section
     
     - Note: trackSectionHover must be set to true on the collection view

    */
    @objc optional func collectionView(_ collectionView: CollectionView, mouseMovedToSection indexPath: IndexPath?)
    
    /**
     Tells the delegate that the mouse was clicked down in the specified index path

     - Parameter collectionView: The collection view recieving the click
     - Parameter indexPath: The index path of the item at the click location, or nil
     - Parameter event: The click event

    */
    @objc optional func collectionView(_ collectionView: CollectionView, mouseDownInItemAt indexPath: IndexPath?, with event: NSEvent)
    
    
    /**
     Tells the delegate that the mouse was released in the specified index path

     - Parameter collectionView: The collection view receiving the click
     - Parameter indexPath: The index path of the item at the click location, or nil
     - Parameter event: The click even

    */
    @objc optional func collectionView(_ collectionView: CollectionView,
                                       mouseUpInItemAt indexPath: IndexPath?,
                                       with event: NSEvent)
    
    
    
    // MARK: - Highlighting
    /*-------------------------------------------------------------------------------*/
    
    
    /**
     Asks the delegate if the item at the specified index path should highlight

     - Parameter collectionView: <#collectionView description#>
     - Parameter indexPath: <#indexPath description#>
     
     - Returns: <#Bool return description#>

    */
    @objc optional func collectionView(_ collectionView: CollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool
    
    
    
    // MARK: - Selections
    /*-------------------------------------------------------------------------------*/
    
    /**
     Tells the delegate

     - Parameter collectionView: <#collectionView description#>
     - Parameter indexPath: <#indexPath description#>
     - Parameter event: <#event description#>
     
     - Returns: <#Bool return description#>

    */
    @objc optional func collectionView(_ collectionView: CollectionView, shouldSelectItemAt indexPath: IndexPath, with event: NSEvent?) -> Bool
    
    /**
     <#Description#>

     - Parameter collectionView: <#collectionView description#>
     - Parameter indexPath: <#indexPath description#>

    */
    @objc optional func collectionView(_ collectionView: CollectionView, didSelectItemAt indexPath: IndexPath)
    
    /**
     <#Description#>

     - Parameter collectionView: <#collectionView description#>
     - Parameter indexPath: <#indexPath description#>
     
     - Returns: <#Bool return description#>

    */
    @objc optional func collectionView(_ collectionView: CollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool
    
    /**
     <#Description#>

     - Parameter collectionView: <#collectionView description#>
     - Parameter indexPath: <#indexPath description#>

    */
    @objc optional func collectionView(_ collectionView: CollectionView, didDeselectItemAt indexPath: IndexPath)
    
    
    /**
     <#Description#>

     - Parameter collectionView: <#collectionView description#>
     - Parameter pressure: <#pressure description#>
     - Parameter indexPath: <#indexPath description#>

    */
    @objc optional func collectionView(_ collectionView: CollectionView, didChangePressure pressure: CGFloat, forItemAt indexPath: IndexPath)
    
    // MARK: - Special Clicks
    /*-------------------------------------------------------------------------------*/
    
    
    /**
     <#Description#>

     - Parameter collectionView: <#collectionView description#>
     - Parameter indexPath: <#indexPath description#>
     - Parameter event: <#event description#>

    */
    @objc optional func collectionView(_ collectionView: CollectionView, didDoubleClickItemAt indexPath: IndexPath?, with event: NSEvent)
    
    /**
     <#Description#>

     - Parameter collectionView: <#collectionView description#>
     - Parameter indexPath: <#indexPath description#>
     - Parameter event: <#event description#>

    */
    @objc optional func collectionView(_ collectionView: CollectionView, didRightClickItemAt indexPath: IndexPath?, with event: NSEvent)
    
    
    // MARK: - View Display
    /*-------------------------------------------------------------------------------*/
    
    @objc optional func collectionView(_ collectionView: CollectionView, willDisplayCell cell:CollectionViewCell, forItemAt indexPath: IndexPath)
    
    
    /**
     <#Description#>

     - Parameter collectionView: <#collectionView description#>
     - Parameter elementKind: <#elementKind description#>
     - Parameter indexPath: <#indexPath description#>

    */
    @objc optional func collectionView(_ collectionView: CollectionView, willDisplaySupplementaryView view:CollectionReusableView, ofElementKind elementKind: String, at indexPath: IndexPath)
    
    
    /**
     <#Description#>

     - Parameter collectionView: <#collectionView description#>
     - Parameter cell: <#cell description#>
     - Parameter indexPath: <#indexPath description#>

    */
    @objc optional func collectionView(_ collectionView: CollectionView, didEndDisplayingCell cell: CollectionViewCell, forItemAt indexPath: IndexPath)
    
    
    /**
     <#Description#>

     - Parameter collectionView: <#collectionView description#>
     - Parameter view: <#view description#>
     - Parameter elementKind: <#elementKind description#>
     - Parameter indexPath: <#indexPath description#>

    */
    @objc optional func collectionView(_ collectionView: CollectionView, didEndDisplayingSupplementaryView view: CollectionReusableView, ofElementKind elementKind: String, at indexPath: IndexPath)
    
    
    // MARK: - Ancoring
    /*-------------------------------------------------------------------------------*/
    
    
    /**
     <#Description#>

     - Parameter collectionView: <#collectionView description#>
     
     - Returns: <#IndexPath return description#>

    */
    @objc optional func collectionViewLayoutAnchor(_ collectionView: CollectionView) -> IndexPath?
    
    // MARK: - Resizing
    /*-------------------------------------------------------------------------------*/
    
    
    /**
     <#Description#>

     - Parameter collectionView: <#collectionView description#>

    */
    @objc optional func collectionViewDidEndLiveResize(_ collectionView: CollectionView)
    
    // MARK: - Scrolling
    /*-------------------------------------------------------------------------------*/
    
    
    /**
     <#Description#>

     - Parameter collectionView: <#collectionView description#>
     - Parameter indexPath: <#indexPath description#>
     
     - Returns: <#Bool return description#>

    */
    @objc optional func collectionView(_ collectionView: CollectionView, shouldScrollToItemAt indexPath: IndexPath) -> Bool
    
    /**
     <#Description#>

     - Parameter collectionView: <#collectionView description#>
     - Parameter indexPath: <#indexPath description#>

    */
    @objc optional func collectionView(_ collectionView: CollectionView, didScrollToItemAt indexPath: IndexPath)

    
    /**
     <#Description#>

     - Parameter collectionView: <#collectionView description#>

    */
    @objc optional func collectionViewDidScroll(_ collectionView: CollectionView)
    
    
    /**
     <#Description#>

     - Parameter collectionView: <#collectionView description#>

    */
    @objc optional func collectionViewWillBeginScrolling(_ collectionView: CollectionView)
    
    
    /**
     <#Description#>

     - Parameter collectionView: <#collectionView description#>
     - Parameter animated: <#animated description#>

    */
    @objc optional func collectionViewDidEndScrolling(_ collectionView: CollectionView, animated: Bool)
}




@available(*, unavailable, renamed: "CollectionViewDragDelegate")
public protocol CollectionViewInteractionDelegate : CollectionViewDelegate { }

/**
 The CollectionViewDragDelegate

*/
@objc public protocol CollectionViewDragDelegate : CollectionViewDelegate {
    
    // MARK: - Dragging Source
    /*-------------------------------------------------------------------------------*/
    
    /**
     <#Description#>

     - Parameter collectionView: <#collectionView description#>
     - Parameter indexPath: <#indexPath description#>
     - Parameter event: <#event description#>
     
     - Returns: <#Bool return description#>

    */
    @objc optional func collectionView(_ collectionView: CollectionView, shouldBeginDraggingAt indexPath: IndexPath, with event: NSEvent) ->Bool
    
    
    /**
     <#Description#>

     - Parameter collectionView: <#collectionView description#>
     
     - Returns: <#IndexPath return description#>

    */
    @objc optional func collectionView(_ collectionView: CollectionView, validateIndexPathsForDrag indexPaths: [IndexPath]) -> [IndexPath]
    
    /**
     <#Description#>

     - Parameter collectionView: <#collectionView description#>
     - Parameter session: <#session description#>
     - Parameter point: <#point description#>

    */
    @objc optional func collectionView(_ collectionView: CollectionView, draggingSession session: NSDraggingSession, willBeginAt point: NSPoint)
    
    /**
     <#Description#>

     - Parameter collectionView: <#collectionView description#>
     - Parameter session: <#session description#>
     - Parameter screenPoint: <#screenPoint description#>
     - Parameter operation: <#operation description#>

    */
    @objc optional func collectionView(_ collectionView: CollectionView, draggingSession session: NSDraggingSession, didEndAt screenPoint: NSPoint, with operation: NSDragOperation, draggedIndexPaths: [IndexPath])
    
    /**
     <#Description#>

     - Parameter collectionView: <#collectionView description#>
     - Parameter session: <#session description#>
     - Parameter point: <#point description#>

    */
    @objc optional func collectionView(_ collectionView: CollectionView, draggingSession session: NSDraggingSession, didMoveTo point: NSPoint)
    
    // MARK: - Dragging Destination
    /*-------------------------------------------------------------------------------*/
    
    /**
     <#Description#>

     - Parameter collectionView: <#collectionView description#>
     - Parameter dragInfo: <#dragInfo description#>
     
     - Returns: <#NSDragOperation return description#>

    */
    @objc optional func collectionView(_ collectionView: CollectionView, dragEntered dragInfo: NSDraggingInfo) -> NSDragOperation
    /**
     <#Description#>

     - Parameter collectionView: <#collectionView description#>
     - Parameter dragInfo: <#dragInfo description#>
     
     - Returns: <#NSDragOperation return description#>

    */
    @objc optional func collectionView(_ collectionView: CollectionView, dragUpdated dragInfo: NSDraggingInfo) -> NSDragOperation
    /**
     <#Description#>

     - Parameter collectionView: <#collectionView description#>
     - Parameter dragInfo: <#dragInfo description#>

    */
    @objc optional func collectionView(_ collectionView: CollectionView, dragExited dragInfo: NSDraggingInfo?)
    
    /**
     <#Description#>

     - Parameter collectionView: <#collectionView description#>
     - Parameter dragInfo: <#dragInfo description#>

    */
    @objc optional func collectionView(_ collectionView: CollectionView, dragEnded dragInfo: NSDraggingInfo?)
    
    /**
     <#Description#>

     - Parameter collectionView: <#collectionView description#>
     - Parameter dragInfo: <#dragInfo description#>
     
     - Returns: <#Bool return description#>

    */
    @objc optional func collectionView(_ collectionView: CollectionView, performDragOperation dragInfo: NSDraggingInfo) -> Bool
}

