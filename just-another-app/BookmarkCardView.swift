//
//  BookmarkCardView.swift
//  just-another-app
//
//  Created by Narayanan VK on 14/02/2026.
//

import SwiftUI
import UIKit

struct BookmarkCardView: View {
    let bookmark: Bookmark
    var onOpenURL: ((URL) -> Void)?
    var onEdit: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                faviconView(size: 20)
                Text(bookmark.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Spacer()
                if bookmark.linkStatus == "dead" {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.caption2)
                }
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
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        .contextMenu {
            Button {
                bookmark.isFavorite.toggle()
            } label: {
                Label(
                    bookmark.isFavorite ? "Unfavorite" : "Favorite",
                    systemImage: bookmark.isFavorite ? "star.slash" : "star.fill"
                )
            }
            Button {
                UIPasteboard.general.string = bookmark.url
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } label: {
                Label("Copy URL", systemImage: "doc.on.doc")
            }
            if let url = URL(string: bookmark.url) {
                Button {
                    onOpenURL?(url)
                } label: {
                    Label("Open in App Browser", systemImage: "safari")
                }
                Button {
                    UIApplication.shared.open(url)
                } label: {
                    Label("Open in Default Browser", systemImage: "arrow.up.right.square")
                }
            }
            Divider()
            Button {
                onEdit?()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button {
                Task { await LinkCheckerService.checkLink(for: bookmark) }
            } label: {
                Label("Check Link", systemImage: "network")
            }
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
