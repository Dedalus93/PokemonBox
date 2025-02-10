//
//  UILabel+Padding.swift
//  PokemonBox
//
//  Created by Samith Aturaliyage on 09/02/25.
//

import UIKit

class PaddingLabel: UILabel {
    
    /// Insets for the label’s text.
    var textInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8) {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsDisplay()
        }
    }
    
    // Override the drawing method to apply the insets.
    override func drawText(in rect: CGRect) {
        let insetRect = rect.inset(by: textInsets)
        super.drawText(in: insetRect)
    }
    
    // Override the intrinsic content size to include the insets.
    override var intrinsicContentSize: CGSize {
        let originalSize = super.intrinsicContentSize
        let width = originalSize.width + textInsets.left + textInsets.right
        let height = originalSize.height + textInsets.top + textInsets.bottom
        return CGSize(width: width, height: height)
    }
    
    // Optionally override sizeThatFits if you're not using Auto Layout.
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let adjustedSize = super.sizeThatFits(size)
        return CGSize(width: adjustedSize.width + textInsets.left + textInsets.right,
                      height: adjustedSize.height + textInsets.top + textInsets.bottom)
    }
}

