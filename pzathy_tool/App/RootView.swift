//
//  RootView.swift
//  pzathy_tool
//
//  Decides between login and the main app, and applies the chosen theme.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        Group {
            if auth.isAuthenticated {
                MainTabView()
                    .transition(.opacity)
            } else {
                LoginView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: auth.isAuthenticated)
        .preferredColorScheme(theme.theme.colorScheme)
    }
}
