//
//  ContainerController.swift
//  SKTextInputsManager
//
//  Created by Sergey Kostyan on 22.08.2018.
//

import UIKit

open class ContainerControllerFactory {
    
    func controller(for view: UIView) -> ContainerControlling {
        guard let scroll = view as? UIScrollView else {
            return ViewController(view: view)
        }
        return ScrollController(scroll: scroll)
    }
    
}
