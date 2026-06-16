//
//  pzathy_toolApp.swift
//  pzathy_tool
//
//  Created by Puthsitha Moeurn on 15/6/26.
//

import SwiftUI

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
        }
    }
}
