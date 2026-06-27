//
//  Track.swift
//  pzathy_tool
//
//  A converted audio item plus the YouTube-sourced metadata.
//

import Foundation

struct Track: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var title: String
    var artist: String
    var details: String          // description from the source
    var thumbnailURL: URL?
    var sourceURL: URL?          // original YouTube link
    var streamURL: URL           // playable audio URL (remote or extracted)
    var duration: TimeInterval   // seconds (0 if unknown)
    var year: Int? = nil         // release/publish year, when known

    /// Relative path (inside Documents) of the downloaded file, if any.
    var downloadedFileName: String?
    var addedAt: Date = Date()

    var isDownloaded: Bool { downloadedFileName != nil }

    /// Local file URL resolved against the current Documents directory.
    var localFileURL: URL? {
        guard let name = downloadedFileName else { return nil }
        return FileStorage.documentsDirectory.appendingPathComponent(name)
    }

    /// The URL the player should use: the local file when available, else the stream.
    var playbackURL: URL {
        if let local = localFileURL, FileManager.default.fileExists(atPath: local.path) {
            return local
        }
        return streamURL
    }
}
