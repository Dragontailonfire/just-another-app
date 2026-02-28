# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**Start here:** Read `README.md` for full project documentation (architecture, file-by-file structure, data models, feature details, CSV format, test coverage, conventions). Read `PLAN.md` for phase status and change log.

## Build and Development

This is a native Xcode iOS project with no external dependencies or package managers.

**Building:**
```bash
xcodebuild -project just-another-app.xcodeproj -scheme just-another-app -configuration Debug -sdk iphonesimulator build
```

**Running tests:**
```bash
# Unit tests (Swift Testing framework)
xcodebuild -project just-another-app.xcodeproj -scheme just-another-app -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test

# Run a single test
xcodebuild -project just-another-app.xcodeproj -scheme just-another-app -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:just-another-appTests/TestClassName/testMethodName test
```

**Requirements:**
- Xcode 26.0+
- iOS 26.0 deployment target (Liquid Glass design)
- Swift 5.0

## Key Conventions

- Use `descriptionText` instead of `description` for SwiftData model properties (avoids NSObject shadow)
- Fetch all with `@Query`, filter/sort in-memory via computed properties
- Forms serve both add and edit modes (pass optional existing object)
- Delete rules: `.nullify` for folder relationships (safe default)
- All destructive actions require confirmation alerts
- New `.swift` files in `just-another-app/` are auto-discovered by Xcode (`PBXFileSystemSynchronizedRootGroup`) — no pbxproj edits needed
- Uses iOS 26 Liquid Glass: `.glassEffect()` on cards/badges/pickers. Standard SwiftUI components auto-adopt glass. (`GlassEffectContainer` removed — cards use system backgrounds per HIG.)
- Extension targets (Share Extension, Widget) include specific main-app files via `PBXFileSystemSynchronizedBuildFileExceptionSet` in `project.pbxproj` — add new shared model files there when needed

## Implementation Plan

See `PLAN.md` for the living implementation plan, phase status tracking, and change log. Update PLAN.md after completing each phase or when the plan changes.

## Quick File Reference

| File | Role |
|------|------|
| `just_another_appApp.swift` | @main entry, SharedModelContainer, quick actions (Add Bookmark, Favorites, Reading List), AppDelegate |
| `MainTabView.swift` | Root TabView (Bookmarks, Folders, Settings, Search) + quick action routing + showingReadingList binding |
| `Bookmark.swift` | @Model: url, name, descriptionText, createdDate, isFavorite, sortOrder, faviconData, linkStatus, lastCheckedDate, folder? |
| `Folder.swift` | @Model: name, sortOrder, parent?, children[], bookmarks[], colorName, iconName + bookmarkCount, totalBookmarkCount |
| `ReadingListItem.swift` | @Model: url, name, faviconData, addedDate — read-now queue separate from bookmarks |
| `BookmarkListState.swift` | @Observable state + ViewMode/SortMode enums + select mode + filterDeadLinksOnly |
| `BookmarksTab.swift` | Bookmarks tab — sort, filter, view toggle, CRUD, batch ops, tap action, undo delete, reading list sheet (text.book.closed toolbar button) |
| `BookmarkListView.swift` | List layout with drag-to-reorder, multi-select UI, separate onSelect/onEdit/onAddToReadingList callbacks |
| `BookmarkRowView.swift` | Row: 32px favicon, name, URL, dead link indicator, folder badge, configurable swipe actions, context menu (Favorite, Add to Reading List, Copy URL, Open, Edit, Check Link, Delete) |
| `BookmarkCardView.swift` | Card: favicon, name, URL, dead link indicator, folder badge, context menu (same as row), system background |
| `BookmarkFormView.swift` | Add/edit form: URL validation, auto-fill + favicon fetch, folder picker search, duplicate detection, onSave callback, startingURL/Name/FaviconData pre-fill params |
| `ReadingListTab.swift` | Reading List sheet: oldest-first list, swipe remove/save, undo toast, at-capacity alert, deferred deletion via onSave, Done button, footer hint |
| `ReadingListRowView.swift` | Row: 32px favicon, name, URL, relative date added |
| `SearchTab.swift` | Unified search tab (Tab role: .search): bookmarks + folders, collapsible sections, undo delete, tap action |
| `FoldersTab.swift` | Folders tab — top-level list, CRUD, drag-to-reorder (always enabled) |
| `FolderDetailView.swift` | Folder contents: subfolders + bookmarks, add bookmark/subfolder, in-folder search, tap action, undo delete, reading list support |
| `FolderRowView.swift` | Row: folder icon, name, total bookmark count, colored icon badge |
| `FolderFormView.swift` | Add/edit form with parent picker (with search), color and icon pickers |
| `FolderAppearance.swift` | Color/icon palette definitions for folder customization |
| `SafariView.swift` | UIViewControllerRepresentable wrapping SFSafariViewController for in-app browsing |
| `SpotlightService.swift` | Core Spotlight indexing with privacy toggle (isEnabled guard, deleteAll) |
| `SettingsTab.swift` | Settings: CSV/HTML export+import, stats, Reading List limit (wheel picker), favicons, link check, Spotlight toggle, Gestures (tap + swipe pickers), changelog |
| `HTMLExportService.swift` | Netscape HTML bookmark export with folder hierarchy (browser-importable) |
| `HTMLImportService.swift` | Netscape HTML merge-import: stack-based parser, findOrCreate folders, skip duplicates, sequential timestamps |
| `CSVService.swift` | CSV engine — section-based format, RFC 4180 escaping, injection protection, URL validation on import, atomic import |
| `URLValidator.swift` | Centralized HTTP(S) URL validation + canonicalization |
| `ConcurrencyLimiter.swift` | Actor-based semaphore for bounded concurrent network requests |
| `ChangelogView.swift` | In-app "What's New" sheet showing version history |
| `SharedModelContainer.swift` | App Group shared ModelContainer for main app + extensions (schema: Bookmark, Folder, ReadingListItem) |
| `FaviconService.swift` | Favicon fetching via LPMetadataProvider + Google fallback |
| `LinkCheckerService.swift` | Dead link detection via HEAD requests |
| `BookmarkShareExtension/ShareViewController.swift` | Share Extension entry point — extracts URL from NSExtensionItem |
| `BookmarkShareExtension/ShareBookmarkView.swift` | Share Extension UI: auto-fills name, segmented picker (Bookmark / Reading List), conditional folder picker |
| `BookmarkWidget/BookmarkWidget.swift` | Home Screen Widget (small + medium): shows Reading List items oldest-first; empty state when list is clear |
