/*
See LICENSE folder for this sample’s licensing information.

Abstract:
MediaSearchTableViewCell` is a `UITableViewCell` subclass that represents an `MediaItem` in the search results from the
            Apple Music Catalog in the `MediaSearchTableViewController`.
*/

import UIKit

class MediaItemTableViewCell: UITableViewCell {

    // MARK: Types
    
    static let identifier = "MediaItemTableViewCell"
    
    // MARK: Properties
    
    /// The `UIImageView` for displaying the artwork of the currently playing `MediaItem`.
    @IBOutlet weak var assetCoverArtImageView: UIImageView!
    
    /// The 'UILabel` for displaying the title of `MediaItem`.
    @IBOutlet weak var mediaItemTitleLabel: UILabel!
    
    /// The 'UILabel` for displaying the artist of `MediaItem`.
    @IBOutlet weak var mediaItemArtistLabel: UILabel!
    
    /// The 'UIButton` for adding the `MediaItem` to the application's `MPMediaPlaylist`.
    @IBOutlet weak var addToPlaylistButton: UIButton!
    
    /// The 'UIButton` for playing the `MediaItem`.
    @IBOutlet weak var playItemButton: UIButton!
    
    /// The `MediaSearchTableViewCellDelegate` that will respond to user interaction events from the `MediaSearchTableViewCell`.
    weak var delegate: MediaSearchTableViewCellDelegate?
    
    var mediaItem: MediaItem? {
        didSet {
            mediaItemTitleLabel.text = mediaItem?.name ?? ""
            mediaItemArtistLabel.text = mediaItem?.artistName ?? ""
            assetCoverArtImageView.image = nil
        }
    }
    
    // MARK: Target-Action Methods
    
    @IBAction func addToPlaylist(_ sender: UIButton) {
        if let mediaItem = mediaItem {
            delegate?.mediaSearchTableViewCell(self, addToPlaylist: mediaItem)
        }
    }
    
}

protocol MediaSearchTableViewCellDelegate: class {
    func mediaSearchTableViewCell(_ mediaSearchTableViewCell: MediaItemTableViewCell, addToPlaylist mediaItem: MediaItem)

}
