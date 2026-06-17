//
//  BackendYouTubeAudioService.swift
//  pzathy_tool
//
//  Client for *your own* conversion backend — the y2mate-style approach.
//
//  This is the piece that talks to a server you control (running yt-dlp + ffmpeg)
//  which extracts a YouTube link and returns a real, transcoded MP3. The app only
//  needs the resulting metadata + MP3 URL; all the heavy/legally-sensitive work
//  happens server-side, exactly like the online downloaders.
//
//  Nothing here breaks the app before you have a server: when no backend URL is
//  configured, `MusicConverterViewModel` keeps using the existing Piped service.
//  The moment you set `BackendConfig.baseURL` (in code or via Info.plist), this
//  client takes over and falls back to Piped only if the backend call fails.
//
//  ──────────────────────────────────────────────────────────────────────────
//  API CONTRACT (implement this on your server — see BACKEND_API.md for details)
//
//    POST  {baseURL}/api/convert
//    Headers:
//      Content-Type: application/json
//      Authorization: Bearer <apiKey>        (optional; sent only if configured)
//    Body:
//      { "url": "<youtube url>", "format": "mp3", "bitrate": 320 }
//
//    200 OK:
//      {
//        "id": "dQw4w9WgXcQ",
//        "title": "Song title",
//        "artist": "Channel / uploader",
//        "description": "optional",
//        "durationSeconds": 213,
//        "thumbnailUrl": "https://.../hq.jpg",   (optional)
//        "audioUrl": "https://.../files/<id>.mp3", (REQUIRED — a real mp3)
//        "mimeType": "audio/mpeg",                (optional)
//        "bitrate": 320                            (optional)
//      }
//
//    Errors (any non-2xx):
//      { "error": "human readable message", "code": "INVALID_URL" }
//  ──────────────────────────────────────────────────────────────────────────
//

import Foundation

// MARK: - Configuration

/// Central place to point the app at your conversion backend.
///
/// Set `baseURL` here, or ship it via Info.plist keys so you don't touch code:
///   • `YTBackendBaseURL`  → e.g. https://api.yourdomain.com
///   • `YTBackendAPIKey`   → optional bearer token
enum BackendConfig {

    /// Hard-coded default. Leave empty to keep the current (Piped) behavior.
    /// Example: "https://api.yourdomain.com"
    static let defaultBaseURL = ""

    /// Resolved base URL: Info.plist override wins, else the hard-coded default.
    static var baseURL: String {
        if let fromPlist = Bundle.main.object(forInfoDictionaryKey: "YTBackendBaseURL") as? String,
           !fromPlist.trimmingCharacters(in: .whitespaces).isEmpty {
            return fromPlist
        }
        return defaultBaseURL
    }

    /// Optional bearer token for the backend.
    static var apiKey: String? {
        (Bundle.main.object(forInfoDictionaryKey: "YTBackendAPIKey") as? String)
            .flatMap { $0.trimmingCharacters(in: .whitespaces).isEmpty ? nil : $0 }
    }

    /// Whether a usable backend is configured.
    static var isConfigured: Bool {
        URL(string: baseURL.trimmingCharacters(in: .whitespaces)).map { $0.scheme != nil } ?? false
    }

    /// Preferred output. 0 = let the server decide.
    static let mp3Bitrate = 320
}

// MARK: - DTOs

private struct ConvertRequest: Encodable {
    let url: String
    let format: String
    let bitrate: Int
}

private struct ConvertResponse: Decodable {
    let id: String?
    let title: String?
    let artist: String?
    let description: String?
    let durationSeconds: Double?
    let thumbnailUrl: String?
    let audioUrl: String
    let mimeType: String?
    let bitrate: Int?
}

private struct BackendError: Decodable {
    let error: String?
    let code: String?
}

// MARK: - Service

final class BackendYouTubeAudioService: YouTubeAudioService {

    private let baseURL: String
    private let apiKey: String?
    private let bitrate: Int
    /// Used so conversion still works if the backend is unreachable.
    private let fallback: YouTubeAudioService?
    private let session: URLSession

    init(baseURL: String = BackendConfig.baseURL,
         apiKey: String? = BackendConfig.apiKey,
         bitrate: Int = BackendConfig.mp3Bitrate,
         fallback: YouTubeAudioService? = PipedYouTubeAudioService(),
         session: URLSession = .shared) {
        self.baseURL = baseURL.trimmingCharacters(in: .whitespaces)
        self.apiKey = apiKey
        self.bitrate = bitrate
        self.fallback = fallback
        self.session = session
    }

    func resolve(link: String) async throws -> Track {
        // Validate the link client-side so we don't waste a backend round-trip.
        guard let videoID = YouTubeLink.videoID(from: link) else {
            throw YouTubeServiceError.invalidURL
        }

        do {
            return try await convert(link: link, videoID: videoID)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            // Backend down/misconfigured — keep the app usable if we can.
            if let fallback = fallback {
                return try await fallback.resolve(link: link)
            }
            throw error
        }
    }

    private func convert(link: String, videoID: String) async throws -> Track {
        guard let endpoint = URL(string: "\(baseURL)/api/convert") else {
            throw YouTubeServiceError.invalidURL
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 120 // extraction + transcode can take a while
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let apiKey = apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        let body = ConvertRequest(
            url: link.trimmingCharacters(in: .whitespacesAndNewlines),
            format: "mp3",
            bitrate: bitrate
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw YouTubeServiceError.extractionFailed
        }
        guard (200..<300).contains(http.statusCode) else {
            // Surface the server's message if it sent one.
            if let err = try? JSONDecoder().decode(BackendError.self, from: data),
               let message = err.error {
                throw NSError(domain: "BackendYouTubeAudioService",
                              code: http.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: message])
            }
            throw YouTubeServiceError.extractionFailed
        }

        let payload = try JSONDecoder().decode(ConvertResponse.self, from: data)
        guard let audioURL = URL(string: payload.audioUrl) else {
            throw YouTubeServiceError.extractionFailed
        }

        let id = payload.id?.isEmpty == false ? payload.id! : videoID
        let title = payload.title?.isEmpty == false ? payload.title! : "YouTube audio"
        let artist = payload.artist?.isEmpty == false ? payload.artist! : "Unknown artist"

        return Track(
            id: id,
            title: title,
            artist: artist,
            details: payload.description?.isEmpty == false
                ? payload.description!
                : "Converted from YouTube • \(id)",
            thumbnailURL: URL(string: payload.thumbnailUrl ?? "")
                ?? URL(string: "https://img.youtube.com/vi/\(id)/hqdefault.jpg"),
            sourceURL: URL(string: link.trimmingCharacters(in: .whitespacesAndNewlines)),
            streamURL: audioURL,
            duration: payload.durationSeconds ?? 0,
            downloadedFileName: nil
        )
    }
}
