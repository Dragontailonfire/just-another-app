//
//  BookmarkRowView.swift
//  just-another-app
//
//  Created by Narayanan VK on 14/02/2026.
//

import SwiftUI

// MARK: - Swipe Action Config

enum SwipeAction: String, CaseIterable {
    case favorite = "favorite"
    case copyURL  = "copyURL"
    case edit     = "edit"
    case delete   = "delete"

    var label: String {
        switch self {
        case .favorite: return "Favorite"
        case .copyURL:  return "Copy URL"
        case .edit:     return "Edit"
        case .delete:   return "Delete"
        }
    }

    var systemImage: String {
        switch self {
        case .favorite: return "star.fill"
        case .copyURL:  return "doc.on.doc"
        case .edit:     return "pencil"
        case .delete:   return "trash"
        }
    }

    var tint: Color {
        switch self {
        case .favorite: return .yellow
        case .copyURL:  return .blue
        case .edit:     return .orange
        case .delete:   return .red
        }
    }
}

// MARK: - Row View

struct BookmarkRowView: View {
    let bookmark: Bookmark
    var onToggleFavorite: () -> Void = {}
    var onDelete: () -> Void = {}
    var onEdit: (() -> Void)?
    var onOpenURL: ((URL) -> Void)?

    @AppStorage("leadingSwipeAction") private var leadingSwipeRaw = SwipeAction.favorite.rawValue
    @AppStorage("trailingSwipeAction") private var trailingSwipeRaw = SwipeAction.delete.rawValue

    private var leadingSwipe: SwipeAction { SwipeAction(rawValue: leadingSwipeRaw) ?? .favorite }
    private var trailingSwipe: SwipeAction { SwipeAction(rawValue: trailingSwipeRaw) ?? .delete }

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
                    Label("Open in Browser", systemImage: "safari")
                }
            }
            Divider()
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            swipeButton(for: trailingSwipe)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            swipeButton(for: leadingSwipe)
        }
    }

    // MARK: - Favicon

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

    // MARK: - Swipe Button Builder

    @ViewBuilder
    private func swipeButton(for action: SwipeAction) -> some View {
        switch action {
        case .favorite:
            Button(action: onToggleFavorite) {
                Label(
                    bookmark.isFavorite ? "Unfavorite" : "Favorite",
                    systemImage: bookmark.isFavorite ? "star.slash" : "star.fill"
                )
            }
            .tint(action.tint)
        case .copyURL:
            Button {
                UIPasteboard.general.string = bookmark.url
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } label: {
                Label("Copy URL", systemImage: "doc.on.doc")
            }
            .tint(action.tint)
        case .edit:
            Button {
                onEdit?()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(action.tint)
        case .delete:
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
