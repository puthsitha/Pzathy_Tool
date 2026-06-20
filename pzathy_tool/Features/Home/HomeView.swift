//
//  HomeView.swift
//  pzathy_tool
//
//  Tab 1: dashboard with a greeting, quick access to live tools, and recents.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var loc: LocalizationManager
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var player: AudioPlayerManager

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    greeting
                    quickAccess
                    featured
                    recents
                }
                .padding(16)
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle(loc.t(.home))
        }
        .navigationViewStyle(.stack)
        .logPage("Home")
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(loc.t(.welcomeBack))
                .font(.subheadline).foregroundColor(AppColor.secondaryText)
            Text(auth.currentUser?.displayName ?? loc.t(.appName))
                .font(.title).fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            LinearGradient(colors: [AppColor.accent.opacity(0.22), AppColor.accentDeep.opacity(0.12)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var quickAccess: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(loc.t(.quickAccess)).font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ToolsCatalog.availableTools) { tool in
                        NavigationLink(destination: ToolDestinationView(tool: tool)) {
                            quickCard(tool)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func quickCard(_ tool: Tool) -> some View {
        let title = tool.titleKey.map { loc.t($0) } ?? tool.name
        return VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Circle().fill(AppColor.accent.opacity(0.18)).frame(width: 46, height: 46)
                Image(systemName: tool.symbol).foregroundColor(AppColor.accent).font(.title3)
            }
            Text(title).font(.subheadline).fontWeight(.semibold).lineLimit(1)
            Text(tool.description).font(.caption2).foregroundColor(AppColor.secondaryText)
                .lineLimit(2)
        }
        .padding(14)
        .frame(width: 170, height: 130, alignment: .topLeading)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var featured: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(loc.t(.featuredTools)).font(.headline)
            NavigationLink(destination: ToolDestinationView(tool: musicTool)) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(LinearGradient(colors: [AppColor.accent, AppColor.accentDeep],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 60, height: 60)
                        Image(systemName: "music.note").font(.title2).foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(loc.t(.musicConverter)).font(.headline)
                        Text(loc.t(.musicConverterDesc))
                            .font(.caption).foregroundColor(AppColor.secondaryText).lineLimit(2)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundColor(AppColor.tertiaryText)
                }
                .padding(16)
                .background(AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var recents: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(loc.t(.recentlyPlayed)).font(.headline)
            if library.tracks.isEmpty {
                Text(loc.t(.noRecent))
                    .font(.subheadline).foregroundColor(AppColor.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(recentTracks) { track in
                        TrackRowView(track: track) { player.play(track, in: library.tracks) }
                            .padding(.horizontal, 12)
                            .background(AppColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
        }
    }

    private var recentTracks: [Track] {
        Array(library.tracks.sorted { $0.addedAt > $1.addedAt }.prefix(4))
    }

    private var musicTool: Tool {
        ToolsCatalog.availableTools.first { $0.route == .musicConverter }
            ?? ToolsCatalog.availableTools[0]
    }
}
