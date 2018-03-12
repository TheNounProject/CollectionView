![CollectionView](https://raw.githubusercontent.com/TheNounProject/CollectionView/master/img/header.png "Collection View")

An easy to use, highly customizable replacement for NSCollectionView.

## Why

Prior to macOS 10.11, NSCollectionView had little in common with it's younger cousin on iOS (UICollectionView). Since then it has recieved some improvements but with no support on 10.10, we needed another solution.

> If you aren't supporting macOS 10.10, NSCollectionView can likely satisfy your needs. That said, CollectionView does provide some additional flexibility and features that may still make it a viable option for your project.


## How

### Docs
Learn about all the classes of CollectionView in the [documentation](https://thenounproject.github.io/CollectionView/)


### Adding to your project
CollectionView isn't currently provided through any package managers. 

Clone or donwload the repo and add it to your project by dragging the CollectionView xCode project to your project.



### Create a CollectionView

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

### So Much More
Check out the documentation for more on what you can do with CollectionView including:

* Content editing (insert, delete, & move)
* Custom layouts
* Section headers and footers
* Drag and drop
* ResultsController for consistent data sourcing (including CoreData implementations)


## Examples

An example project is included in the repo. If you use it, let us know! 

CollectionView is used to power:

* [Lingo for macOS](https://lingoapp.com)
* [Noun Project for macOS](https://thenounproject.com/for-mac/)

## Contributing
Feel free to start a discussion in Issues for bugs, questions, or feature requests.

Or, reach out on twitter: [@NounProjectDev](https://twitter.com/NounProjectDev)

### To do
* Add some common use cell subclasses classes
* Improve performance (it's good, but could always be better 😁)

## Credits
* Thanks to [DeepDiff](https://github.com/onmyway133/DeepDiff) for some diffing logic used in ResultsController

## Licence
This project is released under the [MIT license](https://github.com/TheNounProject/CollectionView/blob/master/LICENSE).

