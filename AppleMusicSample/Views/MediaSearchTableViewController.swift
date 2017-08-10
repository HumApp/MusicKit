/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`MediaSearchTableViewController` is a `UITableViewController` subclass that allows performing a search on the Apple Music Catalog
             and displays the search results.  The results can then either be played using the `MusicPlayerManager` or added to the
             `MPMediaPlaylist` created by the `MediaLibraryManager`.
*/

import UIKit
import StoreKit

@objcMembers
class MediaSearchTableViewController: UITableViewController {
    
    /// The instance of `UISearchController` used for providing the search funcationality in the `UITableView`.
    var searchController = UISearchController(searchResultsController: nil)
    
    /// The instance of `AuthorizationManager` used for querying and requesting authorization status.
    var authorizationManager: AuthorizationManager!
    
    /// The instance of `AppleMusicManager` which is used to make search request calls to the Apple Music Web Services.
    let appleMusicManager = AppleMusicManager()
    
    /// The instance of `MediaLibraryManager` which is used for adding items to the application's playlist.
    var mediaLibraryManager: MediaLibraryManager!
    
    /// A `DispatchQueue` used for synchornizing the setting of `mediaItems` to avoid threading issues with various `UITableView` delegate callbacks.
    var setterQueue = DispatchQueue(label: "MediaSearchTableViewController")
    
    /// The array of `MediaItem` objects that represents the list of search results.
    var mediaItems = [[MediaItem]]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: View Life Cycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure self sizing cells.
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100
        
        // Configure the `UISearchController`.
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        searchController.searchBar.delegate = self
        tableView.tableHeaderView = searchController.searchBar
        
        /*
         Add the notification observers needed to respond to events from the `AuthorizationManager`, `MPMediaLibrary` and `UIApplication`.
         This is so that if the user enables/disables capabilities in the Settings app the application will reflect those changes accurately.
         */
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(self,
                                       selector: #selector(handleAuthorizationManagerAuthorizationDidUpdateNotification),
                                       name: AuthorizationManager.authorizationDidUpdateNotification,
                                       object: nil)
        
        notificationCenter.addObserver(self,
                                       selector: #selector(handleAuthorizationManagerAuthorizationDidUpdateNotification),
                                       name: .UIApplicationWillEnterForeground,
                                       object: nil)
    }
    
    deinit {
        // Remove all notification observers.
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.removeObserver(self, name: AuthorizationManager.authorizationDidUpdateNotification, object: nil)
        notificationCenter.removeObserver(self, name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if appleMusicManager.fetchDeveloperToken() == nil {
            
            searchController.searchBar.isUserInteractionEnabled = false
            
            let alertController = UIAlertController(title: "Error",
                                                    message: "No developer token was specified. See the README for more information.",
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel, handler: nil))
            present(alertController, animated: true, completion: nil)
        } else {
            searchController.searchBar.isUserInteractionEnabled = true
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return mediaItems.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mediaItems[section].count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return NSLocalizedString("Songs", comment: "Songs")
        } else {
            return NSLocalizedString("Albums", comment: "Albums")
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MediaItemTableViewCell.identifier,
                                                       for: indexPath) as? MediaItemTableViewCell else {
                                                        return UITableViewCell()
        }
        
        let mediaItem = mediaItems[indexPath.section][indexPath.row]

        cell.mediaItem = mediaItem
        cell.delegate = self
        
        let cloudServiceCapabilities = authorizationManager.cloudServiceCapabilities
        
        /*
        It is important to actually check if your application has the appropriate `SKCloudServiceCapability` options before enabling functionality
         related to playing back content from the Apple Music Catalog or adding items to the user's Cloud Music Library.
         */
        
        if cloudServiceCapabilities.contains(.addToCloudMusicLibrary) {
            cell.addToPlaylistButton.isEnabled = true
        } else {
            cell.addToPlaylistButton.isEnabled = false
        }
        
        if cloudServiceCapabilities.contains(.musicCatalogPlayback) {
            cell.playItemButton.isEnabled = true
        } else {
            cell.playItemButton.isEnabled = false
        }
        
        return cell
    }
    
    // MARK: Notification Observing Methods
    
    func handleAuthorizationManagerAuthorizationDidUpdateNotification() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}

extension MediaSearchTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchString = searchController.searchBar.text else {
            return
        }
        
        if searchString == "" {
            self.setterQueue.sync {
                self.mediaItems = []
            }
        } else {
            appleMusicManager.performAppleMusicCatalogSearch(with: searchString,
                                                             countryCode: authorizationManager.cloudServiceStorefrontCountryCode,
                                                             completion: { [weak self] (searchResults, error) in
                guard error == nil else {
                    
                    // Your application should handle these errors appropriately depending on the kind of error.
                    self?.setterQueue.sync {
                        self?.mediaItems = []
                    }
                    
                    let alertController: UIAlertController
                    
                    guard let error = error as NSError?, let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? Error else {
                        
                        alertController = UIAlertController(title: "Error",
                                                            message: "Encountered unexpected error.",
                                                            preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
                        
                        DispatchQueue.main.async {
                            self?.present(alertController, animated: true, completion: nil)
                        }
                        
                        return
                    }
                    
                    alertController = UIAlertController(title: "Error",
                                                        message: underlyingError.localizedDescription,
                                                        preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
                    
                    DispatchQueue.main.async {
                        self?.present(alertController, animated: true, completion: nil)
                    }
                    
                    return
                }
                                                                
                self?.setterQueue.sync {
                    self?.mediaItems = searchResults
                }
                                                                
            })
        }
    }
}

extension MediaSearchTableViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        setterQueue.sync {
            self.mediaItems = []
        }
    }
}

extension MediaSearchTableViewController: MediaSearchTableViewCellDelegate {
    func mediaSearchTableViewCell(_ mediaSearchTableViewCell: MediaItemTableViewCell, addToPlaylist mediaItem: MediaItem) {
        mediaLibraryManager.addItem(with: mediaItem.identifier)
    }
}
