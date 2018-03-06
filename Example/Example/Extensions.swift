//
//  Extensions.swift
//  Example
//
//  Created by Wesley Byrne on 2/22/18.
//  Copyright © 2018 Noun Project. All rights reserved.
//

import Foundation
import AppKit


func repeatBlock(_ count: Int, block: ()->Void) {
    for _ in 0..<count {
        block()
    }
}

extension Int {
    
    static func random(in range: ClosedRange<Int>) -> Int {
        let min = range.lowerBound
        let max = range.upperBound
        return Int(arc4random_uniform(UInt32(1 + max - min))) + min
    }
    
    func sampleSize(_ size: Float) -> Int {
        return Swift.min(Int(round(Float(self)/size)), self)
    }
}

extension MutableCollection {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        
        for (firstUnshuffled, unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: IndexDistance = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            let i = index(firstUnshuffled, offsetBy: d)
            swapAt(firstUnshuffled, i)
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

extension Array {
    
    
    func random() -> Element? {
        guard self.count > 0 else { return nil }
        let idx = Int.random(in: 0...self.count - 1)
        return self[idx]
    }
    mutating func removeRandom() -> Element? {
        guard self.count > 0 else { return nil }
        let idx = Int.random(in: 0...self.count - 1)
        return self.remove(at: idx)
    }
    
    mutating func sample(_ size: Float) -> [Element] {
        guard self.count > 1 else { return [] }
        let by =  Swift.max(1, self.count.sampleSize(size))
        var sample = [Element]()
        for idx in stride(from: self.count - 1, through: 0, by: -by) {
            sample.append(self.remove(at: idx))
        }
        return sample
    }
}

class ActionMenuItem : NSMenuItem {
    
    typealias Handler = ((ActionMenuItem)->Void)
    let handler : Handler
    
    init(title: String, handler: @escaping Handler) {
        self.handler = handler
        super.init(title: title, action: #selector(ActionMenuItem.selected(_:)), keyEquivalent: "")
        self.target = self
    }
    
    required init(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func selected(_ sender: Any) {
        self.handler(self)
    }
}
