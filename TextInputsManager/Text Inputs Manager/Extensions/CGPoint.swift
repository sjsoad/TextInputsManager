//
//  CGPoint.swift
//  SKTextInputsManager
//
//  Created by Sergey on 22.08.2018.
//

import Foundation

extension CGPoint {
    
    static func < (lhs: CGPoint, rhs: CGPoint) -> Bool {
        if lhs.y != rhs.y {
            return lhs.y < rhs.y
        } else {
            return lhs.x < rhs.x
        }
    }
    
}
