//
//  IconButton.swift
//  WatchYourBAC
//
//  Created by Wesley Byrne on 10/22/15.
//  Copyright © 2015 Type2Designs. All rights reserved.
//

import Foundation
import AppKit

public extension CAShapeLayer {
    public func setPathAnimated(_ path: CGPath, duration: CFTimeInterval = 0.15) {
        self.path = path
        let anim = CABasicAnimation(keyPath: "path")
        anim.duration = duration
        anim.fromValue = self.presentation()?.value(forKeyPath: "path")
        anim.toValue = path
        anim.fillMode = kCAFillModeBoth
        anim.isAdditive = true
        anim.isRemovedOnCompletion = false
        anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        self.add(anim, forKey: "animatePath")
    }
    
    public func setPath(_ path: CGPath, animated: Bool) {
        if animated {
            self.path = path
            let anim = CABasicAnimation(keyPath: "path")
            anim.duration = duration
            anim.fromValue = self.presentation()?.value(forKeyPath: "path")
            anim.toValue = path
            anim.fillMode = kCAFillModeBoth
            anim.isAdditive = true
            anim.isRemovedOnCompletion = false
            anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            self.add(anim, forKey: "animatePath")
        }
        else {
            self.path = path
        }
    }
    
    
    func setPath(from: CGPoint, to: CGPoint) {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: from.x, y: from.y))
        path.addLine(to: CGPoint(x: to.x, y: to.y))
        self.path = path
    }
}

/**
 Available icons to use with IconButton.
 
 - None:       No icon is displayed
 - Hamburger:  A 3 bar menu hamburger
 - Close:      A close (X) icon
 - Add:        An add (+) icon
 - AngleLeft:  A left pointing cheveron (<)
 - AngleRight: A right pointing cheveron (>)
 - ArrowLeft:  A left pointing arrow
 - ArrowRight: A right pointing Arrow
 */
public enum IconType {
    case none
    case hamburger
    case close
    case add
    case angleLeft
    case angleRight
    case angleDown
    case angleUp
    case arrowLeft
    case arrowRight
    case checkmark
}


/// Display an icon (IconType), drawn and animated with core animation.
@IBDesignable open class IconButton : Button {
    
    private let iconLayer = IconLayer()
    
    /// The color of the icon while the button is highlighted
    @IBInspectable open var tintColor : NSColor {
        set { self.iconLayer.tintColor = newValue }
        get { return iconLayer.tintColor }
    }
    
    /// The color of the icon while the button is highlighted
    @IBInspectable open var highlightTintColor: NSColor?
    
    /// The size of the icon within the button. The icon is always centered
    @IBInspectable open var iconSize : CGSize {
        set { iconLayer.iconSize = newValue }
        get { return iconLayer.iconSize }
    }
    /// The width of each of the bars used to create the icons
    @IBInspectable open var barWidth : CGFloat {
        set { iconLayer.barWidth = newValue }
        get { return iconLayer.barWidth }
    }
    /// If IconType.None is set, the button will be disabled. Otherwise it is enabled.
    @IBInspectable open var autoDisable: Bool = false
    
    /// The icon currently displayed in the button (read only)
    open var iconType: IconType { get { return iconLayer.iconType }}
    
    override open var hovered : Bool {
        didSet {
            if (highlightTintColor != nil) {
                
                if self.fadeDuration == 0 {
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                }
                let color = hovered ? highlightTintColor!.cgColor : tintColor.cgColor
                iconLayer.bar1.strokeColor = color
                iconLayer.bar2.strokeColor = color
                iconLayer.bar3.strokeColor = color
                
                if self.fadeDuration == 0 {
                    CATransaction.commit()
                }
            }
        }
    }

    override func setup() {
        super.setup()
        
        self.wantsLayer = true
        if self.layer == nil {
            self.layer = self.makeBackingLayer()
        }
        self.layer?.addSublayer(iconLayer)
        self.iconLayer.frame = self.bounds
    }
    
    open override func layout() {
        super.layout()
        self.iconLayer.frame = self.bounds
    }
    
   
    /**
     Set the icon to be displayed in the button optionally animating the change.
     
     - parameter type:     A IconType to display
     - parameter animated: If the change should be animated
     */
    open func setIcon(_ type: IconType, animated: Bool) {
        let disable = self.autoDisable ? type == .none : false
        self.isEnabled = !disable
        self.iconLayer.setIcon(type, animated: animated)
    }
}





open class IconLayer : CALayer {
    
    
    public override init() {
        super.init()
        self.setup()
    }
    public override init(layer: Any) {
        super.init(layer: layer)
        self.setup()
    }
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    func setup() {
        for bar in [bar1, bar2, bar3] {
            bar.lineWidth = barWidth
            bar.fillColor = nil
            bar.lineCap = kCALineCapRound
            bar.strokeColor = self.tintColor.cgColor
            self.addSublayer(bar)
        }
        setIcon(self.iconType, animated: false)
    }
    
    
    /// The color of the icon while the button is highlighted
    open var tintColor: NSColor = NSColor.lightGray {
        didSet {
            self.bar1.strokeColor = tintColor.cgColor
            self.bar2.strokeColor = tintColor.cgColor
            self.bar3.strokeColor = tintColor.cgColor
        }
    }
    
    /// The size of the icon within the button. The icon is always centered
    open var iconSize : CGSize  = CGSize(width: 24, height: 24) {
        didSet {
            if !oldValue.equalTo(iconSize) {
                self.setIcon(self.iconType, animated: true)
            }
        }
    }
    /// The width of each of the bars used to create the icons
    open var barWidth : CGFloat = 1 {
        didSet {
            bar1.lineWidth = barWidth
            bar2.lineWidth = barWidth
            bar3.lineWidth = barWidth
        }
    }
    
    /// The icon currently displayed in the button (read only)
    open var iconType: IconType { get { return _type }}
    
    fileprivate var _type : IconType! = .hamburger
    
    fileprivate let bar1 = CAShapeLayer()
    fileprivate let bar2 = CAShapeLayer()
    fileprivate let bar3 = CAShapeLayer()
    
    fileprivate var iconFrame : CGRect {
        get {
            let refSize = self.bounds.size
            var rect = CGRect(x: (refSize.width/2) - iconSize.width/2, y: (refSize.height/2) - iconSize.height/2, width: iconSize.width, height: iconSize.height)
            rect = rect.insetBy(dx: barWidth/2, dy: barWidth/2)
            return rect
        }
    }
    override open var bounds : CGRect {
        didSet {
            if !oldValue.equalTo(self.bounds) {
                self.setIcon(self.iconType, animated: true)
            }
        }
    }
    
    override open var frame : CGRect {
        didSet {
            if !oldValue.size.equalTo(frame.size) {
                self.setIcon(self.iconType, animated: false)
            }
        }
    }
    
    
    
    /**
     Set the icon to be displayed in the button optionally animating the change.
     
     - parameter type:     A IconType to display
     - parameter animated: If the change should be animated
     */
    open func setIcon(_ type: IconType, animated: Bool) {
        if type == .none {
            setBarOpacity(0, o2: 0, o3: 0)
            let path = pathFromPosition(4, toPosition: 4)
            setBarPaths(path,
                        p2: path,
                        p3: path,
                        animated: animated)
        }
        else if type == .hamburger {
            setBarOpacity(1, o2: 1, o3: 1)
            setBarPaths(pathFromPosition(0, toPosition: 2),
                        p2: pathFromPosition(3, toPosition: 5),
                        p3: pathFromPosition(6, toPosition: 8),
                        animated: animated)
        }
        else if type == .close {
            setBarOpacity(1, o2: 0, o3: 1)
            setBarPaths(pathFromPosition(2, toPosition: 6),
                        p2: pathFromPosition(4, toPosition: 4),
                        p3: pathFromPosition(8, toPosition: 0),
                        animated: animated)
        }
        else if type == .add {
            setBarOpacity(1, o2: 0, o3: 1)
            setBarPaths(pathFromPosition(1, toPosition: 7),
                        p2: pathFromPosition(4, toPosition: 4),
                        p3: pathFromPosition(5, toPosition: 3),
                        animated: animated)
        }
        else if type == .angleLeft {
            setBarOpacity(1, o2: 0, o3: 1)
            setBarPaths(pathFromPosition(1, toPosition: 3),
                        p2: pathFromPosition(4, toPosition: 4),
                        p3: pathFromPosition(3, toPosition: 7),
                        animated: animated)
        }
        else if type == .angleRight {
            setBarOpacity(1, o2: 0, o3: 0)
            let iFrame = self.iconFrame.insetBy(dx: 0, dy: 0)
            let p1 = CGPoint(x: iFrame.midX - (iFrame.size.width/4), y: iFrame.minY)
            let p2 = CGPoint(x: iFrame.midX + (iFrame.size.width/4), y: iFrame.midY)
            let p3 = CGPoint(x: iFrame.midX - (iFrame.size.width/4), y: iFrame.maxY)
            
            let path = CGMutablePath()
            path.move(to: CGPoint(x: p1.x, y: p1.y))
            path.addLine(to: CGPoint(x: p2.x, y: p2.y))
            path.addLine(to: CGPoint(x: p3.x, y: p3.y))
            
            setBarPaths(path,
                        p2: pathFromPosition(4, toPosition: 4),
                        p3: pathFromPosition(4, toPosition: 4),
                        animated: animated)
            
            
        }
        else if type == .angleDown {
            setBarOpacity(1, o2: 0, o3: 0)
            let iFrame = self.iconFrame.insetBy(dx: 1, dy: 1)
            let p1 = CGPoint(x: iFrame.minX, y: iFrame.midY - (iFrame.size.height/4))
            let p2 = CGPoint(x: iFrame.midX, y: iFrame.midY + (iFrame.size.height/4))
            let p3 = CGPoint(x: iFrame.maxX, y: iFrame.midY - (iFrame.size.height/4))
            
            let path = CGMutablePath()
            path.move(to: CGPoint(x: p1.x, y: p1.y))
            path.addLine(to: CGPoint(x: p2.x, y: p2.y))
            path.addLine(to: CGPoint(x: p3.x, y: p3.y))
            
            setBarPaths(path,
                        p2: pathFromPosition(4, toPosition: 4),
                        p3: pathFromPosition(4, toPosition: 4),
                        animated: animated)
        }
        else if type == .angleUp {
            setBarOpacity(1, o2: 0, o3: 0)
            let iFrame = self.iconFrame.insetBy(dx: 1, dy: 1)
            let p1 = CGPoint(x: iFrame.minX, y: iFrame.midY + (iFrame.size.height/4))
            let p2 = CGPoint(x: iFrame.midX, y: iFrame.midY - (iFrame.size.height/4))
            let p3 = CGPoint(x: iFrame.maxX, y: iFrame.midY + (iFrame.size.height/4))
            
            //            p1.y -= iconFrame.size.height/4
            //            p2.y -= iconFrame.size.height/4
            //            p3.y -= iconFrame.size.height/4
            
            let path = CGMutablePath()
            path.move(to: CGPoint(x: p1.x, y: p1.y))
            path.addLine(to: CGPoint(x: p2.x, y: p2.y))
            path.addLine(to: CGPoint(x: p3.x, y: p3.y))
            
            setBarPaths(path,
                        p2: pathFromPosition(4, toPosition: 4),
                        p3: pathFromPosition(4, toPosition: 4),
                        animated: animated)
        }
        else if type == .arrowLeft {
            setBarOpacity(1, o2: 1, o3: 1)
            self.setBarPaths(pathFromPosition(1, toPosition: 3),
                             p2: pathFromPosition(3, toPosition: 5),
                             p3: pathFromPosition(3, toPosition: 7),
                             animated: animated)        }
        else if type == .arrowRight {
            setBarOpacity(1, o2: 1, o3: 1)
            self.setBarPaths(pathFromPosition(5, toPosition: 7),
                             p2: pathFromPosition(5, toPosition: 3),
                             p3: pathFromPosition(1, toPosition: 5),
                             animated: animated)
        }
        else if type == .checkmark {
            
            setBarOpacity(1, o2: 0, o3: 0)
            let iFrame = self.iconFrame.insetBy(dx: 1, dy: 1)
            let p1 = CGPoint(x: iFrame.minX, y: iFrame.midY)
            let p2 = CGPoint(x: iFrame.minX + iFrame.size.width/4, y: iFrame.midY + (iFrame.size.height/3))
            let p3 = CGPoint(x: iFrame.maxX, y: iFrame.midY - (iFrame.size.height/3))
            
            let path = CGMutablePath()
            path.move(to: CGPoint(x: p1.x, y: p1.y))
            path.addLine(to: CGPoint(x: p2.x, y: p2.y))
            path.addLine(to: CGPoint(x: p3.x, y: p3.y))
            
            setBarPaths(path,
                        p2: pathFromPosition(4, toPosition: 4),
                        p3: pathFromPosition(4, toPosition: 4),
                        animated: animated)
        }
        self._type = type;
    }
    
    fileprivate func setBarOpacity(_ o1: Float, o2: Float, o3: Float) {
        bar1.opacity = o1
        bar2.opacity = o2
        bar3.opacity = o3
    }
    
    fileprivate func setBarPaths(_ p1: CGPath, p2: CGPath, p3: CGPath, animated: Bool) {
        if animated {
            bar1.setPathAnimated(p1)
            bar2.setPathAnimated(p2)
            bar3.setPathAnimated(p3)
        }
        else {
            for bar in [bar1, bar2, bar3] {
                bar.removeAllAnimations()
            }
            bar1.path = p1
            bar2.path = p2
            bar3.path = p3
        }
        for bar in [bar1, bar2, bar3] {
            bar.lineCap = kCALineCapRound
        }
    }
    
    fileprivate func pointAtPosition(_ pos: Int) -> CGPoint {
        let iFrame = iconFrame
        var point = CGPoint(x: 0, y: 0)
        
        if (pos < 3) { point.y = iFrame.minY }
        else if pos < 6 { point.y = iFrame.midY }
        else { point.y = iFrame.maxY }
        
        let vPos = pos % 3
        if      vPos == 0 { point.x = iFrame.minX }
        else if vPos == 1 { point.x = iFrame.midX }
        else { point.x = iFrame.maxX }
        
        return point
    }
    
    fileprivate func pathFromPosition(_ p1: Int, toPosition p2: Int) -> CGPath {
        let path = NSBezierPath()
        var pt1 = pointAtPosition(p1)
        var pt2 = pointAtPosition(p2)
        
        let adjust = sqrt(min(iconSize.width, iconSize.height))/3
        
        if p1 < 3 && p2 < 3 {
            pt1.y = pt1.y + adjust
            pt2.y = pt2.y + adjust
        }
        else if p1 > 5 && p2 > 5 {
            pt1.y = pt1.y - adjust
            pt2.y = pt2.y - adjust
        }
        else if (p1 == 0 && p2 == 8) {
            pt1 = CGPoint(x: pt1.x + adjust, y: pt1.y + adjust)
            pt2 = CGPoint(x: pt2.x - adjust, y: pt2.y - adjust)
        }
        else if (p1 == 8 && p2 == 0) {
            pt1 = CGPoint(x: pt1.x - adjust, y: pt1.y - adjust)
            pt2 = CGPoint(x: pt2.x + adjust, y: pt2.y + adjust)
        }
        else if (p1 == 6 && p2 == 2) {
            pt1 = CGPoint(x: pt1.x + adjust, y: pt1.y - adjust)
            pt2 = CGPoint(x: pt2.x - adjust, y: pt2.y + adjust)
        }
        else if (p1 == 2 && p2 == 6) {
            pt1 = CGPoint(x: pt1.x - adjust, y: pt1.y + adjust)
            pt2 = CGPoint(x: pt2.x + adjust, y: pt2.y - adjust)
        }
        path.move(to: pt1)
        path.line(to: pt2)
        path.lineCapStyle = NSBezierPath.LineCapStyle.roundLineCapStyle
        return path.toCGPath()!
    }
    
    
}







extension NSBezierPath {
    func toCGPath () -> CGPath? {
        if self.elementCount == 0 {
            return nil
        }
        
        let path = CGMutablePath()
        var didClosePath = false
        
        for i in 0...self.elementCount-1 {
            var points = [NSPoint](repeating: NSZeroPoint, count: 3)
            switch self.element(at: i, associatedPoints: &points) {
            case .moveToBezierPathElement:
                if !points[0].x.isNaN && !points[0].x.isNaN {
                    path.move(to: CGPoint(x: points[0].x,y: points[0].y))
                }
            case .lineToBezierPathElement:
                if !points[0].x.isNaN && !points[0].x.isNaN {
                    path.addLine(to: CGPoint(x: points[0].x, y: points[0].y))
                }
            case .curveToBezierPathElement:
                if !points[0].x.isNaN && !points[0].x.isNaN
                    && !points[1].x.isNaN && !points[1].x.isNaN
                    && !points[2].x.isNaN && !points[2].x.isNaN {
                    
                    path.addCurve(to: CGPoint(x: points[0].x, y: points[0].y),
                                  control1: CGPoint(x: points[1].x, y: points[1].y),
                                  control2: CGPoint(x: points[2].x, y: points[2].y))
                }
            case .closePathBezierPathElement:path.closeSubpath()
            didClosePath = true;
            }
        }
        
        if !didClosePath && !path.isEmpty {
            path.closeSubpath()
        }
        
        return path.copy()
    }
}




extension NSImage {
    func tintedImageWithColor(_ tintColor: NSColor?) -> NSImage {
        if tintColor == nil || self.size == CGSize.zero { return self }
        let size = self.size
        let bounds = NSRect(origin: CGPoint.zero, size: size)
        guard let copy = self.copy() as? NSImage else { return self }
        NSGraphicsContext.saveGraphicsState()
        copy.isTemplate = false
        copy.lockFocus()
        tintColor?.set()
        bounds.fill(using: NSCompositingOperation.sourceAtop)
        copy.unlockFocus()
        NSGraphicsContext.restoreGraphicsState()
        return copy
    }
    
    
}








class ButtonCell : NSButtonCell {
    
    override func drawTitle(_ title: NSAttributedString, withFrame frame: NSRect, in controlView: NSView) -> NSRect {
        return super.drawTitle(self.attributedTitle, withFrame: frame, in: controlView)
    }
    
}


@IBDesignable open class Button : NSButton {
    
    @IBInspectable open var backgroundColor: NSColor? = nil
    @IBInspectable open var backgroundHoverColor: NSColor? = nil
    @IBInspectable open var backgroundDisableColor: NSColor? = nil
    @IBInspectable open var fadeDuration : Double = 0
    
    @IBInspectable open var cornerRadius : CGFloat = 0
    
    /// The border width
    @IBInspectable open var borderWidth: CGFloat = 0
    /// The border color
    @IBInspectable open var borderColor: NSColor = NSColor.lightGray
    @IBInspectable open var borderHoverColor: NSColor? = nil
    @IBInspectable open var borderDisableColor: NSColor? = nil
    
    @IBInspectable var titlePadding: CGFloat = 0 { didSet { needsDisplay = true }}
    @IBInspectable open var titleColor: NSColor! = NSColor.black { didSet { self.updateColors() }}
    @IBInspectable open var titleHoverColor: NSColor? = nil
    @IBInspectable open var titleDisableColor: NSColor? = nil
    
    @IBInspectable open var imageTint : NSColor? = nil { didSet { self.updateColors() }}
    @IBInspectable open var imageHoverTint : NSColor? = nil
    @IBInspectable open var imageDisableTint: NSColor? = nil
    
    @IBInspectable var useLayer : Bool = false
    @IBInspectable var clipsSubviews : Bool = false
    
    open override var wantsDefaultClipping: Bool { return self.clipsSubviews }
    override open var title : String { didSet { self.updateColors() }}
    
    open override var intrinsicContentSize: NSSize {
        var size = super.intrinsicContentSize
        if titlePadding > 0 {
            size.width += (titlePadding * 2)
        }
        return size
    }
    
    
    @IBInspectable var clickScale : CGFloat = 0
    
    override open var isEnabled: Bool { didSet {
        self.needsDisplay = true
        self.updateColors()
        }}
    
    open override var wantsUpdateLayer: Bool { return self.useLayer }
    
    var hovered : Bool = false {
        didSet {
            if hovered == oldValue { return }
            self.updateColors()
            self.needsDisplay = true
        }
    }
    
    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setup()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        self.updateColors()
    }
    
    open func setTintedImage(_ image: NSImage?) {
        self.image = image?.tintedImageWithColor(self._imgTint)
    }
    
    func setup() {
        self.isBordered = false
        (self.cell as? NSButtonCell)?.highlightsBy = NSCell.StyleMask()
        (self.cell as? NSButtonCell)?.imageDimsWhenDisabled = false
        self.bezelStyle = NSButton.BezelStyle.rounded
        self.wantsLayer = useLayer
        self.enableTracking()
        self.image = self.image?.tintedImageWithColor(self.imageTint)
    }
    
    var _imgTint : NSColor? {
        var tint : NSColor?
        if !isEnabled { tint = self.imageDisableTint }
        else if hovered { tint = self.imageHoverTint }
        return tint ?? self.imageTint
    }
    
    
    func updateColors() {
        self.image = self.image?.tintedImageWithColor(self._imgTint)
        
        var tColor : NSColor?
        if !isEnabled { tColor = self.titleDisableColor }
        else if hovered { tColor = self.titleHoverColor }
        
        if tColor == nil {
            tColor = self.titleColor
        }
        
        let t = NSMutableAttributedString(attributedString: self.attributedTitle)
        let range = NSMakeRange(0, t.length)
        t.removeAttribute(NSAttributedStringKey.foregroundColor, range: range)
        t.addAttribute(NSAttributedStringKey.foregroundColor, value: tColor!, range: range)
        self.attributedTitle = t
    }
    
    open override func updateLayer() {
        
        self.layer?.masksToBounds = self.clipsSubviews
        self.layer?.cornerRadius = self.cornerRadius
        var bgColor : NSColor? = nil
        if !self.isEnabled { bgColor = self.backgroundDisableColor }
        else if self.hovered { bgColor = self.backgroundHoverColor }
        
        self.layer?.backgroundColor = (bgColor ?? self.backgroundColor)?.cgColor
        
        if self.borderWidth != 0 {
            var sColor : NSColor? = nil
            if !self.isEnabled { sColor = self.borderDisableColor }
            else if self.hovered { sColor = self.borderHoverColor }
            self.layer?.borderColor = (sColor ?? self.borderColor).cgColor
        }
        self.layer?.borderWidth = self.borderWidth
        
    }
    
    
    open override func draw(_ dirtyRect: NSRect) {
        if self.fadeDuration > 0 {
            super.draw(dirtyRect)
            return
        }
        NSGraphicsContext.saveGraphicsState()
        
        let path = NSBezierPath(roundedRect: self.bounds, xRadius: self.cornerRadius, yRadius: self.cornerRadius)
        
        var bgColor : NSColor? = nil
        if !self.isEnabled { bgColor = self.backgroundDisableColor }
        else if self.hovered { bgColor = self.backgroundHoverColor }
        
        
        if let bc = bgColor ?? self.backgroundColor {
            bc.setFill()
            path.fill()
        }
        if self.borderWidth != 0 {
            
            var sColor : NSColor? = nil
            if !self.isEnabled { sColor = self.borderDisableColor }
            else if self.hovered { sColor = self.borderHoverColor }
            (sColor ?? self.borderColor).setStroke()
            path.addClip()
            path.lineWidth = borderWidth * 2
            path.stroke()
        }
        NSGraphicsContext.restoreGraphicsState()
        super.draw(dirtyRect)
    }
    
    
    override open func mouseEntered(with theEvent: NSEvent) {
        if let view = self.window?.contentView?.hitTest(theEvent.locationInWindow), view.isDescendant(of: self) {
            super.mouseEntered(with: theEvent)
            hovered = true
        }
    }
    
    override open func mouseExited(with theEvent: NSEvent) {
        super.mouseExited(with: theEvent)
        hovered = false
    }
    
    
    open override func acceptsFirstMouse(for theEvent: NSEvent?) -> Bool {
        return true
    }
    var trackingEnabled = true
    fileprivate var _trackingArea : NSTrackingArea?
    open func disableTracking() {
        self.trackingEnabled = false
        self.updateTrackingAreas()
    }
    open func enableTracking() {
        self.trackingEnabled = true
        self.updateTrackingAreas()
    }
    
    var stayHighlighted = false
    open override func updateTrackingAreas() {
        if let tArea = self._trackingArea {
            self.removeTrackingArea(tArea)
            self._trackingArea = nil
        }
        if trackingEnabled {
            self._trackingArea = NSTrackingArea(rect: self.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeInActiveApp], owner: self, userInfo: nil)
            self.addTrackingArea(self._trackingArea!)
            if hovered, let wPoint = self.window?.convertFromScreen(CGRect(origin: NSEvent.mouseLocation, size: CGSize.zero)).origin {
                let point = self.convert(wPoint, from: nil)
                if !self.bounds.contains(point) {
                    self.hovered = false
                }
            }
        }
        else if !stayHighlighted { self.hovered = false }
    }
}




