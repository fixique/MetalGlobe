//
//  AppDelegate.swift
//  MetalGlobe
//
//  Created by Vlad Krupenko on 05.04.17.
//  Copyright © 2017 fixique. All rights reserved.
//

import UIKit

let DemoNumber = 0

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var rootViewController: UIViewController!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        switch DemoNumber {
        case 0:
            rootViewController = SphereViewController()
        case 1:
            rootViewController = GlobeViewController()
        default:
            break
        }
        
        window = UIWindow(frame: UIScreen.main.bounds)
        rootViewController.view.frame = window!.bounds
        window!.rootViewController = rootViewController
        window!.makeKeyAndVisible()
        
        return true
    }

    

}

