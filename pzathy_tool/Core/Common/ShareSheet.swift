//
//  ShareSheet.swift
//  pzathy_tool
//
//  UIActivityViewController wrapper. Supports multi-item / multi-file sharing.
//

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

/// What a user chose to share for a set of tracks.
enum ShareContent {
    /// Shares *only* the MP3 file(s). Each file embeds the song info — thumbnail
    /// (cover art), title, artist and year — as ID3v2 metadata, so no separate text
    /// or image items are included.
    static func asyncItems(for tracks: [Track]) async -> [Any] {
        var result: [Any] = []
        for track in tracks {
            if let file = await mp3File(for: track) {
                result.append(file)
            }
        }
        return result
    }

    /// Produces a tagged MP3 file URL for a single track, or `nil` if the audio
    /// could not be obtained.
    private static func mp3File(for track: Track) async -> URL? {
        // 1. Raw MP3 bytes: the downloaded file when present, else fetch the stream.
        let mp3Data: Data
        if let local = track.localFileURL,
           FileManager.default.fileExists(atPath: local.path),
           let data = try? Data(contentsOf: local) {
            mp3Data = data
        } else if let data = try? await URLSession.shared.data(from: track.playbackURL).0 {
            mp3Data = data
        } else {
            return nil
        }

        // 2. Cover art (best-effort; the file is still shared without it).
        var coverJPEG: Data?
        if let url = track.thumbnailURL,
           let (data, _) = try? await URLSession.shared.data(from: url),
           let image = UIImage(data: data) {
            coverJPEG = image.jpegData(compressionQuality: 0.9)
        }

        // 3. Year: explicit metadata when known, otherwise the year it was added.
        let year = track.year.map(String.init)
            ?? String(Calendar.current.component(.year, from: track.addedAt))

        // 4. Embed metadata and write a temp .mp3 with a friendly filename.
        return try? MP3Metadata.taggedFile(
            mp3Data: mp3Data,
            title: track.title,
            artist: track.artist,
            year: year,
            coverJPEG: coverJPEG,
            fileName: shareFileName(for: track)
        )
    }

    /// A filesystem-safe "Title - Artist.mp3" name for the shared file.
    private static func shareFileName(for track: Track) -> String {
        var base = track.title
        if !track.artist.isEmpty { base += " - \(track.artist)" }
        let invalid = CharacterSet(charactersIn: "/\\:*?\"<>|")
        let safe = base.components(separatedBy: invalid).joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(safe.isEmpty ? track.id : safe).mp3"
    }
}
