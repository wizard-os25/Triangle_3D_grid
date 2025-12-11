//
//  CameraGestureInput.swift
//  3D_triangle
//
//  Created by wizard.os25 on 10/12/25.
//

import UIKit
import simd

// MARK: - CameraGestureInput

/// A system that processes UI inputs (touch/mouse gestures) and converts
/// them into normalized commands for the controller:
/// - Pan gesture → rotate / orbit camera
/// - Pinch gesture → zoom
/// - Drag with two fingers → pan
/// - Scroll wheel → zoom
/// - Double tap → reset camera
///
/// The gesture handler **does not modify the camera directly.**
/// It only translates raw gestures → commands → controller.
final class CameraGestureInput {
    
    // MARK: - Controller Reference
    
    weak var controller: OrbitCameraController?
    
    // MARK: - Gesture State
    
    private var isTwoFingerPan: Bool = false
    
    // MARK: - Initialization
    
    init(controller: OrbitCameraController) {
        self.controller = controller
    }
    
    // MARK: - Gesture Handlers
    
    /// Handle pan gesture (single finger drag)
    /// - Parameters:
    ///   - gesture: The pan gesture recognizer
    func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let controller = controller else { return }
        
        switch gesture.state {
        case .began:
            // Reset gesture translation to get relative movement
            gesture.setTranslation(.zero, in: gesture.view)
            
        case .changed:
            // Get relative translation since last update
            let translation = gesture.translation(in: gesture.view)
            let deltaX = Float(translation.x)
            let deltaY = Float(translation.y)
            
            // Single finger = orbit
            // Two fingers = pan (handled separately)
            if !isTwoFingerPan {
                controller.orbit(deltaYaw: deltaX, deltaPitch: -deltaY) // Negative Y for natural feel
            }
            
            // Reset translation for next frame
            gesture.setTranslation(.zero, in: gesture.view)
            
        case .ended, .cancelled, .failed:
            // Optional: Add momentum based on velocity
            let velocity = gesture.velocity(in: gesture.view)
            if !isTwoFingerPan && (abs(velocity.x) > 50 || abs(velocity.y) > 50) {
                // Add slight momentum for natural feel
                let momentumX = Float(velocity.x) * 0.0001
                let momentumY = Float(velocity.y) * 0.0001
                controller.orbit(deltaYaw: momentumX, deltaPitch: -momentumY)
            }
            
        default:
            break
        }
    }
    
    /// Handle pinch gesture (zoom)
    /// - Parameter gesture: The pinch gesture recognizer
    func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let controller = controller else { return }
        
        switch gesture.state {
        case .began: break
            // Scale is already relative, no need to track last scale
            
        case .changed:
            // Pinch gesture scale: > 1.0 = zoom out (fingers moving apart)
            //                     < 1.0 = zoom in (fingers moving together)
            // We want: positive delta = zoom in, negative = zoom out
            // So we invert: (1.0 - scale) gives us the correct direction
            let scaleChange = Float(1.0 - gesture.scale)
            controller.zoom(delta: scaleChange)
            
            // Reset scale to 1.0 for relative movement
            gesture.scale = 1.0
            
        case .ended, .cancelled, .failed:
            gesture.scale = 1.0
            
        default:
            break
        }
    }
    
    /// Handle two-finger pan (pan the target)
    /// - Parameter gesture: The pan gesture recognizer
    func handleTwoFingerPan(_ gesture: UIPanGestureRecognizer) {
        guard let controller = controller else { return }
        
        isTwoFingerPan = true
        
        switch gesture.state {
        case .began:
            gesture.setTranslation(.zero, in: gesture.view)
            
        case .changed:
            let translation = gesture.translation(in: gesture.view)
            let deltaX = Float(translation.x)
            let deltaY = Float(translation.y)
            
            controller.pan(deltaX: deltaX, deltaY: -deltaY) // Negative Y for natural feel
            gesture.setTranslation(.zero, in: gesture.view)
            
        case .ended, .cancelled, .failed:
            isTwoFingerPan = false
            
        default:
            break
        }
    }
    
    /// Handle double tap (reset camera)
    func handleDoubleTap() {
        controller?.reset()
    }
    
    // MARK: - Convenience: Setup Gestures for View
    
    /// Setup all gesture recognizers on a view
    /// - Parameters:
    ///   - view: The view to attach gestures to
    ///   - onUpdate: Optional callback when camera is updated (for triggering render updates)
    func setupGestures(on view: UIView, onUpdate: (() -> Void)? = nil) {
        // Single finger pan (orbit)
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureHandler(_:)))
        panGesture.maximumNumberOfTouches = 1
        view.addGestureRecognizer(panGesture)
        
        // Pinch (zoom)
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchGestureHandler(_:)))
        view.addGestureRecognizer(pinchGesture)
        
        // Two finger pan (pan target)
        let twoFingerPan = UIPanGestureRecognizer(target: self, action: #selector(twoFingerPanHandler(_:)))
        twoFingerPan.minimumNumberOfTouches = 2
        twoFingerPan.maximumNumberOfTouches = 2
        view.addGestureRecognizer(twoFingerPan)
        
        // Double tap (reset)
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapHandler(_:)))
        doubleTap.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTap)
        
        // Store update callback
        self.updateCallback = onUpdate
    }
    
    private var updateCallback: (() -> Void)?
    
    @objc private func panGestureHandler(_ gesture: UIPanGestureRecognizer) {
        handlePan(gesture)
        updateCallback?()
    }
    
    @objc private func pinchGestureHandler(_ gesture: UIPinchGestureRecognizer) {
        handlePinch(gesture)
        updateCallback?()
    }
    
    @objc private func twoFingerPanHandler(_ gesture: UIPanGestureRecognizer) {
        handleTwoFingerPan(gesture)
        updateCallback?()
    }
    
    @objc private func doubleTapHandler(_ gesture: UITapGestureRecognizer) {
        handleDoubleTap()
        updateCallback?()
    }
}

