/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Various JSON keys needed when making calls to the Apple Music API.
*/

import Foundation

/// Keys related to the `Response Root` JSON object in the Apple Music API.
struct ResponseRootJSONKeys {
    static let data = "data"
    
    static let results = "results"
}

/// Keys related to the `Resource` JSON object in the Apple Music API.
struct ResourceJSONKeys {
    static let identifier = "id"
    
    static let attributes = "attributes"
    
    static let type = "type"
}

/// The various keys needed for parsing a JSON response from the Apple Music Web Service.
struct ResourceTypeJSONKeys {
    static let songs = "songs"
    
    static let albums = "albums"
}
