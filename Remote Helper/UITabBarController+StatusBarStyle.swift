//
//  UITabBarController+StatusBarStyle.swift
//  Video Player
//
//  Created by Venj Chu on 15/11/10.
//  Copyright © 2015年 Home. All rights reserved.
//

import UIKit

extension UITabBarController {
    override open var preferredStatusBarStyle : UIStatusBarStyle {
        guard selectedViewController != nil else { return .default }
        return selectedViewController!.preferredStatusBarStyle
    }
}
