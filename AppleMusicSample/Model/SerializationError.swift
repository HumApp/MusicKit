/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`SerializationError` is an `Error` enum that represents a JSON serialization error.
*/

import Foundation

enum SerializationError: Error {
    
    /// This case indicates that the expected field in the JSON object is not found.
    case missing(String)
}
