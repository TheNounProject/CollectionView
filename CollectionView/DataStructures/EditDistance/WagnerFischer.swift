import Foundation

// https://en.wikipedia.org/wiki/Wagner%E2%80%93Fischer_algorithm

public final class WagnerFischer: DiffAware {
    
    private let reduceMove: Bool
    
//    public typealias Element = T.Iterator.Element
    
    public init(reduceMove: Bool = false) {
        self.reduceMove = reduceMove
    }
    
    public func diff<T: Collection>(old: T, new: T) -> [Edit<T.Iterator.Element>] where T.Iterator.Element:Hashable, T.Index == Int {
        let previousRow = Row<T>()
        previousRow.seed(with: new)
        let currentRow = Row<T>()
        
        // row in matrix
        old.enumerated().forEach { indexInOld, oldItem in
            // reset current row
            currentRow.reset(
                count: previousRow.slots.count,
                indexInOld: indexInOld,
                oldItem: oldItem
            )
            
            // column in matrix
            new.enumerated().forEach { indexInNew, newItem in
                if isEqual(oldItem: old[indexInOld], newItem: new[indexInNew]) {
                    currentRow.update(indexInNew: indexInNew, previousRow: previousRow)
                } else {
                    currentRow.updateWithMin(
                        previousRow: previousRow,
                        indexInNew: indexInNew,
                        newItem: newItem,
                        indexInOld: indexInOld,
                        oldItem: oldItem
                    )
                }
            }
            
            // set previousRow
            previousRow.slots = currentRow.slots
        }
        
        let changes = currentRow.lastSlot()
//        if reduceMove {
//            return MoveReducer<T>().reduce(changes: changes)
//        } else {
            return changes
//        }
    }
    
    // MARK: - Helper
    
    private func isEqual<T: Hashable>(oldItem: T, newItem: T) -> Bool {
        // Same items must have same hashValue
        if oldItem.hashValue != newItem.hashValue {
            return false
        } else {
            // Different hashValue does not always mean different items
            return oldItem == newItem
        }
    }
    
}

//struct MoveReducer<T> {
//    func reduce<T: Equatable>(changes: [Edit<T>]) -> [Edit<T>] {
//        // Find pairs of .insert and .delete with same item
//        let inserts = changes.filter { (e) -> Bool in
//            return e.operation.isInsertion
//        }
//
//        if inserts.isEmpty {
//            return changes
//        }
//
//        var changes = changes
//        inserts.forEach { insert in
//            if let insertIndex = changes.index(where: { $0.insert?.item == insert.item }),
//                let deleteIndex = changes.index(where: { $0.delete?.item == insert.item }) {
//
//                let insertChange = changes[insertIndex].insert!
//                let deleteChange = changes[deleteIndex].delete!
//
//                let move = Move<T>(item: insert.item, fromIndex: deleteChange.index, toIndex: insertChange.index)
//
//                // .insert can be before or after .delete
//                let minIndex = min(insertIndex, deleteIndex)
//                let maxIndex = max(insertIndex, deleteIndex)
//
//                // remove both .insert and .delete, and replace by .move
//                changes.remove(at: minIndex)
//                changes.remove(at: maxIndex.advanced(by: -1))
//                changes.insert(.move(move), at: minIndex)
//            }
//        }
//
//        return changes
//    }
//}



// We can adapt the algorithm to use less space, O(m) instead of O(mn),
// since it only requires that the previous row and current row be stored at any one time
class Row<T:Collection> where T.Iterator.Element:Hashable {
    
    public typealias Element = T.Iterator.Element
    
    /// Each slot is a collection of Change
    var slots: [[Edit<Element>]] = []
    
    /// Seed with .insert from new
    func seed(with new: T) {
        // First slot should be empty
        slots = Array(repeatElement([], count: new.count + 1))
        
        // Each slot increases in the number of changes
        new.enumerated().forEach { index, item in
            let slotIndex = convert(indexInNew: index)
            slots[slotIndex] = combine(
                slot: slots[slotIndex-1],
                change:  Edit(.insertion, value: item, index: index)
            )
            
            
        }
    }
    
    /// Reset with empty slots
    /// First slot is .delete
    func reset(count: Int, indexInOld: Int, oldItem: Element) {
        if slots.isEmpty {
            slots = Array(repeatElement([], count: count))
        }
        slots[0] = combine(
            slot: slots[0],
            change: Edit(.deletion, value: oldItem, index: indexInOld)
        )
    }
    
    /// Use .replace from previousRow
    func update(indexInNew: Int, previousRow: Row) {
        let slotIndex = convert(indexInNew: indexInNew)
        slots[slotIndex] = previousRow.slots[slotIndex - 1]
    }
    
    /// Choose the min
    func updateWithMin(previousRow: Row, indexInNew: Int, newItem: Element, indexInOld: Int, oldItem: Element) {
        let slotIndex = convert(indexInNew: indexInNew)
        let topSlot = previousRow.slots[slotIndex]
        let leftSlot = slots[slotIndex - 1]
        let topLeftSlot = previousRow.slots[slotIndex - 1]
        
        let minCount = min(topSlot.count, leftSlot.count, topLeftSlot.count)
        
        // Order of cases does not matter
        switch minCount {
        case topSlot.count:
            slots[slotIndex] = combine(
                slot: topSlot,
                change: Edit(.deletion, value: oldItem, index: indexInOld)
            )
        case leftSlot.count:
            slots[slotIndex] = combine(
                slot: leftSlot,
                change: Edit(.insertion, value: newItem, index: indexInNew) //.insert(Insert(item: newItem, index: indexInNew))
            )
        case topLeftSlot.count:
            slots[slotIndex] = combine(
                slot: topLeftSlot,
                change: Edit(.substitution, value: newItem, index: indexInNew)
            )
        default:
            assertionFailure()
        }
    }
    
    /// Add one more change
    func combine(slot: [Edit<Element>], change: Edit<Element>) -> [Edit<Element>] {
        var slot = slot
        slot.append(change)
        return slot
    }
    
    //// Last slot
    func lastSlot() -> [Edit<Element>] {
        return slots[slots.count - 1]
    }
    
    /// Convert to slotIndex, as slots has 1 extra at the beginning
    func convert(indexInNew: Int) -> Int {
        return indexInNew + 1
    }
}

