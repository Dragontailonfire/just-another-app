//
//  BookmarkListState.swift
//  just-another-app
//
//  Created by Narayanan VK on 14/02/2026.
//

import SwiftUI
import SwiftData

enum ViewMode: String, CaseIterable {
    case list, card
}

enum SortMode: String, CaseIterable {
    case newestFirst = "Newest First"
    case oldestFirst = "Oldest First"
    case alphabeticalAZ = "A → Z"
    case alphabeticalZA = "Z → A"
    case manual = "Manual"
}

@Observable
class BookmarkListState {
    var viewMode: ViewMode = .list
    var sortMode: SortMode = .newestFirst
    var searchText: String = ""
    var filterFavoritesOnly: Bool = false
    var filterFolder: Folder? = nil
    var filterDeadLinksOnly: Bool = false
    var isSelectMode: Bool = false
    var selectedBookmarkIDs: Set<PersistentIdentifier> = []
}
