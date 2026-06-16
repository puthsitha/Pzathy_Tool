//
//  AudioPlayerManager.swift
//  pzathy_tool
//
//  AVPlayer-backed engine: queue/playlist playback, seeking, next/previous,
//  stop (clears the bar), optional background playback, and lock-screen controls.
//

import Foundation
import AVFoundation
import MediaPlayer
import Combine
import UIKit

@MainActor
final class AudioPlayerManager: ObservableObject {

    // MARK: Published state
    @Published private(set) var currentTrack: Track?
    @Published private(set) var queue: [Track] = []
    @Published private(set) var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published private(set) var isBuffering = false

    /// When false, playback pauses as soon as the app goes to the background.
    @Published var backgroundPlaybackEnabled: Bool {
        didSet {
            UserDefaults.standard.set(backgroundPlaybackEnabled, forKey: Self.bgKey)
            configureAudioSession()
        }
    }

    private static let bgKey = "player.backgroundEnabled"

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var itemEndObserver: NSObjectProtocol?
    private var statusObserver: NSKeyValueObservation?
    private var currentIndex = 0

    init() {
        backgroundPlaybackEnabled = (UserDefaults.standard.object(forKey: Self.bgKey) as? Bool) ?? true
        configureAudioSession()
        setupRemoteCommands()
        observeBackgrounding()
    }

    // MARK: - Public controls

    func play(_ track: Track, in tracks: [Track]? = nil) {
        let newQueue = tracks ?? [track]
        queue = newQueue
        currentIndex = newQueue.firstIndex(of: track) ?? 0
        loadCurrent(autoPlay: true)
    }

    func togglePlayPause() {
        guard let player = player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
        updateNowPlaying()
    }

    func next() {
        guard !queue.isEmpty else { return }
        currentIndex = (currentIndex + 1) % queue.count
        loadCurrent(autoPlay: true)
    }

    func previous() {
        guard !queue.isEmpty else { return }
        // If we're more than 3s in, restart the current track instead.
        if currentTime > 3 {
            seek(to: 0)
            return
        }
        currentIndex = (currentIndex - 1 + queue.count) % queue.count
        loadCurrent(autoPlay: true)
    }

    func seek(to seconds: TimeInterval) {
        guard let player = player else { return }
        let target = CMTime(seconds: seconds, preferredTimescale: 600)
        player.seek(to: target) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.currentTime = seconds
                self?.updateNowPlaying()
            }
        }
    }

    /// Stop and clear the player bar entirely.
    func stop() {
        player?.pause()
        teardownObservers()
        player = nil
        currentTrack = nil
        queue = []
        isPlaying = false
        currentTime = 0
        duration = 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    var isActive: Bool { currentTrack != nil }

    func isCurrent(_ track: Track) -> Bool { currentTrack?.id == track.id }

    // MARK: - Loading

    private func loadCurrent(autoPlay: Bool) {
        guard queue.indices.contains(currentIndex) else { return }
        activateSession()
        let track = queue[currentIndex]
        currentTrack = track

        teardownObservers()
        let item = AVPlayerItem(url: track.playbackURL)
        let player = AVPlayer(playerItem: item)
        self.player = player

        duration = track.duration
        currentTime = 0
        isBuffering = true

        // Observe readiness to pull a precise duration.
        statusObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if item.status == .readyToPlay {
                    self.isBuffering = false
                    let d = item.asset.duration.seconds
                    if d.isFinite, d > 0 { self.duration = d }
                    self.updateNowPlaying()
                }
            }
        }

        // Periodic time updates for the seek bar.
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.currentTime = time.seconds
                self.updateNowPlaying()
            }
        }

        // Auto-advance when the track finishes.
        itemEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.next() }
        }

        if autoPlay {
            player.play()
            isPlaying = true
        }
        updateNowPlaying()
    }

    private func teardownObservers() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        if let itemEndObserver = itemEndObserver {
            NotificationCenter.default.removeObserver(itemEndObserver)
            self.itemEndObserver = nil
        }
        statusObserver?.invalidate()
        statusObserver = nil
    }

    // MARK: - Audio session & backgrounding

    /// Sets the category only. We don't activate the session until playback
    /// actually starts, so launching the app never interrupts other audio.
    private func configureAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
    }

    private func activateSession() {
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func observeBackgrounding() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if !self.backgroundPlaybackEnabled, self.isPlaying {
                    self.togglePlayPause()
                }
            }
        }
    }

    // MARK: - Lock screen / control center

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in if self?.isPlaying == false { self?.togglePlayPause() } }
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in if self?.isPlaying == true { self?.togglePlayPause() } }
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.next() }; return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.previous() }; return .success
        }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let e = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            Task { @MainActor [weak self] in self?.seek(to: e.positionTime) }
            return .success
        }
    }

    private func updateNowPlaying() {
        guard let track = currentTrack else { return }
        let info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.artist,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
