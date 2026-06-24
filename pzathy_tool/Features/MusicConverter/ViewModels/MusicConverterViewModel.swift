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

            // The extractor's stream URL is short-lived (the CDN expires it after a
            // while), so playback would break for long or later sessions. Download
            // the audio to local storage immediately — `Track.playbackURL` then
            // prefers the persistent local file, so playback works anytime, offline,
            // and isn't cut off when the remote link expires. Once the file is local
            // we also backfill the duration from it (no extra download needed).
            Task { [weak library] in
                await library?.download(track)
                let saved = library?.track(withID: track.id) ?? track
                if saved.duration <= 0 {
                    #if DEBUG
                    print("[Duration] track.duration is 0 for '\(saved.title)' (id: \(saved.id)) — probing…")
                    print("[Duration] playbackURL: \(saved.playbackURL)")
                    #endif
                    let seconds = await Self.resolveDuration(for: saved)
                    #if DEBUG
                    print("[Duration] resolved: \(seconds)s for id: \(saved.id)")
                    #endif
                    if seconds > 0 { library?.updateDuration(seconds, forTrackID: saved.id) }
                }
            }
            return true
        } catch {
            errorMessage = "convert"
            return false
        }
    }

    /// Try asset-header probe first; if the CDN doesn't expose duration headers
    /// (timescale 0 → nan), download to a temp file and read locally.
    nonisolated private static func resolveDuration(for track: Track) async -> TimeInterval {
        // 1. Asset probe (fast, works when server sends Content-Duration / mp4 moov)
        let assetSeconds = await assetDuration(for: track.playbackURL)
        #if DEBUG
        print("[Duration] assetDuration probe: \(assetSeconds)s")
        #endif
        if assetSeconds > 0 { return assetSeconds }

        // 2. Download the MP3 bytes to a temp file and let AVAsset read locally.
        //    The CDN won't expose duration over HTTP, but the frames in a downloaded
        //    file are always parseable. Temp file is deleted immediately after.
        #if DEBUG
        print("[Duration] asset probe returned 0 — downloading file to read duration locally…")
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
}
