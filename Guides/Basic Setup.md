# Basic Setup

`CollectionView` is a highly flexible component with many options and features. A basic collection view though can be setup with just a few lines of code. From there you can adjust and refine your implementation as needed.

This guide walks you through the most basic collection view including steps that will be required for any implementation.

---

## Installation & Import
CollectionView isn't currently provided through any package managers. Clone or donwload the repo and add it to your project by dragging the CollectionView xCode project to your project.

Import `CollectionView` to start building. When referencing classes in interface builder you will need to set the module to CollectionView as well.


## Creating a Collection View

Collection views can be created programatically or in interface builder.

In a storyboard or xib, add an NSScrollView to your view and set the class in the inspector to CollectionView. Then create an outlet.

Without IB simply initialize a collection view and add it to your view. Adding layout constraints is recommended.

With your collection view in place there are a few more steps to display your content:

- Set a data source
- Prepare a cell class
- Choose a layout



## Setting up a Data Source

Every collection view needs a data source that conforms to `CollectionViewDataSource`. The data source object provides the content that is to be displayed in the collection view such as how many items and the views that represent those items on screen.

It is important to understand that the collection view organizes data as sections and items. Each section contains zero or more items. The contept of a section may not be necessarily represented in your data but the collection view will still need 1 section to represent your list of items.

> Each element in a collection view is referred to using IndexPaths. To support macOS 10.10 which predates the addition of `item` and `section` properties on IndexPath, and extension provides _item, _section and for().

The only required of your data source are:
```swift
func numberOfSections(in collectionView: CollectionView) -> Int
func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int
func collectionView(_ collectionView: CollectionView, cellForItemAt indexPath: IndexPath) -> CollectionViewCell
```

These tell your collection view about your data and provide the cells used to display each item. If youa are representing a simple array, you will still need to report 1 section to contain that data. More complex data that is grouped into sections should report as such.


## Preparing a cell

A critical task of the data source is to provide views to display your content in the collection view. The collection view is only responsible for applying layout attributes to the view, everying displayed in the cell is your responsibilty.

Cells can be loaded from a xib or programatically from a class.

First, create a subclass of `CollectionViewCell` that will be used to configure each cell.

If you are using a xib, set the root view class in the inspector to your new cell subclass. You can then add subviews and create outlets to your class to be used later when setting up the cell to display an item from your data.

Without a xib, you will need to create the subviews manually in `init(frame frameRect: NSRect)`.

#### Registering Cells

Becuase views are reused by a collection view it is never your responsibilty to load/initialize them. Each class or xib you intent to you must be registered before loading any data.

Use the following depending on your setup:
```swift
func register(class cellClass: CollectionViewCell.Type, forCellWithReuseIdentifier identifier: String)
func register(nib: NSNib, forCellWithReuseIdentifier identifier: String)
```

Each cell should only be registered once when your collection view is setup. Typically this can be done in viewDidLoad in the controller containing your collection view.


#### Dequeing Cells

With your cells registered they can now be used to satisfy one of the requirements of your data source, providing the cells.

Use the reuse identifier you registered each cell with, call `dequeueReusableCell(withReuseIdentifier identifier:for:)`. The collection view will load the cell, either from the xib or class and return it to be configured as needed. Your data source can setup any UI elements (labels, images, etc) in the cell according to the object that cell is representing then return it to the collection view to be presented.


## Setting a layout

The collection view layout object manages the visual representation of each item, most importantly its location and size.

Custom layouts can be created but a few are provided to be used as is:

- `CollectionViewListLayout`
- `CollectionViewColumnLayout`
- `CollectionViewFlowLayout`

Each layout works differently to provide different appearances and flexibility. The provided layouts often allow static values to be set OR accept values provided by a delegate.

For example, the list layout has an itemHeight property that will be used, but, if the collection views delegate also conforms to `CollectionViewDelegateListLayout` and implements `collectionView(_:layout:heightForItemAt:)->CGFloat`, a dynamic height can be provided for each item.

The layouts provide a great deal of flexibility out of the box and one again, custom layouts can be created to do even more.

Simply initialite the layout you want, set and properties and set `collection.collectionViewLayout`.

See the [Layouts](https://thenounproject.github.io/CollectionView/layouts.html) guide for more.


## Example

```swift

// The cell used to list characters
class CharacterCell : CollectionViewCell {
	let nameLabel = NSTextField()

	override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
		// add the subviews
	}

}


class MyController : NSViewController, CollectionViewDataSource, CollectionViewDelegate {

	var charcters : [[String]] = [
		["Willy", "Charlie", "Mike", "Augustus"],
		["Violet", "Veruca"]
	]

	func viewDidLoad() {
		super.viewDidLoad()

		var layout = CollectionViewListLayout()
		layout.itemHeight = 40
		collectionView.collectionViewLayout = listLayout

		collectionView.dataSource = self
	   	collectionView.delegate = self

	   	// Register the class
	   	collectionView.register(class: CharacterCell.self, forCellWithReuseIdentifier: "CharacterCell")

		// If using a nib...
	   	// let nib = NSNib(nibNamed: "CharacterCell", bundle: nil)!
	   	// collectionView.register(nib: nib, forCellWithReuseIdentifier: "CharacterCell")

	   	collectionView.reloadDate()
	}

	func numberOfSections(in collectionView: CollectionView) -> Int {
		return characters.count
	}

	func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int {
		return characters[section].count
	}

	func collectionView(_ collectionView: CollectionView, cellForItemAt indexPath: IndexPath) -> CollectionViewCell {

		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CharacterCell", for: indexPath) as! CharacterCell
		let name = characters[indexPath._section][indexPath._item]
		cell.nameLabel.stringValue = name
		return cell
	}
}
```

![CollectionView](https://github.com/TheNounProject/CollectionView/raw/master/img/demo_setup.gif "Collection View")


## Implementing the Delegate


Collection views can be used for a variety of use cases. Some may be purely for display but in most cases they are intended to support some level of interaction. These interactions are handled by the collection views delegate (`CollectionViewDelegate`).

Selection state is the most common interaction that needs to be handled by an app. The following are useufl for managing selection state:


```swift
@objc optional func collectionView(_ collectionView: CollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool

@objc optional func collectionView(_ collectionView: CollectionView, shouldSelectItemsAt indexPaths: Set<IndexPath>) -> Set<IndexPath>
@objc optional func collectionView(_ collectionView: CollectionView, didSelectItemsAt indexPaths: Set<IndexPath>)

@objc optional func collectionView(_ collectionView: CollectionView, shouldDeselectItemsAt indexPaths: Set<IndexPath>) -> Set<IndexPath>
@objc optional func collectionView(_ collectionView: CollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>)
```

See the [delegate documentation](https://thenounproject.github.io/CollectionView/Protocols/CollectionViewDelegate.html) for more