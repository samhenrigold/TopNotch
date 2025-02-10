//
//  TopNotchManager.swift
//  TopNotch
//
//  Created by Sam Gold on 2025-02-10.
//

import UIKit
import SwiftUI

public final class TopNotchManager {

    // MARK: – Public API
    
    /// A shared instance (singleton).
    public static let shared = TopNotchManager()
    
    /// Exposes the computed exclusion area (the “notch”) from the screen.
    public static var exclusionRect: CGRect = {
        let screen = UIScreen.main
        // UIScreen._exclusionArea
        guard let exclusionAreaMethod = screen.value(forKey: "_" + "exclusion" + "Area") as? NSObject,
              let rect = exclusionAreaMethod.value(forKey: "rect") as? CGRect else {
            print("[TopNotchManager] Exclusion area not available; returning .zero")
            return .zero
        }
        print("[TopNotchManager] Retrieved exclusionRect: \(rect)")
        return rect
    }()
    
    /// True if the notch view is visible.
    public private(set) var isNotchVisible: Bool = false
    /// The exclusion area that was used (if any).
    public private(set) var currentExclusionRect: CGRect = .zero
    /// If the notch cannot be shown, this property holds a (human‑readable) reason.
    public private(set) var cannotShowReason: String? = nil

    // MARK: – Private Properties
    
    private var notchView: UIView?
    private var config: TopNotchConfiguration = TopNotchConfiguration()
    private var notchWindow: UIWindow?
    /// The exclusion rectangle stored when showing; we never update it on rotation.
    private var storedExclusionRect: CGRect?
    
    // MARK: – Orientation‑Locking Container
    
    /// A container view controller that locks orientation to portrait.
    private class NoRotationViewController: UIViewController {
        override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
            return .portrait
        }
        override var shouldAutorotate: Bool {
            return false
        }
        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .clear
            print("[NoRotationViewController] View did load")
        }
    }
    
    // MARK: – Public Methods
    
    /// Shows the TopNotch watermark.
    /// - Parameters:
    ///   - customView: A custom view to use for the notch (if nil, a default view is created).
    ///   - configuration: A configuration object.
    ///   - completion: Called when the operation completes.
    public func show(customView: UIView? = nil,
                     configuration: TopNotchConfiguration = TopNotchConfiguration(),
                     completion: (() -> Void)? = nil) {
        print("[TopNotchManager] Showing notch view")
        config = configuration
        
        // Get the exclusion area from the device.
        let exclusion = TopNotchManager.exclusionRect
        if exclusion == .zero {
            print("[TopNotchManager] Cannot show notch: No exclusion area detected.")
            cannotShowReason = "No exclusion area detected."
            hide(completion: completion)
            return
        } else {
            print("[TopNotchManager] Exclusion area detected: \(exclusion)")
            cannotShowReason = nil
        }
        // Store and expose the exclusion rectangle.
        storedExclusionRect = exclusion
        currentExclusionRect = exclusion
        
        // Use the provided custom view or create a default one.
        if let custom = customView {
            print("[TopNotchManager] Using custom notch view")
            notchView = custom
        } else if notchView == nil {
            print("[TopNotchManager] Creating default notch view")
            notchView = createDefaultNotchView()
        }
        notchView?.isUserInteractionEnabled = false
        
        // Create or update the dedicated top-level window.
        attachNotchViewToWindow()
        
        // Set the notch view’s initial state and frame (using our stored exclusion rect).
        notchView?.alpha = 0
        updateNotchFrame()
        
        // Fade it in.
        UIView.animate(withDuration: config.animationDuration) {
            self.notchView?.alpha = 1.0
        }
        print("[TopNotchManager] Notch view fading in")
        isNotchVisible = true
        
        // Always update on orientation changes (the container is locked to portrait so the stored rect never shifts).
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateNotchFrame),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
        
        // If our config says so, also hide the notch when the app is about to show the task switcher.
        if config.shouldHideForTaskSwitcher {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(sceneWillDeactivateNotification(_:)),
                                                   name: UIScene.willDeactivateNotification,
                                                   object: nil)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(sceneDidActivateNotification(_:)),
                                                   name: UIScene.didActivateNotification,
                                                   object: nil)
            print("[TopNotchManager] Observing scene de/activation for task switcher hiding")
        }
        
        completion?()
    }
    
    /// Hides the TopNotch watermark.
    public func hide(completion: (() -> Void)? = nil) {
        print("[TopNotchManager] Hiding notch view")
        NotificationCenter.default.removeObserver(self)
        UIView.animate(withDuration: config.animationDuration, animations: {
            self.notchView?.alpha = 0
        }) { _ in
            print("[TopNotchManager] Notch view removed from superview")
            self.notchView?.removeFromSuperview()
            self.isNotchVisible = false
            completion?()
        }
    }
    
    // MARK: – Private Helpers
    
    /// Creates a default notch view.
    private func createDefaultNotchView() -> UIView {
        print("[TopNotchManager] Creating default notch view with red color")
        let view = UIView()
        view.backgroundColor = UIColor.red.withAlphaComponent(0.5)
        return view
    }
    
    /// Creates (if needed) and attaches the notch view to its own dedicated window.
    private func attachNotchViewToWindow() {
        if notchWindow == nil {
            print("[TopNotchManager] Creating new UIWindow for notch view")
            // Use connectedScenes to find an active scene.
            if let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                let window = UIWindow(windowScene: windowScene)
                window.frame = windowScene.coordinateSpace.bounds
                window.backgroundColor = .clear
                // Set a high window level to ensure it stays on top.
                window.windowLevel = UIWindow.Level.statusBar + 100
                let containerVC = NoRotationViewController()
                window.rootViewController = containerVC
                window.isUserInteractionEnabled = false
                window.isHidden = false
                window.makeKeyAndVisible()
                notchWindow = window
                print("[TopNotchManager] UIWindow created and visible")
            } else {
                print("[TopNotchManager] Warning: No active window scene found")
            }
        }
        // Remove notchView from any previous superview.
        notchView?.removeFromSuperview()
        if let container = notchWindow?.rootViewController?.view, let view = notchView {
            container.addSubview(view)
            container.bringSubviewToFront(view)
            print("[TopNotchManager] Notch view attached to window")
        }
    }
    
    /// Updates the frame of the notch view.
    /// Instead of re‑computing the notch rectangle on every rotation, we use the stored value.
    @objc public func updateNotchFrame() {
        if let rect = storedExclusionRect, rect != .zero {
            notchView?.frame = rect
            print("[TopNotchManager] Updated notch view frame to: \(rect)")
        } else {
            notchView?.frame = .zero
            print("[TopNotchManager] Notch frame set to .zero")
        }
    }
    
    // MARK: – Task Switcher Notifications
    
    /// Called when the scene is about to deactivate (e.g. task switcher invoked).
    @objc private func sceneWillDeactivateNotification(_ notification: Notification) {
        if config.shouldHideForTaskSwitcher && isNotchVisible {
            print("[TopNotchManager] Hiding notch view for task switcher (willDeactivate)")
            UIView.animate(withDuration: config.animationDuration) {
                self.notchView?.alpha = 0
            }
        }
    }
    
    /// Called when the scene did activate (e.g. task switcher dismissed).
    @objc private func sceneDidActivateNotification(_ notification: Notification) {
        if config.shouldHideForTaskSwitcher && isNotchVisible {
            print("[TopNotchManager] Showing notch view after task switcher (didActivate)")
            UIView.animate(withDuration: config.animationDuration) {
                self.notchView?.alpha = 1.0
            }
        }
    }
}
