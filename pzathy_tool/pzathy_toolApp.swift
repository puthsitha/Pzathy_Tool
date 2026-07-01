//
//  pzathy_toolApp.swift
//  pzathy_tool
//
//  Created by Puthsitha Moeurn on 15/6/26.
//

import SwiftUI
import UIKit

@main
struct pzathy_toolApp: App {
    // App-wide shared state. Owned here so it survives view rebuilds.
    @StateObject private var auth = AuthManager()
    @StateObject private var theme = ThemeManager()
    @StateObject private var localization = LocalizationManager()
    @StateObject private var library = LibraryStore()
    @StateObject private var player = AudioPlayerManager()
    @StateObject private var ads = AdsManager()
    @StateObject private var network = NetworkMonitor()
    @StateObject private var router = AppRouter()
    @UIApplicationDelegateAdaptor(AppShortcutDelegate.self) private var appDelegate

    init() {
        _appDelegate.wrappedValue.router = router
    }

    private func makeShortcutItems() -> [UIApplicationShortcutItem] {
        [
            UIApplicationShortcutItem(
                type: "com.puthsitha.pzathy-tool.musicConverter",
                localizedTitle: localization.t(.shortcutMusicConverterTitle),
                localizedSubtitle: localization.t(.shortcutMusicConverterSubtitle),
                icon: UIApplicationShortcutIcon(type: .play)
            ),
            UIApplicationShortcutItem(
                type: "com.puthsitha.pzathy-tool.spinner",
                localizedTitle: localization.t(.shortcutSpinnerTitle),
                localizedSubtitle: localization.t(.shortcutSpinnerSubtitle),
                icon: UIApplicationShortcutIcon(type: .shuffle)
            ),
            UIApplicationShortcutItem(
                type: "com.puthsitha.pzathy-tool.currency",
                localizedTitle: localization.t(.shortcutCurrencyTitle),
                localizedSubtitle: localization.t(.shortcutCurrencySubtitle),
                icon: UIApplicationShortcutIcon(type: .compose)
            ),
            UIApplicationShortcutItem(
                type: "com.puthsitha.pzathy-tool.settings",
                localizedTitle: localization.t(.shortcutSettingsTitle),
                localizedSubtitle: localization.t(.shortcutSettingsSubtitle),
                icon: UIApplicationShortcutIcon(type: .home)
            )
        ]
    }

    private func updateShortcutItems() {
        UIApplication.shared.shortcutItems = makeShortcutItems()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(theme)
                .environmentObject(localization)
                .environmentObject(library)
                .environmentObject(player)
                .environmentObject(ads)
                .environmentObject(network)
                .environmentObject(router)
                .onAppear {
                    // Let the player backfill durations into the library when it
                    // resolves a precise value during playback.
                    player.onDurationResolved = { [weak library] id, duration in
                        library?.updateDuration(duration, forTrackID: id)
                    }
                    updateShortcutItems()

                    // A shortcut tapped while the app was fully terminated arrives
                    // via launchOptions, not performActionFor, so route it now.
                    if let item = appDelegate.pendingShortcutItem,
                       let action = AppShortcutAction(shortcutItem: item) {
                        router.open(shortcut: action)
                        appDelegate.pendingShortcutItem = nil
                    }
                }
                .onChange(of: localization.language) { _ in
                    updateShortcutItems()
                }
                .onOpenURL { url in
                    router.open(url: url)
                }
        }
    }
}
