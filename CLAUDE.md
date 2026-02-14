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
- Xcode 16.4+
- iOS 18.5 deployment target
- Swift 5.0

## Key Conventions

- Use `descriptionText` instead of `description` for SwiftData model properties (avoids NSObject shadow)
- Fetch all with `@Query`, filter/sort in-memory via computed properties
- Forms serve both add and edit modes (pass optional existing object)
- Delete rules: `.nullify` for folder relationships (safe default)
- All destructive actions require confirmation alerts
- New `.swift` files in `just-another-app/` are auto-discovered by Xcode (`PBXFileSystemSynchronizedRootGroup`) — no pbxproj edits needed

## Implementation Plan

See `PLAN.md` for the living implementation plan, phase status tracking, and change log. Update PLAN.md after completing each phase or when the plan changes.

## Quick File Reference

| File | Role |
|------|------|
| `just_another_appApp.swift` | @main entry, ModelContainer setup |
| `MainTabView.swift` | Root TabView (Bookmarks, Folders, Settings) |
| `Bookmark.swift` | @Model: url, name, descriptionText, createdDate, isFavorite, sortOrder, folder? |
| `Folder.swift` | @Model: name, sortOrder, parent?, children[], bookmarks[], colorName, iconName + bookmarkCount, totalBookmarkCount |
| `BookmarkListState.swift` | @Observable state + ViewMode/SortMode enums + select mode for batch ops |
| `BookmarksTab.swift` | Bookmarks tab — search, sort, filter, view toggle, CRUD, batch operations |
| `BookmarkListView.swift` | List layout with drag-to-reorder, multi-select UI, onOpenURL |
| `BookmarkRowView.swift` | Row: name, URL, relative date, colored folder badge, swipe/context actions, onOpenURL |
| `BookmarkCardView.swift` | Card: headline, description, URL, relative date, colored folder badge, onOpenURL |
| `BookmarkFormView.swift` | Add/edit form with https:// pre-fill, URL validation, auto-fill via LPMetadataProvider, duplicate detection |
| `FoldersTab.swift` | Folders tab — top-level list, CRUD |
| `FolderDetailView.swift` | Folder contents: subfolders + bookmarks, add bookmark/subfolder |
| `FolderRowView.swift` | Row: folder icon, name, total bookmark count, colored icon badge |
| `FolderFormView.swift` | Add/edit form with parent picker, color and icon pickers |
| `FolderAppearance.swift` | Color/icon palette definitions for folder customization |
| `SafariView.swift` | UIViewControllerRepresentable wrapping SFSafariViewController for in-app browsing |
| `SpotlightService.swift` | Core Spotlight indexing for bookmarks and folders |
| `SettingsTab.swift` | Settings tab — CSV export/import, stats, Spotlight rebuild, version display, changelog |
| `CSVService.swift` | CSV engine — section-based format, RFC 4180 escaping, colorName/iconName columns |
| `ChangelogView.swift` | In-app "What's New" sheet showing version history |
