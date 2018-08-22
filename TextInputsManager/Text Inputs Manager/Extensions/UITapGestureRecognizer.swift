//
//  UITapGestureRecognizer.swift
//  SKTextInputsManager
//
//  Created by Sergey on 22.08.2018.
//

import Foundation

extension UITapGestureRecognizer {
    
    convenience init(target: Any?, action: Selector?, numberOfTapsRequired numberOfTaps: Int, delegate: UIGestureRecognizerDelegate) {
        self.init(target: target, action: action)
        self.numberOfTapsRequired = numberOfTaps
        self.delegate = delegate
    }
    
}
