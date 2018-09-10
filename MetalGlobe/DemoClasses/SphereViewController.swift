//
//  SphereViewController.swift
//  MetalGlobe
//
//  Created by Vlad Krupenko on 10.09.2018.
//  Copyright © 2018 fixique. All rights reserved.
//

import UIKit

final class SphereViewController: ViewController {

    // MARK: - Private Properties

    private var depthStencilState: MTLDepthStencilState?
    private var vertexBuffer: MTLBuffer?
    private var indexBuffer: MTLBuffer?
    private var uniformBuffer: MTLBuffer?
    private var depthTexture: MTLTexture?
    private var rotationAngle: Float32 = 0.0

    // MARK:

}
