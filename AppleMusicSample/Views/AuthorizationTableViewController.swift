/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`AuthorizationViewController` is a `UIViewController` subclass that displays the current authorization status of the application.
             It also provides a way to request authorization if needed as well as preesnts the `SKCloudServiceSetupViewController` if appropriate.
*/

import UIKit
import StoreKit
import MediaPlayer

@objcMembers
class AuthorizationTableViewController: UITableViewController {
    
    // MARK: Properties
    
    /// The instance of `AuthorizationManager` used for querying and requesting authorization status.
    var authorizationManager: AuthorizationManager!
    
    /// The instance of `AuthorizationDataSource` that provides information for the `UITableView`.
    var authorizationDataSource: AuthorizationDataSource!
    
    /// A boolean value representing if a `SKCloudServiceSetupViewController` was presented while the application was running.
    var didPresentCloudServiceSetup = false
    
    /// View Life Cycle Methods.

    override func viewDidLoad() {
        super.viewDidLoad()

        authorizationDataSource = AuthorizationDataSource(authorizationManager: authorizationManager)
        
        // Add the notification observers needed to respond to events from the `AuthorizationManager` and `UIApplication`.
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(self,
                                       selector: #selector(handleAuthorizationManagerDidUpdateNotification),
                                       name: AuthorizationManager.cloudServiceDidUpdateNotification,
                                       object: nil)
        
        notificationCenter.addObserver(self,
                                       selector: #selector(handleAuthorizationManagerDidUpdateNotification),
                                       name: AuthorizationManager.authorizationDidUpdateNotification,
                                       object: nil)
        
        notificationCenter.addObserver(self,
                                       selector: #selector(handleAuthorizationManagerDidUpdateNotification),
                                       name: .UIApplicationWillEnterForeground,
                                       object: nil)
        
        setAuthorizationRequestButtonState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setAuthorizationRequestButtonState()
    }
    
    deinit {
        // Remove all notification observers.
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.removeObserver(self,
                                          name: AuthorizationManager.cloudServiceDidUpdateNotification,
                                          object: nil)
        notificationCenter.removeObserver(self,
                                          name: AuthorizationManager.authorizationDidUpdateNotification,
                                          object: nil)
        notificationCenter.removeObserver(self,
                                          name: .UIApplicationWillEnterForeground,
                                          object: nil)
    }
    
    // MARK: UI Updating Methods

    func setAuthorizationRequestButtonState() {
        if SKCloudServiceController.authorizationStatus() == .notDetermined || MPMediaLibrary.authorizationStatus() == .notDetermined {
            self.navigationItem.rightBarButtonItem?.isEnabled = true
        } else {
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
    
    // MARK: Target-Action Methods
    
    @IBAction func requestAuthorization(_ sender: UIBarButtonItem) {
        authorizationManager.requestCloudServiceAuthorization()
        
        authorizationManager.requestMediaLibraryAuthorization()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return authorizationDataSource.numberOfSections()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return authorizationDataSource.numberOfItems(in: section)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return authorizationDataSource.sectionTitle(for: section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AuthorizationCellIdentifier", for: indexPath)

        cell.textLabel?.text = authorizationDataSource.stringForItem(at: indexPath)

        return cell
    }
    
    // MARK: SKCloudServiceSetupViewController Method
    
    func presentCloudServiceSetup() {
        
        guard didPresentCloudServiceSetup == false else {
            return
        }
        
        /*
         If the current `SKCloudServiceCapability` includes `.musicCatalogSubscriptionEligible`, this means that the currently signed in iTunes Store
         account is elgible for an Apple Music Trial Subscription.  To provide the user with an option to sign up for a free trial, your application
         can present the `SKCloudServiceSetupViewController` as demonstrated below.
        */
        
        let cloudServiceSetupViewController = SKCloudServiceSetupViewController()
        cloudServiceSetupViewController.delegate = self
        
        cloudServiceSetupViewController.load(options: [.action: SKCloudServiceSetupAction.subscribe]) { [weak self] (result, error) in
            guard error == nil else {
                fatalError("An Error occurred: \(error!.localizedDescription)")
            }
            
            if result {
                self?.present(cloudServiceSetupViewController, animated: true, completion: nil)
                self?.didPresentCloudServiceSetup = true
            }
        }
    }
    
    // MARK: Notification Observing Methods
    
    func handleAuthorizationManagerDidUpdateNotification() {
        DispatchQueue.main.async {
            if SKCloudServiceController.authorizationStatus() == .notDetermined || MPMediaLibrary.authorizationStatus() == .notDetermined {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
            } else {
                self.navigationItem.rightBarButtonItem?.isEnabled = false
                
                if self.authorizationManager.cloudServiceCapabilities.contains(.musicCatalogSubscriptionEligible) &&
                    !self.authorizationManager.cloudServiceCapabilities.contains(.musicCatalogPlayback) {
                    self.presentCloudServiceSetup()
                }
                
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
}

extension AuthorizationTableViewController: SKCloudServiceSetupViewControllerDelegate {
    func cloudServiceSetupViewControllerDidDismiss(_ cloudServiceSetupViewController: SKCloudServiceSetupViewController) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}
