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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
//        if let c = child {
//            self.badgeLabel.un
//        }
        self.badgeLabel.unbind("stringValue")
    }
    
    var child: Child?
    
    func setup(with child: Child) {
        
        self.child = child
        
        if !self.reused {
            self.layer?.cornerRadius = 3
        }
        self.badgeLabel.stringValue = "\(child.displayOrder)"
        self.titleLabel.stringValue = "Child \(child.idString)"
        self.detailLabel.stringValue = child.dateString
        
        self.badgeLabel.bind("stringValue", to: child, withKeyPath: "displayOrder", options: nil)
    }
    
    static let rBG = NSColor(white: 0.98, alpha: 1)
    static let hBG = NSColor(white: 0.95, alpha: 1)
    
    var bgColor = GridCell.rBG
    
    override func viewWillMove(toSuperview newSuperview: NSView?) {
        super.viewWillMove(toSuperview: newSuperview)
        self.layer?.borderColor = NSColor(white: 0.9, alpha: 1).cgColor
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if selected {
            self.backgroundColor = GridCell.hBG
            self.layer?.borderWidth = 5
        }
        else {
            self.layer?.borderWidth = 0
            self.backgroundColor = self.highlighted
                ? GridCell.hBG
                : bgColor
        }
        self.needsDisplay = true
    }
    
    
    override func applyLayoutAttributes(_ layoutAttributes: CollectionViewLayoutAttributes, animated: Bool) {
        super.applyLayoutAttributes(layoutAttributes, animated: animated)
        
        let ip = layoutAttributes.indexPath
//        let color = self.collectionView?.numberOfItems(in: ip._section) ?? 10
        
        
        
        var s = 1 - (CGFloat(ip._item) * 0.1)
        let h = CGFloat(ip._section) * 0.33
        if s < 0.1 {
            s = (CGFloat(ip._item) * 0.1) - 0.9
        }
        let b = 0.3 + CGFloat(ip._item) * 0.05
        
        let color = NSColor(calibratedHue: h, saturation: s, brightness: b, alpha: 1)
        self.bgColor = color
        self.backgroundColor = bgColor
        self.needsDisplay = true
        
    }
    
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        guard !self.selected else { return }
        self.backgroundColor = highlighted
            ? GridCell.hBG
            : bgColor
        self.needsDisplay = true
    }
    
    
}
