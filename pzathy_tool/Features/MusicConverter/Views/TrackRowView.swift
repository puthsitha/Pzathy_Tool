//
//  TrackRowView.swift
//  pzathy_tool
//

import SwiftUI

struct TrackRowView: View {
    let track: Track
    @EnvironmentObject private var player: AudioPlayerManager
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var loc: LocalizationManager

    var onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Thumbnail(url: track.thumbnailURL)
                    .frame(width: 52, height: 52)
                if player.isCurrent(track) {
                    RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.35))
                        .frame(width: 52, height: 52)
                    Image(systemName: player.isPlaying ? "speaker.wave.2.fill" : "pause.fill")
                        .foregroundColor(.white)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(.subheadline).fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(player.isCurrent(track) ? AppColor.accent : AppColor.primaryText)
                Text(track.artist)
                    .font(.caption).foregroundColor(AppColor.secondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if library.isDownloading(track) {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 24)
            } else if track.isDownloaded {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(AppColor.accent)
                    .font(.system(size: 16))
            }

            Text(TimeFormat.mmss(track.duration))
                .font(.caption2.monospacedDigit())
                .foregroundColor(AppColor.tertiaryText)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}
