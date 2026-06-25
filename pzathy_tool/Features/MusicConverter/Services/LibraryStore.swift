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

    /// Backfills a track's duration once it's actually known. Conversion services
    /// often return 0 (RapidAPI doesn't report it; Piped sometimes omits it), so
    /// the asset probe and the player both call this to fix the displayed time.
    /// No-ops unless the new value is finite, positive and meaningfully different.
    func updateDuration(_ duration: TimeInterval, forTrackID id: String) {
        guard duration.isFinite, duration > 0,
              let idx = tracks.firstIndex(where: { $0.id == id }),
              abs(tracks[idx].duration - duration) > 0.5 else { return }
        tracks[idx].duration = duration
        persistTracks()
    }

    // MARK: - Playlists

    func createPlaylist(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        playlists.append(Playlist(name: trimmed))
        persistPlaylists()
    }

    func deletePlaylist(_ playlist: Playlist) {
        // Clean up any custom cover image so it doesn't linger on disk.
        if let name = playlist.imageFileName {
            try? FileManager.default.removeItem(
                at: FileStorage.playlistImagesDirectory.appendingPathComponent(name))
        }
        playlists.removeAll { $0.id == playlist.id }
        persistPlaylists()
    }

    /// Renames a playlist. No-ops on an empty/whitespace name or unknown playlist.
    func renamePlaylist(_ playlist: Playlist, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              let idx = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        playlists[idx].name = trimmed
        persistPlaylists()
    }

    /// Reorders the songs in a playlist. Offsets are relative to the currently
    /// displayed (resolvable) tracks; this also drops any stale ids as a bonus.
    func moveTracks(in playlist: Playlist, fromOffsets: IndexSet, toOffset: Int) {
        guard let idx = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        var ids = tracks(in: playlist).map { $0.id }
        // Manual reorder so the service stays free of SwiftUI (which is where
        // Collection.move(fromOffsets:toOffset:) is defined). Mirrors its
        // semantics: `toOffset` is an index into the pre-removal array.
        let moving = fromOffsets.sorted().map { ids[$0] }
        for i in fromOffsets.sorted(by: >) { ids.remove(at: i) }
        let insertAt = toOffset - fromOffsets.filter { $0 < toOffset }.count
        ids.insert(contentsOf: moving, at: insertAt)
        playlists[idx].trackIDs = ids
        persistPlaylists()
    }

    // MARK: Playlist cover image

    /// URL of a playlist's custom cover image, or nil if it has none.
    func playlistImageURL(for playlist: Playlist) -> URL? {
        guard let name = playlist.imageFileName else { return nil }
        return FileStorage.playlistImagesDirectory.appendingPathComponent(name)
    }

    /// Stores a new cover image for a playlist, replacing any previous one. The
    /// file name carries a fresh UUID so AsyncImage doesn't serve a stale cache.
    func setPlaylistImage(_ data: Data, for playlist: Playlist) {
        guard let idx = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        if let old = playlists[idx].imageFileName {
            try? FileManager.default.removeItem(
                at: FileStorage.playlistImagesDirectory.appendingPathComponent(old))
        }
        let fileName = "\(playlist.id)-\(UUID().uuidString).jpg"
        let dest = FileStorage.playlistImagesDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: dest, options: .atomic)
            playlists[idx].imageFileName = fileName
            persistPlaylists()
        } catch {
            // Keep the previous cover (now nil reference) on write failure.
        }
    }

    /// Removes a playlist's custom cover image (reverts to the track thumbnail).
    func removePlaylistImage(_ playlist: Playlist) {
        guard let idx = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        if let old = playlists[idx].imageFileName {
            try? FileManager.default.removeItem(
                at: FileStorage.playlistImagesDirectory.appendingPathComponent(old))
        }
        playlists[idx].imageFileName = nil
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
