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
    var commandQueue: MTLCommandQueue! = nil
    
    var timer: CADisplayLink! = nil
    var userToggle: Bool = false
    
    override func loadView() {
        view = MetalHostingView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        metalLayer = view.layer as! CAMetalLayer
        
        view.backgroundColor = UIColor.white
        
        initializeMetal()
        buildPipeLine()
        buildResources()
        startDisplayTimer()
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.tapGesture))
        
        view.addGestureRecognizer(tapRecognizer)
        
    }
    
    override func viewDidLayoutSubviews() {
        self.resize()
    }
    
    func tapGesture() {
        userToggle = !userToggle
    }
    
    func initializeMetal() {
        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        
        commandQueue = device.makeCommandQueue()
    }
    
    func buildPipeLine() {
    }
    
    func buildResources() {
    }
    
    func startDisplayTimer() {
        timer = CADisplayLink(target: self, selector: #selector(ViewController.redraw))
        timer.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
    }
    
    func resize() {
        if let window = view.window {
            let scale = window.screen.nativeScale
            let viewSize = view.bounds.size
            let layerSize = viewSize
            
            view.contentScaleFactor = scale
            metalLayer.drawableSize = CGSize(width: layerSize.width * scale, height: layerSize.height * scale)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    deinit {
        timer.invalidate()
    }
    
    func redraw() {
        autoreleasepool {
            self.draw()
        }
    }
    
    func draw() {
        
    }

}

