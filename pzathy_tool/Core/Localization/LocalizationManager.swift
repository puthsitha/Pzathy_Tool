//
//  LocalizationManager.swift
//  pzathy_tool
//
//  Lightweight runtime localization (English / Khmer) that switches instantly
//  without an app restart. Strings live in code so language can flip live.
//

import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case khmer   = "km"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .khmer:   return "ខ្មែរ"
        }
    }

    var flag: String {
        switch self {
        case .english: return "🇬🇧"
        case .khmer:   return "🇰🇭"
        }
    }
}

/// All localizable string keys. Adding a key here forces both translations.
enum LKey: String {
    // Tabs
    case home, tools, settings

    // General
    case appName, cancel, done, save, search, close, retry, comingSoon, all

    // Auth
    case loginTitle, loginSubtitle, username, password, signIn
    case invalidCredentials, demoAccounts, tapToFill

    // Home
    case welcomeBack, quickAccess, recentlyPlayed, featuredTools, noRecent

    // Tools
    case toolsTitle, fields, categories, openTool

    // Settings
    case account, language, theme, themeSystem, themeLight, themeDark
    case logout, logoutConfirm, preferences, about, version

    // Music converter
    case musicConverter, musicConverterDesc
    case pasteYoutubeLink, convert, converting, addToLibrary
    case library, playlists, songs, nowPlaying, queue
    case download, downloaded, downloading, share, play, pause, stop
    case createPlaylist, playlistName, newPlaylist, emptyLibrary, emptyLibraryHint
    case backgroundPlayback, backgroundPlaybackHint
    case artist, unknownArtist, removeFromLibrary, addToPlaylist
    case convertError, invalidLink
}

final class LocalizationManager: ObservableObject {
    private static let storageKey = "app.language"

    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: Self.storageKey) }
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: Self.storageKey)
        self.language = AppLanguage(rawValue: raw ?? "") ?? .english
    }

    /// Translate a key for the current language (falls back to English, then the raw key).
    func t(_ key: LKey) -> String {
        Self.table[language]?[key] ?? Self.table[.english]?[key] ?? key.rawValue
    }

    // MARK: - Translation table

    private static let table: [AppLanguage: [LKey: String]] = [
        .english: english,
        .khmer:   khmer
    ]

    private static let english: [LKey: String] = [
        .home: "Home", .tools: "Tools", .settings: "Settings",
        .appName: "Pzathy Tool",
        .cancel: "Cancel", .done: "Done", .save: "Save", .search: "Search",
        .close: "Close", .retry: "Retry", .comingSoon: "Coming soon", .all: "All",

        .loginTitle: "Welcome to Pzathy Tool",
        .loginSubtitle: "Your everyday multi-tool kit",
        .username: "Username", .password: "Password", .signIn: "Sign In",
        .invalidCredentials: "Incorrect username or password",
        .demoAccounts: "Demo accounts", .tapToFill: "Tap to fill",

        .welcomeBack: "Welcome back", .quickAccess: "Quick access",
        .recentlyPlayed: "Recently played", .featuredTools: "Featured tools",
        .noRecent: "Nothing played yet",

        .toolsTitle: "Tools", .fields: "Fields", .categories: "Categories",
        .openTool: "Open",

        .account: "Account", .language: "Language", .theme: "Theme",
        .themeSystem: "System", .themeLight: "Light", .themeDark: "Dark",
        .logout: "Log out", .logoutConfirm: "Are you sure you want to log out?",
        .preferences: "Preferences", .about: "About", .version: "Version",

        .musicConverter: "Music Converter",
        .musicConverterDesc: "Convert YouTube links to audio you can play, save and share.",
        .pasteYoutubeLink: "Paste a YouTube link",
        .convert: "Convert", .converting: "Converting…", .addToLibrary: "Add to library",
        .library: "Library", .playlists: "Playlists", .songs: "Songs",
        .nowPlaying: "Now Playing", .queue: "Queue",
        .download: "Download", .downloaded: "Downloaded", .downloading: "Downloading…",
        .share: "Share", .play: "Play", .pause: "Pause", .stop: "Stop",
        .createPlaylist: "Create playlist", .playlistName: "Playlist name",
        .newPlaylist: "New Playlist",
        .emptyLibrary: "Your library is empty",
        .emptyLibraryHint: "Convert a YouTube link to add your first track.",
        .backgroundPlayback: "Background playback",
        .backgroundPlaybackHint: "Keep playing when the app is in the background.",
        .artist: "Artist", .unknownArtist: "Unknown artist",
        .removeFromLibrary: "Remove from library", .addToPlaylist: "Add to playlist",
        .convertError: "Couldn't convert that link. Please try again.",
        .invalidLink: "Please paste a valid YouTube link."
    ]

    private static let khmer: [LKey: String] = [
        .home: "ទំព័រដើម", .tools: "ឧបករណ៍", .settings: "ការកំណត់",
        .appName: "Pzathy Tool",
        .cancel: "បោះបង់", .done: "រួចរាល់", .save: "រក្សាទុក", .search: "ស្វែងរក",
        .close: "បិទ", .retry: "ព្យាយាមម្ដងទៀត", .comingSoon: "នឹងមកដល់ឆាប់ៗ", .all: "ទាំងអស់",

        .loginTitle: "សូមស្វាគមន៍មកកាន់ Pzathy Tool",
        .loginSubtitle: "ឧបករណ៍ប្រើប្រាស់ប្រចាំថ្ងៃរបស់អ្នក",
        .username: "ឈ្មោះអ្នកប្រើ", .password: "ពាក្យសម្ងាត់", .signIn: "ចូល",
        .invalidCredentials: "ឈ្មោះអ្នកប្រើ ឬ ពាក្យសម្ងាត់មិនត្រឹមត្រូវ",
        .demoAccounts: "គណនីសាកល្បង", .tapToFill: "ចុចដើម្បីបំពេញ",

        .welcomeBack: "សូមស្វាគមន៍ការត្រឡប់មកវិញ", .quickAccess: "ចូលប្រើរហ័ស",
        .recentlyPlayed: "បានចាក់ថ្មីៗ", .featuredTools: "ឧបករណ៍ពិសេស",
        .noRecent: "មិនទាន់មានការចាក់ទេ",

        .toolsTitle: "ឧបករណ៍", .fields: "វិស័យ", .categories: "ប្រភេទ",
        .openTool: "បើក",

        .account: "គណនី", .language: "ភាសា", .theme: "រូបរាង",
        .themeSystem: "តាមប្រព័ន្ធ", .themeLight: "ភ្លឺ", .themeDark: "ងងឹត",
        .logout: "ចាកចេញ", .logoutConfirm: "តើអ្នកប្រាកដថាចង់ចាកចេញមែនទេ?",
        .preferences: "ចំណូលចិត្ត", .about: "អំពី", .version: "កំណែ",

        .musicConverter: "កម្មវិធីបម្លែងតន្ត្រី",
        .musicConverterDesc: "បម្លែងតំណ YouTube ទៅជាសំឡេងដែលអ្នកអាចចាក់ រក្សាទុក និងចែករំលែក។",
        .pasteYoutubeLink: "បិទភ្ជាប់តំណ YouTube",
        .convert: "បម្លែង", .converting: "កំពុងបម្លែង…", .addToLibrary: "បន្ថែមទៅបណ្ណាល័យ",
        .library: "បណ្ណាល័យ", .playlists: "បញ្ជីចាក់", .songs: "បទចម្រៀង",
        .nowPlaying: "កំពុងចាក់", .queue: "ជួរ",
        .download: "ទាញយក", .downloaded: "បានទាញយក", .downloading: "កំពុងទាញយក…",
        .share: "ចែករំលែក", .play: "ចាក់", .pause: "ផ្អាក", .stop: "បញ្ឈប់",
        .createPlaylist: "បង្កើតបញ្ជីចាក់", .playlistName: "ឈ្មោះបញ្ជីចាក់",
        .newPlaylist: "បញ្ជីចាក់ថ្មី",
        .emptyLibrary: "បណ្ណាល័យរបស់អ្នកទទេ",
        .emptyLibraryHint: "បម្លែងតំណ YouTube ដើម្បីបន្ថែមបទដំបូងរបស់អ្នក។",
        .backgroundPlayback: "ការចាក់ផ្ទៃខាងក្រោយ",
        .backgroundPlaybackHint: "បន្តចាក់ពេលកម្មវិធីនៅផ្ទៃខាងក្រោយ។",
        .artist: "សិល្បករ", .unknownArtist: "សិល្បករមិនស្គាល់",
        .removeFromLibrary: "លុបចេញពីបណ្ណាល័យ", .addToPlaylist: "បន្ថែមទៅបញ្ជីចាក់",
        .convertError: "មិនអាចបម្លែងតំណនេះបានទេ។ សូមព្យាយាមម្ដងទៀត។",
        .invalidLink: "សូមបិទភ្ជាប់តំណ YouTube ត្រឹមត្រូវ។"
    ]
}
