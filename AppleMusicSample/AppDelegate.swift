/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The Application's AppDelegate which configures the rest of the application's dependencies.
*/

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: Properties
    
    var window: UIWindow?
    
    /// The instance of `AuthorizationManager` which is responsible for managing authorization for the application.
    lazy var authorizationManager: AuthorizationManager = {
        return AuthorizationManager(appleMusicManager: self.appleMusicManager)
    }()
    
    /// The instance of `MediaLibraryManager` which manages the `MPPMediaPlaylist` this application creates.
    lazy var mediaLibraryManager: MediaLibraryManager = {
        return MediaLibraryManager(authorizationManager: self.authorizationManager)
    }()
    
    
    /// The instance of `AppleMusicManager` which handles making web service calls to Apple Music Web Services.
    var appleMusicManager = AppleMusicManager()
    
    // MARK: Application Life Cycle Methods
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        
        guard let authorizationTableViewController = topViewControllerAtTabBarIndex(0) as? AuthorizationTableViewController else {
            fatalError("Unable to find expected \(AuthorizationTableViewController.self) in at TabBar Index 0")
        }
        
        guard let mediaSearchTableViewController = topViewControllerAtTabBarIndex(4) as? MediaSearchTableViewController else {
            fatalError("Unable to find expected \(MediaSearchTableViewController.self) in at TabBar Index 4")
        }
        
        authorizationTableViewController.authorizationManager = authorizationManager
        
        mediaSearchTableViewController.authorizationManager = authorizationManager
        mediaSearchTableViewController.mediaLibraryManager = mediaLibraryManager
        
        return true
    }
    
    
    // MARK: Utility Methods
    
    func topViewControllerAtTabBarIndex(_ index: Int) -> UIViewController? {
        guard let tabBarController = window?.rootViewController as? UITabBarController,
            let navigationController = tabBarController.viewControllers?[index] as? UINavigationController else {
                fatalError("Unable to find expected View Controller in Main.storyboard.")
        }
        
        return navigationController.topViewController
    }
}

