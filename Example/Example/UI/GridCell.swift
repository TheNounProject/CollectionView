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
//        self.badgeLabel.unbind("value")
    }
    
    var child: Child?
    
    func setup(with child: Child) {
        
        self.badgeLabel.unbind("value")
        
        self.child = child
        
        if !self.reused {
            self.layer?.cornerRadius = 3
        }
        self.badgeLabel.stringValue = "\(child.displayOrder)"
        self.titleLabel.stringValue = "Child \(child.idString)"
        self.detailLabel.stringValue = child.dateString
        
//        self.badgeLabel.bind("value", to: child, withKeyPath: "displayOrder", options: nil)
    }
    
    override var description: String {
        return "GridCell: \(child?.description ?? nil)"
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
        
        if self.child?.isDeleted != false || self.child?.displayOrder.intValue != ip._item {
            self.bgColor = NSColor.orange
        }
        else {
            self.bgColor = NSColor(white: 0.98, alpha: 1)
        }
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
