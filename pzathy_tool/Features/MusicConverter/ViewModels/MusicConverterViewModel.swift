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

    /// Swap this for your own backend-backed implementation later — nothing else
    /// changes. Defaults to the real (open-source Piped) extractor.
    private let service: YouTubeAudioService

    init(service: YouTubeAudioService = PipedYouTubeAudioService()) {
        self.service = service
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
