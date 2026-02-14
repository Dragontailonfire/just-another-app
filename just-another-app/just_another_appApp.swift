//
//  just_another_appApp.swift
//  just-another-app
//
//  Created by Narayanan VK on 14/02/2026.
//

import SwiftUI
import SwiftData

@main
struct just_another_appApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Bookmark.self,
            Folder.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Schema migration failed — wipe store and retry
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let defaultStore = appSupport.appendingPathComponent("default.store")
            for suffix in ["", "-wal", "-shm"] {
                let url = suffix.isEmpty ? defaultStore : URL(fileURLWithPath: defaultStore.path + suffix)
                try? FileManager.default.removeItem(at: url)
            }
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer after reset: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
