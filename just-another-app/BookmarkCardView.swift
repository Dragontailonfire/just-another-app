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
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(bookmark.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Spacer()
                if bookmark.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption2)
                }
            }
            Text(bookmark.url)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
            if let folder = bookmark.folder {
                HStack(spacing: 2) {
                    Image(systemName: folder.iconName)
                        .font(.system(size: 8))
                    Text(folder.name)
                        .font(.system(size: 9))
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .foregroundStyle(FolderAppearance.color(for: folder.colorName))
                .background(FolderAppearance.color(for: folder.colorName).opacity(0.15), in: Capsule())
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
    }
}
