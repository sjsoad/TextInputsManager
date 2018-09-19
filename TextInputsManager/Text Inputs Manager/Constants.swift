//
//  Constants.swift
//  SKTextInputsManager
//
//  Created by Sergey on 22.08.2018.
//

import Foundation

public typealias ReturnKeyTypeProvider = ((Int, Bool) -> UIReturnKeyType)

struct KeyboardNotification {
    
    let rect: CGRect
    let animationDurarion: TimeInterval
    let options: UIView.AnimationOptions
    
    init?(from notification: Notification) {
        guard let userInfo = notification.userInfo,
            let rect = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let animationDurarion = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
            let options = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return nil }
        self.rect = rect
        self.animationDurarion = animationDurarion
        self.options = UIView.AnimationOptions(rawValue: options)
    }
    
}
