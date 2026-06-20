//
//  ToolDestinationView.swift
//  pzathy_tool
//
//  Maps a Tool's route to its screen. Unbuilt tools show a friendly placeholder.
//

import SwiftUI

struct ToolDestinationView: View {
    let tool: Tool
    @EnvironmentObject private var loc: LocalizationManager

    var body: some View {
        switch tool.route {
        case .musicConverter:
            MusicConverterView()
        case .comingSoon:
            ComingSoonView(tool: tool)
        }
    }
}

struct ComingSoonView: View {
    let tool: Tool
    @EnvironmentObject private var loc: LocalizationManager

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: tool.symbol)
                .font(.system(size: 52))
                .foregroundColor(AppColor.accent.opacity(0.6))
            Text(tool.name).font(.title3).fontWeight(.semibold)
            Text(tool.description)
                .font(.subheadline).foregroundColor(AppColor.secondaryText)
                .multilineTextAlignment(.center)
            Text(loc.t(.comingSoon).uppercased())
                .font(.caption).fontWeight(.bold)
                .padding(.horizontal, 14).padding(.vertical, 6)
                .background(AppColor.accent.opacity(0.15))
                .foregroundColor(AppColor.accent)
                .clipShape(Capsule())
                .padding(.top, 4)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.background.ignoresSafeArea())
        .navigationTitle(tool.name)
        .navigationBarTitleDisplayMode(.inline)
        .logPage("Coming Soon › \(tool.name)")
    }
}
