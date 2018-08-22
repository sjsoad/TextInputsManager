//
//  TextInputsManagerProtocols.swift
//  SwiftUtils
//
//  Created by Sergey on 12.10.17.
//  Copyright © 2017 Sergey. All rights reserved.
//

import Foundation
import UIKit

public protocol TextInputsManagerReloading {
    func reloadTextInputsManager()
}

public protocol TextInputsClearing {
    func clearTextInputs()
}

public protocol KeyboardHiding {
    func hideKeyboard()
}

public protocol FirstResponding {
    func firstResponder() -> UIView?
}

public protocol ReturnKeyTypeProviding {
    
    func set(returnKeyTypeProvider: @escaping ReturnKeyTypeProvider)
    
}
