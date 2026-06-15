//
//  YouTubeAudioService.swift
//  pzathy_tool
//
//  Abstraction over "turn a YouTube link into a playable/downloadable audio track".
//
//  ⚠️ IMPORTANT (read before shipping):
//  Real YouTube → MP3 extraction CANNOT be done reliably on-device, and doing it
//  directly violates YouTube's Terms of Service and Apple's App Store rules.
//  Production apps perform extraction on a backend you control (e.g. a service
//  wrapping yt-dlp) and return a signed audio URL + metadata.
//
//  This protocol is that seam. Today we ship `MockYouTubeAudioService`, which
//  returns real, royalty-free audio so the whole app (player, downloads,
//  playlists, sharing) works end-to-end. Implement `YouTubeAudioService` against
//  your backend later and swap it in `MusicConverterViewModel` — nothing else
//  changes.
//

import Foundation

enum YouTubeServiceError: LocalizedError {
    case invalidURL
    case extractionFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:       return "Invalid YouTube URL."
        case .extractionFailed: return "Could not extract audio from this link."
        }
    }
}

protocol YouTubeAudioService {
    /// Validate + fetch metadata and a playable audio URL for a YouTube link.
    func resolve(link: String) async throws -> Track
}

// MARK: - Link validation helper

enum YouTubeLink {
    /// Returns the 11-char video id from common YouTube URL shapes, or nil.
    static func videoID(from link: String) -> String? {
        let trimmed = link.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let components = URLComponents(string: trimmed),
              let host = components.host?.lowercased() else { return nil }

        if host.contains("youtu.be") {
            let id = components.path.replacingOccurrences(of: "/", with: "")
            return id.count >= 6 ? id : nil
        }
        if host.contains("youtube.com") {
            if let v = components.queryItems?.first(where: { $0.name == "v" })?.value {
                return v
            }
            // /shorts/<id> or /embed/<id>
            let parts = components.path.split(separator: "/")
            if parts.count >= 2, parts[0] == "shorts" || parts[0] == "embed" {
                return String(parts[1])
            }
        }
        return nil
    }

    static func isValid(_ link: String) -> Bool { videoID(from: link) != nil }
}

// MARK: - Mock implementation (default, works offline of any backend)

final class MockYouTubeAudioService: YouTubeAudioService {

    // Royalty-free streams (SoundHelix) used so playback genuinely works in the demo.
    private static let samples: [(title: String, artist: String, duration: TimeInterval, stream: String)] = [
        ("The Neverwritten Role", "MusiQue",      372, "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"),
        ("Midnight Drive",        "Aria Wells",    426, "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3"),
        ("Golden Hour",           "Leo Hart",      349, "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3"),
        ("Paper Boats",           "Niko & The Sea", 295, "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3"),
        ("Echoes of You",         "Mira Solène",   401, "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3"),
        ("City Lights",           "The Foxgloves", 318, "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3")
    ]

    func resolve(link: String) async throws -> Track {
        guard let videoID = YouTubeLink.videoID(from: link) else {
            throw YouTubeServiceError.invalidURL
        }

        // Simulate network/extraction latency.
        try? await Task.sleep(nanoseconds: 1_200_000_000)

        // Pick a deterministic sample based on the video id so the same link is stable.
        let index = abs(videoID.hashValue) % Self.samples.count
        let sample = Self.samples[index]

        guard let stream = URL(string: sample.stream) else {
            throw YouTubeServiceError.extractionFailed
        }

        return Track(
            id: videoID,
            title: sample.title,
            artist: sample.artist,
            details: "Converted from YouTube • \(videoID)",
            thumbnailURL: URL(string: "https://img.youtube.com/vi/\(videoID)/hqdefault.jpg"),
            sourceURL: URL(string: link.trimmingCharacters(in: .whitespacesAndNewlines)),
            streamURL: stream,
            duration: sample.duration,
            downloadedFileName: nil
        )
    }
}
