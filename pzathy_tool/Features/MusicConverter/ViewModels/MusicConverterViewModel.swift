//
//  MusicConverterViewModel.swift
//  pzathy_tool
//

import Foundation
import Combine

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
            return RapidAPIYouTubeAudioService(fallback: PipedYouTubeAudioService())
        }
        if BackendConfig.isConfigured {
            return BackendYouTubeAudioService(fallback: PipedYouTubeAudioService())
        }
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
            return true
        } catch {
            errorMessage = "convert"
            return false
        }
    }
}
