////: Playground - noun: a place where people can play
//
import Cocoa
//
//var str = "Hello, playground"
//
//
//



struct Person {
    let name : String
    let age : Int
}



struct SortDescriptor<T> {
    
    enum Result {
        case same
        case ascending
        case descending
    }
    
    let ascending : Bool
    private let comparator : (T, T) -> Result
    
    init<V:Comparable>(_ keyPath: KeyPath<T,V>, ascending:Bool = true) {
        self.comparator = {
            let v1 = $0[keyPath: keyPath]
            let v2 = $1[keyPath: keyPath]
            if v1 == v2 { return .same }
            if v1 > v2 { return .descending }
            return .ascending
        }
        self.ascending = ascending
    }
    func compare(_ a:T, to b:T) -> Result {
        return comparator(a, b)
    }
}

extension Array {
    mutating func sort(using sortDescriptor: SortDescriptor<Element>) {
        self.sort(using: [sortDescriptor])
    }
    
    mutating func sort(using sortDescriptors: [SortDescriptor<Element>]) {
        self.sort { (a, b) -> Bool in
            for sortDescriptor in sortDescriptors {
                switch sortDescriptor.compare(a, to: b) {
                case .same: break
                case .descending: return !sortDescriptor.ascending
                case .ascending: return sortDescriptor.ascending
                }
            }
            return false
        }
    }
    
    mutating func sorted(using sortDescriptors: [SortDescriptor<Element>]) -> [Element] {
        return self.sorted { (a, b) -> Bool in
            for sortDescriptor in sortDescriptors {
                switch sortDescriptor.compare(a, to: b) {
                case .same: break
                case .descending: return !sortDescriptor.ascending
                case .ascending: return sortDescriptor.ascending
                }
            }
            return false
        }
    }
}



let jim = Person(name: "Jim", age: 30)
let bob = Person(name: "Bob", age: 35)
let alex = Person(name: "Alex", age: 30)
let steve = Person(name: "Steve", age: 35)



func theAgeGame(with a: Person, and b: Person) -> String {
    switch SortDescriptor(\Person.age).compare(a, to: b) {
    case .same:
        return ("\(a.name) and \(b.name) are both \(a.age)")
    case .ascending:
        return ("\(b.name)(\(b.age)) is \(b.age - a.age) years older than \(a.name)(\(a.age))")
    case .descending:
        return ("\(a.name)(\(a.age)) is \(a.age - b.age) years older than \(b.name)(\(b.age))")
    }
}

theAgeGame(with: jim, and: alex) // "Jim and Alex are both 30"
theAgeGame(with: jim, and: bob)  // "Bob(35) is 5 years older than Jim(30)"

var dudes = [steve, jim, bob, alex] // [{name "Steve", age 35}, {name "Jim", age 30}, {name "Bob", age 35}, {name "Alex", age 30}]

let ageThenName = [SortDescriptor(\Person.age), SortDescriptor(\Person.name)]
let ordered = dudes.sorted(using: ageThenName) // [{name "Alex", age 30}, {name "Jim", age 30}, {name "Bob", age 35}, {name "Steve", age 35}]






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





