//
//  GridCell.swift
//  Example
//
//  Created by Wes Byrne on 1/28/17.
//  Copyright © 2017 Noun Project. All rights reserved.
//

import Foundation
import CollectionView

class GridCell : CollectionViewCell {
    
    
    
    @IBOutlet weak var badgeLabel : NSTextField!
    @IBOutlet weak var titleLabel : NSTextField!
    @IBOutlet weak var detailLabel : NSTextField!
    
    
//    override var wantsUpdateLayer: Bool { return true }
    
    
//    override func updateLayer() {
//        super.updateLayer()
//        
//    }
    
//    override func viewWillDisplay() {
//         super.viewWillDisplay()
//        self.layer?.borderColor = NSColor(white: 0.9, alpha: 1).cgColor
//        
//    }
    
    override func viewWillMove(toSuperview newSuperview: NSView?) {
        super.viewWillMove(toSuperview: newSuperview)
        self.layer?.borderColor = NSColor(white: 0.9, alpha: 1).cgColor
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if selected {
            self.backgroundColor = NSColor(white: 0.95, alpha: 1)
            self.layer?.borderWidth = 5
        }
        else {
            self.layer?.borderWidth = 0
            self.backgroundColor = self.highlighted
                ? NSColor(white: 0.95, alpha: 1)
                : NSColor(white: 0.98, alpha: 1)
        }
        self.needsDisplay = true
    }
    
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        guard !self.selected else { return }
        self.backgroundColor = highlighted
            ? NSColor(white: 0.95, alpha: 1)
            : NSColor(white: 0.98, alpha: 1)
        self.needsDisplay = true
    }
    
    
}
