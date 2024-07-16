//
//  ViewController.swift
//  Hertown
//
//  Created by li.wenxiu on 2024/7/15.
//

import UIKit
import KeyboardLayoutGuide

class ViewController: UIViewController {
    
    @IBOutlet weak var showKeyboardButton: UIButton!
    @IBOutlet weak var textView: FlexibleTextView!
    
    private let customInputAccessoryView = CustomInputAccessoryView.instantiateFromNib()
    
    private var emojiKeyboard: EmojiKeyboard!
    
    private var useInputAccessoryView = true

    override func viewDidLoad() {
        super.viewDidLoad()
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
}

