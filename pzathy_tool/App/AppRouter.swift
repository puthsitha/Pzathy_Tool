import SwiftUI
import Combine
import UIKit

enum AppShortcutAction: String, CaseIterable {
    case musicConverter
    case spinner
    case currency
    case settings

    init?(shortcutItem: UIApplicationShortcutItem) {
        let rawType = shortcutItem.type.components(separatedBy: ".").last ?? ""
        self.init(rawValue: rawType)
    }

    init?(url: URL) {
        if let host = url.host, let action = AppShortcutAction(rawValue: host) {
            self = action
            return
        }

        let pathComponent = url.pathComponents.dropFirst().first
        if let rawPath = pathComponent, let action = AppShortcutAction(rawValue: rawPath) {
            self = action
            return
        }

        return nil
    }
}

final class AppRouter: ObservableObject {
    @Published var selectedTab = 0
    @Published var deepLinkTool: ToolRoute? = nil

    func open(shortcut action: AppShortcutAction) {
        switch action {
        case .musicConverter:
            selectedTab = 1
            deepLinkTool = .musicConverter
        case .spinner:
            selectedTab = 1
            deepLinkTool = .spinner
        case .currency:
            selectedTab = 1
            deepLinkTool = .currency
        case .settings:
            selectedTab = 2
            deepLinkTool = nil
        }
    }

    func open(url: URL) {
        guard let action = AppShortcutAction(url: url) else { return }
        open(shortcut: action)
    }
}

final class AppShortcutDelegate: NSObject, UIApplicationDelegate {
    weak var router: AppRouter?

    /// A shortcut tapped while the app was fully terminated. iOS delivers it via
    /// `launchOptions` instead of `performActionFor` (that delegate method only
    /// fires for a warm/backgrounded launch), so it's stashed here until the
    /// router exists and the root view can consume it.
    var pendingShortcutItem: UIApplicationShortcutItem?

    func application(_ application: UIApplication,
                      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        pendingShortcutItem = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem
        return true
    }

    func application(_ application: UIApplication,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        guard let action = AppShortcutAction(shortcutItem: shortcutItem) else {
            completionHandler(false)
            return
        }

        router?.open(shortcut: action)
        completionHandler(true)
    }
}
