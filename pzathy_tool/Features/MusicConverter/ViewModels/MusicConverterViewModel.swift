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

    /// Swap this for a backend-backed implementation later — nothing else changes.
    private let service: YouTubeAudioService

    init(service: YouTubeAudioService = MockYouTubeAudioService()) {
        self.service = service
    }

    var canConvert: Bool {
        !isConverting && YouTubeLink.isValid(link)
    }

    func convert(into library: LibraryStore) async {
        errorMessage = nil
        guard YouTubeLink.isValid(link) else {
            errorMessage = "invalid"
            return
        }
        isConverting = true
        defer { isConverting = false }

        do {
            let track = try await service.resolve(link: link)
            library.add(track)
            lastConverted = track
            link = ""
        } catch {
            errorMessage = "convert"
        }
    }
}
