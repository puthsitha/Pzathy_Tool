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
    /// Build share items: downloaded files when available, else the source links.
    static func items(for tracks: [Track]) -> [Any] {
        var result: [Any] = []
        for track in tracks {
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
