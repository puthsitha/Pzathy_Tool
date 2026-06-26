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
    /// Async version: downloads thumbnails and builds rich share items
    /// (title + description text, thumbnail image, then the audio file or link).
    static func asyncItems(for tracks: [Track]) async -> [Any] {
        var result: [Any] = []
        for track in tracks {
            // 1. Title + description text
            var text = track.title
            if !track.artist.isEmpty { text += " – \(track.artist)" }
            if !track.details.isEmpty { text += "\n\(track.details)" }
            result.append(text)

            // 2. Thumbnail image (best-effort, skipped if unavailable)
            if let url = track.thumbnailURL,
               let (data, _) = try? await URLSession.shared.data(from: url),
               let image = UIImage(data: data) {
                result.append(image)
            }

            // 3. Audio: local file when downloaded, source link, or stream URL
            if let local = track.localFileURL,
               FileManager.default.fileExists(atPath: local.path) {
                result.append(local)
            } else if let source = track.sourceURL {
                result.append(source)
            } else {
                result.append(track.streamURL)
            }
        }
        return result
    }
}
