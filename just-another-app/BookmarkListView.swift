//
//  BookmarkListView.swift
//  just-another-app
//
//  Created by Narayanan VK on 14/02/2026.
//

import SwiftUI
import SwiftData
import UIKit

struct BookmarkListView: View {
    let bookmarks: [Bookmark]
    @Bindable var listState: BookmarkListState
    var onSelect: (Bookmark) -> Void = { _ in }
    var onDelete: (Bookmark) -> Void = { _ in }
    var onOpenURL: ((URL) -> Void)?

    var body: some View {
        List(selection: listState.isSelectMode ? $listState.selectedBookmarkIDs : nil) {
            ForEach(bookmarks) { bookmark in
                BookmarkRowView(
                    bookmark: bookmark,
                    onToggleFavorite: {
                        bookmark.isFavorite.toggle()
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    },
                    onDelete: { onDelete(bookmark) },
                    onOpenURL: onOpenURL
                )
                .tag(bookmark.persistentModelID)
                .contentShape(Rectangle())
                .onTapGesture {
                    if !listState.isSelectMode {
                        onSelect(bookmark)
                    }
                }
            }
            .onMove(perform: listState.sortMode == .manual && !listState.isSelectMode ? moveBookmarks : nil)
        }
        .environment(\.editMode, listState.isSelectMode ? .constant(.active) : .constant(.inactive))
    }

    private func moveBookmarks(from source: IndexSet, to destination: Int) {
        var ordered = bookmarks
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, bookmark) in ordered.enumerated() {
            bookmark.sortOrder = index
        }
    }
}
