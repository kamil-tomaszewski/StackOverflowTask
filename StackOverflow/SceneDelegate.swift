//
//  SceneDelegate.swift
//  StackOverflow
//
//  Created by Kamil Tomaszewski on 21/02/2026.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let repository = NetworkUsersRepository()
        let viewModel = UserListViewModel(repository: repository)
        let viewController = UserListViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window
    }
}
