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
                Task { [weak library] in
                    let seconds = await Self.assetDuration(for: track.playbackURL)
                    if seconds > 0 { library?.updateDuration(seconds, forTrackID: track.id) }
                }
            }
            return true
        } catch {
            errorMessage = "convert"
            return false
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
