//
//  YouTubeAudioService.swift
//  pzathy_tool
//
//  Abstraction over "turn a YouTube link into a playable/downloadable audio track".
//
//  • `PipedYouTubeAudioService` — talks to the open-source, free (rate-limited)
//    Piped API (https://github.com/TeamPiped/Piped). Piped runs yt-dlp-style
//    extraction on public instances and returns real metadata plus direct,
//    proxied audio stream URLs that AVPlayer can play. No API key needed.
//
//  When extraction fails (every instance down, no fallback configured) the call
//  throws so the UI can surface a real error instead of a placeholder track.
//
//  ⚠️ Note: public Piped instances are community-run and rate-limited. For a
//  production launch, host your own Piped/Invidious/yt-dlp backend and point
//  `PipedYouTubeAudioService.instances` at it.
//

import Foundation

enum YouTubeServiceError: LocalizedError {
    case invalidURL
    case extractionFailed
    case offline

    var errorDescription: String? {
        switch self {
        case .invalidURL:       return "Invalid YouTube URL."
        case .extractionFailed: return "Could not extract audio from this link."
        case .offline:          return "No internet connection."
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

// MARK: - Piped DTOs (only the fields we use)

private struct PipedStreams: Decodable {
    let title: String?
    let uploader: String?
    let description: String?
    let duration: Int?
    let thumbnailUrl: String?
    let audioStreams: [PipedAudioStream]?
}

private struct PipedAudioStream: Decodable {
    let url: String
    let mimeType: String?
    let codec: String?
    let bitrate: Int?
}

// MARK: - Real implementation (open-source Piped API)

final class PipedYouTubeAudioService: YouTubeAudioService {

    /// Public Piped API instances, tried in order. Swap for your own backend in prod.
    private let instances: [String]
    /// Optional secondary extractor if every instance fails. When `nil`, a failure
    /// surfaces as an error instead of silently returning a placeholder track.
    private let fallback: YouTubeAudioService?

    init(instances: [String] = [
            "https://pipedapi.kavin.rocks",
            "https://pipedapi.adminforge.de",
            "https://api.piped.private.coffee"
         ],
         fallback: YouTubeAudioService? = nil) {
        self.instances = instances
        self.fallback = fallback
    }

    func resolve(link: String) async throws -> Track {
        guard let videoID = YouTubeLink.videoID(from: link) else {
            throw YouTubeServiceError.invalidURL
        }

        // Try each instance until one returns a usable audio stream.
        for base in instances {
            guard let url = URL(string: "\(base)/streams/\(videoID)") else { continue }
            do {
                if let track = try await fetchTrack(from: url, videoID: videoID, link: link) {
                    return track
                }
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                continue // network/decoding hiccup — try the next instance
            }
        }

        // Every instance failed. Use the fallback extractor if one was provided,
        // otherwise surface the failure so the UI can show an error.
        if let fallback = fallback {
            return try await fallback.resolve(link: link)
        }
        throw YouTubeServiceError.extractionFailed
    }

    private func fetchTrack(from url: URL, videoID: String, link: String) async throws -> Track? {
        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.loggedData(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            return nil
        }

        let payload = try JSONDecoder().decode(PipedStreams.self, from: data)
        guard let stream = bestAudioStream(payload.audioStreams),
              let streamURL = URL(string: stream.url) else {
            return nil
        }

        let duration = TimeInterval(payload.duration ?? 0)
        let title = payload.title?.isEmpty == false ? payload.title! : "YouTube audio"
        let artist = payload.uploader?.isEmpty == false ? payload.uploader! : "Unknown artist"

        return Track(
            id: videoID,
            title: title,
            artist: artist,
            details: "Converted from YouTube • \(videoID)",
            thumbnailURL: URL(string: payload.thumbnailUrl ?? "")
                ?? URL(string: "https://img.youtube.com/vi/\(videoID)/hqdefault.jpg"),
            sourceURL: URL(string: link.trimmingCharacters(in: .whitespacesAndNewlines)),
            streamURL: streamURL,
            duration: duration,
            downloadedFileName: nil
        )
    }

    /// Pick the best AVPlayer-compatible audio stream: prefer MP4/M4A/AAC
    /// containers (AVPlayer can't decode WebM/Opus), then highest bitrate.
    private func bestAudioStream(_ streams: [PipedAudioStream]?) -> PipedAudioStream? {
        guard let streams = streams, !streams.isEmpty else { return nil }

        func isCompatible(_ s: PipedAudioStream) -> Bool {
            let mime = (s.mimeType ?? "").lowercased()
            let codec = (s.codec ?? "").lowercased()
            return mime.contains("mp4") || mime.contains("m4a")
                || codec.contains("mp4a") || codec.contains("aac")
        }

        let compatible = streams.filter(isCompatible)
        let pool = compatible.isEmpty ? streams : compatible
        return pool.max { ($0.bitrate ?? 0) < ($1.bitrate ?? 0) }
    }
}
