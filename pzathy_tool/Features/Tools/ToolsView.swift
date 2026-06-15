//
//  ToolsView.swift
//  pzathy_tool
//
//  Tab 2: browse tools by field → category → tool.
//

import SwiftUI

struct ToolsView: View {
    @EnvironmentObject private var loc: LocalizationManager
    @State private var search = ""

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredFields) { field in
                        NavigationLink(destination: FieldDetailView(field: field)) {
                            FieldCard(field: field)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle(loc.t(.tools))
            .searchable(text: $search, prompt: loc.t(.search))
        }
        .navigationViewStyle(.stack)
    }

    private var filteredFields: [ToolField] {
        guard !search.isEmpty else { return ToolsCatalog.fields }
        let q = search.lowercased()
        return ToolsCatalog.fields.compactMap { field in
            let matches = field.name.lowercased().contains(q) ||
                field.categories.contains { cat in
                    cat.name.lowercased().contains(q) ||
                    cat.tools.contains { $0.name.lowercased().contains(q) }
                }
            return matches ? field : nil
        }
    }
}

private struct FieldCard: View {
    let field: ToolField
    @EnvironmentObject private var loc: LocalizationManager

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(field.tint.opacity(0.18))
                    .frame(width: 56, height: 56)
                Image(systemName: field.symbol)
                    .font(.system(size: 24))
                    .foregroundColor(field.tint)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(field.name).font(.headline)
                Text("\(field.categories.count) \(loc.t(.categories)) · \(field.toolCount) \(loc.t(.tools))")
                    .font(.caption).foregroundColor(AppColor.secondaryText)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(AppColor.tertiaryText)
        }
        .padding(16)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct FieldDetailView: View {
    let field: ToolField
    @EnvironmentObject private var loc: LocalizationManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ForEach(field.categories) { category in
                    VStack(alignment: .leading, spacing: 12) {
                        Label(category.name, systemImage: category.symbol)
                            .font(.headline)
                            .foregroundColor(AppColor.primaryText)

                        VStack(spacing: 10) {
                            ForEach(category.tools) { tool in
                                NavigationLink(destination: ToolDestinationView(tool: tool)) {
                                    ToolRow(tool: tool)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(AppColor.background.ignoresSafeArea())
        .navigationTitle(field.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ToolRow: View {
    let tool: Tool
    @EnvironmentObject private var loc: LocalizationManager

    private var title: String { tool.titleKey.map { loc.t($0) } ?? tool.name }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(AppColor.accent.opacity(0.15)).frame(width: 44, height: 44)
                Image(systemName: tool.symbol).foregroundColor(AppColor.accent)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(title).font(.subheadline).fontWeight(.medium)
                    if !tool.isAvailable {
                        Text(loc.t(.comingSoon))
                            .font(.caption2)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(AppColor.tertiaryText.opacity(0.15))
                            .foregroundColor(AppColor.secondaryText)
                            .clipShape(Capsule())
                    }
                }
                Text(tool.description).font(.caption).foregroundColor(AppColor.secondaryText)
                    .lineLimit(2)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundColor(AppColor.tertiaryText)
        }
        .padding(12)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .opacity(tool.isAvailable ? 1 : 0.7)
    }
}
