//
//  PomodoroTimerViewModel.swift
//  pzathy_tool
//
//  The Pomodoro timer engine. Drives a single focus → break cycle, advancing
//  phases automatically (or on demand) and keeping a count of completed focus
//  sessions. Time is tracked against a target end-date rather than by
//  decrementing a counter, so backgrounding the app never causes drift.
//

import Foundation
import Combine
import AudioToolbox
import UIKit

@MainActor
final class PomodoroTimerViewModel: ObservableObject {
    private static let settingsKey  = "pomodoro.settings"
    private static let completedKey = "pomodoro.completedFocusSessions"

    /// Tunable settings. Persisted on change; when idle, edits immediately
    /// refresh the displayed time for the current phase.
    @Published var settings: PomodoroSettings {
        didSet {
            persistSettings()
            if !isRunning { resetTimeForCurrentPhase() }
        }
    }

    @Published private(set) var phase: PomodoroPhase = .focus
    @Published private(set) var remaining: TimeInterval
    @Published private(set) var isRunning = false

    /// Completed focus rounds in the current cycle (resets after a long break).
    @Published private(set) var roundInCycle = 0
    /// Total focus sessions completed (persisted across launches).
    @Published private(set) var completedFocusSessions: Int

    /// Absolute time the current run should reach 0. `nil` while paused/idle.
    private var endDate: Date?
    private var timerCancellable: AnyCancellable?

    init() {
        let loaded = Self.loadSettings()
        self.settings = loaded
        self.remaining = loaded.duration(for: .focus)
        self.completedFocusSessions = UserDefaults.standard.integer(forKey: Self.completedKey)
    }

    // MARK: - Derived state

    /// Full length of the current phase, in seconds.
    var totalDuration: TimeInterval { settings.duration(for: phase) }

    /// Progress through the current phase, 0…1.
    var progress: Double {
        let total = totalDuration
        guard total > 0 else { return 0 }
        return min(1, max(0, 1 - remaining / total))
    }

    // MARK: - Controls

    func toggle() { isRunning ? pause() : start() }

    func start() {
        guard !isRunning, remaining > 0 else { return }
        endDate = Date().addingTimeInterval(remaining)
        isRunning = true
        startTicking()
    }

    func pause() {
        guard isRunning else { return }
        if let endDate { remaining = max(0, endDate.timeIntervalSinceNow) }
        stopTicking()
        isRunning = false
    }

    /// Stops and restores the current phase to its full duration.
    func reset() {
        stopTicking()
        isRunning = false
        resetTimeForCurrentPhase()
    }

    /// Jumps to the next phase without counting the current one as completed.
    func skip() {
        advance(countCompletion: false, autoStart: false)
    }

    /// Manually switch to a specific phase (stops any running timer).
    func select(_ newPhase: PomodoroPhase) {
        guard newPhase != phase else {
            if !isRunning { reset() }
            return
        }
        stopTicking()
        isRunning = false
        phase = newPhase
        resetTimeForCurrentPhase()
    }

    // MARK: - Engine

    private func resetTimeForCurrentPhase() {
        remaining = settings.duration(for: phase)
    }

    private func startTicking() {
        timerCancellable = Timer.publish(every: 0.2, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func stopTicking() {
        timerCancellable?.cancel()
        timerCancellable = nil
        endDate = nil
    }

    private func tick() {
        guard isRunning, let endDate else { return }
        let r = endDate.timeIntervalSinceNow
        if r <= 0 {
            remaining = 0
            completePhase()
        } else {
            remaining = r
        }
    }

    /// Called when a phase reaches 0. Alerts the user and advances.
    private func completePhase() {
        stopTicking()
        isRunning = false
        notifyPhaseEnd()
        advance(countCompletion: true, autoStart: settings.autoStartNext)
    }

    /// Moves to the next phase in the cycle.
    /// - Parameters:
    ///   - countCompletion: whether a finished focus session counts toward the
    ///     completed total and the long-break cycle.
    ///   - autoStart: whether to immediately start the next phase.
    private func advance(countCompletion: Bool, autoStart: Bool) {
        let next: PomodoroPhase
        switch phase {
        case .focus:
            if countCompletion {
                completedFocusSessions += 1
                UserDefaults.standard.set(completedFocusSessions, forKey: Self.completedKey)
                roundInCycle += 1
            }
            if roundInCycle >= max(1, settings.roundsBeforeLongBreak) {
                roundInCycle = 0
                next = .longBreak
            } else {
                next = .shortBreak
            }
        case .shortBreak, .longBreak:
            next = .focus
        }

        stopTicking()
        isRunning = false
        phase = next
        resetTimeForCurrentPhase()
        if autoStart { start() }
    }

    // MARK: - Feedback

    private func notifyPhaseEnd() {
        guard settings.soundAndHaptics else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        // Gentle built-in alert tone — no bundled audio asset needed.
        AudioServicesPlaySystemSound(1304)
    }

    // MARK: - Persistence

    private func persistSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: Self.settingsKey)
        }
    }

    private static func loadSettings() -> PomodoroSettings {
        guard
            let data = UserDefaults.standard.data(forKey: settingsKey),
            let decoded = try? JSONDecoder().decode(PomodoroSettings.self, from: data)
        else { return .default }
        return decoded
    }
}
