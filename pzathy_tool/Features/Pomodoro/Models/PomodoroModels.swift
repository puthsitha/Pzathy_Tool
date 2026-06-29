//
//  PomodoroModels.swift
//  pzathy_tool
//
//  Models for the Pomodoro Timer tool: the cycle phases and the user-tunable
//  settings (durations, rounds, behaviour) persisted as JSON in UserDefaults.
//

import Foundation

/// The three phases of a Pomodoro cycle.
enum PomodoroPhase: String, Codable, CaseIterable, Identifiable {
    case focus
    case shortBreak
    case longBreak

    var id: String { rawValue }

    /// Localized title key for the phase.
    var titleKey: LKey {
        switch self {
        case .focus:      return .focus
        case .shortBreak: return .shortBreak
        case .longBreak:  return .longBreak
        }
    }

    var symbol: String {
        switch self {
        case .focus:      return "brain.head.profile"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak:  return "figure.walk"
        }
    }

    var isBreak: Bool { self != .focus }
}

/// User-configurable Pomodoro settings, persisted as JSON in UserDefaults.
struct PomodoroSettings: Codable, Equatable {
    /// Focus session length, in minutes.
    var focusMinutes: Int
    /// Short break length, in minutes.
    var shortBreakMinutes: Int
    /// Long break length, in minutes.
    var longBreakMinutes: Int
    /// Number of focus rounds before a long break.
    var roundsBeforeLongBreak: Int
    /// Automatically start the next phase when one finishes.
    var autoStartNext: Bool
    /// Play a sound + haptic when a phase ends.
    var soundAndHaptics: Bool

    static let `default` = PomodoroSettings(
        focusMinutes: 25,
        shortBreakMinutes: 5,
        longBreakMinutes: 15,
        roundsBeforeLongBreak: 4,
        autoStartNext: false,
        soundAndHaptics: true
    )

    /// Duration (in seconds) for a given phase, clamped to at least one minute.
    func duration(for phase: PomodoroPhase) -> TimeInterval {
        let minutes: Int
        switch phase {
        case .focus:      minutes = focusMinutes
        case .shortBreak: minutes = shortBreakMinutes
        case .longBreak:  minutes = longBreakMinutes
        }
        return TimeInterval(max(1, minutes) * 60)
    }
}
