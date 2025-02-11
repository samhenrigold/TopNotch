//
//  TopNotchModifier.swift
//  TopNotch
//
//  Created by Sam Gold on 2025-02-10.
//

import SwiftUI

/// A view modifier that adds the TopNotch watermark to a SwiftUI view.
@available(iOS 13.0, *)
public struct TopNotchModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content.background(TopNotchRepresentable())
    }
}

/// A representable that triggers the TopNotch view in a SwiftUI hierarchy.
@available(iOS 13.0, *)
public struct TopNotchRepresentable: UIViewRepresentable {
    public func makeUIView(context: Context) -> UIView {
        // Trigger TopNotch.
        TopNotchManager.shared.show()
        return UIView(frame: .zero)
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        // No updates required.
    }
}

/// An extension to easily apply the TopNotch modifier to SwiftUI views.
@available(iOS 13.0, *)
public extension View {
    /// Adds the TopNotch watermark to the view.
    func topNotch() -> some View {
        self.modifier(TopNotchModifier())
    }
}
