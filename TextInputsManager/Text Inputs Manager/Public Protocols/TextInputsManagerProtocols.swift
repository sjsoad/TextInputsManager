//
//  TextInputsManagerProtocols.swift
//  SwiftUtils
//
//  Created by Sergey on 12.10.17.
//  Copyright © 2017 Sergey. All rights reserved.
//

import Foundation
import UIKit

public protocol TextFieldsManagerReloading {
    func reloadTextFieldsManager()
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
