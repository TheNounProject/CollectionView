# Basic Setup
![CollectionView](https://github.com/TheNounProject/CollectionView/raw/master/img/demo_setup.gif "Collection View")

* Add a NSScrollView to your interface, set the class and make an outlet
* Create a collection view layout and apply it to the collection view.
* Register reusable views
* Set the data source and delegate
* Implement the required data source functions

Which looks like:

```swift
class MyController : NSViewController, CollectionViewDataSource, CollectionViewDelegate {

	func viewDidLoad() {
		super.viewDidLoad()

		var layout = CollectionViewFlowLayout()
		collectionView.collectionViewLayout = listLayout

		collectionView.dataSource = self
	   	collectionView.delegate = self

	   	// Using a nib
	   	let nib = NSNib(nibNamed: "UserCell", bundle: nil)!
	   	collectionView.register(nib: nib, forCellWithReuseIdentifier: "UserCell")

	   	//OR
	   	collectionView.register(class: UserCell.self, forCellWithReuseIdentifier: "UserCell")

	   	collectionView.reloadDate()
	}
}

func numberOfSections(in collectionView: CollectionView) -> Int {
    return 5
}

func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int {
	return 3
}

func collectionView(_ collectionView: CollectionView, cellForItemAt indexPath: IndexPath) -> CollectionViewCell {

	let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserCell", for: indexPath) as! UserCell
	... setup the cell as needed
	return cell
}

```

### Implementing the Delegate
Events such as selection, scrolling, and even dragging from the collection view are delievered to the collection views's delegate.

See the [delegate documentation](https://thenounproject.github.io/CollectionView/Protocols/CollectionViewDelegate.html) for more

```swift
// Somewhere in MyController

func collectionView(_ collectionView: CollectionView, didSelectItemAt indexPath: IndexPath) {
    var myObject = myData[indexPath._item]
    Do something ...
}


func collectionView(_ collectionView: CollectionView, didRightClickItemAt indexPath: IndexPath, with event: NSEvent) {
	// Same as selection but right click\
}
```