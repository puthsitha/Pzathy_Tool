//
//  PlayerBarView.swift
//  pzathy_tool
//
//  Compact "now playing" bar shown above the tab bar while audio is loaded.
//

import SwiftUI

struct PlayerBarView: View {
    @EnvironmentObject private var player: AudioPlayerManager
    @State private var showFullPlayer = false

    var body: some View {
        if let track = player.currentTrack {
            VStack(spacing: 0) {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(AppColor.accent)
                    .scaleEffect(x: 1, y: 0.6, anchor: .center)

                HStack(spacing: 12) {
                    Thumbnail(url: track.thumbnailURL, cornerRadius: 8)
                        .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(track.title).font(.subheadline).fontWeight(.medium).lineLimit(1)
                        Text(track.artist).font(.caption2).foregroundColor(AppColor.secondaryText).lineLimit(1)
                    }

                    Spacer(minLength: 4)

                    Button { player.togglePlayPause() } label: {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title3)
                            .frame(width: 36, height: 36)
                    }
                    Button { player.next() } label: {
                        Image(systemName: "forward.fill")
                            .font(.body)
                            .frame(width: 32, height: 36)
                    }
                    Button { player.stop() } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline)
                            .frame(width: 30, height: 36)
                            .foregroundColor(AppColor.secondaryText)
                    }
                }
                .foregroundColor(AppColor.primaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .background(.ultraThinMaterial)
            .overlay(Rectangle().frame(height: 0.5).foregroundColor(AppColor.separator), alignment: .top)
            .contentShape(Rectangle())
            .onTapGesture { showFullPlayer = true }
            .sheet(isPresented: $showFullPlayer) {
                PlayerFullView()
            }
        }
    }

    private var progress: Double {
        guard player.duration > 0 else { return 0 }
        return min(max(player.currentTime / player.duration, 0), 1)
    }
}
