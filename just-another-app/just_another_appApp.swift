//
//  just_another_appApp.swift
//  just-another-app
//
//  Created by Narayanan VK on 14/02/2026.
//

import SwiftUI
import SwiftData

enum QuickActionRoute: String {
    case addBookmark = "AddBookmark"
    case favorites = "Favorites"
    case readingList = "ReadingList"
}

@Observable
class QuickActionService {
    var pendingRoute: QuickActionRoute?
}

@main
struct just_another_appApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var quickActionService = QuickActionService()

    var sharedModelContainer: ModelContainer = SharedModelContainer.create()

    var body: some Scene {
        WindowGroup {
            MainTabView(quickActionService: quickActionService)
                .onAppear {
                    registerShortcuts()
                }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                handleShortcutIfNeeded()
            }
        }
    }

    @Environment(\.scenePhase) private var scenePhase

    private func registerShortcuts() {
        UIApplication.shared.shortcutItems = [
            UIApplicationShortcutItem(
                type: QuickActionRoute.addBookmark.rawValue,
                localizedTitle: "Add Bookmark",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(type: .add),
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: QuickActionRoute.favorites.rawValue,
                localizedTitle: "View Favorites",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(type: .favorite),
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: QuickActionRoute.readingList.rawValue,
                localizedTitle: "Reading List",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "text.book.closed"),
                userInfo: nil
            ),
        ]
    }

    private func handleShortcutIfNeeded() {
        guard let shortcutType = Self.pendingShortcutType else { return }
        Self.pendingShortcutType = nil
        quickActionService.pendingRoute = QuickActionRoute(rawValue: shortcutType)
    }

    // Static storage for shortcut received before UI is ready
    static var pendingShortcutType: String?
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        if let shortcutItem = options.shortcutItem {
            just_another_appApp.pendingShortcutType = shortcutItem.type
        }
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        just_another_appApp.pendingShortcutType = shortcutItem.type
        completionHandler(true)
    }
}
