//
//  BookmarkListView.swift
//  just-another-app
//
//  Created by Narayanan VK on 14/02/2026.
//

import SwiftUI
import UIKit

struct BookmarkListView: View {
    let bookmarks: [Bookmark]
    var listState: BookmarkListState
    var onSelect: (Bookmark) -> Void = { _ in }
    var onDelete: (Bookmark) -> Void = { _ in }
    var onOpenURL: ((URL) -> Void)?

    var body: some View {
        List {
            ForEach(bookmarks) { bookmark in
                HStack {
                    if listState.isSelectMode {
                        Image(systemName: listState.selectedBookmarkIDs.contains(bookmark.persistentModelID) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(listState.selectedBookmarkIDs.contains(bookmark.persistentModelID) ? .blue : .secondary)
                            .font(.title3)
                    }
                    BookmarkRowView(
                        bookmark: bookmark,
                        onToggleFavorite: {
                            bookmark.isFavorite.toggle()
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        },
                        onDelete: { onDelete(bookmark) },
                        onOpenURL: onOpenURL
                    )
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if listState.isSelectMode {
                        toggleSelection(bookmark)
                    } else {
                        onSelect(bookmark)
                    }
                }
            }
            .onMove(perform: listState.sortMode == .manual && !listState.isSelectMode ? moveBookmarks : nil)
        }
    }

    private func toggleSelection(_ bookmark: Bookmark) {
        let id = bookmark.persistentModelID
        if listState.selectedBookmarkIDs.contains(id) {
            listState.selectedBookmarkIDs.remove(id)
        } else {
            listState.selectedBookmarkIDs.insert(id)
        }
    }

    private func moveBookmarks(from source: IndexSet, to destination: Int) {
        var ordered = bookmarks
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, bookmark) in ordered.enumerated() {
            bookmark.sortOrder = index
        }
    }
}
