# Insert, Delete, and Move

As data changes a collection view displaying that data will need to update as well. New content could be pulled from a remote service or the user could take an action. Collection view supports inserting, deleting, moving, and reloading sections and items.


## Single Updates

To perform a single update operation you can use any of the update functions directly.

```
public func insertSections(_ sections: IndexSet, animated: Bool)
public func deleteSections(_ sections: IndexSet, animated: Bool)
public func moveSection(_ section: Int, to newSection: Int, animated: Bool)

public func insertItems(at indexPaths: [IndexPath], animated: Bool)
public func deleteItems(at indexPaths: [IndexPath], animated: Bool)
public func reloadItems(at indexPaths: [IndexPath], animated: Bool)
public func moveItem(at indexPath : IndexPath, to destinationIndexPath: IndexPath, animated: Bool)
```

Before doing so you must be sure that your data source will report the change. For example, if inserting an item your data source must report 1 more item than the collection view currently has.

> Note that these operations currently reload the entire layout object and should not be called excessivly.


## Batch Updates

Multiple updates can be performed simultaneously use `performBatchUpdates(_:completion:)`. Any changes made in the first closure will be batched together and commited as a single operation.

```
myData.remove(at: 1)
myData.append("Another Entry")

collectionView.performBatchUpdates({
    collectionView.deletItems(at: [IndexPath.for(item: 1, section: 0)])
    collectionView.insertITems(at: [[IndexPath.for(item: myData.count - 1, section: 0)]])
}) { (completed) in
    // Animation is complete!
}
```

Note that delete and reload updates use index paths prior to any changes, inserts refer to index paths after all changes are made, and moves go from a pre-update index path fo a post-updates index path. The following illustrates this

```
Section A
[H] [J] [K]
Section B
[X] [Y] [Z]

move section A to 1
Move [1, 1] to [1, 1]

Section B
[X] [Z]
Section A
[H] [Y] [J] [K]
```

Notice that the second move at [1, 1] moves [Y] from it's starting index path [1, 1] to it's final index path after changes [1, 1].

Managing these changes can be tricky to understand especially when making many changes together. This is why we create ResultsController to help connect your collection view to your data.
