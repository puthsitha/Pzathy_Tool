//
//  AddToPlaylistView.swift
//  pzathy_tool
//

import SwiftUI

struct AddToPlaylistView: View {
    let track: Track
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    @State private var newName = ""

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        TextField(loc.t(.playlistName), text: $newName)
                        Button(loc.t(.createPlaylist)) {
                            library.createPlaylist(name: newName)
                            newName = ""
                        }
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                Section(loc.t(.playlists)) {
                    if library.playlists.isEmpty {
                        Text(loc.t(.newPlaylist)).foregroundColor(AppColor.secondaryText)
                    }
                    ForEach(library.playlists) { playlist in
                        Button {
                            toggle(playlist)
                        } label: {
                            HStack {
                                Image(systemName: "music.note.list").foregroundColor(AppColor.accent)
                                Text(playlist.name).foregroundColor(AppColor.primaryText)
                                Spacer()
                                if playlist.trackIDs.contains(track.id) {
                                    Image(systemName: "checkmark").foregroundColor(AppColor.accent)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(loc.t(.addToPlaylist))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(loc.t(.done)) { dismiss() }
                }
            }
        }
    }

    private func toggle(_ playlist: Playlist) {
        if playlist.trackIDs.contains(track.id) {
            library.remove(track, from: playlist)
        } else {
            library.add(track, to: playlist)
        }
    }
}
