//
//  Helpers.swift
//  Example
//
//  Created by Wesley Byrne on 1/30/17.
//  Copyright © 2017 Noun Project. All rights reserved.
//

import Foundation


extension String {
    
    var numericString : String {
        let set = CharacterSet(charactersIn: "0123456789.")
        return self.stringByValidatingCharactersInSet(set)
    }
    
    func stringByValidatingCharactersInSet(_ set: CharacterSet) -> String {
        let comps = self.components(separatedBy: set.inverted)
        return comps.joined(separator: "")
    }
    
    
    
    func sub(to: Int) -> String {
        let idx = self.index(self.startIndex,
                             offsetBy: to)
        return self.substring(to: idx)
    }
    
    func sub(from: Int) -> String {
        let idx = self.index(from >= 0 ? self.startIndex: self.endIndex,
                             offsetBy: from)
        return self.substring(from: idx)
    }
    
    func sub(from: Int, to: Int) -> String {
        let start = self.index(self.startIndex, offsetBy: from)
        let end = self.index(self.startIndex, offsetBy: to)
        return String(self[start..<end])
    }
    
}
