//
//  MusicConverterViewModel.swift
//  pzathy_tool
//

import Foundation
import Combine
import AVFoundation

@MainActor
final class MusicConverterViewModel: ObservableObject {
    @Published var link: String = ""
    @Published private(set) var isConverting = false
    @Published var errorMessage: String?
    @Published var lastConverted: Track?

    /// The active extractor. Resolved automatically by configuration:
    ///   1. RapidAPI MP3 downloader, if `RapidAPIConfig` has a key.
    ///   2. Your own conversion backend, if `BackendConfig` has a URL.
    ///   3. The open-source Piped extractor otherwise.
    /// Each of (1) and (2) falls back to Piped if its call fails.
    private let service: YouTubeAudioService

    init(service: YouTubeAudioService = MusicConverterViewModel.defaultService()) {
        self.service = service
    }

    /// Picks the configured extractor (RapidAPI → backend → Piped).
    /// `nonisolated` so it can be used as a default argument (those expressions
    /// are evaluated outside the main actor).
    nonisolated static func defaultService() -> YouTubeAudioService {
        if RapidAPIConfig.isConfigured {
            #if DEBUG
            print("[MusicConverter] Using RapidAPI extractor (key loaded).")
            #endif
            return RapidAPIYouTubeAudioService(fallback: PipedYouTubeAudioService())
        }
        if BackendConfig.isConfigured {
            return BackendYouTubeAudioService(fallback: PipedYouTubeAudioService())
        }
        #if DEBUG
        print("[MusicConverter] No RapidAPI key found — falling back to Piped. "
            + "Check that RapidAPIKey is in the built Info.plist (Secrets.local.xcconfig → RAPIDAPI_KEY).")
        #endif
        return PipedYouTubeAudioService()
    }

    var canConvert: Bool {
        !isConverting && YouTubeLink.isValid(link)
    }

    /// Attempts conversion. Returns `false` (without networking) when offline so
    /// the caller can surface a "No internet" popup.
    @discardableResult
    func convert(into library: LibraryStore, isConnected: Bool = true) async -> Bool {
        errorMessage = nil
        guard YouTubeLink.isValid(link) else {
            errorMessage = "invalid"
            return false
        }
        guard isConnected else {
            errorMessage = "offline"
            return false
        }
        isConverting = true
        defer { isConverting = false }

        do {
            let track = try await service.resolve(link: link)
            library.add(track)
            lastConverted = track
            link = ""

            // Some extractors (RapidAPI, occasionally Piped) don't report a
            // duration, leaving the row stuck at 0:00. Probe the audio asset in
            // the background and backfill it so the time shows without playing.
            if track.duration <= 0 {
                #if DEBUG
                print("[Duration] track.duration is 0 for '\(track.title)' (id: \(track.id)) — probing…")
                print("[Duration] playbackURL: \(track.playbackURL)")
                #endif
                Task { [weak library] in
                    let seconds = await Self.resolveDuration(for: track)
                    #if DEBUG
                    print("[Duration] resolved: \(seconds)s for id: \(track.id)")
                    #endif
                    if seconds > 0 { library?.updateDuration(seconds, forTrackID: track.id) }
                }
            } else {
                #if DEBUG
                print("[Duration] track.duration = \(track.duration)s for '\(track.title)' (id: \(track.id))")
                #endif
            }
            return true
        } catch {
            errorMessage = "convert"
            return false
        }
    }

    /// Try asset-header probe first; if the CDN doesn't expose duration headers
    /// (timescale 0 → nan), fall back to the Piped API using the YouTube video ID.
    nonisolated private static func resolveDuration(for track: Track) async -> TimeInterval {
        // 1. Asset probe (fast, works when server sends Content-Duration / mp4 moov)
        let assetSeconds = await assetDuration(for: track.playbackURL)
        #if DEBUG
        print("[Duration] assetDuration probe: \(assetSeconds)s")
        #endif
        if assetSeconds > 0 { return assetSeconds }

        // 2. Piped / Invidious metadata API using the YouTube video ID
        #if DEBUG
        print("[Duration] asset probe returned 0 — trying Piped/Invidious for id: \(track.id)")
        #endif
        let apiSeconds = await pipedDuration(forVideoID: track.id)
        if apiSeconds > 0 { return apiSeconds }

        // 3. Guaranteed fallback: download the MP3 bytes to a temp file and let
        //    AVAsset read the duration locally (the CDN won't expose it over HTTP,
        //    but the frames in the downloaded file are always parseable). Only the
        //    streamURL is worth downloading — a local file would already have been
        //    read by the asset probe in step 1.
        #if DEBUG
        print("[Duration] metadata APIs failed — downloading file to read duration locally…")
        #endif
        return await downloadedFileDuration(for: track.streamURL)
    }

    /// Downloads the audio to a temporary file and reads its duration locally.
    /// Reliable when the CDN doesn't expose duration over the network. The temp
    /// file is removed afterwards. Returns 0 on any failure.
    nonisolated private static func downloadedFileDuration(for url: URL) async -> TimeInterval {
        do {
            let (tempURL, _) = try await URLSession.shared.download(from: url)
            // AVAsset sniffs type better with an extension; give it ".mp3".
            let mp3URL = tempURL.appendingPathExtension("mp3")
            let assetURL: URL
            if (try? FileManager.default.moveItem(at: tempURL, to: mp3URL)) != nil {
                assetURL = mp3URL
            } else {
                assetURL = tempURL
            }
            defer { try? FileManager.default.removeItem(at: assetURL) }
            let seconds = await assetDuration(for: assetURL)
            #if DEBUG
            print("[Duration] local file probe returned \(seconds)s")
            #endif
            return seconds
        } catch {
            #if DEBUG
            print("[Duration] download for duration failed: \(error.localizedDescription)")
            #endif
            return 0
        }
    }

    /// Loads an audio asset's duration (seconds) without downloading the whole
    /// file. iOS 15-compatible; returns 0 when the duration can't be determined.
    nonisolated private static func assetDuration(for url: URL) async -> TimeInterval {
        let asset = AVURLAsset(url: url)
        return await withCheckedContinuation { continuation in
            asset.loadValuesAsynchronously(forKeys: ["duration"]) {
                let seconds = asset.duration.seconds
                continuation.resume(returning: seconds.isFinite && seconds > 0 ? seconds : 0)
            }
        }
    }

    /// Fetches duration (seconds) from the Piped `/streams/{videoID}` endpoint,
    /// then falls back to Invidious `/api/v1/videos/{videoID}` if all Piped instances fail.
    nonisolated private static func pipedDuration(forVideoID videoID: String) async -> TimeInterval {
        // — Piped —
        let pipedInstances = [
            "https://pipedapi.kavin.rocks",
            "https://pipedapi.adminforge.de",
            "https://api.piped.private.coffee"
        ]
        for base in pipedInstances {
            guard let url = URL(string: "\(base)/streams/\(videoID)") else { continue }
            do {
                var request = URLRequest(url: url)
                request.timeoutInterval = 10
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                let (data, _) = try await URLSession.shared.data(for: request)
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let duration = json["duration"] as? Int, duration > 0 {
                    #if DEBUG
                    print("[Duration] Piped returned \(duration)s from \(base)")
                    #endif
                    return TimeInterval(duration)
                }
            } catch { continue }
        }
        #if DEBUG
        print("[Duration] All Piped instances failed for id: \(videoID) — trying Invidious…")
        #endif

        // — Invidious fallback —
        let invidiousInstances = [
            "https://inv.nadeko.net",
            "https://invidious.nerdvpn.de",
            "https://invidious.privacyredirect.com"
        ]
        for base in invidiousInstances {
            guard let url = URL(string: "\(base)/api/v1/videos/\(videoID)?fields=lengthSeconds") else { continue }
            do {
                var request = URLRequest(url: url)
                request.timeoutInterval = 10
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                let (data, _) = try await URLSession.shared.data(for: request)
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let duration = json["lengthSeconds"] as? Int, duration > 0 {
                    #if DEBUG
                    print("[Duration] Invidious returned \(duration)s from \(base)")
                    #endif
                    return TimeInterval(duration)
                }
            } catch { continue }
        }
        #if DEBUG
        print("[Duration] All Piped + Invidious instances failed for id: \(videoID)")
        #endif
        return 0
    }
}
