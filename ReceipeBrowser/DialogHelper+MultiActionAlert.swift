//
//  DialogHelper+MultiActionAlert.swift
//  ReceipeBrowser
//
//  Created by Andrii on 5/8/16.
//  Copyright © 2016 Andrii. All rights reserved.
//

import Foundation
import UIKit

class DialogHelper{
    
    static func showOkAlertOnRootVC (message:String?, title:String? = nil){
        if let presentedVC = UIApplication.sharedApplication().keyWindow?.rootViewController{
            showOkAlert(message, title: title, viewController: presentedVC)
        }
    }
    
    static func showOkAlert(message: String?, title: String? = nil, viewController: UIViewController) {
        showAlert(title, message: message, buttonTitles: ["Ok"], actions: [nil], delegate: viewController)
    }
    
    static func showAlert(title: String? = nil, message: String?, buttonTitles:[String], actions: [(() -> ())?], delegate: UIViewController) {
        MultiActionAlert(style: UIAlertControllerStyle.Alert, title: title, message: message, buttonTitles: buttonTitles, actions: actions, delegate: delegate).showAlert()
    }
}

class MultiActionAlert {
    let style: UIAlertControllerStyle
    let title: String?
    let message: String?
    let buttonTitles:[String]
    let actions: [(() -> ())?]
    var delegate:UIViewController?
    let actionStyles:[UIAlertActionStyle]?
    
    init (style: UIAlertControllerStyle, title: String? = nil, message: String? = nil, buttonTitles:[String], actionStyles:[UIAlertActionStyle]? = nil, actions: [(() -> ())?], delegate: UIViewController) {
        self.style = style
        self.title = title
        self.message = message
        self.buttonTitles = buttonTitles
        self.actions = actions
        self.delegate = delegate
        self.actionStyles = actionStyles
    }
    
    func showAlert() {
        if let delegate = self.delegate {
            let alert = UIAlertController(title: self.title, message: self.message, preferredStyle: self.style)
            for x in 0..<buttonTitles.count {
                let buttonTitle = self.buttonTitles[x]
                let action =  self.actions[x]
                if let actionStyles = self.actionStyles{
                    let style = actionStyles[x]
                    alert.addAction(UIAlertAction(title: buttonTitle, style: style, handler: {_ in
                        action?()
                    }))
                } else {
                    alert.addAction(UIAlertAction(title: buttonTitle, style: .Default, handler: {_ in
                        action?()
                    }))
                }
            }
            delegate.presentViewController(alert, animated: true, completion: nil)
        }
    }
}