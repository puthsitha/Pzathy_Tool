//
//  Playlist.swift
//  pzathy_tool
//
//  A playlist == an album of converted tracks (by track id).
//

import Foundation

struct Playlist: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var name: String
    var trackIDs: [String]
    var createdAt: Date
    /// File name (in FileStorage.playlistImagesDirectory) of a user-picked cover
    /// image. When nil the UI falls back to the first track's thumbnail.
    var imageFileName: String?

    init(id: String = UUID().uuidString, name: String, trackIDs: [String] = [],
         createdAt: Date = Date(), imageFileName: String? = nil) {
        self.id = id
        self.name = name
        self.trackIDs = trackIDs
        self.createdAt = createdAt
        self.imageFileName = imageFileName
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, trackIDs, createdAt, imageFileName
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        trackIDs = try c.decode([String].self, forKey: .trackIDs)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        // Optional so playlists saved before cover images decode cleanly.
        imageFileName = try c.decodeIfPresent(String.self, forKey: .imageFileName)
    }
}
