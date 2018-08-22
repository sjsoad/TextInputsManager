//
//  UITextView.swift
//  SKTextInputsManager
//
//  Created by Sergey on 22.08.2018.
//

import Foundation

extension UITextView {
    
    func clear() {
        text = String()
        attributedText = NSAttributedString(string: String())
    }
    
}
