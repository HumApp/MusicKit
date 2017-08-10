# Adding Content to Apple Music

Demonstrates how to add content from the Apple Music catalog to the iCloud Music Library.

## Overview

This sample shows how to use the MediaPlayer and StoreKit frameworks as well as the Apple Music Web Service to do the following:

* Request access to the iOS device's Media and Apple Music.
* Present the Apple Music subscriber setup flow if the currently signed in iTunes Store account is elgible.
* Search the Apple Music catalog for songs and albums using the Apple Music Web Service.
* Create a new [`MPMediaPlaylist`](https://developer.apple.com/documentation/mediaplayer/mpmediaplaylist) locally or in the user's iCloud Music Library and add items to it.
* Playback items from the Apple Music catalog or play the [`MPMediaPlaylist`](https://developer.apple.com/documentation/mediaplayer/mpmediaplaylist) created by the application.

## Getting Started

You use a developer token to authenticate yourself as a trusted developer and member of the Apple Developer Program. A developer token is required in the header of every Apple Music API request. To create a developer token, first create a MusicKit signing key in your developer account, create a JSON Web Token (JWT) in the format Apple expects, and then sign it with the MusicKit signing key.  For more information about this process and how to create a developer token please see the following documentation:

* [Apple Music API Reference - Get Keys and Create Tokens](https://developer.apple.com/go/?id=apple-music-keys-and-tokens).

Once you have a developer token, you need to update the `AppleMusicManager.fetchDeveloperToken()` method in `AppleMusicManager.swift` to retrieve your valid developer token.

``` swift
func fetchDeveloperToken() -> String? {
    
    // MARK: ADAPT: YOU MUST IMPLEMENT THIS METHOD
    let developerAuthenticationToken: String? = nil
    return developerAuthenticationToken
}
```

Keep in mind, you should not hardcode the value of the developer token in your application.  This is so that if you need to generate a new developer token you are able to without having to submit a new version of your application to the App Store.

## Requesting Authorization

Before interacting with these APIs your application needs to request authorization from the user to interact with the device media library and with Apple Music.  

There are two different authorizations that iOS applications can request. Depending on your application's usecase, you may only need to request one of the above or request both of them.

### Media Library Authorization

If your application wants to access the items in the user's media library then you should request authorization using the [`MPMediaLibrary`](https://developer.apple.com/documentation/mediaplayer/mpmedialibrary) APIs.

To query your application's current [`MPMediaLibraryAuthorizationStatus`](https://developer.apple.com/documentation/mediaplayer/mpmedialibraryauthorizationstatus), you can call [`MPMediaLibrary.authorizationStatus()`](https://developer.apple.com/documentation/mediaplayer/mpmedialibrary/1621282-authorizationstatus).

``` swift
guard MPMediaLibrary.authorizationStatus() == .notDetermined else { return }
```

If the authorization status is `.notDetermined` then your application should request authorization by calling [`MPMediaLibrary.requestAuthorization(_:)`](https://developer.apple.com/documentation/mediaplayer/mpmedialibrary/1621276-requestauthorization).

``` swift
MPMediaLibrary.requestAuthorization { (_) in
    NotificationCenter.default.post(name: AuthorizationManager.cloudServiceDidUpdateNotification, object: nil)
}
```

### Cloud Service Authorization

 If your application wants to be able to playback items from the Apple Music catalog or add items to the user's iCloud Music Library then you should request authorization using the `SKCloudServiceController` APIs.

 To query your application's current [`SKCloudServiceAuthorizationStatus`](https://developer.apple.com/documentation/storekit/skcloudserviceauthorizationstatus), you can call [`SKCloudServiceController.authorizationStatus()`](https://developer.apple.com/documentation/storekit/skcloudservicecontroller/1620631-authorizationstatus).

``` swift
guard SKCloudServiceController.authorizationStatus() == .notDetermined else { return }
```

If the authorization status is `.notDetermined` then your application should request authorization by calling [`SKCloudServiceController.requestAuthorization(_:)`](https://developer.apple.com/documentation/storekit/skcloudservicecontroller/1620609-requestauthorization).

``` swift
SKCloudServiceController.requestAuthorization { [weak self] (authorizationStatus) in
    switch authorizationStatus {
    case .authorized:
        self?.requestCloudServiceCapabilities()
        self?.requestUserToken()
    default:
        break
    }
    
    NotificationCenter.default.post(name: AuthorizationManager.authorizationDidUpdateNotification, object: nil)
}
```

Once your application has the `.authorized` status, you can query the the device for more information about the capabilities associated with the device.  These capabilities are represented as [`SKCloudServiceCapability`](https://developer.apple.com/documentation/storekit/skcloudservicecapability) and can be queried by calling [`requestCapabilities(completionHandler:)`](https://developer.apple.com/documentation/storekit/skcloudservicecontroller/1620610-requestcapabilities) on an instance of [`SKCloudServiceController`](https://developer.apple.com/documentation/storekit/skcloudservicecontroller).

```swift
let controller = SKCloudServiceController()
controller.requestCapabilities(completionHandler: { (cloudServiceCapability, error) in
    guard error == nil else {
        // Handle Error accordingly, see SKError.h for error codes.
    }

    if cloudServiceCapabilities.contains(.addToCloudMusicLibrary) {
        // The application can add items to the iCloud Music Library.
    }

    if cloudServiceCapabilities.contains(.musicCatalogPlayback) {
        // The application can playback items from the Apple Music catalog.
    }

    if cloudServiceCapabilities.contains(.musicCatalogSubscriptionEligible) {
        // The iTunes Store account is currently elgible for and Apple Music Subscription trial.
    }
})
```

## Requesting a Music User Token

If your application makes calls to the Apple Music API for personalized requests that return user-specific data, your request will need to include a music user token.  To create a music user token you first need to have a valid developer token as discussed above in the "Getting Started" section.

Once you have a developer token,  you can use the native APIs availalbe on the `SKCloudServiceController` class as demonstrated below:

```swift
let completionHandler: (String?, Error?) -> Void = { [weak self] (token, error) in
    guard error == nil else {
        // Handle Error accordingly, see SKError.h for error codes.
    }

    guard let token = token else {
        print("Unexpected value from SKCloudServiceController for user token.")
        return
    }
    
    self?.userToken = token
}

if #available(iOS 11.0, *) {
    cloudServiceController.requestUserToken(forDeveloperToken: developerToken, completionHandler: completionHandler)
} else {
    cloudServiceController.requestPersonalizationToken(forClientToken: developerToken, withCompletionHandler: completionHandler)
}
```

Once you have a valid music user token, your application should cache it for future use in personalized requests for the Apple Music API.  For additional information about how the music user token is used in making requests, please see the following documentation:

* [Apple Music API Reference - Authenticate Requests](https://developer.apple.com/library/content/documentation/NetworkingInternetWeb/Conceptual/AppleMusicWebServicesReference/SetUpWebServices.html#//apple_ref/doc/uid/TP40017625-CH2-SW7).

## Creating and Adding Items to a Media Playlist

After your application is authorized to access the iCloud Music Library, you can use the `MPMediaLibrary` APIs to create or retrieve an existing [`MPMediaPlaylist`](https://developer.apple.com/documentation/mediaplayer/mpmediaplaylist).

To create or retrieve an [`MPMediaPlaylist`](https://developer.apple.com/documentation/mediaplayer/mpmediaplaylist), use the [`MPMediaLibrary.getPlaylist(with:creationMetadata:completionHandler:)`](https://developer.apple.com/documentation/mediaplayer/mpmedialibrary/1621273-getplaylist) as demonstrated below:

```swift
/*
Create an instance of `UUID` to identify the new playlist.  If you wish to be able to retrieve this playlist in the future, 
save this UUID in your application for future use.
*/
let playlistUUID = UUID()

// Create an instance of `MPMediaPlaylistCreationMetadata`, this represents the metadata to associate with the new playlist.
var playlistCreationMetadata = MPMediaPlaylistCreationMetadata(name: "My Playlist")
playlistCreationMetadata.descriptionText = "This playlist contains awesome items."

// Request the new or existing playlist from the device.
MPMediaLibrary.default().getPlaylist(with: playlistUUID, creationMetadata: playlistCreationMetadata) { (playlist, error) in
    guard error == nil else {
        // Handle Error accordingly, see MPError.h for error codes.
    }
    
    self.mediaPlaylist = playlist
}
```

Once you have an instance of [`MPMediaPlaylist`](https://developer.apple.com/documentation/mediaplayer/mpmediaplaylist), you can then add items to the playlist using the [`MPMediaPlaylist.addItem(withProductID:completionHandler:)`](https://developer.apple.com/documentation/mediaplayer/mpmediaplaylist/1618706-additem) API.

``` swift
mediaPlaylist.addItem(withProductID: identifier, completionHandler: { (error) in
    guard error == nil else {
        fatalError("An error occurred while adding an item to the playlist: \(error!.localizedDescription)")
    }
    
    NotificationCenter.default.post(name: MediaLibraryManager.libraryDidUpdate, object: nil)
})
```

## Playing Items from the Apple Music catalog

After your application is authorized and has the `SKCloudServiceCapability.musicCatalogPlayback` capability, you can play one or more items from the Apple Music catalog or the iCloud Music Library using the `MPMusicPlayerController` APIs.

If you have items from the Apple Music API that you wish to play, you can use the [`MPMusicPlayerController.setQueueWithStoreIDs(_:)`](https://developer.apple.com/documentation/mediaplayer/mpmusicplayercontroller/1624253-setqueuewithstoreids) API and pass in an array of strings that represent the id of the resource from the Apple Music API.

``` swift
musicPlayerController.setQueue(with: [itemID])
        
musicPlayerController.play()
```

If you have an [`MPMediaPlaylist`](https://developer.apple.com/documentation/mediaplayer/mpmediaplaylist) or `MPMediaItemCollection` that you wish to play, you can use the [`MPMusicPlayerController.setQueue(with:)`](https://developer.apple.com/documentation/mediaplayer/mpmusicplayercontroller/1624171-setqueue) API.

``` swift
musicPlayerController.setQueue(with: itemCollection)
        
musicPlayerController.play()
```
