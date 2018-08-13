/*:
 
# Collection View
 
This playground includes some of the utilities in the CollectionView library
*/

import Cocoa
import CollectionView

//: ## Sort Descriptors
struct Person {
    let name: String
    let age: Int
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

var dudes = [steve, jim, bob, alex]

let ageThenName = [SortDescriptor(\Person.age), SortDescriptor(\Person.name)]
let ordered = dudes.sorted(using: ageThenName)

//: ## CollectionView editing

class Section {
    enum State {
        case updated(index: Int, count: Int)
        case inserted(index: Int)
        case deleted(index: Int)
    }
    var target: Int?
    var state: State
    var expected: Int {
        if case let .updated(_, count) = self.state {
            return count + inserted.count - removed.count
        }
        return 0
    }
    var inserted = Set<IndexPath>()
    var removed = Set<IndexPath>()

    init(index: Int, count: Int) {
        self.state = .updated(index: index, count: count)
    }
}

var data = [5, 5, 5, 5]
//var insert : [IndexPath] = [[0,2], [2,0]]
//var remove : [IndexPath] = [[0,2], [2,0]]

//var sections = [Section]()
//for s in data.enumerated() {
//    sections.append(Section(index: s.offset, count: s.element))
//}
