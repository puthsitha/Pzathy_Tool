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

/// How playback behaves when a track reaches the end.
enum RepeatMode: String {
    case off   // stop at the end (don't play again)
    case all   // advance to the next track (wraps around)
    case one   // loop the current track
}

@MainActor
final class AudioPlayerManager: ObservableObject {

    // MARK: Published state
    @Published private(set) var currentTrack: Track?
    @Published private(set) var queue: [Track] = []
    @Published private(set) var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published private(set) var isBuffering = false

    /// What happens at the end of a track. Defaults to `.off` so a finished song
    /// does not play again unless the user turns repeat on.
    @Published var repeatMode: RepeatMode {
        didSet { UserDefaults.standard.set(repeatMode.rawValue, forKey: Self.repeatKey) }
    }

    /// When true, next/previous (and repeat-all auto-advance) pick a random track.
    @Published var isShuffle: Bool {
        didSet { UserDefaults.standard.set(isShuffle, forKey: Self.shuffleKey) }
    }

    /// When false, playback pauses as soon as the app goes to the background.
    @Published var backgroundPlaybackEnabled: Bool {
        didSet {
            UserDefaults.standard.set(backgroundPlaybackEnabled, forKey: Self.bgKey)
            configureAudioSession()
        }
    }

    /// Called when a precise duration is resolved for the current track, so the
    /// library can backfill durations the conversion service didn't provide.
    var onDurationResolved: (@MainActor (_ trackID: String, _ duration: TimeInterval) -> Void)?

    private static let bgKey = "player.backgroundEnabled"
    private static let repeatKey = "player.repeatMode"
    private static let shuffleKey = "player.shuffle"

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var itemEndObserver: NSObjectProtocol?
    private var statusObserver: NSKeyValueObservation?
    private var durationObserver: NSKeyValueObservation?
    private var currentIndex = 0

    private var isInBackground = false
    private var cachedArtwork: MPMediaItemArtwork?
    private var artworkTrackID: String?

    init() {
        backgroundPlaybackEnabled = (UserDefaults.standard.object(forKey: Self.bgKey) as? Bool) ?? true
        repeatMode = RepeatMode(rawValue: UserDefaults.standard.string(forKey: Self.repeatKey) ?? "") ?? .off
        isShuffle = UserDefaults.standard.bool(forKey: Self.shuffleKey)
        configureAudioSession()
        setupRemoteCommands()
        observeBackgrounding()
    }

    // MARK: - Public controls

    func play(_ track: Track, in tracks: [Track]? = nil) {
        // Tapping the track that's already loaded should toggle play/pause
        // rather than restart it from the beginning.
        if currentTrack?.id == track.id, player != nil {
            togglePlayPause()
            return
        }
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
        if isShuffle, queue.count > 1 {
            currentIndex = randomIndex(excluding: currentIndex)
        } else {
            currentIndex = (currentIndex + 1) % queue.count
        }
        loadCurrent(autoPlay: true)
    }

    func previous() {
        guard !queue.isEmpty else { return }
        // If we're more than 3s in, restart the current track instead.
        if currentTime > 3 {
            seek(to: 0)
            return
        }
        if isShuffle, queue.count > 1 {
            currentIndex = randomIndex(excluding: currentIndex)
        } else {
            currentIndex = (currentIndex - 1 + queue.count) % queue.count
        }
        loadCurrent(autoPlay: true)
    }

    /// Cycle off → all → one → off.
    func cycleRepeatMode() {
        switch repeatMode {
        case .off: repeatMode = .all
        case .all: repeatMode = .one
        case .one: repeatMode = .off
        }
    }

    func toggleShuffle() { isShuffle.toggle() }

    private func randomIndex(excluding i: Int) -> Int {
        guard queue.count > 1 else { return i }
        var n = Int.random(in: 0..<queue.count)
        if n == i { n = (n + 1) % queue.count }
        return n
    }

    /// Called when the current track plays to the end.
    private func handleTrackEnded() {
        switch repeatMode {
        case .one:
            seek(to: 0)
            player?.play()
            isPlaying = true
            updateNowPlaying()
        case .all:
            next()
        case .off:
            // Don't play again: stop at the end and reset to the start.
            player?.pause()
            isPlaying = false
            seek(to: 0)
            updateNowPlaying()
        }
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
        cachedArtwork = nil
        artworkTrackID = nil
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

        // Observe readiness to pull a precise duration. Prefer the player item's
        // own duration (reliable for remote MP3s) over the asset's estimate.
        statusObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if item.status == .readyToPlay {
                    self.isBuffering = false
                    self.applyDuration(from: item)
                    self.updateNowPlaying()
                }
            }
        }

        // The duration is often unknown until enough is buffered; update when it
        // becomes available so the seek bar and time label are correct.
        durationObserver = item.observe(\.duration, options: [.new]) { [weak self] item, _ in
            Task { @MainActor [weak self] in self?.applyDuration(from: item) }
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

        // Handle end-of-track per the repeat mode (default: stop, don't replay).
        itemEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.handleTrackEnded() }
        }

        if autoPlay {
            player.play()
            isPlaying = true
        }
        updateNowPlaying()
        fetchArtwork(for: track)
    }

    /// Adopt a finite, positive duration from the player item, ignoring the
    /// `indefinite`/`NaN` values AVPlayer reports before the duration is known.
    private func applyDuration(from item: AVPlayerItem) {
        let d = item.duration.seconds
        guard d.isFinite, d > 0 else { return }
        if abs(d - duration) > 0.5 {
            duration = d
            updateNowPlaying()
        }
        // Persist the precise duration back to the library (no-ops if unchanged).
        if let id = currentTrack?.id {
            onDurationResolved?(id, d)
        }
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
        durationObserver?.invalidate()
        durationObserver = nil
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
                self.isInBackground = true
                // Remove artwork from lock screen when in background
                self.updateNowPlaying()
                if !self.backgroundPlaybackEnabled, self.isPlaying {
                    self.togglePlayPause()
                }
            }
        }
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isInBackground = false
                // Restore artwork on lock screen when returning to foreground
                self.updateNowPlaying()
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

    /// Downloads the thumbnail for `track` and caches it as MPMediaItemArtwork,
    /// then refreshes the Now Playing info so the lock screen shows the cover art.
    private func fetchArtwork(for track: Track) {
        guard let url = track.thumbnailURL else { return }
        let trackID = track.id
        Task.detached(priority: .utility) { [weak self] in
            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  let image = UIImage(data: data) else { return }
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            await MainActor.run { [weak self] in
                guard let self, self.currentTrack?.id == trackID else { return }
                self.cachedArtwork = artwork
                self.artworkTrackID = trackID
                self.updateNowPlaying()
            }
        }
    }

    private func updateNowPlaying() {
        guard let track = currentTrack else { return }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.artist,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        // Show album art on the lock screen only while the app is in the foreground;
        // hide it when backgrounded so the Now Playing widget stays minimal.
        if !isInBackground, let artwork = cachedArtwork, artworkTrackID == track.id {
            info[MPMediaItemPropertyArtwork] = artwork
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
