//
//  MainTabView.swift
//  just-another-app
//
//  Created by Narayanan VK on 14/02/2026.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Bookmarks", systemImage: "bookmark.fill") {
                BookmarksTab()
            }
            Tab("Folders", systemImage: "folder.fill") {
                FoldersTab()
            }
            Tab("Settings", systemImage: "gear") {
                SettingsTab()
            }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Bookmark.self, Folder.self], inMemory: true)
}
