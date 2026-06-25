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
    @State private var showSplash = true

    var body: some View {
        ZStack {
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

            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .preferredColorScheme(theme.theme.colorScheme)
        .task {
            // Hold the branded splash briefly, then reveal the app.
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            withAnimation(.easeInOut(duration: 0.45)) { showSplash = false }
        }
    }
}
