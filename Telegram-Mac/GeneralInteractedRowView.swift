//
//  GeneralInteractedRowView.swift
//  Telegram-Mac
//
//  Created by keepcoder on 12/10/2016.
//  Copyright © 2016 Telegram. All rights reserved.
//

import Cocoa
import TGUIKit


class GeneralInteractedRowView: GeneralRowView {
    
    private(set) var switchView:SwitchView?
    private(set) var textView:TextView?
    private(set) var descriptionView: TextView?
    private var nextView:ImageView = ImageView()
    
    override func set(item:TableRowItem, animated:Bool = false) {
        
        
        nextView.image = theme.icons.generalNext
        

        if let item = item as? GeneralInteractedRowItem {
            
            if let descLayout = item.descLayout {
                if descriptionView == nil {
                    descriptionView = TextView()
                    descriptionView?.userInteractionEnabled = false
                    descriptionView?.isSelectable = false
                    addSubview(descriptionView!)
                }
                descriptionView?.update(descLayout)
            } else {
                descriptionView?.removeFromSuperview()
                descriptionView = nil
            }
            
            nextView.isHidden = true
            if case let .switchable(stateback) = item.type {
                if switchView == nil {
                    switchView = SwitchView(frame: NSMakeRect(0, 0, 32, 20))
                    addSubview(switchView!)
                }
                switchView?.autoswitch = item.autoswitch
                switchView?.presentation = item.switchAppearance
                switchView?.setIsOn(stateback,animated:animated)
                
                switchView?.stateChanged = item.action
                switchView?.userInteractionEnabled = item.enabled
            } else {
                switchView?.removeFromSuperview()
                switchView = nil
            }
            
            if case let .image(stateback) = item.type {
                nextView.image = stateback
                nextView.sizeToFit()
                nextView.isHidden = false
            }
            
            switch item.type {
            case let .context(value), let .nextContext(value), let .contextSelector(value, _):
                if textView == nil {
                    textView = TextView()
                    textView?.animates = false
                    textView?.userInteractionEnabled = false
                    textView?.isEventLess = true
                    addSubview(textView!)
                }
                let layout = item.isSelected ? nil : TextViewLayout(.initialize(string: value, color: isSelect ? theme.colors.underSelectedColor : theme.colors.grayText, font: .normal(.title)), maximumNumberOfLines: 1)
                
                textView?.set(layout: layout)
                
                nextView.isHidden = false
            default:
                textView?.removeFromSuperview()
                textView = nil
            }
            
            
            textView?.backgroundColor = theme.colors.background
            
           
            
            
            if case let .selectable(value) = item.type {
                nextView.isHidden = !value
                nextView.image = theme.icons.generalCheck
                nextView.sizeToFit()
            }
            
            var needNextImage: Bool = false
            if case .colorSelector = item.type {
                needNextImage = true
            }
            if case .next = item.type {
                needNextImage = true
            }
            if case .nextContext = item.type {
                needNextImage = true
            }
            if needNextImage {
                nextView.isHidden = false
                nextView.image = item.isSelected ? nil : theme.icons.generalNext
                nextView.sizeToFit()
            }
            
            
        }
        super.set(item: item, animated: animated)
        self.needsLayout = true
        self.needsDisplay = true
    }
    
    override var backdorColor: NSColor {
        return isSelect ? theme.colors.blueSelect : theme.colors.background
    }
    private var mouseIsDown: Bool = false
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        mouseIsDown = true
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        if mouseInside(), mouseIsDown, event.clickCount == 1, let item = item as? GeneralInteractedRowItem {
            if item.enabled {
                if let textView = self.textView {
                    switch item.type {
                    case let .contextSelector(_, items):
                        showPopover(for: textView, with: SPopoverViewController(items: items), edge: .minX, inset: NSMakePoint(0,-30))
                        return
                    default:
                        break
                    }
                }
                
                
                item.action()
                switch item.type {
                case let .switchable(enabled):
                    if item.autoswitch {
                        item.type = .switchable(!enabled)
                        self.switchView?.setIsOn(!enabled)
                    }
                    
                default:
                    break
                }
            } else {
                item.disabledAction()
            }
        }
        mouseIsDown = false
    }
    
    override func updateColors() {
        super.updateColors()
        descriptionView?.backgroundColor = backdorColor
        textView?.backgroundColor = backdorColor
        
        if isSelect {
            // overlay.set(background: .clear, for: .Highlight)
        } else {
            //overlay.set(background: theme.colors.grayTransparent, for: .Highlight)
            
        }
        // overlay.set(background: backdorColor, for: .Hover)
        
    }
    
    override func shakeView() {
        self.shake()
    }
    
    private var textXAdditional: CGFloat {
        var textXAdditional:CGFloat = 0
        guard let item = item as? GeneralInteractedRowItem else {return 0}
        let t = item.isSelected ? item.activeThumb : item.thumb
        if let thumb = t {
            if let textInset = thumb.textInset {
                textXAdditional = textInset
            } else {
                textXAdditional = thumb.thumb.backingSize.width + 10
            }
        }
        return textXAdditional
    }
    
    override func draw(_ layer: CALayer, in ctx: CGContext) {
        
        super.draw(layer, in: ctx)
        
        if let item = item as? GeneralInteractedRowItem {
            
            
            let t = item.isSelected ? item.activeThumb : item.thumb
            if let thumb = t {
                var f = focus(thumb.thumb.backingSize)
                if item.descLayout != nil {
                    f.origin.y = 11
                }
                let icon = thumb.thumb //isSelect ? ControlStyle(highlightColor: .white).highlight(image: thumb.thumb) : 
                ctx.draw(icon, in: NSMakeRect(item.inset.left, f.minY, f.width, f.height))
            }
            
            if item.drawCustomSeparator, !isSelect {
                ctx.setFillColor(theme.colors.border.cgColor)
                ctx.fill(NSMakeRect(textXAdditional + item.inset.left, frame.height - .borderSize, frame.width - (item.inset.left + item.inset.right + textXAdditional), .borderSize))
            }
            
            if let nameLayout = (item.isSelected ? item.nameLayoutSelected : item.nameLayout) {
                var textRect = focus(NSMakeSize(nameLayout.0.size.width,nameLayout.0.size.height))
                textRect.origin.x = item.inset.left + textXAdditional
                textRect.origin.y -= 1
                if item.descLayout != nil {
                    textRect.origin.y = 10
                }
                
                nameLayout.1.draw(textRect, in: ctx, backingScaleFactor: backingScaleFactor, backgroundColor: backgroundColor)
            }
            
            if case let .colorSelector(stateback) = item.type {
                ctx.setFillColor(stateback.cgColor)
                ctx.fillEllipse(in: NSMakeRect(frame.width - 14 - item.inset.right - 16, floorToScreenPixels(scaleFactor: backingScaleFactor, (frame.height - 14) / 2), 14, 14))
            }
        }
        
    }
    
    required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        nextView.sizeToFit()
        addSubview(nextView)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    override func layout() {
        super.layout()
        
        if let item = item as? GeneralInteractedRowItem {
            let inset = general?.inset ?? NSEdgeInsetsZero
            
            if let descriptionView = descriptionView {
                
                descriptionView.setFrameOrigin(inset.left + textXAdditional, floorToScreenPixels(scaleFactor: backingScaleFactor, frame.height - descriptionView.frame.height - 6))
            }
            
            let nextInset = nextView.isHidden ? 0 : nextView.frame.width + 6 + (inset.right == 0 ? 10 : 0)
            
            if let switchView = switchView {
                switchView.centerY(x:frame.width - inset.right - switchView.frame.width - nextInset)
            }
            if let textView = textView {
                var width:CGFloat = 100
                if let name = item.nameLayout {
                    width = frame.width - name.0.size.width - nextInset - inset.right - inset.left - 10
                }
                
                
                textView.layout?.measure(width: width)
                textView.update(textView.layout)
                textView.centerY(x:frame.width - inset.right - textView.frame.width - nextInset)
                if !nextView.isHidden {
                    textView.setFrameOrigin(textView.frame.minX,textView.frame.minY - 1)
                }
            }
            nextView.centerY(x: frame.width - (inset.right == 0 ? 10 : inset.right) - nextView.frame.width)
        }
        
        
    }
    
}
