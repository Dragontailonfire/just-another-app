//
//  SharedModelContainer.swift
//  just-another-app
//
//  Created by Narayanan VK on 16/02/2026.
//

import Foundation
import SwiftData

enum SharedModelContainer {
    static let appGroupID = "group.tech.prana.just-another-app"

    private static var _cached: ModelContainer?

    static func create() -> ModelContainer {
        if let cached = _cached {
            return cached
        }

        let schema = Schema([
            Bookmark.self,
            Folder.self,
            ReadingListItem.self,
        ])

        let storeURL = containerURL().appendingPathComponent("bookmarks.store")
        let modelConfiguration = ModelConfiguration(schema: schema, url: storeURL)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            _cached = container
            return container
        } catch {
            // Schema migration failed — wipe store and retry
            for suffix in ["", "-wal", "-shm"] {
                let url = suffix.isEmpty ? storeURL : URL(fileURLWithPath: storeURL.path + suffix)
                try? FileManager.default.removeItem(at: url)
            }
            do {
                let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                _cached = container
                return container
            } catch {
                fatalError("Could not create ModelContainer after reset: \(error)")
            }
        }
    }

    private static func containerURL() -> URL {
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return url
        }
        // Fallback for simulator/testing when App Group isn't configured
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    }
}
