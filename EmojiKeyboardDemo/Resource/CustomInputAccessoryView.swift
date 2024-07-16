//
//  CustomInputAccessoryView.swift
//  EmojiKeyboardDemo
//
//  Created by li.wenxiu on 2024/7/16.
//

import UIKit

class CustomInputAccessoryView: UIView, NibInstantiatable {
    
    var sendHandler: ((NSAttributedString?) -> Void)?

    @IBOutlet weak var textView: FlexibleTextView!
    @IBOutlet weak var controlContainerView: UIView!
    var emojiKeyboard: EmojiKeyboard!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textView.maxHeight = 100
        textView.returnKeyType = .send
        textView.placeholderTextColor = UIColor.black.withAlphaComponent(0.3)
        textView.placeholderFont = UIFont.systemFont(ofSize: 14)
        textView.textColor = UIColor.black
        textView.font = UIFont.systemFont(ofSize: 14)
        textView.lineFragmentPadding = 0
        textView.textContainerInset = UIEdgeInsets(top: 9, left: 12, bottom: 9, right: 0)
        
        
        textView.caretConfiguration = .forChat
        textView.textLengthLimit = 10
        
        let  emojiKeyboard = EmojiKeyboard(textInput: textView)
        self.emojiKeyboard = emojiKeyboard
        
        let triggerButton = self.emojiKeyboard.triggerButton
        triggerButton.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        self.addSubview(triggerButton)
        triggerButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            triggerButton.topAnchor.constraint(equalTo: self.controlContainerView.topAnchor),
            triggerButton.bottomAnchor.constraint(equalTo: self.controlContainerView.bottomAnchor),
            triggerButton.centerXAnchor.constraint(equalTo: self.controlContainerView.centerXAnchor),
        ])
    }
    
}
