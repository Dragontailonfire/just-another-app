//
//  SpotlightService.swift
//  just-another-app
//
//  Created by Narayanan VK on 14/02/2026.
//

import CoreSpotlight
import SwiftData

enum SpotlightService {
    private static let domainIdentifier = "tech.prana.just-another-app.bookmarks"

    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "spotlightIndexingEnabled") as? Bool ?? true
    }

    static func index(bookmark: Bookmark) {
        guard isEnabled else { return }

        let attributeSet = CSSearchableItemAttributeSet(contentType: .url)
        attributeSet.title = bookmark.name
        attributeSet.contentDescription = bookmark.descriptionText
        attributeSet.url = URL(string: bookmark.url)
        if let folder = bookmark.folder {
            attributeSet.keywords = [folder.name]
        }

        let identifier = bookmark.persistentModelID.hashValue.description
        let item = CSSearchableItem(
            uniqueIdentifier: identifier,
            domainIdentifier: domainIdentifier,
            attributeSet: attributeSet
        )
        CSSearchableIndex.default().indexSearchableItems([item])
    }

    static func deindex(bookmark: Bookmark) {
        let identifier = bookmark.persistentModelID.hashValue.description
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [identifier])
    }

    static func reindexAll(bookmarks: [Bookmark]) {
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [domainIdentifier]) { _ in
            guard isEnabled else { return }
            let items = bookmarks.map { bookmark -> CSSearchableItem in
                let attributeSet = CSSearchableItemAttributeSet(contentType: .url)
                attributeSet.title = bookmark.name
                attributeSet.contentDescription = bookmark.descriptionText
                attributeSet.url = URL(string: bookmark.url)
                if let folder = bookmark.folder {
                    attributeSet.keywords = [folder.name]
                }
                let identifier = bookmark.persistentModelID.hashValue.description
                return CSSearchableItem(
                    uniqueIdentifier: identifier,
                    domainIdentifier: domainIdentifier,
                    attributeSet: attributeSet
                )
            }
            CSSearchableIndex.default().indexSearchableItems(items)
        }
    }

    static func deleteAll() {
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [domainIdentifier])
    }
}
