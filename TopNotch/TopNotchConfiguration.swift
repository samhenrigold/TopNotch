//
//  TopNotchConfiguration.swift
//  TopNotch
//
//  Created by Sam Gold on 2025-02-10.
//

import UIKit

/// A configuration object for TopNotch behavior.
public struct TopNotchConfiguration {
    /// The duration of the show/hide animation.
    public var animationDuration: TimeInterval
    /// Whether to animate frame changes.
    public var shouldAnimate: Bool
    /// If true, the watermark will hide when the app is about to show the entire screen (e.g. task switcher).
    public var shouldHideForTaskSwitcher: Bool

    public init(animationDuration: TimeInterval = 0.3,
                shouldAnimate: Bool = true,
                shouldHideForTaskSwitcher: Bool = true) {
        self.animationDuration = animationDuration
        self.shouldAnimate = shouldAnimate
        self.shouldHideForTaskSwitcher = shouldHideForTaskSwitcher
    }
}
