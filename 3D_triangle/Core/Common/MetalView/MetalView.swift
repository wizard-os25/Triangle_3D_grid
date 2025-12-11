//
//  MetalView.swift
//  GeometryLab
//
//  Created by wizard.os25 on 5/12/25.
//

import Foundation
import Metal
import MetalKit
import simd

final class MetalView: MTKView {
    var sceneRenderer: SceneRenderer?
    
    // MARK: - Initialization
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device ?? GPUDevice.shared.device)
        setupView()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        device = GPUDevice.shared.device
        setupView()
    }
    
    // MARK: - XIB Loading
    
    /// Load MetalView from XIB file
    /// - Returns: MetalView instance loaded from XIB
    static func loadFromXIB() -> MetalView {
        let bundle = Bundle(for: MetalView.self)
        let nib = UINib(nibName: "MetalView", bundle: bundle)
        let views = nib.instantiate(withOwner: nil, options: nil)
        
        guard let metalView = views.first as? MetalView else {
            fatalError("Failed to load MetalView from XIB. Make sure the XIB contains a MetalView with custom class set.")
        }
        
        return metalView
    }
    
    /// Load MetalView from XIB with owner (for outlet connections)
    /// - Parameter owner: The owner object that will receive outlet connections
    /// - Returns: MetalView instance loaded from XIB
    static func loadFromXIB(owner: Any) -> MetalView {
        let bundle = Bundle(for: MetalView.self)
        let nib = UINib(nibName: "MetalView", bundle: bundle)
        let views = nib.instantiate(withOwner: owner, options: nil)
        
        guard let metalView = views.first as? MetalView else {
            fatalError("Failed to load MetalView from XIB. Make sure the XIB contains a MetalView with custom class set.")
        }
        
        return metalView
    }
    
    // MARK: - Setup
    
    private func setupView() {
        // Set device if not already set
        if device == nil {
            device = GPUDevice.shared.device
        }
        
        delegate = self
        clearColor = MTLClearColorMake(0.1, 0.1, 0.12, 1.0)
        colorPixelFormat = .bgra8Unorm
        depthStencilPixelFormat = .depth32Float
        preferredFramesPerSecond = 60
        isUserInteractionEnabled = true
        enableSetNeedsDisplay = false  // Enable automatic rendering
        autoResizeDrawable = true
    }
    
    // MARK: - Configuration
    
    /// Configure the MetalView with a scene renderer
    /// - Parameter renderer: The SceneRenderer to use for rendering
    func configure(with renderer: SceneRenderer) {
        self.sceneRenderer = renderer
        if bounds.width > 0 && bounds.height > 0 {
            renderer.setViewSize(bounds.size)
        }
    }
}

extension MetalView: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // This is called automatically when the view size changes (including rotation)
        print("MetalView: Drawable size will change to \(size)")
        sceneRenderer?.setViewSize(size)
        
        // Also update based on bounds in case there's any discrepancy
        DispatchQueue.main.async {
            if let renderer = self.sceneRenderer {
                renderer.setViewSize(view.bounds.size)
            }
        }
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let sceneRenderer = sceneRenderer else {
            // Debug: Log why rendering is skipped
            if view.currentDrawable == nil {
                print("MetalView: draw() skipped - no currentDrawable")
            } else if view.currentRenderPassDescriptor == nil {
                print("MetalView: draw() skipped - no renderPassDescriptor")
            } else if sceneRenderer == nil {
                print("MetalView: draw() skipped - no sceneRenderer")
            }
            return
        }
        
        // Ensure view size is set
        if sceneRenderer.viewSize.width == 0 || sceneRenderer.viewSize.height == 0 {
            sceneRenderer.setViewSize(view.bounds.size)
        }
        
        // Clear color attachment
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].clearColor = clearColor
        
        // Clear depth buffer
        descriptor.depthAttachment?.loadAction = .clear
        descriptor.depthAttachment?.clearDepth = 1.0
        
        sceneRenderer.render(descriptor: descriptor, drawable: drawable)
    }
}
