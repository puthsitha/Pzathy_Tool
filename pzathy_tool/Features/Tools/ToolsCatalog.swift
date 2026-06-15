//
//  ToolsCatalog.swift
//  pzathy_tool
//
//  The catalog hierarchy: Field → Category → Tool.
//  Add new tools here; only `route`d tools are interactive, the rest show
//  "coming soon" so the structure is visible while the app grows.
//

import SwiftUI

enum ToolRoute: Equatable {
    case musicConverter
    case comingSoon
}

struct Tool: Identifiable {
    let id: String
    let name: String
    let titleKey: LKey?     // optional localized title (overrides name)
    let description: String
    let symbol: String
    let route: ToolRoute

    var isAvailable: Bool { route != .comingSoon }

    init(id: String, name: String, titleKey: LKey? = nil, description: String,
         symbol: String, route: ToolRoute = .comingSoon) {
        self.id = id; self.name = name; self.titleKey = titleKey
        self.description = description; self.symbol = symbol; self.route = route
    }
}

struct ToolCategory: Identifiable {
    let id: String
    let name: String
    let symbol: String
    let tools: [Tool]
}

struct ToolField: Identifiable {
    let id: String
    let name: String
    let symbol: String
    let tint: Color
    let categories: [ToolCategory]

    var toolCount: Int { categories.reduce(0) { $0 + $1.tools.count } }
}

enum ToolsCatalog {
    static let fields: [ToolField] = [
        ToolField(
            id: "media", name: "Media", symbol: "play.rectangle.on.rectangle",
            tint: AppColor.accent,
            categories: [
                ToolCategory(id: "audio", name: "Audio", symbol: "waveform", tools: [
                    Tool(id: "music_converter",
                         name: "Music Converter", titleKey: .musicConverter,
                         description: "YouTube link → playable MP3 you can save & share.",
                         symbol: "music.note", route: .musicConverter),
                    Tool(id: "audio_trim", name: "Audio Trimmer",
                         description: "Cut and trim audio clips.", symbol: "scissors")
                ]),
                ToolCategory(id: "video", name: "Video", symbol: "film", tools: [
                    Tool(id: "video_compress", name: "Video Compressor",
                         description: "Shrink video file size.", symbol: "arrow.down.right.and.arrow.up.left")
                ])
            ]
        ),
        ToolField(
            id: "productivity", name: "Productivity", symbol: "checklist",
            tint: AppColor.accentDeep,
            categories: [
                ToolCategory(id: "documents", name: "Documents", symbol: "doc.text", tools: [
                    Tool(id: "pdf_tools", name: "PDF Toolkit",
                         description: "Merge, split and compress PDFs.", symbol: "doc.on.doc"),
                    Tool(id: "scanner", name: "Doc Scanner",
                         description: "Scan documents with your camera.", symbol: "doc.viewfinder")
                ]),
                ToolCategory(id: "time", name: "Time", symbol: "clock", tools: [
                    Tool(id: "pomodoro", name: "Pomodoro Timer",
                         description: "Focus sessions and breaks.", symbol: "timer")
                ])
            ]
        ),
        ToolField(
            id: "developer", name: "Developer", symbol: "chevron.left.forwardslash.chevron.right",
            tint: AppColor.accent,
            categories: [
                ToolCategory(id: "encode", name: "Encoding", symbol: "number", tools: [
                    Tool(id: "json_format", name: "JSON Formatter",
                         description: "Pretty-print and validate JSON.", symbol: "curlybraces"),
                    Tool(id: "base64", name: "Base64",
                         description: "Encode and decode Base64.", symbol: "textformat.abc")
                ])
            ]
        ),
        ToolField(
            id: "utilities", name: "Utilities", symbol: "wrench.and.screwdriver",
            tint: AppColor.accentDeep,
            categories: [
                ToolCategory(id: "convert", name: "Converters", symbol: "arrow.left.arrow.right", tools: [
                    Tool(id: "unit_convert", name: "Unit Converter",
                         description: "Length, weight, temperature and more.", symbol: "ruler"),
                    Tool(id: "currency", name: "Currency",
                         description: "Convert between currencies.", symbol: "dollarsign.circle")
                ])
            ]
        )
    ]

    /// Flattened list of every interactive tool (used by Home for quick access).
    static var availableTools: [Tool] {
        fields.flatMap { $0.categories.flatMap { $0.tools } }.filter { $0.isAvailable }
    }
}
