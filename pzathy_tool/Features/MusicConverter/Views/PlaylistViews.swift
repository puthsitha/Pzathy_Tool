//
//  PlaylistViews.swift
//  pzathy_tool
//
//  Playlist grid + detail (an album of converted tracks).
//

import SwiftUI

struct PlaylistDetailView: View {
    let playlist: Playlist
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var player: AudioPlayerManager
    @EnvironmentObject private var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    @State private var showShare = false
    @State private var showEdit = false
    @State private var showDeleteConfirm = false

    /// Always read the freshest copy from the store so renames, cover changes and
    /// reorders made elsewhere are reflected immediately.
    private var live: Playlist {
        library.playlists.first { $0.id == playlist.id } ?? playlist
    }

    private var tracks: [Track] { library.tracks(in: live) }

    /// Custom cover if set, otherwise the first track's thumbnail.
    private var coverURL: URL? {
        library.playlistImageURL(for: live) ?? tracks.first?.thumbnailURL
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    Thumbnail(url: coverURL, cornerRadius: 14)
                        .frame(width: 96, height: 96)
                        .padding(.trailing, 16)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(live.name).font(.title3).fontWeight(.bold)
                        Text("\(tracks.count) \(loc.t(.songs))")
                            .font(.caption).foregroundColor(AppColor.secondaryText)
                        HStack(spacing: 12) {
                            Button {
                                if let first = tracks.first { player.play(first, in: tracks) }
                            } label: {
                                Label(loc.t(.play), systemImage: "play.fill")
                                    .font(.caption).padding(.horizontal, 14).padding(.vertical, 7)
                                    .background(AppColor.accent).foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                            // .borderless keeps each button's tap target isolated;
                            // without it a List row routes taps to every button, so
                            // tapping Play would also trigger the share sheet.
                            .buttonStyle(.borderless)
                            .disabled(tracks.isEmpty)

                            Button { showShare = true } label: {
                                Image(systemName: "square.and.arrow.up")
                                    .padding(7).background(AppColor.surfaceElevated).clipShape(Circle())
                            }
                            .buttonStyle(.borderless)
                            .disabled(tracks.isEmpty)
                        }
                        .padding(.top, 2)
                    }
                }
                .listRowBackground(Color.clear)
            }

            Section(loc.t(.songs)) {
                ForEach(tracks) { track in
                    TrackRowView(track: track) { player.play(track, in: tracks) }
                        .swipeActions {
                            Button(role: .destructive) {
                                library.remove(track, from: live)
                            } label: { Image(systemName: "minus.circle") }
                        }
                }
                // Drag the handles (in Edit mode) to reorder songs in the playlist.
                .onMove { from, to in
                    library.moveTracks(in: live, fromOffsets: from, toOffset: to)
                }
            }

            // Reserve space so the floating player bar doesn't cover the last row.
            if player.isActive {
                Color.clear
                    .frame(height: 64)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(live.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                EditButton()
                Menu {
                    Button { showEdit = true } label: {
                        Label(loc.t(.editPlaylist), systemImage: "pencil")
                    }
                    Button(role: .destructive) { showDeleteConfirm = true } label: {
                        Label(loc.t(.deletePlaylist), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showShare) {
            ShareSheet(items: ShareContent.items(for: tracks))
        }
        .sheet(isPresented: $showEdit) {
            EditPlaylistView(playlist: live)
        }
        .confirmationDialog(
            loc.t(.deletePlaylist), isPresented: $showDeleteConfirm, titleVisibility: .visible
        ) {
            Button(loc.t(.deletePlaylist), role: .destructive) {
                library.deletePlaylist(live)
                dismiss()
            }
            Button(loc.t(.cancel), role: .cancel) {}
        } message: {
            Text(loc.t(.deletePlaylistConfirm))
        }
    }
}

/// Rename a playlist and set / change / remove its cover image.
private struct EditPlaylistView: View {
    let playlist: Playlist
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var showPhotoPicker = false

    init(playlist: Playlist) {
        self.playlist = playlist
        _name = State(initialValue: playlist.name)
    }

    private var live: Playlist {
        library.playlists.first { $0.id == playlist.id } ?? playlist
    }

    private var coverURL: URL? {
        library.playlistImageURL(for: live) ?? library.tracks(in: live).first?.thumbnailURL
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(spacing: 12) {
                        Thumbnail(url: coverURL, cornerRadius: 16)
                            .frame(width: 120, height: 120)
                        Button { showPhotoPicker = true } label: {
                            Label(loc.t(.changeImage), systemImage: "photo")
                        }
                        if live.imageFileName != nil {
                            Button(role: .destructive) {
                                library.removePlaylistImage(live)
                            } label: { Text(loc.t(.removeImage)) }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }

                Section(loc.t(.playlistName)) {
                    TextField(loc.t(.playlistName), text: $name)
                        .submitLabel(.done)
                        .onSubmit(saveAndDismiss)
                }
            }
            .navigationTitle(loc.t(.editPlaylist))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc.t(.cancel)) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(loc.t(.save), action: saveAndDismiss)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPicker { data in library.setPlaylistImage(data, for: live) }
            }
        }
    }

    private func saveAndDismiss() {
        library.renamePlaylist(live, to: name)
        dismiss()
    }
}

struct PlaylistsGrid: View {
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var loc: LocalizationManager
    @EnvironmentObject private var player: AudioPlayerManager
    @State private var showCreate = false
    @State private var newName = ""

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                createCard
                ForEach(library.playlists) { playlist in
                    NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                        card(for: playlist)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            library.deletePlaylist(playlist)
                        } label: { Label(loc.t(.deletePlaylist), systemImage: "trash") }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, player.isActive ? 88 : 20)
        }
        .alert(loc.t(.newPlaylist), isPresented: $showCreate) {
            TextField(loc.t(.playlistName), text: $newName)
            Button(loc.t(.createPlaylist)) {
                library.createPlaylist(name: newName); newName = ""
            }
            Button(loc.t(.cancel), role: .cancel) { newName = "" }
        }
    }

    private var createCard: some View {
        Button { showCreate = true } label: {
            VStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(AppColor.accent)
                Text(loc.t(.createPlaylist)).font(.caption).foregroundColor(AppColor.secondaryText)
            }
            .frame(maxWidth: .infinity).frame(height: 150)
            .background(AppColor.surface)
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AppColor.accent.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [6])))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func card(for playlist: Playlist) -> some View {
        let tracks = library.tracks(in: playlist)
        let cover = library.playlistImageURL(for: playlist) ?? tracks.first?.thumbnailURL
        return VStack(alignment: .leading, spacing: 8) {
            Thumbnail(url: cover, cornerRadius: 12)
                .frame(height: 110)
                .frame(maxWidth: .infinity)
            Text(playlist.name).font(.subheadline).fontWeight(.semibold).lineLimit(1)
            Text("\(tracks.count) \(loc.t(.songs))")
                .font(.caption2).foregroundColor(AppColor.secondaryText)
        }
        .padding(10)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
