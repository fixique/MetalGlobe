//
//  ViewController.swift
//  MetalGlobe
//
//  Created by Vlad Krupenko on 05.04.17.
//  Copyright © 2017 fixique. All rights reserved.
//

import UIKit
import Metal

class MetalHostingView: UIView {
    override class var layerClass: Swift.AnyClass {
        return CAMetalLayer.self
    }
}

class ViewController: UIViewController {

    var metalLayer: CAMetalLayer! = nil
    let device = MTLCreateSystemDefaultDevice()!
    var pipeline: MTLRenderPipelineState! = nil
    var commadQueue: MTLCommandQueue! = nil
    
    var timer: CADisplayLink! = nil
    var userToggle: Bool = false
    
    override func loadView() {
        self.view = MetalHostingView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        metalLayer = view.layer as! CAMetalLayer
        
        view.backgroundColor = UIColor.white
        
        
    }
    

}

