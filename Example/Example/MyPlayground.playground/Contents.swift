////: Playground - noun: a place where people can play
//
import Cocoa
//
//var str = "Hello, playground"
//
//
//
//
//protocol Section {
//    var displayName : String { get }
//}
//
//
//class Root : Section {
//    var displayName: String { return "Root" }
//}
//
//class Another : Root {
//    override var displayName: String { return "Another" }
//}
//
//Root().displayName
//Another().displayName
//
//
//protocol Groupable {
//    associatedtype Measurment
//    func groupValue() -> Measurment
////    func groupValue2() -> Measurment
//}
//
//extension Groupable {
//    
//    func groupValue() -> Int {
//        return 0
//    }
//}
//
//extension Groupable {
//    func groupValue() -> String {
//        return "None"
//    }
//}
//
//struct Group<Parent, Element> {
//    var object: Parent
//    var items : [Element]
//}
//
//struct Primitive<String>: Groupable {
//    var name : String
//    func groupValue() -> String {
//        return name
//    }
//}
//
//
//struct Relative<Section, Element>  {
//    var size : Int
////    func groupValue() -> Int {
////        return size
////    }
//}
//
//
//Person(name: "Sarah").groupValue()
//Person(name: "John").groupValue()
//Shoe(size: 6).groupValue()
//Shoe(size: 8).groupValue()




var indexSet = IndexSet()
indexSet.insert(1)
indexSet.insert(5)
indexSet.insert(8)
debugPrint(indexSet)

for idx in indexSet {
    print(idx)
}