//
//  AppDelegate.swift
//  MetalGlobe
//
//  Created by Vlad Krupenko on 05.04.17.
//  Copyright © 2017 fixique. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - Enums

    private enum DemoType: Int {
        case sphere = 0
        case globe
    }

    // MARK: - Internal properties

    var window: UIWindow?

    // MARK: - Private properties

    private var demoType: DemoType = .sphere

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        setupDemo()
        window?.makeKeyAndVisible()

        return true
    }

}

// MARK: - Configure

private extension AppDelegate {

    func setupDemo() {
        switch demoType {
        case .sphere:
            window?.rootViewController = SphereViewController()
        case .globe:
            window?.rootViewController = GlobeViewController()
        }
    }

}
