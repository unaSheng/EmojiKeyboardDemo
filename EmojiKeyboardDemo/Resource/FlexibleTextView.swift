//
//  FlexibleTextView.swift
//  Hertown
//
//  Created by li.wenxiu on 2024/7/15.
//

import UIKit
import simd

class FlexibleTextView: EmojiTextView {
    
    var heightDidChanged : ((CGFloat)->Void)?
    var textDidChanged: ((String) -> Void)?
    
    var maxHeight: CGFloat = 0.0 {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }
    
    var minHeight: CGFloat = 0 {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }
    
    private let placeholderTextView: UITextView = {
        let tv = UITextView()
        tv.backgroundColor = .clear
        tv.isScrollEnabled = false
        tv.isUserInteractionEnabled = false
        tv.textColor = #colorLiteral(red: 0.5843137255, green: 0.5843137255, blue: 0.5843137255, alpha: 1)
        return tv
    }()
    
    var placeholder: String? {
        get {
            return placeholderTextView.text
        }
        set {
            placeholderTextView.text = newValue
        }
    }
    
    var placeholderAttributeText: NSAttributedString? {
        get {
            return placeholderTextView.attributedText
        }
        set {
            placeholderTextView.attributedText = newValue
        }
    }
    
    var placeholderTextColor: UIColor? {
        get {
            return placeholderTextView.textColor
        }
        set {
            placeholderTextView.textColor = newValue
        }
    }
    
    var placeholderFont: UIFont? {
        get {
            return placeholderTextView.font
        }
        set {
            placeholderTextView.font = newValue
        }
    }
    
    var placeholderTextAlignment: NSTextAlignment {
        get {
            return placeholderTextView.textAlignment
        }
        set {
            placeholderTextView.textAlignment = newValue
        }
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setupSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }
    
    private func setupSubviews() {
        isScrollEnabled = false
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        NotificationCenter.default.addObserver(self, selector: #selector(textDidChange(_:)), name: UITextView.textDidChangeNotification, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(textDidBeginEditing(_:)), name: UITextView.textDidBeginEditingNotification, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(textDidEndEditing(_:)), name: UITextView.textDidEndEditingNotification, object: self)
        addSubview(placeholderTextView)
    }
    
    var sizeChangedHandler: (() -> Void)?
    
    private var oldSize: CGSize?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.placeholderTextView.frame = self.bounds
        self.updateCaret(selectedTextRange: self.selectedTextRange)
        if oldSize != self.frame.size {
            oldSize = self.frame.size
            self.sizeChangedHandler?()
        }
    }
    
    override var text: String! {
        didSet {
            invalidateIntrinsicContentSize()
            placeholderTextView.isHidden = !text.isEmpty
            updateCaret(selectedTextRange: self.selectedTextRange)
        }
    }
    
    override var attributedText: NSAttributedString! {
        didSet {
            invalidateIntrinsicContentSize()
            placeholderTextView.isHidden = !attributedText.string.isEmpty
            updateCaret(selectedTextRange: self.selectedTextRange)
        }
    }
    
    override var font: UIFont? {
        didSet {
            placeholderTextView.font = font
            invalidateIntrinsicContentSize()
            updateCaret(selectedTextRange: self.selectedTextRange)
        }
    }
    
    override var textContainerInset: UIEdgeInsets {
        didSet {
            placeholderTextView.textContainerInset = textContainerInset
            updateCaret(selectedTextRange: self.selectedTextRange)
        }
    }
    
    var lineFragmentPadding: CGFloat = 0 {
        didSet {
            textContainer.lineFragmentPadding = lineFragmentPadding
            placeholderTextView.textContainer.lineFragmentPadding = lineFragmentPadding
            updateCaret(selectedTextRange: self.selectedTextRange)
        }
    }
    
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        if size.height == UIView.noIntrinsicMetric {
            layoutManager.glyphRange(for: textContainer)
            size.height = layoutManager.usedRect(for: textContainer).height + textContainerInset.top + textContainerInset.bottom
        }
        if maxHeight > 0.0 && size.height > maxHeight {
            size.height = maxHeight
            if !isScrollEnabled {
                isScrollEnabled = true
            }
        } else if isScrollEnabled {
            isScrollEnabled = false
        }
        if minHeight > 0 && size.height < minHeight {
            size.height = minHeight
        }
        heightDidChanged?(size.height)
        return size
    }
    
    override func resetTextStyle() {
        super.resetTextStyle()
        self.limitTextLength()
    }
    
    @objc private func textDidChange(_ note: Notification) {
        invalidateIntrinsicContentSize()
        placeholderTextView.isHidden = !attributedText.string.isEmpty
        textDidChanged?(text.trimmingCharacters(in: .newlines))
        self.updateCaret(selectedTextRange: self.selectedTextRange)
        self.limitTextLength()
    }
    
    @objc private func textDidBeginEditing(_ note: Notification) {
        self.updateCaret(selectedTextRange: self.selectedTextRange)
    }
    
    @objc private func textDidEndEditing(_ note: Notification) {
        self.updateCaret(selectedTextRange: self.selectedTextRange)
    }
    
    struct CaretConfiguration {
        var image: UIImage
        var caretTint: UIColor
        
        static var forChat: CaretConfiguration = CaretConfiguration(image: UIImage(named: "chat_input_caret_image")!, caretTint: .red)
    }
    
    var caretConfiguration: CaretConfiguration? {
        didSet {
            assert(oldValue == nil)
            self.updateCaret(selectedTextRange: self.selectedTextRange)
        }
    }
    
    private weak var caretImageView: UIImageView?
    private var caretAnimationDisplayLinkCanceller: CADisplayLink.Canceller?
    private var caretAnimationT: CFAbsoluteTime = 0
    
    private func updateCaret(selectedTextRange: UITextRange?) {
        self.caretAnimationT = 0.3
        if let caretConfiguration = self.caretConfiguration {
            if caretImageView == nil {
                let caretImageView = UIImageView(image: caretConfiguration.image)
                caretImageView.autoresizingMask = []
                self.addSubview(caretImageView)
                self.caretImageView = caretImageView
                self.caretAnimationDisplayLinkCanceller = CADisplayLink.add(to: .main, in: .common, handler: { [weak self] displayLink in
                    guard let strongSelf = self else { return }
                    strongSelf.caretAnimationT += displayLink.duration
                    let t = strongSelf.caretAnimationT
                    let round = simd_fract(t)
                    let alpha: CGFloat
                    if round < 0.3 {
                        alpha = CGFloat(round/0.3)
                    } else if round > 0.7 {
                        alpha = CGFloat(1.0 - (round - 0.7)/0.3)
                    } else {
                        alpha = 1
                    }
                    strongSelf.caretImageView?.alpha = alpha
                })
            }
            if let selectedTextRange = selectedTextRange, self.isFirstResponder {
                if selectedTextRange.isEmpty {
                    tintColor = .clear
                    caretImageView?.isHidden = false
                    var rect = self.caretRect(for: selectedTextRange.start)
                    rect.size.width = caretConfiguration.image.size.width
                    if rect.origin.y < 0 {
                        rect.size.height += rect.origin.y
                        rect.origin.y = 0
                    }
                    rect.origin.x += 1
                    caretImageView?.frame = rect
                } else {
                    tintColor = caretConfiguration.caretTint
                    caretImageView?.isHidden = true
                }
            } else {
                tintColor = caretConfiguration.caretTint
                caretImageView?.isHidden = true
            }
        }
    }
    
    override var selectedTextRange: UITextRange? {
        set {
            self.updateCaret(selectedTextRange: newValue)
            super.selectedTextRange = newValue
        }
        get {
            super.selectedTextRange
        }
    }
    
    override var selectedRange: NSRange {
        set {
            super.selectedRange = newValue
            self.updateCaret(selectedTextRange: self.selectedTextRange)
        }
        get {
            super.selectedRange
        }
    }
    
    var textLengthLimit: Int = 0
}


extension FlexibleTextView {
    private func limitTextLength() {
        DispatchQueue.main.async {
            guard self.markedTextRange == nil || self.markedTextRange?.isEmpty == true else { return }
            guard self.textLengthLimit > 0 else { return }
            let limit = self.textStorage.string.prefix(self.textLengthLimit)
            let nsStringLimit = (limit as NSString).length
            if self.textStorage.length - nsStringLimit > 0 {
                self.textStorage.beginEditing()
                self.textStorage.deleteCharacters(in: NSRange(location: nsStringLimit, length: self.textStorage.length - nsStringLimit))
                self.textStorage.endEditing()
                self.updateCaret(selectedTextRange: self.selectedTextRange)
            }
        }
    }
}
