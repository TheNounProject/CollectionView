# Drag & Drop

Drag and drop is a common interaction when using collection views. Items in the view may need to be dragged to another application or rearranged internally. If you are familiar with Pasteboard APIs, the collection view dragging API should be an easy transition.

For the most part, a collection view simply forwards the system drag protocols to the collection view's delegate if it conforms to CollectionViewDragDelegate. This protocol contains functions similar to those in the native dragging APIs and allows you to customize both dragging target and dragging source interactions and behavior. If you are unfamiliar you should be able to coorelate the native APIs to the functions provided by the drag delegate.


## Implementing Your Drag Delegate

The drag delegate has a number of functions that give you full control over a dragging event. Different ones must be implemented to become a drag target or a drag source.

**Dragging Source**

The first method shouldBeginDragging must be implemented to allow a drag session to begin. The others allow you to customize the contents and respond to stages of the drag.
```
@objc optional func collectionView(_ collectionView: CollectionView, shouldBeginDraggingAt indexPath: IndexPath, with event: NSEvent) ->Bool
@objc optional func collectionView(_ collectionView: CollectionView, validateIndexPathsForDrag indexPaths: [IndexPath]) -> [IndexPath]
@objc optional func collectionView(_ collectionView: CollectionView, draggingSession session: NSDraggingSession, willBeginAt point: NSPoint)
@objc optional func collectionView(_ collectionView: CollectionView, draggingSession session: NSDraggingSession, didEndAt screenPoint: NSPoint, with operation: NSDragOperation, draggedIndexPaths: [IndexPath])
@objc optional func collectionView(_ collectionView: CollectionView, draggingSession session: NSDraggingSession, didMoveTo point: NSPoint)
```

**Dragging Target**


When accepting drag events in the collection view you must register the view for drag types as you would any view. This will allow the default dragging APIs to be triggered which will then be delivered to you via the drag delegate to respond to changes and finally handle the drag.

`collectionView(_:performDragOperation:)` must be implemented to responsd to the end of a successful and accepted drag event.

```
@objc optional func collectionView(_ collectionView: CollectionView, dragEntered dragInfo: NSDraggingInfo) -> NSDragOperation
@objc optional func collectionView(_ collectionView: CollectionView, dragUpdated dragInfo: NSDraggingInfo) -> NSDragOperation
@objc optional func collectionView(_ collectionView: CollectionView, dragExited dragInfo: NSDraggingInfo?)
@objc optional func collectionView(_ collectionView: CollectionView, dragEnded dragInfo: NSDraggingInfo?)
@objc optional func collectionView(_ collectionView: CollectionView, performDragOperation dragInfo: NSDraggingInfo) -> Bool
```

