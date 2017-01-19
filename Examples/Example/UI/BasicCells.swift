//
//  BasicCells.swift
//  Lingo
//
//  Created by Wesley Byrne on 4/6/16.
//  Copyright © 2016 The Noun Project. All rights reserved.
//

import Foundation
import CollectionView



protocol BasicHeaderDelegate : class {
    func basicHeaderView(_ view: BasicHeaderView, didSelectButton button: IconButton)
}


final class BasicHeaderView : CollectionReusableView {
    
    let titleLabel = NSTextField(frame: CGRect.zero)
    let accessoryButton = IconButton(frame: CGRect.zero)
    
    weak var delegate : BasicHeaderDelegate?
    
    var titleInset : CGFloat {
        set { _titleInset.constant = newValue }
        get { return _titleInset.constant }
    }
    private var _titleInset : NSLayoutConstraint!
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        titleLabel.isBordered = false
        titleLabel.drawsBackground = false
        accessoryButton.isBordered = false
        accessoryButton.imageTint = NSColor.gray
        accessoryButton.imageHoverTint = NSColor.darkGray
        
        accessoryButton.iconSize = CGSize(width: 12, height: 12)
        accessoryButton.barWidth = 1
        accessoryButton.autoDisable = false
        accessoryButton.title = ""
        accessoryButton.target = self
        accessoryButton.action = #selector(accessoryButtonSelected(_:))
        
        self.addSubview(accessoryButton)
        self.addSubview(titleLabel)
        
        accessoryButton.addSizeConstraints(NSSize(width: 30, height: 30))
        
        accessoryButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        
        
        _titleInset = NSLayoutConstraint(item: titleLabel, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 8)
        
        self.addConstraints([
            _titleInset,
            NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: titleLabel, attribute: .centerY, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: titleLabel, attribute: .right, relatedBy: .equal, toItem: accessoryButton, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .right, relatedBy: .equal, toItem: accessoryButton, attribute: .right, multiplier: 1, constant: 6),
            NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: accessoryButton, attribute: .centerY, multiplier: 1, constant: 0)
            ])
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    var drawBorder: Bool = true {
        didSet { self.needsDisplay = true }
    }
    
    class func register(_ collectionView: CollectionView) {
        collectionView.registerClass(BasicHeaderView.self, forSupplementaryViewOfKind: CollectionViewLayoutElementKind.SectionHeader, withReuseIdentifier: "BasicHeaderView")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        NSColor(white: 1, alpha: 0.95).setFill()
        NSRectFill(dirtyRect)
        
        if drawBorder {
            let context = NSGraphicsContext.current()!.cgContext
            context.setLineWidth(1)
            context.setStrokeColor(NSColor(white: 0, alpha: 0.08).cgColor)
            
            context.move(to: CGPoint.zero)
            context.addLine(to: CGPoint(x: self.bounds.size.width, y: 0))
            context.strokePath()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.accessoryButton.setIcon(.none, animated: false)
    }
    
    @IBAction func accessoryButtonSelected(_ sender: AnyObject) {
        self.delegate?.basicHeaderView(self, didSelectButton: accessoryButton)
    }
    
    
}

