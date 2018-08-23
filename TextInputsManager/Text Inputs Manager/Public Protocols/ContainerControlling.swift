//
//  ContainerControlling.swift
//  SKTextInputsManager
//
//  Created by Sergey Kostyan on 22.08.2018.
//

import Foundation

protocol ContainerControlling {
    
    func moveTo(_ responder: UIView, keyboardFrame rect: CGRect, spaceAboveKeyboard: CGFloat)
    func handleKeyboardAppearance(keyboardFrame rect: CGRect, spaceAboveKeyboard: CGFloat)
    func handleKeyboardDisappearance()
    
}

extension ContainerControlling {
    
    func handleKeyboardAppearance(keyboardFrame rect: CGRect, spaceAboveKeyboard: CGFloat) {
        print("default behaviour")
    }
    
}
