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

    /// The active extractor. Resolved automatically:
    ///   • If your conversion backend is configured (`BackendConfig`), use it
    ///     (true y2mate-style: real MP3 from a server you control), falling back
    ///     to Piped if the backend is unreachable.
    ///   • Otherwise use the open-source Piped extractor as before.
    private let service: YouTubeAudioService

    init(service: YouTubeAudioService = MusicConverterViewModel.defaultService()) {
        self.service = service
    }

    /// Picks the backend client when a server URL is set, else Piped.
    /// `nonisolated` so it can be used as a default argument (those expressions
    /// are evaluated outside the main actor).
    nonisolated static func defaultService() -> YouTubeAudioService {
        BackendConfig.isConfigured
            ? BackendYouTubeAudioService(fallback: PipedYouTubeAudioService())
            : PipedYouTubeAudioService()
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
