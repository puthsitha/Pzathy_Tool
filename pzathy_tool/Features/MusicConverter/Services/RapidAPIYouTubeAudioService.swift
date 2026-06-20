//
//  RapidAPIYouTubeAudioService.swift
//  pzathy_tool
//
//  YouTube → MP3 via the RapidAPI "youtube-mp3-audio-video-downloader" endpoint.
//
//  Flow:
//    1. Extract the 11-char video id from the pasted link (YouTubeLink.videoID).
//    2. GET /get_mp3_download_link/{videoID}?quality=...&wait_until_the_file_is_ready=...
//       → returns { file, reserved_file, comment }.
//    3. The returned file 404s until the server finishes encoding (20–300 s).
//       We verify reachability (HEAD) and, if not ready, poll `file` then
//       `reserved_file` until one responds, so the Track we hand back actually
//       plays/downloads instead of 404-ing in AVPlayer.
//    4. Title/artist/thumbnail come from YouTube's free oEmbed endpoint (no key).
//
//  The RapidAPI key is read from the environment / Info.plist (see RapidAPIConfig)
//  — never hard-coded — so it stays out of source control.
//
//  Falls back to the Piped extractor if the key is missing or the call fails, so
//  conversion still yields something playable.
//

import Foundation

// MARK: - Configuration

/// Configuration for the RapidAPI MP3 downloader.
///
/// Provide the key without committing it. Resolution order:
///   1. Process environment `RAPIDAPI_KEY` (Xcode scheme → Run → Environment
///      Variables, or a real env var) — handy for local dev.
///   2. Info.plist key `RapidAPIKey` (best wired from a gitignored .xcconfig).
///   3. The empty default (keeps the previous Piped behavior).
enum RapidAPIConfig {

    static let host = "youtube-mp3-audio-video-downloader.p.rapidapi.com"

    /// Leave empty. Do NOT paste your key here — it would be committed to git.
    static let defaultAPIKey = ""

    static var apiKey: String {
        if let env = ProcessInfo.processInfo.environment["RAPIDAPI_KEY"],
           !env.trimmingCharacters(in: .whitespaces).isEmpty {
            return env
        }
        if let plist = Bundle.main.object(forInfoDictionaryKey: "RapidAPIKey") as? String,
           !plist.trimmingCharacters(in: .whitespaces).isEmpty {
            return plist
        }
        return defaultAPIKey
    }

    static var isConfigured: Bool {
        !apiKey.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// "low" | "high" — passed straight through as the `quality` query item.
    static let quality = "low"

    /// When true the API holds the request open until the file is ready (up to
    /// ~300 s), which is fragile and prone to URLSession timeouts. We poll for
    /// readiness ourselves, so `false` is safer: the API returns the link
    /// immediately and we wait via lightweight HEAD polls instead.
    static let waitUntilReady = false

    /// Max seconds to wait for the encoded file to become reachable.
    static let maxWaitSeconds: TimeInterval = 300
    /// Delay between reachability polls.
    static let pollIntervalSeconds: UInt64 = 5
}

// MARK: - DTOs

private struct RapidAPILinkResponse: Decodable {
    let comment: String?
    let file: String
    let reservedFile: String?

    enum CodingKeys: String, CodingKey {
        case comment
        case file
        case reservedFile = "reserved_file"
    }
}

private struct OEmbedResponse: Decodable {
    let title: String?
    let authorName: String?
    let thumbnailUrl: String?

    enum CodingKeys: String, CodingKey {
        case title
        case authorName = "author_name"
        case thumbnailUrl = "thumbnail_url"
    }
}

// MARK: - Service

final class RapidAPIYouTubeAudioService: YouTubeAudioService {

    private let host: String
    private let apiKey: String
    private let quality: String
    private let waitUntilReady: Bool
    private let maxWaitSeconds: TimeInterval
    private let pollIntervalSeconds: UInt64
    /// Used so conversion still works if RapidAPI fails or no key is set.
    private let fallback: YouTubeAudioService?
    private let session: URLSession

    init(host: String = RapidAPIConfig.host,
         apiKey: String = RapidAPIConfig.apiKey,
         quality: String = RapidAPIConfig.quality,
         waitUntilReady: Bool = RapidAPIConfig.waitUntilReady,
         maxWaitSeconds: TimeInterval = RapidAPIConfig.maxWaitSeconds,
         pollIntervalSeconds: UInt64 = RapidAPIConfig.pollIntervalSeconds,
         fallback: YouTubeAudioService? = PipedYouTubeAudioService(),
         session: URLSession = .shared) {
        self.host = host
        self.apiKey = apiKey.trimmingCharacters(in: .whitespaces)
        self.quality = quality
        self.waitUntilReady = waitUntilReady
        self.maxWaitSeconds = maxWaitSeconds
        self.pollIntervalSeconds = pollIntervalSeconds
        self.fallback = fallback
        self.session = session
    }

    func resolve(link: String) async throws -> Track {
        guard let videoID = YouTubeLink.videoID(from: link) else {
            throw YouTubeServiceError.invalidURL
        }

        do {
            return try await convert(link: link, videoID: videoID)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            if let fallback = fallback {
                return try await fallback.resolve(link: link)
            }
            throw error
        }
    }

    private func convert(link: String, videoID: String) async throws -> Track {
        guard !apiKey.isEmpty else { throw YouTubeServiceError.extractionFailed }

        // 1. Ask RapidAPI for the download link(s).
        let response = try await requestDownloadLink(videoID: videoID)

        // 2. Collect candidate URLs (primary first, then the reserved mirror).
        let candidates = [response.file, response.reservedFile]
            .compactMap { $0 }
            .compactMap { URL(string: $0) }
        guard !candidates.isEmpty else { throw YouTubeServiceError.extractionFailed }

        // 3. Wait until one actually serves the file (it 404s while encoding).
        let readyURL = try await firstReachable(candidates) ?? candidates[0]

        // 4. Best-effort metadata from YouTube oEmbed (no key required).
        let meta = await fetchMetadata(videoID: videoID)

        return Track(
            id: videoID,
            title: meta?.title?.isEmpty == false ? meta!.title! : "YouTube audio",
            artist: meta?.authorName?.isEmpty == false ? meta!.authorName! : "Unknown artist",
            details: "Converted from YouTube • \(videoID)",
            thumbnailURL: URL(string: meta?.thumbnailUrl ?? "")
                ?? URL(string: "https://img.youtube.com/vi/\(videoID)/hqdefault.jpg"),
            sourceURL: URL(string: link.trimmingCharacters(in: .whitespacesAndNewlines)),
            streamURL: readyURL,
            duration: 0,
            downloadedFileName: nil
        )
    }

    private func requestDownloadLink(videoID: String) async throws -> RapidAPILinkResponse {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = "/get_mp3_download_link/\(videoID)"
        components.queryItems = [
            URLQueryItem(name: "quality", value: quality),
            URLQueryItem(name: "wait_until_the_file_is_ready", value: waitUntilReady ? "true" : "false")
        ]
        guard let url = components.url else { throw YouTubeServiceError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // With wait=false the API responds quickly; with wait=true it can hold
        // the connection open while encoding, so allow the full window + slack.
        request.timeoutInterval = waitUntilReady ? maxWaitSeconds + 30 : 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(host, forHTTPHeaderField: "x-rapidapi-host")
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")

        let (data, response) = try await session.loggedData(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw YouTubeServiceError.extractionFailed
        }
        guard (200..<300).contains(http.statusCode) else {
            #if DEBUG
            let body = String(data: data, encoding: .utf8) ?? ""
            print("[RapidAPI] \(http.statusCode) for \(url.absoluteString)\n\(body)")
            #endif
            throw YouTubeServiceError.extractionFailed
        }
        return try JSONDecoder().decode(RapidAPILinkResponse.self, from: data)
    }

    /// Polls the candidate URLs until one responds (the file 404s while encoding).
    private func firstReachable(_ urls: [URL]) async throws -> URL? {
        let deadline = Date().addingTimeInterval(maxWaitSeconds)
        repeat {
            for url in urls {
                if Task.isCancelled { throw CancellationError() }
                if await isReachable(url) { return url }
            }
            if Date() >= deadline { break }
            try await Task.sleep(nanoseconds: pollIntervalSeconds * 1_000_000_000)
        } while Date() < deadline
        return nil
    }

    private func isReachable(_ url: URL) async -> Bool {
        // Try HEAD first; if the file host rejects HEAD (405/403), fall back to a
        // tiny ranged GET so we still detect readiness without downloading it all.
        if let status = await statusCode(for: url, method: "HEAD") {
            if (200..<300).contains(status) { return true }
            if status == 404 { return false } // still encoding
        }
        if let status = await statusCode(for: url, method: "GET", rangeFirstByte: true) {
            return (200..<300).contains(status)
        }
        return false
    }

    private func statusCode(for url: URL, method: String, rangeFirstByte: Bool = false) async -> Int? {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 15
        if rangeFirstByte { request.setValue("bytes=0-0", forHTTPHeaderField: "Range") }
        guard let (_, response) = try? await session.loggedData(for: request),
              let http = response as? HTTPURLResponse else {
            return nil
        }
        return http.statusCode
    }

    private func fetchMetadata(videoID: String) async -> OEmbedResponse? {
        var components = URLComponents(string: "https://www.youtube.com/oembed")
        components?.queryItems = [
            URLQueryItem(name: "url", value: "https://www.youtube.com/watch?v=\(videoID)"),
            URLQueryItem(name: "format", value: "json")
        ]
        guard let url = components?.url else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        guard let (data, response) = try? await session.loggedData(for: request),
              let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            return nil
        }
        return try? JSONDecoder().decode(OEmbedResponse.self, from: data)
    }
}
