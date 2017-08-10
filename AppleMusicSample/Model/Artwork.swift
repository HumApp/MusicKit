/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`Artwork` represents a `Artwork` object from the Apple Music Web Services.
*/

import UIKit

class Artwork {
    
    // MARK: Types
    
    /// The various keys needed for serializing an instance of `Artwork` using a JSON response from the Apple Music Web Service.
    struct JSONKeys {
        static let height = "height"
        
        static let width = "width"
        
        static let url = "url"
    }
    
    // MARK: Properties
    
    /// The maximum height available for the image.
    let height: Int
    
    /// The maximum width available for the image.
    let width: Int
    
    /**
     The string representation of the URL to request the image asset. This template should be used to create the URL for the correctly sized image
     your application wishes to use.  See `Artwork.imageURL(size:)` for additional information.
     */
    let urlTemplateString: String
    
    // MARK: Initialization
    
    init(json: [String: Any]) throws {
        guard let height = json[JSONKeys.height] as? Int else {
            throw SerializationError.missing(JSONKeys.height)
        }
        
        guard let width = json[JSONKeys.width] as? Int else {
            throw SerializationError.missing(JSONKeys.width)
        }
        
        guard let urlTemplateString = json[JSONKeys.url] as? String else {
            throw SerializationError.missing(JSONKeys.url)
        }
        
        self.height = height
        self.width = width
        self.urlTemplateString = urlTemplateString
    }
    
    // MARK: Image URL Generation Method
    
    func imageURL(size: CGSize) -> URL {
        
        /*
         There are three pieces of information needed to create the URL for the image we want for a given size.  This information is the width, height
         and image format.  We can use this information in addition to the `urlTemplateString` to create the URL for the image we wish to use.
         */
        
        // 1) Replace the "{w}" placeholder with the desired width as an integer value.
        var imageURLString = urlTemplateString.replacingOccurrences(of: "{w}", with: "\(Int(size.width))")
        
        // 2) Replace the "{h}" placeholder with the desired height as an integer value.
        imageURLString = imageURLString.replacingOccurrences(of: "{h}", with: "\(Int(size.width))")
        
        // 3) Replace the "{f}" placeholder with the desired image format.
        imageURLString = imageURLString.replacingOccurrences(of: "{f}", with: "png")
        
        return URL(string: imageURLString)!
    }
}
