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
        HStack(spacing: 10) {
            faviconView(size: 32)
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(bookmark.name)
                        .font(.body)
                        .lineLimit(1)
                    Spacer()
                    if bookmark.linkStatus == "dead" {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                    if bookmark.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                    }
                }
                HStack(spacing: 6) {
                    Text(bookmark.url)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    if let folder = bookmark.folder {
                        HStack(spacing: 3) {
                            Image(systemName: folder.iconName)
                                .font(.system(size: 9))
                            Text(folder.name)
                                .font(.caption2)
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .foregroundStyle(FolderAppearance.color(for: folder.colorName))
                        .background(FolderAppearance.color(for: folder.colorName).opacity(0.15), in: Capsule())
                    }
                }
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

    @ViewBuilder
    private func faviconView(size: CGFloat) -> some View {
        if let data = bookmark.faviconData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
        } else {
            Image(systemName: "globe")
                .font(.system(size: size * 0.45))
                .frame(width: size, height: size)
                .foregroundStyle(.secondary)
                .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: size * 0.22))
        }
    }
}
