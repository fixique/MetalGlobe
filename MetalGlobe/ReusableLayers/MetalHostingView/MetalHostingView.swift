//
//  MetalHostingView.swift
//  MetalGlobe
//
//  Created by Vlad Krupenko on 10.09.2018.
//  Copyright © 2018 fixique. All rights reserved.
//

import UIKit

final class MetalHostingView: UIView {

    override class var layerClass: Swift.AnyClass {
        return CAMetalLayer.self
    }

}
