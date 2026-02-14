//
//  Bookmark.swift
//  just-another-app
//
//  Created by Narayanan VK on 14/02/2026.
//

import Foundation
import SwiftData

@Model
final class Bookmark {
    var url: String
    var name: String
    var descriptionText: String
    var createdDate: Date
    var isFavorite: Bool
    var sortOrder: Int

    @Relationship(inverse: \Folder.bookmarks)
    var folder: Folder?

    init(
        url: String,
        name: String,
        descriptionText: String = "",
        createdDate: Date = .now,
        isFavorite: Bool = false,
        sortOrder: Int = 0,
        folder: Folder? = nil
    ) {
        self.url = url
        self.name = name
        self.descriptionText = descriptionText
        self.createdDate = createdDate
        self.isFavorite = isFavorite
        self.sortOrder = sortOrder
        self.folder = folder
    }
}
