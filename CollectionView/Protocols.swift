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
 
 At a minimum, all data source objects must implement:
 - `numberOfSections(in:)`
 - `collectionView(_:numberOfItemsInSection:)`
 - `collectionView(_:cellForItemAt:)`.
 
 These methods are responsible for returning the number of items in the collection view along with the items themselves.
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
     Your implementation of this method is responsible for creating, configuring, and returning the appropriate cell for the given item. You do this by calling the `dequeueReusableCell(withReuseIdentifier:for:)` method of the collection view and passing the reuse identifier that corresponds to the cell type you want. That method always returns a valid cell object. Upon receiving the cell, you should set any properties that correspond to the data of the corresponding item, perform any additional needed configuration, and return the cell.
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
     Your implementation of this method is responsible for creating, configuring, and returning the appropriate supplementary view that is being requested. You do this by calling the `dequeueReusableSupplementaryView(ofKind:withReuseIdentifier:for:)` method of the collection view and passing the information that corresponds to the view you want. That method always returns a valid view object. Upon receiving the view, you should set any properties that correspond to the data you want to display, perform any additional needed configuration, and return the view.
     You do not need to set the location of the supplementary view inside the collection view’s bounds. The collection view sets the location of each view using the layout attributes provided by its layout object.

    */
    @objc optional func collectionView(_ collectionView: CollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> CollectionReusableView
    
    // MARK: - Dragging Items
    /*-------------------------------------------------------------------------------*/
    
    /**
     Asks your data source for a pasteboard writing for the item at the specified index path

     - Parameter collectionView: The collection view requesting this information.
     - Parameter indexPath: The index path of the item to represent with the pasteboard writer
     
     - Returns: The pasteboard writer object to use for managing the item data. Return nil to prevent the collection view from dragging the item.
     
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
     Asks the data source to validate the drag rect for an item to be dragged, allowing for adjustment.

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
     Notifies the delegate that the collection view will reload it's layout
     
     It can be assumed that the data has been reloaded

     - Parameter collectionView: The collection view is reloading it's layout
     
     - Note: Calculating layout properties that can be cached can be done here and later returned in associated the layout delegate methods.
    */
    @objc optional func collectionViewWillReloadLayout(_ collectionView: CollectionView)
    
	/**
	Notifies the delegate that the collection view finished reloading it's layout
     
     It can be assumed that the data has been reloaded and  is up to date

	- Parameter collectionView: The collection view

	*/
    @objc optional func collectionViewDidReloadLayout(_ collectionView: CollectionView)
    
    // MARK: - First Responder
    /*-------------------------------------------------------------------------------*/
    
    /**
     Notifies the delegate that the collection view has changed status as first responder

     - Parameter collectionView: The collection view changing status
     - Parameter firstResponder: True if the collection view is first responder

    */
    @objc optional func collectionView(_ collectionView: CollectionView, didChangeFirstResponderStatus firstResponder: Bool)
    
    // MARK: - Mouse Tracking
    /*-------------------------------------------------------------------------------*/
    
    /**
      Notifies the delegate that the mouse has moved into the frame of a section.

     - Parameter collectionView: The collection view notifying you of the event
     - Parameter indexPath: the index path of the section
     
     - Note: trackSectionHover must be set to true on the collection view

    */
    @objc optional func collectionView(_ collectionView: CollectionView, mouseMovedToSection indexPath: IndexPath?)
    
    /**
     Notifies the delegate that the mouse was clicked down in the specified index path

     - Parameter collectionView: The collection view recieving the click
     - Parameter indexPath: The index path of the item at the click location, or nil
     - Parameter event: The click event

    */
    @objc optional func collectionView(_ collectionView: CollectionView, mouseDownInItemAt indexPath: IndexPath?, with event: NSEvent)
    
    /**
     Notifies the delegate that the mouse was released in the specified index path

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

     - Parameter collectionView: The asking collection view
     - Parameter indexPath: The index path of the item to highlight
     
     - Returns: True if the item should highlight

    */
    @objc optional func collectionView(_ collectionView: CollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool
    
    // MARK: - Selections
    /*-------------------------------------------------------------------------------*/
    
    // Single index path selection delegate methods are deprecated. Please use Set<IndexPath> versions.
    @available(*, deprecated, message: "Please use collectionView(_:, shouldDeselectItemsAt:)")
    @objc optional func collectionView(_ collectionView: CollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool
    
    @available(*, deprecated, message: "Please use collectionView(_:, didDeselectItemsAt:)")
    @objc optional func collectionView(_ collectionView: CollectionView, didDeselectItemAt indexPath: IndexPath)
    
    @available(*, deprecated, message: "Please use collectionView(_:, shouldSelectItemsAt:)")
    @objc optional func collectionView(_ collectionView: CollectionView, shouldSelectItemAt indexPath: IndexPath, with event: NSEvent?) -> Bool
    
    @available(*, deprecated, message: "Please use collectionView(_:, didSelectItemsAt:)")
    @objc optional func collectionView(_ collectionView: CollectionView, didSelectItemAt indexPath: IndexPath)
    
    /**
     Asks the delegate to approve the pending selection of items.
     
     - Parameter collectionView: The collection view making the request.
     - Parameter indexPath: The set of NSIndexPath objects corresponding to the items selected by the user.
     - Parameter event: The event that cause the selection
     
     - Returns: The set of NSIndexPath objects corresponding to the items that you want to be selected. If you do not want any items selected, return an empty set.
     
     Use this method to approve or modify the items that the user tries to select. During interactive selection, the collection view calls this method whenever the user selects new items. Your implementation of the method can return the proposed set of index paths as-is or modify the set before returning it. You might modify the set to disallow the selection of specific items or specific combinations of items.
     
     If you do not implement this method, the collection view selects the items specified by the indexPaths parameter.
     
     */
    @objc optional func collectionView(_ collectionView: CollectionView, shouldSelectItemsAt indexPaths: Set<IndexPath>) -> Set<IndexPath>
    
    /**
     Notifies the delegate object that one or more items were selected.
     
     - Parameter collectionView: The collection view notifying you of the selection change.
     - Parameter indexPath: The set of NSIndexPath objects corresponding to the items that are now selected.
     
     After the user successfully selects one or more items, the collection view calls this method to let you know that the selection has been made. Use this method to respond to the selection change and to make any necessary adjustments to your content or the collection view.
     
     - Note: The provided index paths do not inlcude index paths selected prior to this event.
     */
    
    @objc optional func collectionView(_ collectionView: CollectionView, didSelectItemsAt indexPaths: Set<IndexPath>)
    
    /**
     Asks the delegate object to approve the pending deselection of items.
     
     - Parameter collectionView: The collection view making the request.
     - Parameter indexPath: The set of NSIndexPath objects corresponding to the items deselected by the user.
     
     - Returns: The set of NSIndexPath objects corresponding to the items that you want to be selected. If you do not want any items selected return an empty set.
     
     Use this method to approve or modify the items that the user tries to deselect. During interactive selection, the collection view calls this method whenever the user deselects items. Your implementation of the method can return the proposed set of index paths as-is or modify the set before returning it. You might modify the set to disallow the deselection of specific items.
     
     */
    @objc optional func collectionView(_ collectionView: CollectionView, shouldDeselectItemsAt indexPaths: Set<IndexPath>) -> Set<IndexPath>
    
    /**
     Notifies the delegate object that one or more items were deselected.
     
     - Parameter collectionView: The collection view notifying you of the selection change.
     - Parameter indexPath: The set of NSIndexPath objects corresponding to the items that were deselected.
     
     After the user successfully deselects one or more items, the collection view calls this method to let you know that the items are no longer selected. Use this method to respond to the selection change and to make any necessary adjustments to your content or the collection view.
     */
    @objc optional func collectionView(_ collectionView: CollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>)
    
    /**
     Not implemented

     - Parameter collectionView: <#collectionView description#>
     - Parameter pressure: <#pressure description#>
     - Parameter indexPath: <#indexPath description#>

    */
    @available(*, unavailable, message: "Trackpad pressure is not yet implemented")
    @objc optional func collectionView(_ collectionView: CollectionView, didChangePressure pressure: CGFloat, forItemAt indexPath: IndexPath)
    
    /**
     Notifies the delegate that an item was double clicked
     
     - Parameter collectionView: The collection view containing the clicked item
     - Parameter indexPath: The index path of the clicked item
     - Parameter event: The click event that double clicked the item

    */
    @objc optional func collectionView(_ collectionView: CollectionView, didDoubleClickItemAt indexPath: IndexPath?, with event: NSEvent)
    
    /**
     Notifies the delegate that an item was right clicked

     - Parameter collectionView: The collection view containing the clicked item
     - Parameter indexPath: The index path of the clicked item
     - Parameter event: The click event

    */
    @objc optional func collectionView(_ collectionView: CollectionView, didRightClickItemAt indexPath: IndexPath?, with event: NSEvent)
    
    // MARK: - View Display
    /*-------------------------------------------------------------------------------*/
    
    @objc optional func collectionView(_ collectionView: CollectionView, willDisplayCell cell: CollectionViewCell, forItemAt indexPath: IndexPath)
    
    /**
     Notifies the delegate that a supplementary view will bw displayed
     
     - Parameter collectionView: The collection view containing the supplementary view
     - Parameter elementKind: The element kind of the view
     - Parameter indexPath: The index path of the view

    */
    @objc optional func collectionView(_ collectionView: CollectionView, willDisplaySupplementaryView view: CollectionReusableView, ofElementKind elementKind: String, at indexPath: IndexPath)
    
    /**
     Notifies the delegate that a cell was removed from view

     - Parameter collectionView: The collection view containing the cell
     - Parameter cell: The cell that was removed
     - Parameter indexPath: The index path of the removed cell

    */
    @objc optional func collectionView(_ collectionView: CollectionView, didEndDisplayingCell cell: CollectionViewCell, forItemAt indexPath: IndexPath)
    
    /**
     Notifies the delegate that a supplementary view was removed from view

     - Parameter collectionView: The collection view containing the supplementary view
     - Parameter view: The view that was removed
     - Parameter elementKind: The kind of the removed element
     - Parameter indexPath: The index path of the removed view

    */
    @objc optional func collectionView(_ collectionView: CollectionView, didEndDisplayingSupplementaryView view: CollectionReusableView, ofElementKind elementKind: String, at indexPath: IndexPath)
    
    // MARK: - Ancoring
    /*-------------------------------------------------------------------------------*/
    
    /**
     Asks the delegate for an index path to anchor when resizing
     
     - Parameter collectionView: The collection view
     
     - Returns: The index path to anchor to when resizing
     
     Defaults to an index path for one of the first visible items

    */
    @objc optional func collectionViewLayoutAnchor(_ collectionView: CollectionView) -> IndexPath?
    
    // MARK: - Resizing
    /*-------------------------------------------------------------------------------*/
    
    /**
     Notifies the delegate that the collection view did begin resizing

     - Parameter collectionView: The collection view

    */
    @objc optional func collectionViewDidEndLiveResize(_ collectionView: CollectionView)
    
    // MARK: - Scrolling
    /*-------------------------------------------------------------------------------*/
    
    /**
     Asks the delegate if the collection view should scroll to an item

     - Parameter collectionView: The collection view
     - Parameter indexPath: The index path that may be scrolled to
     
     - Returns: True if the collection view should perform the scroll

    */
    @objc optional func collectionView(_ collectionView: CollectionView, shouldScrollToItemAt indexPath: IndexPath) -> Bool
    
    /**
     Notifies the delegate that the collection view did complete a scrolling action

     - Parameter collectionView: The collection view that performed a scrolling animation
     - Parameter indexPath: The index path that was scrolled to

    */
    @objc optional func collectionView(_ collectionView: CollectionView, didScrollToItemAt indexPath: IndexPath)
    
    /**
     Notifies the delegate that the collection view was scrolled

     - Parameter collectionView: The collection view that was scrolled
     
     Because this is called continuously as the scroll position is changed, beware of performance.

    */
    @objc optional func collectionViewDidScroll(_ collectionView: CollectionView)
    
    /**
     Notifies the delegate that the collection view will begin scrolling
     
     - Parameter collectionView: The collection view that will begin scrolling
     - Parameter aniated: If the scroll is triggered by user input, this will be false

    */
    @objc optional func collectionViewWillBeginScrolling(_ collectionView: CollectionView, animated: Bool)
    
    /**
     Notifies the delegate that the collection view did end scrolling
     
     - Parameter collectionView: The collection view that was scrolled
     - Parameter animated: True if the scroll was animated (false for user driven scrolling)

    */
    @objc optional func collectionViewDidEndScrolling(_ collectionView: CollectionView, animated: Bool)
}

@available(*, unavailable, renamed: "CollectionViewDragDelegate")
public protocol CollectionViewInteractionDelegate: CollectionViewDelegate { }

/**
 The CollectionViewDragDelegate forwards system drag functions to the delegate in the context of a Collection View.

*/
@objc public protocol CollectionViewDragDelegate: CollectionViewDelegate {
    
    // MARK: - Dragging Source
    /*-------------------------------------------------------------------------------*/
    
    /**
     Asks the delegate if a dragging session should be started

     - Parameter collectionView: The collection view
     - Parameter indexPath: The indexpath at the location of the drag
     - Parameter event: The mouse event
     
     - Returns: True if a dragging session should begin

    */
    @objc optional func collectionView(_ collectionView: CollectionView, shouldBeginDraggingAt indexPath: IndexPath, with event: NSEvent) -> Bool
    
    /**
     Asks the delegate to validate the selected items for drag.

     - Parameter collectionView: The collection view that began the drag
     - Parameter indexPaths: The selected index paths when the drag began
     
     - Returns: The index paths that should be included in the drag.
     
     This provides an opputunity to exclude some of the selected index paths from being dragged

    */
    @objc optional func collectionView(_ collectionView: CollectionView, validateIndexPathsForDrag indexPaths: [IndexPath]) -> [IndexPath]
    
    /**
     Notifies the delegate that a dragging session will begin

     - Parameter collectionView: The collection view
     - Parameter session: The dragging session
     - Parameter point: The location of the drag
     
     If collectionView(:shouldBeginDraggingAt:with) returns false this will not be called

    */
    @objc optional func collectionView(_ collectionView: CollectionView, draggingSession session: NSDraggingSession, willBeginAt point: NSPoint)
    
    /**
     Notifies the delegate that a dragging session ended

     - Parameter collectionView: The collection view
     - Parameter session: The drag session
     - Parameter screenPoint: The screen point at which the drag ended
     - Parameter operation: The dragging operation at the time the drag ended

    */
    @objc optional func collectionView(_ collectionView: CollectionView, draggingSession session: NSDraggingSession, didEndAt screenPoint: NSPoint, with operation: NSDragOperation, draggedIndexPaths: [IndexPath])
    
    /**
     Notifies the delegate that a dragging session moved

     - Parameter collectionView: The collection view
     - Parameter session: The drag session
     - Parameter point: The location of the drag

    */
    @objc optional func collectionView(_ collectionView: CollectionView, draggingSession session: NSDraggingSession, didMoveTo point: NSPoint)
    
    // MARK: - Dragging Destination
    /*-------------------------------------------------------------------------------*/
    
    /**
     Asks the delegate for an operation for the drag at its current state when it enters the collection view

     - Parameter collectionView: The collection view
     - Parameter dragInfo: The drag info
     
     - Returns: A drag operation indicating how the drag should be handled

    */
    @objc optional func collectionView(_ collectionView: CollectionView, dragEntered dragInfo: NSDraggingInfo) -> NSDragOperation
    /**
     Asks the delegate for an operation for the drag at its current state as it updates

     - Parameter collectionView: The collection view
     - Parameter dragInfo: The drag info
     
     - Returns: A drag operation indicating how the drag should be handled

    */
    @objc optional func collectionView(_ collectionView: CollectionView, dragUpdated dragInfo: NSDraggingInfo) -> NSDragOperation
    /**
     Notifies the delegate that a drag exited the collection view as a dragging destination

     - Parameter collectionView: The collection view
     - Parameter dragInfo: The drag info

    */
    @objc optional func collectionView(_ collectionView: CollectionView, dragExited dragInfo: NSDraggingInfo?)
    
    /**
     Notifies the delegate that a drag ended in the collection view as a dragging destination

     - Parameter collectionView: The collection view
     - Parameter dragInfo: The drag info
     
    */
    @objc optional func collectionView(_ collectionView: CollectionView, dragEnded dragInfo: NSDraggingInfo?)
    
    /**
     Asks the delegate to handle the drop in the collection view

     - Parameter collectionView: The collection view (dragging destination) the drag ended in
     - Parameter dragInfo: The drag info
     
     - Returns: True if the drag is completed. False to cancel the drag 

    */
    @objc optional func collectionView(_ collectionView: CollectionView, performDragOperation dragInfo: NSDraggingInfo) -> Bool
}
