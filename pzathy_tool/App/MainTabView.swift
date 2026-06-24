//
//  MainTabView.swift
//  pzathy_tool
//
//  The 3-tab shell with a floating mini-player above the tab bar.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var loc: LocalizationManager
    @EnvironmentObject private var player: AudioPlayerManager
    @State private var selection = 0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                TabView(selection: $selection) {
                    HomeView()
                        .tabItem { Label(loc.t(.home), systemImage: "house.fill") }
                        .tag(0)
                    ToolsView()
                        .tabItem { Label(loc.t(.tools), systemImage: "square.grid.2x2.fill") }
                        .tag(1)
                    SettingsView()
                        .tabItem { Label(loc.t(.settings), systemImage: "gearshape.fill") }
                        .tag(2)
                }
                .tint(AppColor.accent)

                // Floating now-playing bar + (hidden) ad slot, lifted above the tab bar.
                VStack(spacing: 0) {
                    AdBannerView()
                    PlayerBarView()
                }
                .padding(.bottom, 49 + geo.safeAreaInsets.bottom)
                // Keep the bar pinned above the tab bar; don't let the keyboard
                // push it up to the top of the screen.
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .animation(.easeInOut(duration: 0.2), value: player.isActive)
            }
        }
    }
}
