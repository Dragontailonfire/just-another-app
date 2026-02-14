//
//  BookmarkRowView.swift
//  just-another-app
//
//  Created by Narayanan VK on 14/02/2026.
//

import SwiftUI

struct BookmarkRowView: View {
    let bookmark: Bookmark
    var onToggleFavorite: () -> Void = {}
    var onDelete: () -> Void = {}
    var onOpenURL: ((URL) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(bookmark.name)
                    .font(.body)
                    .lineLimit(1)
                Spacer()
                if bookmark.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                }
            }
            Text(bookmark.url)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(bookmark.createdDate, format: .relative(presentation: .named))
                .font(.caption2)
                .foregroundStyle(.tertiary)
            if let folder = bookmark.folder {
                HStack(spacing: 4) {
                    Image(systemName: folder.iconName)
                        .font(.caption2)
                    Text(folder.name)
                        .font(.caption2)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .foregroundStyle(FolderAppearance.color(for: folder.colorName))
                .background(FolderAppearance.color(for: folder.colorName).opacity(0.15), in: Capsule())
            }
        }
        .contextMenu {
            Button(action: onToggleFavorite) {
                Label(
                    bookmark.isFavorite ? "Unfavorite" : "Favorite",
                    systemImage: bookmark.isFavorite ? "star.slash" : "star.fill"
                )
            }
            if let url = URL(string: bookmark.url) {
                Button {
                    onOpenURL?(url)
                } label: {
                    Label("Open in Browser", systemImage: "safari")
                }
            }
            Divider()
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button(action: onToggleFavorite) {
                Label(
                    bookmark.isFavorite ? "Unfavorite" : "Favorite",
                    systemImage: bookmark.isFavorite ? "star.slash" : "star.fill"
                )
            }
            .tint(.yellow)
        }
    }
}
