//
//  MainTabView.swift
//  just-another-app
//
//  Created by Narayanan VK on 14/02/2026.
//

import SwiftUI

struct MainTabView: View {
    var quickActionService: QuickActionService
    @State private var selectedTab = "bookmarks"
    @State private var showingAddBookmark = false
    @State private var filterFavoritesOnAppear = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Bookmarks", systemImage: "bookmark.fill", value: "bookmarks") {
                BookmarksTab(filterFavoritesOnAppear: $filterFavoritesOnAppear)
            }
            Tab("Folders", systemImage: "folder.fill", value: "folders") {
                FoldersTab()
            }
            Tab("Settings", systemImage: "gear", value: "settings") {
                SettingsTab()
            }
            Tab("Search", systemImage: "magnifyingglass", value: "search", role: .search) {
                SearchTab()
            }
        }
        .onChange(of: quickActionService.pendingRoute) { _, route in
            guard let route = route else { return }
            quickActionService.pendingRoute = nil
            switch route {
            case .addBookmark:
                selectedTab = "bookmarks"
                // Small delay to ensure tab switch completes before presenting sheet
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showingAddBookmark = true
                }
            case .favorites:
                selectedTab = "bookmarks"
                filterFavoritesOnAppear = true
            }
        }
        .sheet(isPresented: $showingAddBookmark) {
            BookmarkFormView()
        }
    }
}

#Preview {
    MainTabView(quickActionService: QuickActionService())
        .modelContainer(for: [Bookmark.self, Folder.self], inMemory: true)
}
