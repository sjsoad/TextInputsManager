//
//  ViewController.swift
//  SKTextInputsManager
//
//  Created by Sergey on 23.08.2018.
//

import UIKit

final class ViewController: ContainerControlling {
    
    private var view: UIView
    
    init(view: UIView) {
        self.view = view
    }
    
    // MARK: - ViewManipulating -
    
    func moveTo(_ responder: UIView, keyboardFrame rect: CGRect, spaceAboveKeyboard: CGFloat) {
        view.transform = .identity
        var frame = view.convert(responder.frame, to: UIApplication.shared.keyWindow)
        frame.origin.y += spaceAboveKeyboard
        guard frame.maxY > rect.minY else { return }
        let delta =  rect.minY - frame.maxY
        view.transform = CGAffineTransform(translationX: 0, y: delta)
    }
    
    func handleKeyboardDisappearance() {
        view.transform = .identity
    }
    
}
