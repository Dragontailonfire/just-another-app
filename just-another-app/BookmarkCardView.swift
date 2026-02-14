//
//  BookmarkCardView.swift
//  just-another-app
//
//  Created by Narayanan VK on 14/02/2026.
//

import SwiftUI

struct BookmarkCardView: View {
    let bookmark: Bookmark
    var onOpenURL: ((URL) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(bookmark.name)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                if bookmark.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                }
            }
            if !bookmark.descriptionText.isEmpty {
                Text(bookmark.descriptionText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            HStack {
                Text(bookmark.url)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                Spacer()
                Text(bookmark.createdDate, format: .relative(presentation: .named))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
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
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }
}
