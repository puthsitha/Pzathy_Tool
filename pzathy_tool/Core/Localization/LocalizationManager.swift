//
//  LocalizationManager.swift
//  pzathy_tool
//
//  Lightweight runtime localization (English / Khmer) that switches instantly
//  without an app restart. Strings live in code so language can flip live.
//

import SwiftUI
import Combine

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

    // Shortcuts
    case shortcutMusicConverterTitle, shortcutMusicConverterSubtitle
    case shortcutSpinnerTitle, shortcutSpinnerSubtitle
    case shortcutCurrencyTitle, shortcutCurrencySubtitle
    case shortcutSettingsTitle, shortcutSettingsSubtitle

    // Widget
    case widgetTitle, widgetMusic, widgetSpinner, widgetCurrency, widgetSettings

    // Music converter
    case musicConverter, musicConverterDesc
    case pasteYoutubeLink, convert, converting, addToLibrary
    case library, playlists, songs, nowPlaying, queue
    case download, downloaded, downloading, share, play, pause, stop
    case shuffle, repeatTrack
    case createPlaylist, playlistName, newPlaylist, emptyLibrary, emptyLibraryHint
    case editPlaylist, renamePlaylist, deletePlaylist, deletePlaylistConfirm
    case changeImage, removeImage, coverImage
    case backgroundPlayback, backgroundPlaybackHint
    case artist, unknownArtist, removeFromLibrary, addToPlaylist
    case convertError, convertErrorTitle, invalidLink

    // Pomodoro timer
    case pomodoroTimer, pomodoroDesc
    case focus, shortBreak, longBreak
    case startTimer, pauseTimer, resumeTimer, resetTimer, skip
    case timerSettings, focusLength, shortBreakLength, longBreakLength
    case roundsBeforeLongBreak, autoStartNext, soundAndHaptics
    case sessionsCompleted, minutesShort

    // Utilities — converters
    case unitConverter, currency
    case from, to
    case unitLength, unitMass, unitTemperature, unitVolume, unitSpeed, unitArea
    case selectCurrency, lastUpdated, ratesError

    // Spinner
    case spinner, spinnerDesc, spin, spinAgain
    case addItem, itemsHeader, clearAll
    case removeAfterSpin, celebrationSound, winnerTitle, spinNeedItems

    // Connectivity
    case noInternetTitle, noInternetMessage, offlineBanner, ok
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
        .appName: "Pzathy Tools",
        .cancel: "Cancel", .done: "Done", .save: "Save", .search: "Search",
        .close: "Close", .retry: "Retry", .comingSoon: "Coming soon", .all: "All",

        .loginTitle: "Welcome to Pzathy Tools",
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
        .shortcutMusicConverterTitle: "Music Converter",
        .shortcutMusicConverterSubtitle: "Open the music converter",
        .shortcutSpinnerTitle: "Spinner",
        .shortcutSpinnerSubtitle: "Open the spinner tool",
        .shortcutCurrencyTitle: "Currency",
        .shortcutCurrencySubtitle: "Open currency conversion",
        .shortcutSettingsTitle: "Settings",
        .shortcutSettingsSubtitle: "Open app settings",
        .widgetTitle: "Pzathy Tools",
        .widgetMusic: "Music",
        .widgetSpinner: "Spinner",
        .widgetCurrency: "Currency",
        .widgetSettings: "Settings",
        .library: "Library", .playlists: "Playlists", .songs: "Songs",
        .nowPlaying: "Now Playing", .queue: "Queue",
        .download: "Download", .downloaded: "Downloaded", .downloading: "Downloading…",
        .share: "Share", .play: "Play", .pause: "Pause", .stop: "Stop",
        .shuffle: "Shuffle", .repeatTrack: "Repeat",
        .createPlaylist: "Create playlist", .playlistName: "Playlist name",
        .newPlaylist: "New Playlist",
        .editPlaylist: "Edit playlist", .renamePlaylist: "Rename",
        .deletePlaylist: "Delete playlist",
        .deletePlaylistConfirm: "This playlist will be deleted. Your songs stay in your library.",
        .changeImage: "Change image", .removeImage: "Remove image",
        .coverImage: "Cover image",
        .emptyLibrary: "Your library is empty",
        .emptyLibraryHint: "Convert a YouTube link to add your first track.",
        .backgroundPlayback: "Background playback",
        .backgroundPlaybackHint: "Keep playing when the app is in the background.",
        .artist: "Artist", .unknownArtist: "Unknown artist",
        .removeFromLibrary: "Remove from library", .addToPlaylist: "Add to playlist",
        .convertError: "Couldn't convert that link. Please try again.",
        .convertErrorTitle: "Conversion Failed",
        .invalidLink: "Please paste a valid YouTube link.",

        .pomodoroTimer: "Pomodoro Timer",
        .pomodoroDesc: "Focus in timed sessions with short and long breaks.",
        .focus: "Focus", .shortBreak: "Short Break", .longBreak: "Long Break",
        .startTimer: "Start", .pauseTimer: "Pause", .resumeTimer: "Resume",
        .resetTimer: "Reset", .skip: "Skip",
        .timerSettings: "Timer Settings",
        .focusLength: "Focus length", .shortBreakLength: "Short break",
        .longBreakLength: "Long break",
        .roundsBeforeLongBreak: "Rounds before long break",
        .autoStartNext: "Auto-start next session",
        .soundAndHaptics: "Sound & vibration",
        .sessionsCompleted: "Sessions completed", .minutesShort: "min",

        .unitConverter: "Unit Converter", .currency: "Currency",
        .from: "From", .to: "To",
        .unitLength: "Length", .unitMass: "Weight", .unitTemperature: "Temperature",
        .unitVolume: "Volume", .unitSpeed: "Speed", .unitArea: "Area",
        .selectCurrency: "Select currency", .lastUpdated: "Updated",
        .ratesError: "Couldn't load exchange rates.",

        .spinner: "Spinner",
        .spinnerDesc: "Add choices and spin to pick one.",
        .spin: "Spin", .spinAgain: "Spin again",
        .addItem: "Add an item", .itemsHeader: "Items", .clearAll: "Clear all",
        .removeAfterSpin: "Remove winner after spin",
        .celebrationSound: "Celebration sound",
        .winnerTitle: "Winner", .spinNeedItems: "Add at least 2 items to spin.",

        .noInternetTitle: "No Internet Connection",
        .noInternetMessage: "Please check your connection and try again.",
        .offlineBanner: "You're offline",
        .ok: "OK"
    ]

    private static let khmer: [LKey: String] = [
        .home: "ទំព័រដើម", .tools: "ឧបករណ៍", .settings: "ការកំណត់",
        .appName: "Pzathy Tools",
        .cancel: "បោះបង់", .done: "រួចរាល់", .save: "រក្សាទុក", .search: "ស្វែងរក",
        .close: "បិទ", .retry: "ព្យាយាមម្ដងទៀត", .comingSoon: "នឹងមកដល់ឆាប់ៗ", .all: "ទាំងអស់",

        .loginTitle: "សូមស្វាគមន៍មកកាន់ Pzathy Tools",
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
        .shuffle: "ច្របល់", .repeatTrack: "ចាក់ឡើងវិញ",
        .createPlaylist: "បង្កើតបញ្ជីចាក់", .playlistName: "ឈ្មោះបញ្ជីចាក់",
        .newPlaylist: "បញ្ជីចាក់ថ្មី",
        .editPlaylist: "កែប្រែបញ្ជីចាក់", .renamePlaylist: "ប្ដូរឈ្មោះ",
        .deletePlaylist: "លុបបញ្ជីចាក់",
        .deletePlaylistConfirm: "បញ្ជីចាក់នេះនឹងត្រូវលុប។ បទចម្រៀងរបស់អ្នកនៅតែមាននៅក្នុងបណ្ណាល័យ។",
        .changeImage: "ប្ដូររូបភាព", .removeImage: "លុបរូបភាព",
        .coverImage: "រូបភាពគម្រប",
        .emptyLibrary: "បណ្ណាល័យរបស់អ្នកទទេ",
        .emptyLibraryHint: "បម្លែងតំណ YouTube ដើម្បីបន្ថែមបទដំបូងរបស់អ្នក។",
        .backgroundPlayback: "ការចាក់ផ្ទៃខាងក្រោយ",
        .backgroundPlaybackHint: "បន្តចាក់ពេលកម្មវិធីនៅផ្ទៃខាងក្រោយ។",
        .artist: "សិល្បករ", .unknownArtist: "សិល្បករមិនស្គាល់",
        .removeFromLibrary: "លុបចេញពីបណ្ណាល័យ", .addToPlaylist: "បន្ថែមទៅបញ្ជីចាក់",
        .convertError: "មិនអាចបម្លែងតំណនេះបានទេ។ សូមព្យាយាមម្ដងទៀត។",
        .convertErrorTitle: "ការបម្លែងបរាជ័យ",
        .invalidLink: "សូមបិទភ្ជាប់តំណ YouTube ត្រឹមត្រូវ។",
        .shortcutMusicConverterTitle: "កម្មវិធីបម្លែងតន្ត្រី",
        .shortcutMusicConverterSubtitle: "បើកកម្មវិធីបម្លែងតន្ត្រី",
        .shortcutSpinnerTitle: "កង់បង្វិល",
        .shortcutSpinnerSubtitle: "បើកឧបករណ៍កង់បង្វិល",
        .shortcutCurrencyTitle: "រូបិយប័ណ្ណ",
        .shortcutCurrencySubtitle: "បើកការបម្លែងរូបិយប័ណ្ណ",
        .shortcutSettingsTitle: "ការកំណត់",
        .shortcutSettingsSubtitle: "បើកការកំណត់កម្មវិធី",
        .widgetTitle: "Pzathy Tools",
        .widgetMusic: "តន្ត្រី",
        .widgetSpinner: "កង់បង្វិល",
        .widgetCurrency: "រូបិយប័ណ្ណ",
        .widgetSettings: "ការកំណត់",

        .pomodoroTimer: "នាឡិកា Pomodoro",
        .pomodoroDesc: "ផ្ដោតការងារតាមវគ្គ ជាមួយការសម្រាកខ្លី និងវែង។",
        .focus: "ផ្ដោតអារម្មណ៍", .shortBreak: "សម្រាកខ្លី", .longBreak: "សម្រាកវែង",
        .startTimer: "ចាប់ផ្ដើម", .pauseTimer: "ផ្អាក", .resumeTimer: "បន្ត",
        .resetTimer: "កំណត់ឡើងវិញ", .skip: "រំលង",
        .timerSettings: "ការកំណត់នាឡិកា",
        .focusLength: "រយៈពេលផ្ដោតអារម្មណ៍", .shortBreakLength: "សម្រាកខ្លី",
        .longBreakLength: "សម្រាកវែង",
        .roundsBeforeLongBreak: "ចំនួនវគ្គមុនសម្រាកវែង",
        .autoStartNext: "ចាប់ផ្ដើមវគ្គបន្ទាប់ដោយស្វ័យប្រវត្តិ",
        .soundAndHaptics: "សំឡេង និងរំញ័រ",
        .sessionsCompleted: "វគ្គដែលបានបញ្ចប់", .minutesShort: "នាទី",

        .unitConverter: "កម្មវិធីបម្លែងឯកតា", .currency: "រូបិយប័ណ្ណ",
        .from: "ពី", .to: "ទៅ",
        .unitLength: "ប្រវែង", .unitMass: "ទម្ងន់", .unitTemperature: "សីតុណ្ហភាព",
        .unitVolume: "មាឌ", .unitSpeed: "ល្បឿន", .unitArea: "ផ្ទៃក្រឡា",
        .selectCurrency: "ជ្រើសរើសរូបិយប័ណ្ណ", .lastUpdated: "បានធ្វើបច្ចុប្បន្នភាព",
        .ratesError: "មិនអាចទាញយកអត្រាប្ដូរប្រាក់បានទេ។",

        .spinner: "កង់បង្វិល",
        .spinnerDesc: "បន្ថែមជម្រើស រួចបង្វិលដើម្បីជ្រើសរើសមួយ។",
        .spin: "បង្វិល", .spinAgain: "បង្វិលម្ដងទៀត",
        .addItem: "បន្ថែមធាតុ", .itemsHeader: "ធាតុ", .clearAll: "សម្អាតទាំងអស់",
        .removeAfterSpin: "លុបអ្នកឈ្នះក្រោយបង្វិល",
        .celebrationSound: "សំឡេងអបអរ",
        .winnerTitle: "អ្នកឈ្នះ", .spinNeedItems: "បន្ថែមយ៉ាងតិច ២ ធាតុដើម្បីបង្វិល។",

        .noInternetTitle: "គ្មានការតភ្ជាប់អ៊ីនធឺណិត",
        .noInternetMessage: "សូមពិនិត្យការតភ្ជាប់របស់អ្នក រួចព្យាយាមម្ដងទៀត។",
        .offlineBanner: "អ្នកកំពុងនៅក្រៅបណ្ដាញ",
        .ok: "យល់ព្រម"
    ]
}
