//
//  UIScreen.swift
//  SKTextInputsManager
//
//  Created by Sergey on 23.08.2018.
//

import Foundation

extension UIScreen {
    
    func contentHeightNotCoveredBy(keyboardFrame rect: CGRect) -> CGFloat {
        return bounds.height - rect.height
    }
    
}
