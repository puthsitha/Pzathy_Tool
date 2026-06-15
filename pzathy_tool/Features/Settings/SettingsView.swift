//
//  SettingsView.swift
//  pzathy_tool
//
//  Tab 3: profile header, language, theme, background playback, logout.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var loc: LocalizationManager
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var player: AudioPlayerManager

    @State private var showLogoutConfirm = false

    var body: some View {
        NavigationView {
            List {
                profileSection
                preferencesSection
                aboutSection
                logoutSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle(loc.t(.settings))
        }
        .navigationViewStyle(.stack)
        .confirmationDialog(loc.t(.logoutConfirm), isPresented: $showLogoutConfirm, titleVisibility: .visible) {
            Button(loc.t(.logout), role: .destructive) { auth.logout() }
            Button(loc.t(.cancel), role: .cancel) {}
        }
    }

    // MARK: - Profile

    private var profileSection: some View {
        Section {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [AppColor.accent, AppColor.accentDeep],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 64, height: 64)
                    Image(systemName: auth.currentUser?.avatarSymbol ?? "person.fill")
                        .font(.title2).foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(auth.currentUser?.displayName ?? "—")
                        .font(.headline)
                    Text(auth.currentUser?.role ?? "")
                        .font(.subheadline).foregroundColor(AppColor.secondaryText)
                    Text("@\(auth.currentUser?.username ?? "")")
                        .font(.caption).foregroundColor(AppColor.tertiaryText)
                }
                Spacer()
            }
            .padding(.vertical, 6)
        }
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        Section(loc.t(.preferences)) {
            // Language
            Picker(selection: $loc.language) {
                ForEach(AppLanguage.allCases) { lang in
                    Text("\(lang.flag)  \(lang.displayName)").tag(lang)
                }
            } label: {
                Label(loc.t(.language), systemImage: "globe")
            }

            // Theme
            Picker(selection: $theme.theme) {
                ForEach(AppTheme.allCases) { t in
                    Label(loc.t(t.localizationKey), systemImage: t.symbol).tag(t)
                }
            } label: {
                Label(loc.t(.theme), systemImage: "paintbrush")
            }

            // Background playback (also surfaced here for convenience)
            Toggle(isOn: $player.backgroundPlaybackEnabled) {
                Label(loc.t(.backgroundPlayback), systemImage: "speaker.wave.2")
            }
            .tint(AppColor.accent)
        }
    }

    private var aboutSection: some View {
        Section(loc.t(.about)) {
            HStack {
                Label(loc.t(.version), systemImage: "info.circle")
                Spacer()
                Text(appVersion).foregroundColor(AppColor.secondaryText)
            }
        }
    }

    private var logoutSection: some View {
        Section {
            Button(role: .destructive) {
                showLogoutConfirm = true
            } label: {
                Label(loc.t(.logout), systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}
