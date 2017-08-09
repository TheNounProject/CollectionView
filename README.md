# CollectionView

A highly customizable collection view similiar to NS/UICollectionView.

## Docs 
https://thenounproject.github.io/CollectionView/


## Getting Started

Clone or donwload the repo and add it to your project by dragging the CollectionView xCode project to your project.


## Setup

###  Using Interface Builder/Storyboard
Add a NSScrollView to your view or view controller and set the class to CollectionView using the identity inspector.

### Creating a CollectionView Programatically
Just call CollectionView() and add it to your view

### Loading Data
In your view/controller class:

* Create a collection view layout and apply it to the collection view.
* Set the data source and delegate
* Implement the required data source functions