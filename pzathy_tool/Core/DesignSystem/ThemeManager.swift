//
//  ThemeManager.swift
//  pzathy_tool
//
//  Controls the app appearance (light / dark / system) and persists the choice.
//

import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    /// Localization key for the option label.
    var localizationKey: LKey {
        switch self {
        case .system: return .themeSystem
        case .light:  return .themeLight
        case .dark:   return .themeDark
        }
    }

    var symbol: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max"
        case .dark:   return "moon.stars"
        }
    }

    /// The SwiftUI color scheme to force, or nil to follow the system.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

final class ThemeManager: ObservableObject {
    private static let storageKey = "app.theme"

    @Published var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: Self.storageKey) }
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: Self.storageKey)
        self.theme = AppTheme(rawValue: raw ?? "") ?? .system
    }
}
