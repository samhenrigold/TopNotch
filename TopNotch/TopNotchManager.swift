//
//  TopNotchManager.swift
//  TopNotch
//
//  Created by Sam Gold on 2025-02-10.
//

import UIKit

public final class TopNotchManager {

    // MARK: Public API
    
    /// A shared instance (singleton).
    public static let shared = TopNotchManager()
    
    /// The computed exclusion area (the “notch”) retrieved via KVC.
    public static var exclusionRect: CGRect = {
        let screen = UIScreen.main
        guard let exclusionAreaMethod = screen.value(forKey: "_exclusionArea") as? NSObject,
              let rect = exclusionAreaMethod.value(forKey: "rect") as? CGRect else {
            print("[TopNotchManager] Exclusion area not available; returning .zero")
            return .zero
        }
        print("[TopNotchManager] Retrieved exclusionRect: \(rect)")
        return rect
    }()
    
    public private(set) var isNotchVisible: Bool = false
    public private(set) var currentExclusionRect: CGRect = .zero
    public private(set) var cannotShowReason: String? = nil

    // MARK: Private Properties
    
    private var notchView: UIView?
    private var config: TopNotchConfiguration = TopNotchConfiguration()
    private var notchWindow: UIWindow?
    /// The raw exclusion rectangle stored when showing; we do not update it on rotation.
    private var storedExclusionRect: CGRect?
    
    // MARK: Model Overrides
    
    /// Individual model overrides – leave empty for now (override as needed).
    /*
    private let modelOverrides: [String: (scale: CGFloat, heightFactor: CGFloat, radius: CGFloat)] = [
        // Example:
        // "iPhoneXX": (scale: 0.80, heightFactor: 0.80, radius: 25)
    ]
    */
    private let modelOverrides: [String: (scale: CGFloat, heightFactor: CGFloat, radius: CGFloat)] = [:]
    
    /// Series overrides. Any device whose model identifier begins with the key string will use these settings.
    private let modelSeriesOverrides: [String: (scale: CGFloat, heightFactor: CGFloat, radius: CGFloat)] = [
        "iPhone13": (scale: 0.95, heightFactor: 1.0, radius: 27), // iPhone 12 series
        "iPhone14": (scale: 0.75, heightFactor: 0.75, radius: 24)  // iPhone 13/14 series
    ]
    
    // MARK: Orientation‑Locking Container
    
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
    
    // MARK: Public Methods
    
    /// Shows the notch view using an optional custom view and configuration.
    ///
    /// - Parameters:
    ///   - customView: A custom view to use for the notch. If nil, a default red‑tinted view is used.
    ///   - configuration: A configuration object controlling animation duration and whether the view should hide for the task switcher.
    public func show(customView: UIView? = nil,
                     with configuration: TopNotchConfiguration = TopNotchConfiguration()) {
        print("[TopNotchManager] Showing notch view")
        config = configuration
        
        // Retrieve the exclusion area.
        let exclusion = TopNotchManager.exclusionRect
        guard exclusion != .zero else {
            print("[TopNotchManager] Cannot show notch: No exclusion area detected.")
            cannotShowReason = "No exclusion area detected."
            hide()
            return
        }
        cannotShowReason = nil
        storedExclusionRect = exclusion
        currentExclusionRect = exclusion
        
        // Use the provided custom view or create a default view.
        if let custom = customView {
            print("[TopNotchManager] Using custom notch view")
            notchView = custom
        } else if notchView == nil {
            print("[TopNotchManager] Creating default notch view")
            notchView = createDefaultNotchView()
        }
        notchView?.isUserInteractionEnabled = false
        
        // Create (or update) the dedicated top‑level window.
        attachNotchViewToWindow()
        
        // Set initial state and update the frame.
        notchView?.alpha = 0
        updateNotchFrame()
        
        // Animate fade‑in.
        UIView.animate(withDuration: config.animationDuration) {
            self.notchView?.alpha = 1.0
        }
        print("[TopNotchManager] Notch view fading in")
        isNotchVisible = true
        
        // Register for orientation changes.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateNotchFrame),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
        // Optionally hide the notch when the task switcher appears.
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
    }
    
    /// Hides the notch view by fading it out and removing it.
    public func hide() {
        print("[TopNotchManager] Hiding notch view")
        NotificationCenter.default.removeObserver(self)
        UIView.animate(withDuration: config.animationDuration, animations: {
            self.notchView?.alpha = 0
        }) { _ in
            print("[TopNotchManager] Notch view removed from superview")
            self.notchView?.removeFromSuperview()
            self.isNotchVisible = false
        }
    }
    
    // MARK: Private Helpers
    
    /// Creates a default notch view with a red tint.
    private func createDefaultNotchView() -> UIView {
        print("[TopNotchManager] Creating default notch view with red tint")
        let view = UIView()
        view.backgroundColor = UIColor.red.withAlphaComponent(0.5)
        return view
    }
    
    /// Creates (if needed) and attaches the notch view to its own dedicated window.
    private func attachNotchViewToWindow() {
        if notchWindow == nil {
            print("[TopNotchManager] Creating new UIWindow for notch view")
            if let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                let window = UIWindow(windowScene: windowScene)
                window.frame = windowScene.coordinateSpace.bounds
                window.backgroundColor = .clear
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
        notchView?.removeFromSuperview()
        if let container = notchWindow?.rootViewController?.view, let view = notchView {
            container.addSubview(view)
            container.bringSubviewToFront(view)
            print("[TopNotchManager] Notch view attached to window")
        }
    }
    
    /// Updates the notch view’s frame using the stored exclusion rectangle and applies model‑specific adjustments.
    @objc public func updateNotchFrame() {
        guard let rawRect = storedExclusionRect, rawRect != .zero else {
            notchView?.frame = .zero
            print("[TopNotchManager] Notch frame set to .zero")
            return
        }
        
        let modelId = UIDevice.modelIdentifier
        var adjustedFrame = rawRect
        
        // First check for individual model overrides (if any).
        if let override = modelOverrides[modelId] {
            let newWidth = rawRect.width * override.scale
            let newX = rawRect.origin.x + (rawRect.width - newWidth) / 2
            let newHeight = rawRect.height * override.heightFactor
            adjustedFrame = CGRect(x: newX, y: rawRect.origin.y, width: newWidth, height: newHeight)
            print("[TopNotchManager] Applied individual override for \(modelId): \(adjustedFrame)")
            applyCornerStyling(with: override.radius, roundBottomOnly: true)
        }
        // Otherwise, check for series overrides.
        else if let seriesOverride = modelSeriesOverrides.first(where: { modelId.hasPrefix($0.key) }) {
            let override = seriesOverride.value
            let newWidth = rawRect.width * override.scale
            let newX = rawRect.origin.x + (rawRect.width - newWidth) / 2
            let newHeight = rawRect.height * override.heightFactor
            adjustedFrame = CGRect(x: newX, y: rawRect.origin.y, width: newWidth, height: newHeight)
            print("[TopNotchManager] Applied series override for \(modelId) (prefix \(seriesOverride.key)): \(adjustedFrame)")
            applyCornerStyling(with: override.radius, roundBottomOnly: true)
        }
        // Otherwise, use default styling.
        else {
            adjustedFrame = rawRect
            // Assuming that if the notch doesn't touch the top, it needs a pill-shaped mask
            if rawRect.origin.y > 0 {
                let capsuleRadius = rawRect.height / 2
                applyCornerStyling(with: capsuleRadius)
                print("[TopNotchManager] Dynamic island default styling (radius \(capsuleRadius))")
            } else {
                applyCornerStyling(with: 21, roundBottomOnly: true)
                print("[TopNotchManager] Original notch default styling (radius 21)")
            }
        }
        
        notchView?.frame = adjustedFrame
        print("[TopNotchManager] Updated notch view frame to: \(adjustedFrame)")
    }
    
    /// Applies corner styling using a CAShapeLayer mask so that the rounded corners aren’t clipped.
    ///
    /// - Parameters:
    ///   - radius: The corner radius to apply.
    ///   - roundBottomOnly: If true, only the bottom corners are rounded.
    private func applyCornerStyling(with radius: CGFloat, roundBottomOnly: Bool = false) {
        guard let view = notchView else { return }
        // Disable the standard clipping.
        view.clipsToBounds = false
        
        let path: UIBezierPath
        if roundBottomOnly {
            path = UIBezierPath(roundedRect: view.bounds, byRoundingCorners: [.bottomLeft, .bottomRight], cornerRadii: CGSize(width: radius, height: radius))
        } else {
            path = UIBezierPath(roundedRect: view.bounds, cornerRadius: radius)
        }
        
        let maskLayer = CAShapeLayer()
        maskLayer.frame = view.bounds
        maskLayer.path = path.cgPath
        view.layer.mask = maskLayer
    }
    
    // MARK: Task Switcher Notifications
    
    @objc private func sceneWillDeactivateNotification(_ notification: Notification) {
        if config.shouldHideForTaskSwitcher && isNotchVisible {
            print("[TopNotchManager] Hiding notch view for task switcher (willDeactivate)")
            UIView.animate(withDuration: config.animationDuration) {
                self.notchView?.alpha = 0
            }
        }
    }
    
    @objc private func sceneDidActivateNotification(_ notification: Notification) {
        if config.shouldHideForTaskSwitcher && isNotchVisible {
            print("[TopNotchManager] Showing notch view after task switcher (didActivate)")
            UIView.animate(withDuration: config.animationDuration) {
                self.notchView?.alpha = 1.0
            }
        }
    }
}
