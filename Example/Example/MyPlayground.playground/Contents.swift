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


extension MutableCollection where Indices.Iterator.Element == Index {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        
        for (firstUnshuffled , unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: IndexDistance = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            guard d != 0 else { continue }
            let i = index(firstUnshuffled, offsetBy: d)
            swap(&self[firstUnshuffled], &self[i])
        }
    }
}

extension Sequence {
    /// Returns an array with the contents of this sequence, shuffled.
    func shuffled() -> [Iterator.Element] {
        var result = Array(self)
        result.shuffle()
        return result
    }
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


var source = // ["H", "F", "A", "G", "E", "C", "D"]
    [
    "H","C","D","A","E","F", "G"
].shuffled()

var target = source.sorted()
target.removeFirst()
_ = target

target.insert("B", at: 0)


func describeEdits(for changeSet: ChangeSet<[String]>) -> String {
    var str = ""
    for e in changeSet.edits {
        str += "\(e.description)\n"
    }
    return str
    
}

var cs1 = ChangeSet(source: source, target: target, options: .minimumOperations)
//var cs2 = ChangeSet(source: source, target: target)
//cs1.matrixLog
//

_ = source
_ = target

describeEdits(for: cs1)
//
cs1.reduceEdits()
describeEdits(for: cs1)
//
//
//
//cs2.matrixLog
//describeEdits(for: cs2)
//cs2.reduceEdits()
//describeEdits(for: cs2)





