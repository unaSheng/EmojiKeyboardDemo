//
//  EmojiKeyboard.swift
//  Hertown
//
//  Created by li.wenxiu on 2024/7/15.
//

import UIKit
import Combine
import SDWebImage
import UIExtensions

protocol InputViewCustomizableTextInput {
    var inputView: UIView? { get set }
}

protocol EmojiTextInput {
    func insertEmoji(_ emoji: EmojiKeyboard.Emoji)
}

typealias InputViewCustomizableResponder = UIView & UITextInput & InputViewCustomizableTextInput

extension UITextView: InputViewCustomizableTextInput {
    
}

extension UITextField: InputViewCustomizableTextInput {
    
}

class EmojiKeyboard: NSObject, UIGestureRecognizerDelegate {
    
    var backgroundColor: UIColor? = UIColor.systemBackground.withAlphaComponent(0.8)
    
    var isTapTextInputToDismissEnabled: Bool = false
    
    let activeStateDidChange = PassthroughSubject<Bool, Never>()
    
    private(set) var triggerButton: UIButton = UIButton(type: .system)
    
    private(set) var isActive: Bool = false {
        didSet {
            if oldValue != isActive {
                self.activeStateDidChange.send(isActive)
            }
        }
    }
    
    private var observers: [AnyCancellable] = []
    private weak var textInput: InputViewCustomizableResponder?
    
    init(textInput: InputViewCustomizableResponder) {
        super.init()
        self.textInput = textInput
        self.triggerButton.setImage(UIImage(named: "chat_emoji_normal"), for: .normal)
        self.triggerButton.tintColor = UIColor.systemGray2
        self.triggerButton.addTarget(self, action: #selector(switchKeyboard), for: .touchUpInside)
        self.triggerButton.sizeToFit()
        
        let tapGestureReconginzer = UITapGestureRecognizer(target: self, action: #selector(handleTextInputTap))
        tapGestureReconginzer.delegate = self
        self.textInput?.addGestureRecognizer(tapGestureReconginzer)
        
        if let textView = self.textInput as? UITextView {
            textView.publisher(for: \.inputView).sink(receiveValue: { [weak self] view in
                self?.checkActive(inputView: view)
            }).store(in: &observers)
        }
        
        if let textView = self.textInput as? UITextField {
            textView.publisher(for: \.inputView).sink(receiveValue: { [weak self] view in
                self?.checkActive(inputView: view)
            }).store(in: &observers)
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive event: UIEvent) -> Bool {
        if self.textInput?.inputView is EmojiKeyboardView, isTapTextInputToDismissEnabled {
            return true
        } else {
            return false
        }
    }
    
    private func checkActive(inputView: UIView?) {
        if inputView is EmojiKeyboardView {
            self.isActive = true
        } else {
            self.isActive = false
        }
    }
    
    @objc private func handleTextInputTap(_ sender: UITapGestureRecognizer) {
        self.switchToDefaultKeyboard()
    }
    
    @objc private func switchKeyboard() {
        if self.textInput?.inputView is EmojiKeyboardView {
            self.switchToDefaultKeyboard()
        } else {
            self.switchToEmojiKeyboard()
        }
    }
    
    private func switchToEmojiKeyboard() {
        let keyboardView = EmojiKeyboardView.instantiateFromNib()
        keyboardView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 300)
        keyboardView.inputHandler = { [weak self] emoji in
            if let textInput = self?.textInput as? EmojiTextInput {
                textInput.insertEmoji(emoji)
            } else {
                self?.inputText(EmojiKeyboard.placeholderString(for: emoji))
            }
        }
        keyboardView.backspaceHandler = { [weak self] in
            self?.backspace()
        }
        keyboardView.returnHandler = { [weak self] in
            self?.inputText("\n")
        }
        keyboardView.backgroundColor = self.backgroundColor
        self.textInput?.inputView = keyboardView
        self.textInput?.reloadInputViews()
        self.triggerButton.setImage(UIImage(named: "chat_keyboard_normal"), for: .normal)
        self.isActive = true
    }
    
    private func switchToDefaultKeyboard() {
        self.textInput?.inputView = nil
        self.textInput?.reloadInputViews()
        self.triggerButton.setImage(UIImage(named: "chat_emoji_normal"), for: .normal)
        self.isActive = false
    }
    
    private func backspace() {
        guard let textInput = self.textInput else { return }
        textInput.deleteBackward()
    }
    
    private func inputText(_ text: String) {
        if let selectedTextRange = self.textInput?.selectedTextRange,
           self.textInputShouldReplaceTextInRange(selectedTextRange, replacementText: text) {
            self.textInput?.replace(selectedTextRange, withText: text)
        }
    }
    
    private func textInputShouldReplaceTextInRange(_ range: UITextRange, replacementText: String) -> Bool {
        guard let textInput = self.textInput else { return true }
        var shouldChange = true
        let startOffset = self.textInput?.offset(from: textInput.beginningOfDocument, to: range.start)
        let endOffset = self.textInput?.offset(from: textInput.beginningOfDocument, to: range.end)
        guard let start = startOffset, let end = endOffset else { return true }
        let replacementRange = NSRange(location: start, length: end - start)
        if let textView = textInput as? UITextView {
            shouldChange = (textView.delegate?.textView?(textView, shouldChangeTextIn: replacementRange, replacementText: replacementText)) ?? true
        }
        if let textField = textInput as? UITextField {
            shouldChange = (textField.delegate?.textField?(textField, shouldChangeCharactersIn: replacementRange, replacementString: replacementText)) ?? true
        }
        return shouldChange
    }
}

extension EmojiKeyboard {
    struct Emoji: Codable {
        var text: String
        var resourceName: String
        var animatedResourceName: String
        
        enum CodingKeys: String, CodingKey {
            case text
            case resourceName
            case animatedResourceName = "dynamicName"
        }
        
        var imageURL: URL {
            return Emoji.bundleURL.appendingPathComponent(resourceName)
        }
        
        var animatedImageURL: URL {
            return Emoji.bundleURL.appendingPathComponent(animatedResourceName)
        }
        
        static let bundleURL: URL = Bundle.main.url(forResource: "Emojis", withExtension: "bundle")!
        
        static let all: [Emoji] = {
            let manifestURL = Emoji.bundleURL.appendingPathComponent("manifest.json")
            let manifestData = try! Data(contentsOf: manifestURL)
            return try! JSONDecoder().decode([Emoji].self, from: manifestData)
        }()
    }
}

extension EmojiKeyboard {
    
    fileprivate class EmojiAttachment: NSTextAttachment {
        
        let emoji: Emoji
        let font: UIFont
        
        private let imageSize: CGSize
        
        private static let imageCache = NSCache<NSURL, UIImage>()
        
        init(emoji: Emoji, font: UIFont) {
            self.emoji = emoji
            self.font = font
            self.imageSize = EmojiAttachment.image(for: emoji)?.size ?? CGSize(width: 1, height: 1)
            super.init(data: nil, ofType: nil)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
            let font: UIFont
            if textContainer?.responds(to: NSSelectorFromString("textView")) == true && textContainer?.value(forKey: "textView") != nil {
                font = textContainer?.layoutManager?.textStorage?.attributes(at: charIndex, effectiveRange: nil)[.font] as? UIFont ?? self.font
            } else {
                font = self.font
            }
            var rect: CGRect = .zero
            rect.origin.y = font.descender * 1.06
            rect.size.height = (font.lineHeight) * 1.03
            rect.size.width = (rect.size.height / self.imageSize.height * self.imageSize.width)
            return rect
        }
        
        override func image(forBounds imageBounds: CGRect, textContainer: NSTextContainer?, characterIndex charIndex: Int) -> UIImage? {
            return EmojiAttachment.image(for: emoji)
        }
        
        private static func image(for emoji: Emoji) -> UIImage? {
            if let image = EmojiAttachment.imageCache.object(forKey: emoji.imageURL as NSURL) {
                return image
            } else if let image = UIImage(contentsOfFile: emoji.imageURL.path)?.mtr.resized(to: CGSize(width: 64, height: 64), resizingMode: .scaleAspectFit) {
                EmojiAttachment.imageCache.setObject(image, forKey: emoji.imageURL as NSURL)
                return image
            } else {
                return nil
            }
        }
    }
    
    struct EmojiRange {
        var range: NSRange
        var emoji: Emoji
    }
    
    static func emojiAttributeRanges(from text: String) -> [EmojiRange] {
        guard let regularExpression = try? NSRegularExpression(pattern: "\\[(\\w+)\\]", options: []) else {
            return []
        }
        let matches = regularExpression.matches(in: text, options: [], range: NSRange(location: 0, length: (text as NSString).length))
        var ranges: [EmojiRange] = []
        for match in matches where match.numberOfRanges > 1 {
            let matchedTextRange = match.range(at: 1)
            if let textRange = Range(matchedTextRange, in: text) {
                let text = text[textRange]
                if let emoji = Emoji.all.first(where: { $0.text == text }) {
                    ranges.append(EmojiRange(range: match.range(at: 0), emoji: emoji))
                }
            }
        }
        return ranges
    }
    
    fileprivate static func attributedString(for emoji: Emoji, font: UIFont) -> NSAttributedString {
        let attachment = EmojiAttachment(emoji: emoji, font: font)
        let emojiAttributedString = NSMutableAttributedString(attachment: attachment)
        emojiAttributedString.addAttributes([.font: font], range: NSRange(location: 0, length: emojiAttributedString.length))
        return emojiAttributedString
    }
    
    fileprivate static func attributedStringByReplacingEmojiPlaceholder(in attributedString: NSAttributedString, font: UIFont) -> NSAttributedString {
        let text = attributedString.mutableCopy() as! NSMutableAttributedString
        let emojiRanges = self.emojiAttributeRanges(from: attributedString.string)
        
        for emojiRange in emojiRanges.reversed() {
            text.replaceCharacters(in: emojiRange.range, with: self.attributedString(for: emojiRange.emoji, font: font))
        }
        return text
    }
    
    fileprivate static func attributedStringByReplacingEmojiPlaceholder(in attributedString: NSAttributedString, font: UIFont, single: UIFont) -> NSAttributedString {
        let text = attributedString.mutableCopy() as! NSMutableAttributedString
        let emojiRanges = self.emojiAttributeRanges(from: attributedString.string)
        
        if emojiRanges.count == 1, let emojiRange = emojiRanges.first, emojiRange.range.location == 0, emojiRange.range.length == attributedString.string.count {
            text.replaceCharacters(in: emojiRange.range, with: self.attributedString(for: emojiRange.emoji, font: single))
        } else {
            for emojiRange in emojiRanges.reversed() {
                text.replaceCharacters(in: emojiRange.range, with: self.attributedString(for: emojiRange.emoji, font: font))
            }
        }
        return text
    }
    
    fileprivate static func plainTextWithEmojiPlaceholder(from emojiAttributedString: NSAttributedString) -> String {
        var text = emojiAttributedString.string
        emojiAttributedString.enumerateAttribute(.attachment, in: NSRange(location: 0, length: (text as NSString).length), options: [.reverse], using: { obj, range, _ in
            if let emoji = (obj as? EmojiAttachment)?.emoji {
                text = (text as NSString).replacingCharacters(in: range, with: placeholderString(for: emoji))
            }
        })
        return text
    }
    
    static func placeholderString(for emoji: Emoji) -> String {
        return "[" + emoji.text + "]"
    }
}


extension NSAttributedString {
    //@MainActor
    func replacingEmojiPlaceholder(font: UIFont) -> NSAttributedString {
        EmojiKeyboard.attributedStringByReplacingEmojiPlaceholder(in: self, font: font)
    }
    
    func replacingEmojiPlaceholder(font: UIFont, single: UIFont) -> NSAttributedString {
        EmojiKeyboard.attributedStringByReplacingEmojiPlaceholder(in: self, font: font, single: single)
    }
}


class EmojiTextView: UITextView, EmojiTextInput {
    
    private var _font: UIFont?
    override var font: UIFont? {
        get {
            _font ?? super.font
        }
        set {
            _font = newValue
            super.font = newValue
            self.resetTextStyle()
        }
    }
    
    private var _textColor: UIColor?
    override var textColor: UIColor? {
        get {
            _textColor ?? super.textColor
        }
        set {
            _textColor = newValue
            super.textColor = newValue
            self.resetTextStyle()
        }
    }
    
    private var plainText: String {
        EmojiKeyboard.plainTextWithEmojiPlaceholder(from: self.textStorage).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func resetTextStyle() {
        let wholeRange = NSRange(location: 0, length: self.textStorage.length)
        self.textStorage.beginEditing()
        self.textStorage.removeAttribute(.font, range: wholeRange)
        self.textStorage.removeAttribute(.foregroundColor, range: wholeRange)
        if let font = self.font, let textColor = self.textColor {
            self.textStorage.addAttribute(.font, value: font, range: wholeRange)
            self.textStorage.addAttribute(.foregroundColor, value: textColor, range: wholeRange)
        }
        self.textStorage.endEditing()
    }
    
    func insertEmoji(_ emoji: EmojiKeyboard.Emoji) {
        let cursorLocation = self.selectedRange.location
        let font = self.font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
        self.textStorage.insert(NSAttributedString(attachment: EmojiKeyboard.EmojiAttachment(emoji: emoji, font: font)), at: cursorLocation)
        self.selectedRange.location = cursorLocation + 1
        self.scrollRangeToVisible(self.selectedRange)
        resetTextStyle()
    }
    
    override var editingInteractionConfiguration: UIEditingInteractionConfiguration {
        return .none
    }
    
    override func copy(_ sender: Any?) {
        let range = self.selectedRange
        let text = self.attributedText.attributedSubstring(from: range)
        let plainText = EmojiKeyboard.plainTextWithEmojiPlaceholder(from: text)
        UIPasteboard.general.string = plainText
    }
    
    override func cut(_ sender: Any?) {
        let range = self.selectedRange
        let text = self.attributedText.attributedSubstring(from: range)
        super.cut(sender)
        let plainText = EmojiKeyboard.plainTextWithEmojiPlaceholder(from: text)
        UIPasteboard.general.string = plainText
    }
    
    override func paste(_ sender: Any?) {
        let defaultPasteboard = UIPasteboard.general
        if let pasteboardString = defaultPasteboard.string, !pasteboardString.isEmpty {
            var range = self.selectedRange
            if range.location == NSNotFound {
                range.location = self.plainText.count
            }
            if delegate?.textView?(self, shouldChangeTextIn: range, replacementText: pasteboardString) ?? true {
                let font = self.font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
                let newAttributedString = NSAttributedString(string: pasteboardString).replacingEmojiPlaceholder(font: font)
                self.textStorage.insert(newAttributedString, at: range.location)
                self.selectedRange = NSRange(location: range.location + newAttributedString.length, length: 0)
                resetTextStyle()

            }
            return
        }
        super.paste(sender)
    }
}
