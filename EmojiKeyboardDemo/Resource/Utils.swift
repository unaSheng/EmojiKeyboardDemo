//
//  Utils.swift
//  EmojiKeyboardDemo
//
//  Created by li.wenxiu on 2024/7/22.
//

import Foundation
import UIKit
import Algorithms

class Utils {
    
    static func textAttributeValue(for attribute: NSAttributedString.Key, in label: UILabel, lineHeight: CGFloat? = nil, at point: CGPoint) -> Any? {
        guard let attributedText = label.attributedText else { return nil }
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: label.bounds.size)
        let textStorage = NSTextStorage(attributedString: attributedText)
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        layoutManager.ensureGlyphs(forGlyphRange: layoutManager.glyphRange(for: textContainer))
        layoutManager.ensureLayout(for: textContainer)
        let locationOfTouchInLabel = point
        let textBoundingBox: CGRect
        let lines = (label.attributedText?.boundingRect(with: label.bounds.size, options: [.usesFontLeading,.usesLineFragmentOrigin], context: nil).height ?? 0) / max(1, (lineHeight ?? 0), label.font.lineHeight)
        if lines < 2 {
            textBoundingBox = label.bounds
        } else {
            textBoundingBox = layoutManager.usedRect(for: textContainer)
        }
        let labelSize = label.bounds.size
        let textContainerOffset = CGPoint(x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x, y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y)
        let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x, y: locationOfTouchInLabel.y - textContainerOffset.y)
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        guard indexOfCharacter >= 0 && indexOfCharacter < attributedText.length else {
            return nil
        }
        return attributedText.attribute(attribute, at: indexOfCharacter, effectiveRange: nil)
    }
}

struct AttributedStringLineInfo {
    var range: NSRange
    var attributedString: NSAttributedString
}


extension NSAttributedString {
    func numberOfLines(maxWidth width: CGFloat) -> [AttributedStringLineInfo] {
        // 创建一个 NSTextStorage 并设置富文本
        let textStorage = NSTextStorage(attributedString: self)
        
        // 创建一个 NSTextContainer 并设置宽度和无高度限制
        let textContainer = NSTextContainer(size: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
        textContainer.lineFragmentPadding = 0.0
        
        // 创建一个 NSLayoutManager 并将其添加到 NSTextStorage 中
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        
        // 强制布局
        layoutManager.ensureLayout(for: textContainer)
        layoutManager.glyphRange(for: textContainer)
        
        var index = 0
        var lineRange = NSRange(location: 0, length: 0)
        var lineInfos: [AttributedStringLineInfo] = []
        
        // 遍历每一行
        while index < layoutManager.numberOfGlyphs {
            layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: &lineRange)
            index = NSMaxRange(lineRange)
            let attributedString = self.attributedSubstring(from: lineRange)
            let info = AttributedStringLineInfo(range: lineRange, attributedString: attributedString)
            lineInfos.append(info)
        }
        return lineInfos
    }
    
    func appendFoldAttributedString(_ foldAttributedString: NSAttributedString,
                                    maxLine: Int,
                                    maxWidth: CGFloat) -> NSAttributedString {
        let lines = numberOfLines(maxWidth: maxWidth)
        if lines.count <= maxLine {
            return self
        }
        var finalAttributedString = self
        for line in lines.reversed() {
            var stop = false
            for length in stride(from: line.range.length - 1, to: 0, by: -1) {
                let maxLength = line.range.location + length
                let tempAttributedString = NSMutableAttributedString(attributedString: self.attributedSubstring(from: NSRange(location: 0, length: maxLength)))
                tempAttributedString.append(foldAttributedString)
                let tempLines = tempAttributedString.numberOfLines(maxWidth: maxWidth)
                if tempLines.count <=  maxLine, let tempLastLine = tempLines.last {
                    let tempLastLineSize = tempLastLine.attributedString.boundingRect(with: CGSize(width: 0, height: 1), context: nil)
                    if tempLastLineSize.width <= maxWidth {
                        if tempAttributedString.string.hasSuffix("\n") {
                            tempAttributedString.replaceCharacters(in: NSRange(location: tempAttributedString.length - 1, length: 1), with: "")
                        }
                        finalAttributedString = NSAttributedString(attributedString: tempAttributedString)
                        stop = true
                        break
                    }
                }
            }
            if stop {
                break
            }
        }
        return finalAttributedString
    }
}
