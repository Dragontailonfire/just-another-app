//
//  just_another_appTests.swift
//  just-another-appTests
//
//  Created by Narayanan VK on 14/02/2026.
//

import Testing
import Foundation
import SwiftData
@testable import just_another_app

@MainActor
private func makeContainer() throws -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(for: Bookmark.self, Folder.self, configurations: config)
}

// MARK: - Bookmark Model Tests

@Suite
struct BookmarkTests {

    @Test func bookmarkInitDefaults() {
        let bookmark = Bookmark(url: "https://example.com", name: "Example")
        #expect(bookmark.url == "https://example.com")
        #expect(bookmark.name == "Example")
        #expect(bookmark.descriptionText == "")
        #expect(bookmark.isFavorite == false)
        #expect(bookmark.sortOrder == 0)
        #expect(bookmark.folder == nil)
    }

    @Test func bookmarkInitWithAllFields() {
        let folder = Folder(name: "Tech")
        let date = Date(timeIntervalSince1970: 1000)
        let bookmark = Bookmark(
            url: "https://swift.org",
            name: "Swift",
            descriptionText: "Swift language",
            createdDate: date,
            isFavorite: true,
            sortOrder: 5,
            folder: folder
        )
        #expect(bookmark.url == "https://swift.org")
        #expect(bookmark.name == "Swift")
        #expect(bookmark.descriptionText == "Swift language")
        #expect(bookmark.createdDate == date)
        #expect(bookmark.isFavorite == true)
        #expect(bookmark.sortOrder == 5)
        #expect(bookmark.folder === folder)
    }

    @Test @MainActor func bookmarkInsertAndFetch() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let bookmark = Bookmark(url: "https://example.com", name: "Example")
        context.insert(bookmark)
        try context.save()

        let descriptor = FetchDescriptor<Bookmark>()
        let fetched = try context.fetch(descriptor)
        #expect(fetched.count == 1)
        #expect(fetched.first?.url == "https://example.com")
    }

    @Test @MainActor func bookmarkDelete() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let bookmark = Bookmark(url: "https://example.com", name: "Example")
        context.insert(bookmark)
        try context.save()

        context.delete(bookmark)
        try context.save()

        let descriptor = FetchDescriptor<Bookmark>()
        let fetched = try context.fetch(descriptor)
        #expect(fetched.isEmpty)
    }

    @Test func bookmarkFavoriteToggle() {
        let bookmark = Bookmark(url: "https://example.com", name: "Test")
        #expect(bookmark.isFavorite == false)
        bookmark.isFavorite.toggle()
        #expect(bookmark.isFavorite == true)
        bookmark.isFavorite.toggle()
        #expect(bookmark.isFavorite == false)
    }

    @Test @MainActor func bookmarkUpdateFields() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let bookmark = Bookmark(url: "https://old.com", name: "Old")
        context.insert(bookmark)
        try context.save()

        bookmark.url = "https://new.com"
        bookmark.name = "New"
        bookmark.descriptionText = "Updated"
        try context.save()

        let descriptor = FetchDescriptor<Bookmark>()
        let fetched = try context.fetch(descriptor)
        #expect(fetched.first?.url == "https://new.com")
        #expect(fetched.first?.name == "New")
        #expect(fetched.first?.descriptionText == "Updated")
    }
}

// MARK: - Folder Model Tests

@Suite
struct FolderTests {

    @Test func folderInitDefaults() {
        let folder = Folder(name: "Reading")
        #expect(folder.name == "Reading")
        #expect(folder.sortOrder == 0)
        #expect(folder.parent == nil)
        #expect(folder.children.isEmpty)
        #expect(folder.bookmarks.isEmpty)
    }

    @Test @MainActor func folderBookmarkCount() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let folder = Folder(name: "Tech")
        context.insert(folder)

        let b1 = Bookmark(url: "https://a.com", name: "A", folder: folder)
        let b2 = Bookmark(url: "https://b.com", name: "B", folder: folder)
        context.insert(b1)
        context.insert(b2)
        try context.save()

        #expect(folder.bookmarkCount == 2)
    }

    @Test @MainActor func folderTotalBookmarkCountWithNesting() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let parent = Folder(name: "Parent")
        let child = Folder(name: "Child", parent: parent)
        context.insert(parent)
        context.insert(child)

        let b1 = Bookmark(url: "https://a.com", name: "A", folder: parent)
        let b2 = Bookmark(url: "https://b.com", name: "B", folder: child)
        let b3 = Bookmark(url: "https://c.com", name: "C", folder: child)
        context.insert(b1)
        context.insert(b2)
        context.insert(b3)
        try context.save()

        #expect(parent.bookmarkCount == 1)
        #expect(child.bookmarkCount == 2)
        #expect(parent.totalBookmarkCount == 3)
        #expect(child.totalBookmarkCount == 2)
    }

    @Test @MainActor func folderInsertAndFetch() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let folder = Folder(name: "Work")
        context.insert(folder)
        try context.save()

        let descriptor = FetchDescriptor<Folder>()
        let fetched = try context.fetch(descriptor)
        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "Work")
    }

    @Test @MainActor func folderDeleteNullifiesBookmarks() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let folder = Folder(name: "Temp")
        context.insert(folder)
        let bookmark = Bookmark(url: "https://a.com", name: "A", folder: folder)
        context.insert(bookmark)
        try context.save()

        context.delete(folder)
        try context.save()

        let bookmarks = try context.fetch(FetchDescriptor<Bookmark>())
        #expect(bookmarks.count == 1)
        #expect(bookmarks.first?.folder == nil)
    }

    @Test @MainActor func folderParentChildRelationship() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let parent = Folder(name: "Parent")
        let child = Folder(name: "Child", parent: parent)
        context.insert(parent)
        context.insert(child)
        try context.save()

        #expect(child.parent === parent)
        #expect(parent.children.count == 1)
        #expect(parent.children.first?.name == "Child")
    }
}

// MARK: - BookmarkListState Tests

@Suite
struct BookmarkListStateTests {

    @Test func defaultState() {
        let state = BookmarkListState()
        #expect(state.viewMode == .list)
        #expect(state.sortMode == .newestFirst)
        #expect(state.searchText == "")
        #expect(state.filterFavoritesOnly == false)
        #expect(state.filterFolder == nil)
    }

    @Test func viewModeToggle() {
        let state = BookmarkListState()
        state.viewMode = .card
        #expect(state.viewMode == .card)
        state.viewMode = .list
        #expect(state.viewMode == .list)
    }

    @Test func sortModeCases() {
        let allCases = SortMode.allCases
        #expect(allCases.count == 5)
        #expect(allCases.contains(.newestFirst))
        #expect(allCases.contains(.oldestFirst))
        #expect(allCases.contains(.alphabeticalAZ))
        #expect(allCases.contains(.alphabeticalZA))
        #expect(allCases.contains(.manual))
    }

    @Test func sortModeRawValues() {
        #expect(SortMode.newestFirst.rawValue == "Newest First")
        #expect(SortMode.oldestFirst.rawValue == "Oldest First")
        #expect(SortMode.alphabeticalAZ.rawValue == "A → Z")
        #expect(SortMode.alphabeticalZA.rawValue == "Z → A")
        #expect(SortMode.manual.rawValue == "Manual")
    }
}

// MARK: - CSVService Tests

@Suite
struct CSVServiceTests {

    @Test func escapeFieldPlain() {
        #expect(CSVService.escapeField("hello") == "hello")
    }

    @Test func escapeFieldWithComma() {
        #expect(CSVService.escapeField("hello,world") == "\"hello,world\"")
    }

    @Test func escapeFieldWithQuotes() {
        #expect(CSVService.escapeField("say \"hi\"") == "\"say \"\"hi\"\"\"")
    }

    @Test func parseCSVRowSimple() {
        let fields = CSVService.parseCSVRow("a,b,c")
        #expect(fields == ["a", "b", "c"])
    }

    @Test func parseCSVRowQuoted() {
        let fields = CSVService.parseCSVRow("\"hello,world\",normal,\"with \"\"quotes\"\"\"")
        #expect(fields.count == 3)
        #expect(fields[0] == "hello,world")
        #expect(fields[1] == "normal")
        #expect(fields[2] == "with \"quotes\"")
    }

    @Test func parseCSVRowEmpty() {
        let fields = CSVService.parseCSVRow("a,,c")
        #expect(fields == ["a", "", "c"])
    }

    @Test @MainActor func exportImportRoundTrip() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let parent = Folder(name: "Work", sortOrder: 0, colorName: "red", iconName: "briefcase.fill")
        let child = Folder(name: "Projects", sortOrder: 1, colorName: "green", iconName: "star.fill", parent: parent)
        context.insert(parent)
        context.insert(child)

        let b1 = Bookmark(url: "https://swift.org", name: "Swift", descriptionText: "The Swift language", isFavorite: true, sortOrder: 0, folder: parent)
        let b2 = Bookmark(url: "https://example.com", name: "Example", descriptionText: "A test, with \"commas\"", isFavorite: false, sortOrder: 1, folder: child)
        context.insert(b1)
        context.insert(b2)
        try context.save()

        let allFolders = try context.fetch(FetchDescriptor<Folder>())
        let allBookmarks = try context.fetch(FetchDescriptor<Bookmark>())
        let csv = CSVService.exportCSV(folders: allFolders, bookmarks: allBookmarks)

        // Import into fresh context
        let container2 = try makeContainer()
        let context2 = container2.mainContext
        try CSVService.importCSV(from: csv, context: context2)

        let importedFolders = try context2.fetch(FetchDescriptor<Folder>())
        let importedBookmarks = try context2.fetch(FetchDescriptor<Bookmark>())

        #expect(importedFolders.count == 2)
        #expect(importedBookmarks.count == 2)

        let importedWork = importedFolders.first(where: { $0.name == "Work" })
        #expect(importedWork?.colorName == "red")
        #expect(importedWork?.iconName == "briefcase.fill")

        let importedProjects = importedFolders.first(where: { $0.name == "Projects" })
        #expect(importedProjects?.parent?.name == "Work")
        #expect(importedProjects?.colorName == "green")

        let importedSwift = importedBookmarks.first(where: { $0.name == "Swift" })
        #expect(importedSwift?.url == "https://swift.org")
        #expect(importedSwift?.isFavorite == true)
        #expect(importedSwift?.folder?.name == "Work")

        let importedExample = importedBookmarks.first(where: { $0.name == "Example" })
        #expect(importedExample?.descriptionText == "A test, with \"commas\"")
        #expect(importedExample?.folder?.name == "Projects")
    }

    @Test @MainActor func importMissingSections() throws {
        let container = try makeContainer()
        let context = container.mainContext

        #expect(throws: CSVService.CSVError.self) {
            try CSVService.importCSV(from: "just some text", context: context)
        }
    }
}
