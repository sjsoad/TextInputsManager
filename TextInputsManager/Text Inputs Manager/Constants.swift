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
    let options: UIViewAnimationOptions

    init?(from notification: Notification) {
        guard let userInfo = notification.userInfo,
            let rect = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect,
            let animationDurarion = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval,
            let options = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? UInt else { return nil }
        self.rect = rect
        self.animationDurarion = animationDurarion
        self.options = UIViewAnimationOptions(rawValue: options)
    }
    
}
