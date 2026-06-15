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

    init(id: String = UUID().uuidString, name: String, trackIDs: [String] = [], createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.trackIDs = trackIDs
        self.createdAt = createdAt
    }
}
