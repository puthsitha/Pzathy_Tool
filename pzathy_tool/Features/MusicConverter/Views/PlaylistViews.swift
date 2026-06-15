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
    @State private var showShare = false

    private var tracks: [Track] { library.tracks(in: playlist) }

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    Thumbnail(url: tracks.first?.thumbnailURL, cornerRadius: 14)
                        .frame(width: 96, height: 96)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(playlist.name).font(.title3).fontWeight(.bold)
                        Text("\(tracks.count) \(loc.t(.songs))")
                            .font(.caption).foregroundColor(AppColor.secondaryText)
                        HStack {
                            Button {
                                if let first = tracks.first { player.play(first, in: tracks) }
                            } label: {
                                Label(loc.t(.play), systemImage: "play.fill")
                                    .font(.caption).padding(.horizontal, 14).padding(.vertical, 7)
                                    .background(AppColor.accent).foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                            .disabled(tracks.isEmpty)

                            Button { showShare = true } label: {
                                Image(systemName: "square.and.arrow.up")
                                    .padding(7).background(AppColor.surfaceElevated).clipShape(Circle())
                            }
                            .disabled(tracks.isEmpty)
                        }
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            Section(loc.t(.songs)) {
                ForEach(tracks) { track in
                    TrackRowView(track: track) { player.play(track, in: tracks) }
                        .swipeActions {
                            Button(role: .destructive) {
                                library.remove(track, from: playlist)
                            } label: { Image(systemName: "minus.circle") }
                        }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(playlist.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShare) {
            ShareSheet(items: ShareContent.items(for: tracks))
        }
    }
}

struct PlaylistsGrid: View {
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var loc: LocalizationManager
    @State private var showCreate = false
    @State private var newName = ""

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 14)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 14) {
                createCard
                ForEach(library.playlists) { playlist in
                    NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                        card(for: playlist)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
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
        return VStack(alignment: .leading, spacing: 8) {
            Thumbnail(url: tracks.first?.thumbnailURL, cornerRadius: 12)
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
