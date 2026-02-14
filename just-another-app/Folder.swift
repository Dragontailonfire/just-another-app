//
//  Folder.swift
//  just-another-app
//
//  Created by Narayanan VK on 14/02/2026.
//

import Foundation
import SwiftData

@Model
final class Folder {
    var name: String
    var sortOrder: Int
    var colorName: String
    var iconName: String

    @Relationship(deleteRule: .nullify)
    var parent: Folder?

    @Relationship(deleteRule: .nullify, inverse: \Folder.parent)
    var children: [Folder]

    @Relationship(deleteRule: .nullify)
    var bookmarks: [Bookmark]

    init(
        name: String,
        sortOrder: Int = 0,
        colorName: String = "blue",
        iconName: String = "folder.fill",
        parent: Folder? = nil
    ) {
        self.name = name
        self.sortOrder = sortOrder
        self.colorName = colorName
        self.iconName = iconName
        self.parent = parent
        self.children = []
        self.bookmarks = []
    }

    var bookmarkCount: Int {
        bookmarks.count
    }

    var totalBookmarkCount: Int {
        bookmarks.count + children.reduce(0) { $0 + $1.totalBookmarkCount }
    }
}
