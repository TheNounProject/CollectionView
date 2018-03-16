# Supplementary Views

Collection views rely heavily on the concept of sections and items. When multiple sections are displayed it is usually important to provide some affordance for each. Supplementary views are views displayed in or around a section such as a header or footer.

Using supplementary views is very similar to cells so this should seem familiar if you have read the Basic Setup guide.


## Preparing a View

Views can be loaded from a xib or programatically from a class.

First, create a subclass of CollectionReusable that will be used to configure each cell.

If you are using a xib, set the root view class in the inspector to your new reusable view subclass. You can then add subviews and create outlets to your class to be used later when setting up the view in your data source (more on the layer).

Without a xib, you will need to create the subviews manually in `init(frame frameRect: NSRect)`.

> If you view is not dynamic or does not need outlsets you can also create a nib with a view of type CollectionReusableView and avoid creating a subclass.

#### Registering Cells

Becuase views are reused by a collection view it is never your responsibilty to load/initialize them. Each class or xib you intent to you must be registered before loading any data.

Use the following depending on if you are using a xib or a class alone:
```
public func register(class viewClass: CollectionReusableView.Type, forSupplementaryViewOfKind kind: String, withReuseIdentifier identifier: String)
public func register(nib: NSNib, forSupplementaryViewOfKind elementKind: String, withReuseIdentifier identifier: String)
```

The kind property is used to load multiple supplementary views per section. The common kinds that are provided in CollectionViewLayoutElementKind are header and footer.

Views only need to registered once when your collection view is setup. Typically this can be done in viewDidLoad in the controller containing your collection view.


#### Dequeing Cells

With your views registered they can now be used used by your data source.

Before your collection view will ask your data source for views, your layout must be setup to show them. Every layout is a different but the provided layouts typically have a headerHeight or footerHeight property or delegate calls to provide dynamic heights. If the layout does not make room for supplementary views the collection view will avoid asking for a view to display.

If we are using CollectionViewListLayout, the following would add a 50pt header at the beginning of each section
```
let layout = CollectionViewListLayout()
layout.headerHeight = 40
```

Now we can implement our data source method to provide the view for each section. If you ar using multiple kinds of supplementary views you should check the kind value and return the appropriate view.

```
@objc optional func collectionView(_ collectionView: CollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> CollectionReusableView {
    let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "MyReuseIdentifier", for: indexPath)
    // setup the view as needed
    return view
}
```
