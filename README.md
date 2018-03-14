![CollectionView](https://raw.githubusercontent.com/TheNounProject/CollectionView/master/img/header.png "Collection View")

An easy to use, highly customizable replacement for NSCollectionView.

## Why

Prior to macOS 10.11, NSCollectionView had little in common with its younger cousin on iOS (UICollectionView). Since then it has recieved some improvements but with no support on 10.10, we needed another solution.

CollectionView provides a ton of functionality, flexibility, and high performance. Some of it's features include:

* Highly customizable out of the box
* Custom layouts for even more customizations
* Content editing inluding animations (insert, delete, & move)
* Section headers and footers
* Drag and drop
* Photos-like preview transitions
* ResultsController for consistent data sourcing (including CoreData implementations)

> If you aren't supporting macOS 10.10, NSCollectionView can likely satisfy your needs. That said, CollectionView does provide some additional flexibility and features that may still make it a viable option for your project.


## How

Get collection view up and running in just a few minutes. Checkout the guides & documentation.

- [Introduction](https://thenounproject.github.io/CollectionView/introduction.html)
- [Basic Setup](https://thenounproject.github.io/CollectionView/basic-setup.html)
- [Documentation](https://thenounproject.github.io/CollectionView/index.html)


### Adding to your project
CollectionView isn't currently provided through any package managers.

Clone or donwload the repo and add it to your project by dragging the CollectionView xCode project to your project.

## Examples

CollectionView is used to power:

* Demo app (in this repo)
* [Lingo for macOS](https://lingoapp.com)
* [Noun Project for macOS](https://thenounproject.com/for-mac/)

Let us know if you use it too.

## Contributing
Feel free to create an Issue for bugs, questions, or feature requests.

Or, reach out on twitter: [@NounProjectDev](https://twitter.com/NounProjectDev)

### To do
* Add some common use cell subclasses
* Improve performance (it's good, but could always be better 😁)
* Some sort of layout context to avoid full reloads

## Credits
* Thanks to [DeepDiff](https://github.com/onmyway133/DeepDiff) for some diffing logic used in ResultsController

## Licence
This project is released under the [MIT license](https://github.com/TheNounProject/CollectionView/blob/master/LICENSE).

