//
//  Array.swift
//  AERecord
//
//  Created by Sergey on 22.08.2018.
//

import Foundation

extension Array where Element == UIView {
    
    mutating func sortByOrigin(convertedTo view: UIView?) {
        sort { (currentObject, nextObject) -> Bool in
            let currentObjectOrigin = currentObject.convert(currentObject.frame.origin, to: view)
            let nextObjectOrigin = nextObject.convert(nextObject.frame.origin, to: view)
            return currentObjectOrigin < nextObjectOrigin
        }
    }
    
    func nextResponder(after view: UIView) -> UIView? {
        guard let indexOfObject = index(of: view) else { return nil }
        return enumerated().first(where: { (index, view) -> Bool in
            return index > indexOfObject && view.canBecomeFirstResponder
        })?.element
    }
    
}
