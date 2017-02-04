////: Playground - noun: a place where people can play
//
import Cocoa
//
//var str = "Hello, playground"
//
//
//

extension Int {
    
    static func random(in range: ClosedRange<Int>) -> Int {
        let min = range.lowerBound
        let max = range.upperBound
        return Int(arc4random_uniform(UInt32(1 + max - min))) + min
    }
}

func randomString(length: Int) -> String {
    
    let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    let len = UInt32(letters.length)
    
    var randomString = ""
    
    for _ in 0 ..< length {
        let rand = arc4random_uniform(len)
        var nextChar = letters.character(at: Int(rand))
        randomString += NSString(characters: &nextChar, length: 1) as String
    }
    
    return randomString
}



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




//var indexSet = IndexSet()
//indexSet.insert(1)
//indexSet.insert(5)
//indexSet.insert(8)
//debugPrint(indexSet)
//
//for idx in indexSet {
//    print(idx)
//}



func runTime(_ block: ()->Void) -> TimeInterval {
    let start = CFAbsoluteTimeGetCurrent()
    block()
    let dur = CFAbsoluteTimeGetCurrent() - start
    return dur
}



import CollectionView


var source = [
    IndexPath.for(item: 1, section: 1),
    IndexPath.for(item: 0, section: 2),
    IndexPath.for(item: 1, section: 0),
    IndexPath.for(item: 0, section: 0)
]
var target = source.sorted()


func describeEdits(for changeSet: ChangeSet<[IndexPath]>) -> String {
    var str = ""
    for e in changeSet.edits {
        str += "\(e.description)\n"
    }
    return str
    
}

var cs1 = ChangeSet(source: source, target: target, options: .minimumOperations)
cs1.matrixLog
describeEdits(for: cs1)

cs1.reduceEdits()
describeEdits(for: cs1)









