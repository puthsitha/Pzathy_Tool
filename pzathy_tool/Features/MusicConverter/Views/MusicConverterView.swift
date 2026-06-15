//
//  MusicConverterView.swift
//  pzathy_tool
//
//  The Music Converter tool: paste a YouTube link, convert, then play / download /
//  share / organize tracks into playlists.
//

import SwiftUI

struct MusicConverterView: View {
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var player: AudioPlayerManager
    @EnvironmentObject private var loc: LocalizationManager

    @StateObject private var vm = MusicConverterViewModel()

    private enum Tab: Hashable { case songs, playlists }
    @State private var tab: Tab = .songs
    @State private var shareTracks: [Track]?

    var body: some View {
        VStack(spacing: 0) {
            converterCard
            picker
            Divider()
            content
        }
        .background(AppColor.background.ignoresSafeArea())
        .navigationTitle(loc.t(.musicConverter))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: Binding(
            get: { shareTracks.map { ShareBox(tracks: $0) } },
            set: { shareTracks = $0?.tracks }
        )) { box in
            ShareSheet(items: ShareContent.items(for: box.tracks))
        }
    }

    // MARK: - Converter input

    private var converterCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "link").foregroundColor(AppColor.secondaryText)
                TextField(loc.t(.pasteYoutubeLink), text: $vm.link)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                if !vm.link.isEmpty {
                    Button { vm.link = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(AppColor.tertiaryText)
                    }
                }
            }
            .padding(.vertical, 12).padding(.horizontal, 14)
            .background(AppColor.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Button {
                Task { await vm.convert(into: library) }
            } label: {
                HStack {
                    if vm.isConverting {
                        ProgressView().tint(.white)
                        Text(loc.t(.converting))
                    } else {
                        Image(systemName: "wand.and.stars")
                        Text(loc.t(.convert))
                    }
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity).padding(.vertical, 13)
            }
            .background(vm.canConvert ? AppColor.accent : AppColor.accent.opacity(0.5))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .disabled(!vm.canConvert)

            if let error = vm.errorMessage {
                Text(error == "invalid" ? loc.t(.invalidLink) : loc.t(.convertError))
                    .font(.caption).foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
    }

    private var picker: some View {
        Picker("", selection: $tab) {
            Text(loc.t(.songs)).tag(Tab.songs)
            Text(loc.t(.playlists)).tag(Tab.playlists)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .songs:     songsList
        case .playlists: PlaylistsGrid()
        }
    }

    @ViewBuilder
    private var songsList: some View {
        if library.tracks.isEmpty {
            emptyState
        } else {
            List {
                ForEach(library.tracks) { track in
                    TrackRowView(track: track) {
                        player.play(track, in: library.tracks)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            library.remove(track)
                        } label: { Image(systemName: "trash") }

                        Button {
                            shareTracks = [track]
                        } label: { Image(systemName: "square.and.arrow.up") }
                        .tint(AppColor.accent)
                    }
                    .swipeActions(edge: .leading) {
                        if !track.isDownloaded {
                            Button {
                                Task { await library.download(track) }
                            } label: { Image(systemName: "arrow.down") }
                            .tint(.blue)
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundColor(AppColor.accent.opacity(0.6))
            Text(loc.t(.emptyLibrary)).font(.headline)
            Text(loc.t(.emptyLibraryHint))
                .font(.subheadline).foregroundColor(AppColor.secondaryText)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Identifiable wrapper so a `[Track]` can drive a `.sheet(item:)`.
private struct ShareBox: Identifiable {
    let id = UUID()
    let tracks: [Track]
}
