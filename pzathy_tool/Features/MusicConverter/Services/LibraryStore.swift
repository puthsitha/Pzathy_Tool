//
//  LibraryStore.swift
//  pzathy_tool
//
//  Source of truth for converted tracks, playlists, and downloads. Persists to
//  JSON in Documents and downloads audio files to disk.
//

import Foundation
import Combine

@MainActor
final class LibraryStore: ObservableObject {
    @Published private(set) var tracks: [Track] = []
    @Published private(set) var playlists: [Playlist] = []

    /// Track ids that are currently downloading.
    @Published private(set) var downloadingIDs: Set<String> = []

    private let tracksFile = "library_tracks.json"
    private let playlistsFile = "library_playlists.json"

    init() {
        tracks = FileStorage.loadJSON([Track].self, named: tracksFile) ?? []
        playlists = FileStorage.loadJSON([Playlist].self, named: playlistsFile) ?? []
    }

    // MARK: - Tracks

    func contains(_ track: Track) -> Bool {
        tracks.contains { $0.id == track.id }
    }

    func add(_ track: Track) {
        guard !contains(track) else { return }
        tracks.insert(track, at: 0)
        persistTracks()
    }

    func remove(_ track: Track) {
        // Delete any downloaded file.
        if let local = track.localFileURL {
            try? FileManager.default.removeItem(at: local)
        }
        tracks.removeAll { $0.id == track.id }
        // Remove from every playlist too.
        for i in playlists.indices {
            playlists[i].trackIDs.removeAll { $0 == track.id }
        }
        persistTracks()
        persistPlaylists()
    }

    func track(withID id: String) -> Track? {
        tracks.first { $0.id == id }
    }

    // MARK: - Playlists

    func createPlaylist(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        playlists.append(Playlist(name: trimmed))
        persistPlaylists()
    }

    func deletePlaylist(_ playlist: Playlist) {
        playlists.removeAll { $0.id == playlist.id }
        persistPlaylists()
    }

    func add(_ track: Track, to playlist: Playlist) {
        add(track) // ensure it's in the library
        guard let idx = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        if !playlists[idx].trackIDs.contains(track.id) {
            playlists[idx].trackIDs.append(track.id)
            persistPlaylists()
        }
    }

    func remove(_ track: Track, from playlist: Playlist) {
        guard let idx = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        playlists[idx].trackIDs.removeAll { $0 == track.id }
        persistPlaylists()
    }

    func tracks(in playlist: Playlist) -> [Track] {
        playlist.trackIDs.compactMap { id in tracks.first { $0.id == id } }
    }

    // MARK: - Downloads

    func isDownloading(_ track: Track) -> Bool {
        downloadingIDs.contains(track.id)
    }

    func download(_ track: Track) async {
        guard !track.isDownloaded, !downloadingIDs.contains(track.id) else { return }
        add(track) // make sure it's saved before downloading

        downloadingIDs.insert(track.id)
        defer { downloadingIDs.remove(track.id) }

        do {
            let (tempURL, _) = try await URLSession.shared.download(from: track.streamURL)
            let fileName = "\(track.id).mp3"
            let dest = FileStorage.audioDirectory.appendingPathComponent(fileName)
            try? FileManager.default.removeItem(at: dest)
            try FileManager.default.moveItem(at: tempURL, to: dest)

            if let idx = tracks.firstIndex(where: { $0.id == track.id }) {
                tracks[idx].downloadedFileName = "Audio/\(fileName)"
                persistTracks()
            }
        } catch {
            // Leave the track as stream-only on failure.
        }
    }

    // MARK: - Persistence

    private func persistTracks() { FileStorage.saveJSON(tracks, named: tracksFile) }
    private func persistPlaylists() { FileStorage.saveJSON(playlists, named: playlistsFile) }
}
