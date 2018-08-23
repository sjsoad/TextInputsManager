//
//  UIView.swift
//  TextInputsManager
//
//  Created by Sergey on 22.08.2018.
//  Copyright © 2018 Sergey Kostyan. All rights reserved.
//

import UIKit

extension UIView {
    
    func subviewsOf<T>(type: T.Type) -> [T] {
        var searchedSubviews = [T]()
        subviews.forEach { (subview) in
            if let view = subview as? T {
                searchedSubviews.append(view)
            }
            searchedSubviews += subview.subviewsOf(type: T.self)
        }
        return searchedSubviews
    }
    
    var distanceToBottomOfScreen: CGFloat {
        let convertedFrame = convert(bounds, to: UIApplication.shared.keyWindow)
        return UIScreen.main.bounds.height - convertedFrame.maxY
    }
    
}
