# Results Controller

Collection views are a data driven UI element. Managing data is hard enough, making sure changes to that data are relfected in your app can add a lot of complexity quickly; Especially with highly dynamic data.

Resultscontroller is designed to bridge the gap between data and a collection view. While it's inspiration, NSFetchedResultsController only works with CoreData and it's NSManagedObject, this implementation uses native Swift KeyPaths and a generic SortDescriptor type making usable any object type.

---

## A Mutable Results Controller?

Traditionally, the beauty of NSFetchedResutls controller is that it listens to your Core Data store and tells you when changes are made. This is great, and you can do that here too (see below) but one of the other helpful aspects of a results controller is translating changes in your data to changes in a collection view. As mentioned in the Content Manipulation guide, tracking those changes can complicated with highly dynamic data.

MutableResultsController is designed manage your data, respond to changes in that data, and translate those changes into updates a collection view can understand. The only difference from a core data backed controller that recieves changes by monitoring the store is that you provide the changes. Let's take a look

A very basic example of a mutable results controller setup:
```
let mrc = MutableResultsController<NoSectionType, Child>()

let child1 = Child()
let child2 = Child()
mrc.setContents([child1, child2])
mrc.numberOfSections() // 1
mrc.numberOfObjects(in: 0) // 2
```

In this simple example we it may not seem clear why using a controller is better than a simple array. One nice benefit is that you can maintain a consistent api for powering your data source. But the real power comes when we start set up a more complex controller.

Let's add a section key path and ordering. Defining a name and age property on our Child object we can then use those properties to group and sort a set of chilren. Let's group them by age and then sort by name within each group. And finally we also went each group to line up from youngest to oldes.

```
struct Child {
    let name : String
    let age : String
}

let mrc = MutableResultsController<Int, Child>(sectionKeyPath: \Child.rank,
                                    sortDescriptors: [SortDescriptor(\Child.name)],
                                    sectionSortDescriptors: [SortDescriptor<Int>.ascending])

mrc.setContents([
    Child((name: "Geoff", age: 9),
    Child((name: "Sarah", age: 8),
    Child((name: "Steve", age: 10)
    Child((name: "Amy", age: 8),
])

// Sections
8 : [Child((name: "Amy", age: 8), Child((name: "Sarah", age: 8)]
9 : [Child((name: "Geoff", age: 9)]
10: [Child((name: "Steve", age: 10)]

mrc.numberOfSections() // 3
mrc.numberOfObjects(in: 0) // 2
mrc.numberOfObjects(in: 1) // 1
mrc.numberOfObjects(in: 2) // 1
mrc.object(at: IndexPath.for(item: 0, section: 0)) // name:Amy age:8)

```

Using results controller now provides a bit more usfullness. Setting the contents handles a lot of data processing both grouping the items then sorting everything, that data is then exposed in a consistent API that aligns with the collection view API. When implementing collections views in various places results controller can help make more of your collection view implmentations reusable.


## Core Data Results Controllers

Mentioned above, Results Controller is inspired by NSFetchedResultsController and originally started as a CoreData only controller. As of v2 of CollectionView though the core data implementation is a simple subclass of MutableResultsController.

FetchedResultsController and RelationalResultsController monitor the provided NSManagedObjectContext for changes and process those changes, updating their data as needed.

See the docs for these controllers for more information.