//
//  AppDelegate.swift
//  Hertown
//
//  Created by li.wenxiu on 2024/7/15.
//

import UIKit
import SDWebImage
import SDWebImageWebPCoder

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        SDImageCodersManager.shared.addCoder(SDImageWebPCoder.shared)
        
        return true
    }
}

