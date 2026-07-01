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

    /// The app has a scene manifest (SwiftUI generates one by default), which
    /// means iOS delivers quick actions to the *scene* delegate below, not to
    /// the two methods above — those only apply to a non-scene app. Attaching
    /// a scene delegate here is what actually makes shortcuts arrive at all.
    func application(_ application: UIApplication,
                      configurationForConnecting connectingSceneSession: UISceneSession,
                      options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = AppSceneDelegate.self
        return configuration
    }
}

/// Catches Home Screen quick actions for both cold launch (`willConnectTo`)
/// and warm launch (`windowScene(_:performActionFor:)`). Deliberately does
/// nothing else — it must not create or assign its own window, since
/// SwiftUI's App/WindowGroup owns and renders the scene's content regardless
/// of whatever UIWindowSceneDelegate subclass is attached to it.
final class AppSceneDelegate: NSObject, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let shortcutItem = connectionOptions.shortcutItem else { return }
        (UIApplication.shared.delegate as? AppShortcutDelegate)?.pendingShortcutItem = shortcutItem
    }

    func windowScene(_ windowScene: UIWindowScene,
                      performActionFor shortcutItem: UIApplicationShortcutItem,
                      completionHandler: @escaping (Bool) -> Void) {
        guard let action = AppShortcutAction(shortcutItem: shortcutItem),
              let delegate = UIApplication.shared.delegate as? AppShortcutDelegate else {
            completionHandler(false)
            return
        }
        delegate.router?.open(shortcut: action)
        completionHandler(true)
    }
}
