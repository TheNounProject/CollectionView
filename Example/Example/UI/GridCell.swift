//
//  GridCell.swift
//  Example
//
//  Created by Wes Byrne on 1/28/17.
//  Copyright © 2017 Noun Project. All rights reserved.
//

import Foundation
import CollectionView


class GridCell : CollectionViewPreviewCell {
    
    @IBOutlet weak var badgeLabel : NSTextField!
    @IBOutlet weak var titleLabel : NSTextField!
    @IBOutlet weak var detailLabel : NSTextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.useMask = false
//        self.badgeLabel.isHidden = true
//        self.titleLabel.isHidden = true
//        self.detailLabel.isHidden = true
    }
    override var wantsUpdateLayer: Bool { return true }
    override func prepareForReuse() {
        super.prepareForReuse()
        self.badgeLabel.unbind(NSBindingName(rawValue: "value"))
        self.titleLabel.unbind(NSBindingName(rawValue: "value"))
    }
    
    var child: Child?
    
    func setup(with child: Child) {
        self.child = child
        
        if !self.reused {
            self.layer?.cornerRadius = 3
        }
        self.badgeLabel.stringValue = "\(child.displayOrder)"
        self.titleLabel.stringValue = child.name
        self.detailLabel.stringValue = ""
        
        self.badgeLabel.bind(NSBindingName(rawValue: "value"), to: child, withKeyPath: "displayOrder", options: nil)
        self.titleLabel.bind(NSBindingName(rawValue: "value"), to: child, withKeyPath: "name", options: nil)
    }

    
    override class var defaultReuseIdentifier : String {
        return "GridCell"
    }
    
    override class func register(in collectionView: CollectionView) {
        collectionView.register(nib: NSNib(nibNamed: NSNib.Name(rawValue: "GridCell"), bundle: nil)!, forCellWithReuseIdentifier: self.defaultReuseIdentifier)
    }
    
    
    override var description: String {
        return "GridCell: \(child?.description ?? "nil")"
    }
    
    static let rBG = NSColor(white: 0.98, alpha: 1)
    static let hBG = NSColor(white: 0.95, alpha: 1)
    
    var bgColor = GridCell.rBG
    
    override func viewWillMove(toSuperview newSuperview: NSView?) {
        super.viewWillMove(toSuperview: newSuperview)
        self.layer?.borderColor = NSColor(white: 0.9, alpha: 1).cgColor
    }
    
    
    
    // MARK: - Selection & Highlighting
    /*-------------------------------------------------------------------------------*/
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
    
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        guard !self.selected else { return }
        self.backgroundColor = highlighted
            ? GridCell.hBG
            : bgColor
        self.needsDisplay = true
    }
}


