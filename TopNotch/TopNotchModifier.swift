//
//  TopNotchModifier.swift
//  TopNotch
//
//  Created by Sam Gold on 2025-02-10.
//

import SwiftUI

@available(iOS 13.0, *)
public struct TopNotchModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .background(TopNotchRepresentable())
    }
}

@available(iOS 13.0, *)
public struct TopNotchRepresentable: UIViewRepresentable {
    public func makeUIView(context: Context) -> UIView {
        // A dummy view that triggers TopNotch.
        TopNotchManager.shared.show()
        return UIView(frame: .zero)
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        // No update needed.
    }
}

@available(iOS 13.0, *)
public extension View {
    /// Adds the TopNotch watermark to the view.
    func topNotch() -> some View {
        self.modifier(TopNotchModifier())
    }
}
