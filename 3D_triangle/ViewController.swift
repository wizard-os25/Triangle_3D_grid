//
//  ViewController.swift
//  3D_triangle
//
//  Created by wizard.os25 on 4/12/25.
//

import UIKit
import MetalKit

final class ViewController: UIViewController {
    var metalView: MetalView!
    var sceneRenderer: SceneRenderer!
    var cameraGestureInput: CameraGestureInput!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMetal()
        setupGestures()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // MetalView frame is automatically adjusted via autoresizingMask
        // Update scene renderer size if needed
        if let sceneRenderer = sceneRenderer {
            sceneRenderer.setViewSize(view.bounds.size)
        }
    }
    
    func setupMetal() {
        let device = GPUDevice.shared.device
        
        // Load MetalView from XIB
        metalView = MetalView.loadFromXIB()
        metalView.frame = view.bounds
        metalView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(metalView)
        
        // Create SceneRenderer
        sceneRenderer = SceneRenderer(device: device)
        
        // Configure MetalView with SceneRenderer
        metalView.configure(with: sceneRenderer)
    }
    
    func setupGestures() {
        // Create camera gesture input system
        // This follows the architecture: CameraGestureInput → OrbitCameraController → Camera
        cameraGestureInput = CameraGestureInput(controller: sceneRenderer.controller)
        
        // Setup all gestures on the view
        // The gesture input will handle pan, pinch, two-finger pan, and double tap
        cameraGestureInput.setupGestures(on: view) { [weak self] in
            // Update uniforms when camera changes
            self?.sceneRenderer.updateUniforms()
        }
    }
}
