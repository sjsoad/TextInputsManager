//
//  ContainerController.swift
//  SKTextInputsManager
//
//  Created by Sergey Kostyan on 22.08.2018.
//

import UIKit

final class ContainerController {
    
    func controller(for view: UIView) -> ContainerControlling {
        guard let scroll = view as? UIScrollView else {
            return ViewController(view: view)
        }
        return ScrollController(scroll: scroll)
    }
    
}

open class ViewController: ContainerControlling {

    private var view: UIView
    
    init(view: UIView) {
        self.view = view
    }
    
    // MARK: - ViewManipulating -
    
    func moveTo() {
        let visibleContentHeight = UIScreen.main.bounds.height - rect.height
        let yPositionRelativeToWindow = view.frame.minY + frame.maxY
        guard yPositionRelativeToWindow > visibleContentHeight else { return }
        let delta = yPositionRelativeToWindow - visibleContentHeight
        view.transform = CGAffineTransform(translationX: 0, y: -delta)
    }
    
    func handleKeyboardAppearance() {
        
    }
    
    func handleKeyboardDisappearance() {
        view.transform = .identity
    }
    
}

open class ScrollController: ContainerControlling {
    
    private var scroll: UIScrollView
    
    init(scroll: UIScrollView) {
        self.scroll = scroll
    }
    
    // MARK: - ViewManipulating -
    
    func moveTo() {
        var frame = scroll.convert(activeInputView.bounds, from: activeInputView)
        frame.origin.y += additionalSpaceAboveKeyboard
        scroll.scrollRectToVisible(frame, animated: false)
    }
    
    func handleKeyboardAppearance() {
        let distance = UIScreen.main.bounds.maxY - scroll.frame.maxY
        let bottomInset = rect.height - distance + additionalSpaceAboveKeyboard
        scroll.contentInset.bottom = bottomInset
    }
    
    func handleKeyboardDisappearance() {
        scroll.contentInset.bottom = 0
    }
    
}
