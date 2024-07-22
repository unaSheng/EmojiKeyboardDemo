//
//  ViewController.swift
//  Hertown
//
//  Created by li.wenxiu on 2024/7/15.
//

import UIKit
import KeyboardLayoutGuide
import SDWebImage
import SDWebImageWebPCoder

class ViewController: UIViewController {
    private let labelLineHeight: CGFloat = 24
    private let labelFont = UIFont.systemFont(ofSize: 15)
    
    @IBOutlet weak var canExpandLabel: UILabel!
    
    @IBOutlet weak var showKeyboardButton: UIButton!
    @IBOutlet weak var textView: FlexibleTextView!
    
    private let customInputAccessoryView = CustomInputAccessoryView.instantiateFromNib()
    
    private var emojiKeyboard: EmojiKeyboard!
    
    private var useInputAccessoryView = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        canExpandLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(canExpandLabelTapped(_:))))
        setupTextInputAccessoryView()
    }

    
    @IBAction func showKeyboardButtonTapped(_ sender: Any) {
        let textView: UITextView?
        if useInputAccessoryView {
            textView = customInputAccessoryView.textView
        } else {
            textView = self.textView
        }
        guard let textView = textView else { return }
        if textView.isFirstResponder {
            textView.resignFirstResponder()
        } else {
            textView.becomeFirstResponder()
        }
    }
    
    func setupLabelAttributedText(expand: Bool) {
        let text = EmojiKeyboard.plainTextWithEmojiPlaceholder(from: textView.textStorage).trimmingCharacters(in: .whitespacesAndNewlines)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = labelLineHeight
        paragraphStyle.maximumLineHeight = labelLineHeight
        
        var attributedText = NSMutableAttributedString(string: text, attributes: [.font: labelFont,
                                                                                  .foregroundColor: UIColor.black,
                                                                                  .paragraphStyle: paragraphStyle])
        if expand {
            let foldStr = NSMutableAttributedString(string: " 收起", attributes: [.font: labelFont])
            foldStr.addAttribute(.link, value: URL(string: "fold")!, range: NSRange(location: 0, length: foldStr.length))
            attributedText.append(foldStr)
            attributedText = attributedText.replacingEmojiPlaceholder(font: labelFont) as! NSMutableAttributedString
            self.canExpandLabel.attributedText = attributedText
        } else {
            let expandStr = NSMutableAttributedString(string: "...展开", attributes: [.font: labelFont])
            expandStr.addAttribute(.link, value: URL(string: "expand")!, range: NSRange(location: 0, length: expandStr.length))
            attributedText = attributedText.replacingEmojiPlaceholder(font: labelFont) as! NSMutableAttributedString
            let canExpandAttributedString = attributedText.appendFoldAttributedString(expandStr, maxLine: 2, maxWidth: canExpandLabel.bounds.width)
            canExpandLabel.attributedText = canExpandAttributedString
        }
    }
    
    @objc private func canExpandLabelTapped(_ tap: UITapGestureRecognizer) {
        if let url = Utils.textAttributeValue(for: .link, in: self.canExpandLabel,
                                              lineHeight: labelLineHeight,
                                              at: tap.location(in: self.canExpandLabel)) as? URL  {
            let text = url.absoluteString
            if text == "expand" {
                setupLabelAttributedText(expand: true)
            } else if text == "fold" {
                setupLabelAttributedText(expand: false)
            }
        }
    }
    
    func setupTextInputAccessoryView() {
        if useInputAccessoryView {
            customInputAccessoryView.sendHandler = { [weak self] attributedString in
                self?.textView.attributedText = attributedString
            }
            customInputAccessoryView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(customInputAccessoryView)
            NSLayoutConstraint.activate([
                customInputAccessoryView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                customInputAccessoryView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                customInputAccessoryView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuideNoSafeArea.topAnchor),
            ])
        } else {
            let  emojiKeyboard = EmojiKeyboard(textInput: textView)
            emojiKeyboard.returnHandler = { [weak self] in
                self?.setupLabelAttributedText(expand: false)
            }
            self.emojiKeyboard = emojiKeyboard
            
            let triggerButton = self.emojiKeyboard.triggerButton
            self.view.addSubview(triggerButton)
            triggerButton.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                triggerButton.leadingAnchor.constraint(equalTo: self.showKeyboardButton.trailingAnchor, constant: 20),
                triggerButton.centerYAnchor.constraint(equalTo: self.showKeyboardButton.centerYAnchor),
            ])
        }
    }
}
