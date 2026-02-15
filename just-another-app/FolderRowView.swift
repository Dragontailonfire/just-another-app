//
//  FolderRowView.swift
//  just-another-app
//
//  Created by Narayanan VK on 14/02/2026.
//

import SwiftUI

struct FolderRowView: View {
    let folder: Folder

    var body: some View {
        HStack {
            Image(systemName: folder.iconName)
                .foregroundStyle(FolderAppearance.color(for: folder.colorName))
            VStack(alignment: .leading) {
                Text(folder.name)
                    .font(.body)
                HStack(spacing: 8) {
                    if !folder.children.isEmpty {
                        Text("\(folder.children.count) \(folder.children.count == 1 ? "folder" : "folders")")
                    }
                    Text("\(folder.totalBookmarkCount) \(folder.totalBookmarkCount == 1 ? "bookmark" : "bookmarks")")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }
}
