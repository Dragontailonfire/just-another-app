//
//  ReadingListItem.swift
//  just-another-app
//
//  Created by Narayanan VK on 19/02/2026.
//

import Foundation
import SwiftData

@Model
class ReadingListItem {
    var url: String
    var name: String
    var faviconData: Data?
    var addedDate: Date

    init(url: String, name: String, faviconData: Data? = nil) {
        self.url = url
        self.name = name
        self.faviconData = faviconData
        self.addedDate = Date()
    }
}
