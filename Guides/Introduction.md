# Collection View Basics

A collection view coordinatess many different objects to display content. For basic usage most of these can be used as is leaving your app to provide only a few pieces of information. Each component can then be highly customized to meet your specific needs.

Let's start with an overview of these components, then the other guides will go into more detail about how to use and customize each of them.

---

## The CollectionView

The collection view itself is the container and coordinator that brings all the information together to preset something on the screen. Its primary resources are the data source and layout object.

A `CollectionViewController` provides a controller preconfiguerd with a collection view.


## DataSource and Delegate

The data source is the key input **required** by your app to display a collection view. The data source manages the content to be displayed and provides the cells that represent each member of that content on screen.

While the data source provides for the collection view, the delegate lets you optionally react to messages and customize behavior. Selection, highlight and scroll events for example are reported to the delegate. All delegate methods are optional.

The `CollectionViewDragDelegate` is an extension of the standard delegate protocol that allows forwarding dragging events to the delegate.


## Presentation

`CollectionReusableView` are used to represent the content of your collection view on screen. This class provides the mechanisms for layout and reusability of views to maintain adequate performance.

The `CollectionViewCell` is a special type of reusable view used to display The main elements of your data.

## Layout

Subclasses of `CollectionViewLayout` are used to manage the location, size, and visual attributes of each reusable view (and cell) in the collection view.

The layout creates layout attributes (`CollectionViewLayoutAttributes`) for each cell and resuable view which are then used by the collection view.
