//
//  MainSceneViewController.swift
//  MetalGlobe
//
//  Created by Vlad Krupenko on 10.09.2018.
//  Copyright © 2018 fixique. All rights reserved.
//

import UIKit
import Metal

class MainSceneViewController: UIViewController {

    // MARK: - Private Properties

    private let device = MTLCreateSystemDefaultDevice()
    private var metalLayer: CAMetalLayer?
    private var pipeline: MTLRenderPipelineState?
    private var commandQueue: MTLCommandQueue?

    private var timer: CADisplayLink?
    private var userToggle: Bool = false

    // MARK: - UIViewController

    override func loadView() {
        view = MetalHostingView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackgroundAndLayer()
        configureTapGesture()
        initializeMetal()
        buildPipeLine()
        buildResources()
        startDisplayTimer()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resize()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Internal methods

    func buildPipeLine() {
        preconditionFailure("This method must be overriden by the subclass")
    }

    func buildResources() {
        preconditionFailure("This method must be overriden by the subclass")
    }

    func draw() {
        preconditionFailure("This method must be overriden by the subclass")
    }

}

// MARK: - Configure Scene

private extension MainSceneViewController {

    func configureBackgroundAndLayer() {
        metalLayer = view.layer as? CAMetalLayer
        view.backgroundColor = UIColor.white
    }

    func initializeMetal() {
        metalLayer?.device = device
        metalLayer?.pixelFormat = .bgra8Unorm
        commandQueue = device?.makeCommandQueue()
    }

    func resize() {
        guard let window = view.window else {
            return
        }

        let scale = window.screen.nativeScale
        let viewSize = window.bounds.size
        let layerSize = viewSize

        view.contentScaleFactor = scale
        metalLayer?.drawableSize = CGSize(width: layerSize.width * scale,
                                          height: layerSize.height * scale)
    }

    func configureTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapScreen))
        view.addGestureRecognizer(tapGesture)
    }

    func startDisplayTimer() {
        timer = CADisplayLink(target: self, selector: #selector(redraw))
        timer?.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
    }

}

// MARK: - Actions

private extension MainSceneViewController {

    @objc
    func didTapScreen() {
        userToggle = !userToggle
    }

    @objc
    func redraw() {
        autoreleasepool { [weak self] in
            self?.redraw()
        }
    }

}
