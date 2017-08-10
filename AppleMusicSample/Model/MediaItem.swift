/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`MediaItem` represents a `Resource` object from the Apple Music Web Services.
*/

import Foundation

class MediaItem {
    
    // MARK: Types
    
    /// The type of resource.
    ///
    /// - songs: This indicates that the `MediaItem` is a song from the Apple Music Catalog.
    /// - albums: This indicates that the `MediaItem` is an album from the Apple Music Catalog.
    enum MediaType: String {
        case songs, albums, stations, playlists
    }
    
    /// The various keys needed for serializing an instance of `MediaItem` using a JSON response from the Apple Music Web Service.
    struct JSONKeys {
        static let identifier = "id"
        
        static let type = "type"
        
        static let attributes = "attributes"
        
        static let name = "name"
        
        static let artistName = "artistName"
        
        static let artwork = "artwork"
    }
    
    // MARK: Properties
    
    /// The persistent identifier of the resource which is used to add the item to the playlist or trigger playback.
    let identifier: String
    
    /// The localized name of the album or song.
    let name: String
    
    /// The artist’s name.
    let artistName: String
    
    /// The album artwork associated with the song or album.
    let artwork: Artwork
    
    /// The type of the `MediaItem` which in this application can be either `songs` or `albums`.
    let type: MediaType
    
    // MARK: Initialization
    
    init(json: [String: Any]) throws {
        guard let identifier = json[JSONKeys.identifier] as? String else {
            throw SerializationError.missing(JSONKeys.identifier)
        }
        
        guard let typeString = json[JSONKeys.type] as? String, let type = MediaType(rawValue: typeString) else {
            throw SerializationError.missing(JSONKeys.type)
        }
        
        guard let attributes = json[JSONKeys.attributes] as? [String: Any] else {
            throw SerializationError.missing(JSONKeys.attributes)
        }
        
        guard let name = attributes[JSONKeys.name] as? String else {
            throw SerializationError.missing(JSONKeys.name)
        }
        
        let artistName = attributes[JSONKeys.artistName] as? String ?? " "
        
        guard let artworkJSON = attributes[JSONKeys.artwork] as? [String: Any], let artwork = try? Artwork(json: artworkJSON) else {
            throw SerializationError.missing(JSONKeys.artwork)
        }
        
        self.identifier = identifier
        self.type = type
        self.name = name
        self.artistName = artistName
        self.artwork = artwork
    }
}
