//
//  SceneDelegate.swift
//  ExampleProject
//
//  Created by 王落凡 on 2026/6/9.
//

import UIKit

class wc: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ iw70OUs04e9516508XY0cRV7HHo88: UIScene, willConnectTo KL2fhIC4Z0Btl0rshV7SYF8Z: UISceneSession, options Z24m4zZIC94bctQpQ112Aweg935: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (iw70OUs04e9516508XY0cRV7HHo88 as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ iw70OUs04e9516508XY0cRV7HHo88: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ iw70OUs04e9516508XY0cRV7HHo88: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ iw70OUs04e9516508XY0cRV7HHo88: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ iw70OUs04e9516508XY0cRV7HHo88: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ iw70OUs04e9516508XY0cRV7HHo88: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

