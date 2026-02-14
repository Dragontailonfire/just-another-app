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
                Text("\(folder.totalBookmarkCount) bookmarks")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
