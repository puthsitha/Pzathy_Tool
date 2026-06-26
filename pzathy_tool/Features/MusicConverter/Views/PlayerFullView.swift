//
//  PlayerFullView.swift
//  pzathy_tool
//
//  The expanded "Now Playing" screen with full controls.
//

import SwiftUI

struct PlayerFullView: View {
    @EnvironmentObject private var player: AudioPlayerManager
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    @State private var isScrubbing = false
    @State private var scrubValue: Double = 0
    @State private var shareItems: [Any]?
    @State private var showAddToPlaylist = false

    var body: some View {
        Group {
            if let track = player.currentTrack {
                content(for: track)
            } else {
                // Player was stopped while open.
                Color.clear.onAppear { dismiss() }
            }
        }
    }

	private func content(for track: Track) -> some View {
		ZStack(alignment: .top) {
			ScrollView {
				VStack(spacing: 22) {
					Thumbnail(url: track.thumbnailURL, cornerRadius: 18)
						.frame(maxWidth: 320)
						.aspectRatio(1, contentMode: .fit)
						.shadow(color: .black.opacity(0.2), radius: 18, y: 10)
					
					VStack(spacing: 6) {
						Text(track.title)
							.font(.title3).fontWeight(.bold)
							.multilineTextAlignment(.center)
						Text(track.artist)
							.font(.subheadline)
							.foregroundColor(AppColor.secondaryText)
						if !track.details.isEmpty {
							Text(track.details)
								.font(.caption)
								.foregroundColor(AppColor.tertiaryText)
								.multilineTextAlignment(.center)
								.lineLimit(2)
								.padding(.top, 2)
						}
					}
					.padding(.horizontal)
					
					seekBar
					transportControls
					secondaryActions(track)
				}
				.padding(20)
				.frame(maxWidth: 520)
				.frame(maxWidth: .infinity)
			}
			
			// Floating grabber, overlaid above the scroll content (and the Thumbnail).
			grabber
		}
		.background(AppColor.background.ignoresSafeArea())
		.sheet(isPresented: Binding(
				get: { shareItems != nil },
				set: { if !$0 { shareItems = nil } }
			)) {
				if let items = shareItems { ShareSheet(items: items) }
			}
		.sheet(isPresented: $showAddToPlaylist) {
			AddToPlaylistView(track: track)
		}
	}

	private var grabber: some View {
		Capsule()
			.fill(AppColor.tertiaryText)
			.frame(width: 40, height: 5)
			.padding(.vertical, 10)
			.frame(maxWidth: .infinity)
			.background(.ultraThinMaterial.opacity(0.001))
	}

    private var seekBar: some View {
        VStack(spacing: 4) {
            Slider(
                value: Binding(
                    get: { isScrubbing ? scrubValue : player.currentTime },
                    set: { scrubValue = $0 }
                ),
                in: 0...max(player.duration, 1),
                onEditingChanged: { editing in
                    if editing {
                        isScrubbing = true
                        scrubValue = player.currentTime
                    } else {
                        player.seek(to: scrubValue)
                        isScrubbing = false
                    }
                }
            )
            .tint(AppColor.accent)

            HStack {
                Text(TimeFormat.mmss(isScrubbing ? scrubValue : player.currentTime))
                Spacer()
                Text(TimeFormat.mmss(player.duration))
            }
            .font(.caption2.monospacedDigit())
            .foregroundColor(AppColor.secondaryText)
        }
    }

    private var transportControls: some View {
        HStack(spacing: 24) {
            Button { player.toggleShuffle() } label: {
                Image(systemName: "shuffle").font(.title3)
                    .foregroundColor(player.isShuffle ? AppColor.accent : AppColor.primaryText)
            }
            .accessibilityLabel(loc.t(.shuffle))

            Button { player.previous() } label: {
                Image(systemName: "backward.fill").font(.title2)
            }
            Button { player.togglePlayPause() } label: {
                Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(AppColor.accent)
            }
            Button { player.next() } label: {
                Image(systemName: "forward.fill").font(.title2)
            }

            Button { player.cycleRepeatMode() } label: {
                Image(systemName: player.repeatMode == .one ? "repeat.1" : "repeat")
                    .font(.title3)
                    .foregroundColor(player.repeatMode == .off ? AppColor.primaryText : AppColor.accent)
            }
            .accessibilityLabel(loc.t(.repeatTrack))
        }
        .foregroundColor(AppColor.primaryText)
    }

    private func secondaryActions(_ track: Track) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 28) {
                actionButton(
                    icon: track.isDownloaded ? "checkmark.circle.fill" : "arrow.down.circle",
                    label: track.isDownloaded ? loc.t(.downloaded) : loc.t(.download),
                    active: track.isDownloaded
                ) {
                    Task { await library.download(track) }
                }
                .disabled(track.isDownloaded || library.isDownloading(track))

                actionButton(icon: "square.and.arrow.up", label: loc.t(.share)) {
                    Task { shareItems = await ShareContent.asyncItems(for: [track]) }
                }

                actionButton(icon: "text.badge.plus", label: loc.t(.addToPlaylist)) {
                    showAddToPlaylist = true
                }

                actionButton(icon: "stop.circle", label: loc.t(.stop)) {
                    player.stop()
                }
            }

            Toggle(isOn: $player.backgroundPlaybackEnabled) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(loc.t(.backgroundPlayback)).font(.subheadline)
                    Text(loc.t(.backgroundPlaybackHint))
                        .font(.caption2).foregroundColor(AppColor.secondaryText)
                }
            }
            .tint(AppColor.accent)
            .padding(.horizontal, 4)
            .padding(.top, 4)
        }
        .padding(.top, 8)
    }

    private func actionButton(icon: String, label: String, active: Bool = false,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(active ? AppColor.accent : AppColor.primaryText)
                Text(label).font(.caption2)
                    .foregroundColor(AppColor.secondaryText)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
