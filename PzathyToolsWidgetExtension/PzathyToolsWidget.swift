import WidgetKit
import SwiftUI

struct PzathyToolsWidgetEntry: TimelineEntry {
    let date: Date
}

struct PzathyToolsWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> PzathyToolsWidgetEntry {
        PzathyToolsWidgetEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (PzathyToolsWidgetEntry) -> Void) {
        completion(PzathyToolsWidgetEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PzathyToolsWidgetEntry>) -> Void) {
        let entry = PzathyToolsWidgetEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct PzathyToolsWidgetEntryView: View {
    let entry: PzathyToolsWidgetEntry
    @Environment(\.widgetFamily) private var family

    private var musicURL: URL { URL(string: "pzathy-tool://musicConverter")! }
    private var spinnerURL: URL { URL(string: "pzathy-tool://spinner")! }
    private var currencyURL: URL { URL(string: "pzathy-tool://currency")! }
    private var settingsURL: URL { URL(string: "pzathy-tool://settings")! }

    var body: some View {
        switch family {
        case .systemSmall:
            Link(destination: musicURL) {
                ZStack {
                    Color(.systemBackground)
                    VStack(alignment: .leading, spacing: 10) {
                        Label(WidgetLocalization.t("widgetTitle"), systemImage: "wand.and.stars")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(WidgetLocalization.t("shortcutMusicConverterSubtitle"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    .padding(14)
                }
            }
        default:
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(WidgetLocalization.t("widgetTitle"), systemImage: "wand.and.stars")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                }

                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        widgetButton(title: WidgetLocalization.t("widgetMusic"), symbol: "music.note", destination: musicURL)
                        widgetButton(title: WidgetLocalization.t("widgetSpinner"), symbol: "arrow.triangle.2.circlepath", destination: spinnerURL)
                    }
                    HStack(spacing: 10) {
                        widgetButton(title: WidgetLocalization.t("widgetCurrency"), symbol: "dollarsign.circle", destination: currencyURL)
                        widgetButton(title: WidgetLocalization.t("widgetSettings"), symbol: "gearshape", destination: settingsURL)
                    }
                }
            }
            .padding(14)
            .background(Color(.systemBackground))
        }
    }

    @ViewBuilder
    private func widgetButton(title: String, symbol: String, destination: URL) -> some View {
        Link(destination: destination) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.title3)
                    .frame(width: 28, height: 28)
                Text(title)
                    .font(.subheadline).fontWeight(.semibold)
                Spacer()
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .foregroundColor(.primary)
        }
    }
}
private struct WidgetLocalization {
    static func t(_ key: String) -> String {
        let language = Locale.current.languageCode
        if language == "km" {
            return khmer[key] ?? english[key] ?? key
        }
        return english[key] ?? key
    }

    private static let english: [String: String] = [
        "widgetTitle": "Pzathy Tools",
        "shortcutMusicConverterSubtitle": "Open Music Converter",
        "widgetMusic": "Music",
        "widgetSpinner": "Spinner",
        "widgetCurrency": "Currency",
        "widgetSettings": "Settings"
    ]

    private static let khmer: [String: String] = [
        "widgetTitle": "Pzathy Tools",
        "shortcutMusicConverterSubtitle": "បើកកម្មវិធីបម្លែងតន្ត្រី",
        "widgetMusic": "តន្ត្រី",
        "widgetSpinner": "កង់បង្វិល",
        "widgetCurrency": "រូបិយប័ណ្ណ",
        "widgetSettings": "ការកំណត់"
    ]
}
@main
struct PzathyToolsWidgetBundle: WidgetBundle {
    var body: some Widget {
        PzathyToolsWidget()
    }
}

struct PzathyToolsWidget: Widget {
    let kind: String = "PzathyToolsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PzathyToolsWidgetProvider()) { entry in
            PzathyToolsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Pzathy Tools")
        .description("Launch Music Converter, Spinner, Currency or Settings quickly.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
