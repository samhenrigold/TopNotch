//
//  SceneDelegate.swift
//  TopNotchDemo
//
//  Created by Sam Gold on 2025-02-10.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        // Use the insetGrouped table view controller.
        let fontTableVC = FontTableViewController()
        let navController = UINavigationController(rootViewController: fontTableVC)
        
        window.rootViewController = navController
        self.window = window
        window.makeKeyAndVisible()
    }
}
