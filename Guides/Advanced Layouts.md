# Advanced Layouts

Every collection view relys on a CollectionViewLayout object to provide the information. This allows a layout object to reason about the desired layout in whatever way is most appropriate for its goal. Every layout is a subclass of CollectionViewLayout, an abstract class that provides the framework for collection view to access information it needs to display each item correctly.

A few layouts are provided and allow for customization. We'll go through each of these layouts and some of the tips and tricks of each then discuss building your own layout.


## CollectionViewListLayout

CollectionViewListLayout is a simple vertical list similar to an NSTableView/UITableView.

Some of the key customization tips for this layout are the `interitemSpacing` and `sectionInsets`. Also available via CollectionViewDelegateListLayout methods for per section values, these properties can turn an ordinary list into a card style list with minimal effort.


## CollectionViewColumnLayout

CollectionViewColumnLayout organizes items in each section into columns creating a grid or a pintrest style waterfall depending on your setup.

### Coumns and Width
Your first choice is how many columns should be used in a given section. This number in conjunction with column spacing and section insets will determin the width of each item. In the example below our collection view is 800pt wide, with insets of 10 and column spacing of 10 wit 5 columns. This leaves 88pts for each cell, remember at this stage we are only worried about width.

![ColumnLayoutSpacing](https://raw.githubusercontent.com/TheNounProject/CollectionView/master/img/column_layout.png "Column layout spacing")

Columns are always equal width and adjusting the spacing, insets, or number of columns will affect the width of each column equally.


### Item Height







## CollectionViewFlowLayout


## Custom Layouts