/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`AuthorizationDataSource` is the data source for the `AuthorizationTableViewController` that provides the current authorization
             information for the application.
*/

import UIKit
import StoreKit
import MediaPlayer

class AuthorizationDataSource {
    
    enum SectionTypes: Int {
        case mediaLibraryAuthorizationStatus = 0, cloudServiceAuthorizationStatus, requestCapabilities
        
        func sectionTitle() -> String {
            switch self {
            case .cloudServiceAuthorizationStatus:
                return "SKCloudServiceController"
            case .requestCapabilities:
                return "Capabilities"
            case .mediaLibraryAuthorizationStatus:
                return "MPMediaLibrary"
            }
        }
    }
    
    let authorizationManager: AuthorizationManager
    
    var capabilities = [SKCloudServiceCapability]()
    
    // MARK: Initialization
    
    init(authorizationManager: AuthorizationManager) {
        self.authorizationManager = authorizationManager
    }
    
    // MARK: Data Source Methods
    
    public func numberOfSections() -> Int {
        // There is always a section for the displaying +authorizationStatus from `SKCloudServiceController` and `MPMediaLibrary`.
        var section = 2
        
        // If we have capabilities to display from +requestCapabilities from SKCloudServiceController.
        if SKCloudServiceController.authorizationStatus() == .authorized {
            
            let cloudServiceCapabilities = authorizationManager.cloudServiceCapabilities
            
            capabilities = []
            
            if cloudServiceCapabilities.contains(.addToCloudMusicLibrary) {
                capabilities.append(.addToCloudMusicLibrary)
            }
            
            if cloudServiceCapabilities.contains(.musicCatalogPlayback) {
                capabilities.append(.musicCatalogPlayback)
            }
            
            if cloudServiceCapabilities.contains(.musicCatalogSubscriptionEligible) {
                capabilities.append(.musicCatalogSubscriptionEligible)
            }
            
            section += 1
        }
        
        return section
    }
    
    public func numberOfItems(in section: Int) -> Int {
        guard let sectionType = SectionTypes(rawValue: section) else {
            return 0
        }
        
        switch sectionType {
        case .cloudServiceAuthorizationStatus:
            return 1
        case .requestCapabilities:
            return capabilities.count
        case .mediaLibraryAuthorizationStatus:
            return 1
        }
    }
    
    public func sectionTitle(for section: Int) -> String {
        guard let sectionType = SectionTypes(rawValue: section) else {
            return ""
        }
        
        return sectionType.sectionTitle()
    }
    
    public func stringForItem(at indexPath: IndexPath) -> String {
        guard let sectionType = SectionTypes(rawValue: indexPath.section) else {
            return ""
        }
        
        switch sectionType {
        case .cloudServiceAuthorizationStatus:
            return SKCloudServiceController.authorizationStatus().statusString()
        case .requestCapabilities:
            return capabilities[indexPath.row].capabilityString()
        case .mediaLibraryAuthorizationStatus:
            return MPMediaLibrary.authorizationStatus().statusString()
        }
    }
}

// MARK: Helpful Extension Methods

extension SKCloudServiceAuthorizationStatus {
    func statusString() -> String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        case .authorized:
            return "Authorized"
        }
    }
}

extension MPMediaLibraryAuthorizationStatus {
    func statusString() -> String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        case .authorized:
            return "Authorized"
        }
    }
}

extension SKCloudServiceCapability {
    func capabilityString() -> String {
        switch self {
        case .addToCloudMusicLibrary:
            return "Add To Cloud Music Library"
        case .musicCatalogPlayback:
            return "Music Catalog Playback"
        case .musicCatalogSubscriptionEligible:
            return "Music Catalog Subscription Eligible"
        default:
            return ""
        }
    }
}
