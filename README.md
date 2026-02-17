# Just Another App

A personal bookmarking app for iOS built with SwiftUI and SwiftData. Save, organize, and manage web links with folders, search, sorting, filtering, card/list views, CSV import/export, in-app browsing, Spotlight indexing, batch operations, favicons, Share Extension, home screen widget, dead link detection, quick actions, and privacy controls.

## Requirements

- Xcode 26.0+
- iOS 26.0 deployment target (Liquid Glass design)
- Swift 5.0
- No external dependencies or package managers

## Build & Test

```bash
# Build
xcodebuild -project just-another-app.xcodeproj -scheme just-another-app -configuration Debug -sdk iphonesimulator build

# Run all tests
xcodebuild -project just-another-app.xcodeproj -scheme just-another-app -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test

# Run a single test
xcodebuild -project just-another-app.xcodeproj -scheme just-another-app -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:just-another-appTests/BookmarkTests/bookmarkInitDefaults test
```

## Architecture

**Pattern:** SwiftUI + SwiftData with @Observable state objects. Tab-based navigation.

**Data flow:** `just_another_appApp` creates a `ModelContainer` (schema: `Bookmark`, `Folder`) → injected via `.modelContainer()` modifier → views access data via `@Environment(\.modelContext)` and `@Query`.

**Xcode project note:** The project uses `PBXFileSystemSynchronizedRootGroup`, so new Swift files placed in `just-another-app/` are automatically discovered by Xcode — no manual pbxproj edits needed.

## Project Structure

```
just-another-app/
├── just-another-app/                  # Main app source
│   ├── just_another_appApp.swift      # @main entry point, ModelContainer setup
│   ├── MainTabView.swift              # Root TabView (Bookmarks, Folders, Settings)
│   │
│   ├── Bookmark.swift                 # SwiftData @Model — url, name, descriptionText, createdDate, isFavorite, sortOrder, folder?
│   ├── Folder.swift                   # SwiftData @Model — name, sortOrder, parent?, children[], bookmarks[]
│   ├── BookmarkListState.swift        # @Observable state — viewMode, sortMode, searchText, filters (also defines ViewMode & SortMode enums)
│   │
│   ├── BookmarksTab.swift             # Bookmarks tab root — search, sort, filter, card/list toggle, add/edit/delete
│   ├── BookmarkListView.swift         # List layout for bookmarks (supports manual drag-to-reorder)
│   ├── BookmarkRowView.swift          # Single bookmark row — name, URL, relative date, folder badge, swipe actions, context menu
│   ├── BookmarkCardView.swift         # Card layout — headline, description, URL, relative date, folder badge
│   ├── BookmarkFormView.swift         # Add/edit form — URL (with validation), name, description, folder picker
│   │
│   ├── FoldersTab.swift               # Folders tab root — list of top-level folders, add/edit/delete
│   ├── FolderDetailView.swift         # Folder contents — subfolders section + bookmarks section, add bookmark/subfolder
│   ├── FolderRowView.swift            # Single folder row — icon, name, total bookmark count
│   ├── FolderFormView.swift           # Add/edit form — name, parent folder picker
│   │
│   ├── SettingsTab.swift              # Settings tab — CSV export (ShareLink), CSV import (fileImporter), stats
│   ├── CSVService.swift               # CSV export/import engine — section-based format, RFC 4180 escaping
│   │
│   ├── SafariView.swift               # UIViewControllerRepresentable wrapping SFSafariViewController
│   ├── SpotlightService.swift         # Core Spotlight indexing for bookmarks and folders
│   ├── FolderAppearance.swift         # Color/icon palette definitions for folder customization
│   ├── ChangelogView.swift            # In-app "What's New" version history sheet
│   ├── SharedModelContainer.swift     # App Group shared ModelContainer for extensions
│   ├── FaviconService.swift           # Favicon fetching via LPMetadataProvider + Google API
│   ├── LinkCheckerService.swift       # Dead link detection via HEAD requests
│   ├── URLValidator.swift             # Centralized HTTP(S) URL validation
│   ├── ConcurrencyLimiter.swift       # Actor-based semaphore for bounded concurrency
│   │
│   └── Assets.xcassets/               # Asset catalog
│
├── BookmarkShareExtension/            # Share Extension target
│   ├── ShareViewController.swift      # Extension entry point, URL extraction
│   ├── ShareBookmarkView.swift        # SwiftUI form for saving shared URLs
│   ├── BookmarkShareExtension.entitlements
│   └── Info.plist                     # Extension activation rules
│
├── BookmarkWidget/                    # Widget Extension target
│   ├── BookmarkWidget.swift           # Timeline provider, small/medium widget views
│   └── BookmarkWidget.entitlements
│
├── just-another-appTests/             # Unit tests (Swift Testing framework)
│   └── just_another_appTests.swift    # BookmarkTests, FolderTests, BookmarkListStateTests, CSVServiceTests
│
├── just-another-appUITests/           # UI tests (XCTest)
│   ├── just_another_appUITests.swift
│   └── just_another_appUITestsLaunchTests.swift
│
├── CLAUDE.md                          # Claude Code instructions (build commands, conventions, pointers)
├── PLAN.md                            # Implementation plan, phase tracker, change log
├── CHANGELOG.md                       # Version history (keep in format)
├── LICENSE                            # MIT License
└── README.md                          # This file
```

## Data Models

### Bookmark (`Bookmark.swift`)

| Property | Type | Default | Notes |
|----------|------|---------|-------|
| `url` | `String` | — | HTTP/HTTPS URL |
| `name` | `String` | — | Display name |
| `descriptionText` | `String` | `""` | Named `descriptionText` to avoid shadowing NSObject's `description` |
| `createdDate` | `Date` | `.now` | |
| `isFavorite` | `Bool` | `false` | |
| `sortOrder` | `Int` | `0` | Used for manual drag-to-reorder |
| `faviconData` | `Data?` | `nil` | Stored PNG favicon |
| `linkStatus` | `String` | `"unknown"` | "unknown", "valid", or "dead" |
| `lastCheckedDate` | `Date?` | `nil` | When link was last validated |
| `folder` | `Folder?` | `nil` | Inverse of `Folder.bookmarks` |

### Folder (`Folder.swift`)

| Property | Type | Default | Notes |
|----------|------|---------|-------|
| `name` | `String` | — | |
| `sortOrder` | `Int` | `0` | |
| `parent` | `Folder?` | `nil` | Enables nesting |
| `children` | `[Folder]` | `[]` | Inverse of `parent`. Delete rule: `.nullify` |
| `bookmarks` | `[Bookmark]` | `[]` | Delete rule: `.nullify` (bookmarks become uncategorized) |
| `colorName` | `String` | `"blue"` | Folder color key (maps via `FolderAppearance`) |
| `iconName` | `String` | `"folder.fill"` | SF Symbol name for folder icon (maps via `FolderAppearance`) |

**Computed properties:**
- `bookmarkCount` — direct bookmark count
- `totalBookmarkCount` — recursive count including all nested children

## Features

### Bookmarks Tab (`BookmarksTab.swift`)

- **View modes:** List (`BookmarkListView`) and Card (`BookmarkCardView`) grid, toggled with toolbar button. Animated crossfade transition between modes.
- **Search:** `searchable` modifier filtering by name, URL, and description (case-insensitive, in-memory).
- **Sort:** Toolbar menu — Newest First, Oldest First, A-Z, Z-A, Manual. Manual mode enables drag-to-reorder via `.onMove`.
- **Filter:** Toolbar menu — Favorites Only toggle, Folder picker (with active filter count badge on icon).
- **Bookmark row:** Rounded-rect favicon (32px), name, URL with inline colored folder badge capsule. Swipe right to favorite (yellow tint), swipe left to delete. Context menu: favorite, open in-app browser, delete. Supports `onOpenURL` for deep linking.
- **Bookmark card:** Rounded-rect favicon (20px), name, URL, colored folder badge. Glass effect card. Context menu same as row. Supports `onOpenURL` for deep linking.
- **Add/Edit:** Sheet form (`BookmarkFormView`) with URL field (pre-filled with `https://`, keyboard type `.URL`, HTTP/HTTPS validation with inline error), name (auto-filled from URL via `LPMetadataProvider`), description (multi-line), folder picker (Button-based selection). Duplicate URL detection warns when a URL already exists. Same form serves both add and edit. Edit mode shows created date.
- **Delete:** All deletes show a confirmation alert before proceeding.
- **Batch operations:** Select mode enables multi-select across bookmarks. Batch actions: toggle favorite, move to folder, delete selected. Managed via `BookmarkListState`.

### Folders Tab (`FoldersTab.swift`)

- **List:** Top-level folders (filtered by `parent == nil`), sorted by name. Each row shows folder icon, name, and total bookmark count.
- **Navigation:** `NavigationLink` pushes to `FolderDetailView`.
- **FolderDetailView:** Two sections — Subfolders (with NavigationLinks for deep nesting) and Bookmarks (sorted newest first). Toolbar "+" menu to add bookmark (pre-selects current folder) or add subfolder.
- **Add/Edit:** Sheet form (`FolderFormView`) with name field, parent folder picker (Button-based selection, excludes self to prevent cycles), color picker, and icon picker.
- **Colors & icons:** Folders can have a custom color and SF Symbol icon (defined in `FolderAppearance.swift`). Colored icon badges appear in folder rows, folder detail views, and bookmark folder badge capsules.
- **Swipe actions:** Swipe left to delete (with confirmation), swipe right to edit (orange tint). Context menu: edit, delete.
- **Delete:** Confirmation alert warns bookmarks will become uncategorized.

### Settings Tab (`SettingsTab.swift`)

- **Export:** `ShareLink` generates CSV string and presents iOS share sheet. Filename: `bookmarks.csv`.
- **Import:** `fileImporter` accepting `.commaSeparatedText` and `.plainText`. Shows confirmation alert warning that import replaces all data. Handles security-scoped resource access. Shows success/error alert.
- **Stats:** Displays current bookmark and folder counts.
- **Spotlight:** "Rebuild Spotlight Index" button to re-index all bookmarks.
- **About:** Displays app version (marketing version + build number from `Bundle.main.infoDictionary`). "What's New" button opens `ChangelogView` sheet with version history.

### CSV Format (`CSVService.swift`)

Section-based single-file format with RFC 4180 field escaping:

```
#FOLDERS
name,sortOrder,parentPath,colorName,iconName
Work,0,,blue,briefcase.fill
Projects,1,Work,green,folder.fill
Personal,2,,purple,heart.fill

#BOOKMARKS
url,name,descriptionText,createdDate,isFavorite,sortOrder,folderPath
https://example.com,Example,A site,2026-02-14T10:00:00Z,true,0,Work/Projects
```

- Folder hierarchy preserved via path strings (e.g. `Work/Projects/Archive`)
- `parentPath`/`folderPath` empty = no parent / uncategorized
- Dates in ISO 8601 format
- Import: deletes all existing data, creates folders top-down by path depth, then creates bookmarks with folder lookups
- Export: folders flattened parent-first via recursive traversal, bookmarks as-is

### Favicons (`FaviconService.swift`)

- Bookmark favicons are fetched automatically when adding a new bookmark.
- Uses `LPMetadataProvider.iconProvider` (same as name auto-fill) with fallback to Google's favicon API.
- Favicons stored as PNG data on the `Bookmark` model (`faviconData: Data?`).
- Displayed as rounded-rect icons in `BookmarkRowView` (32x32) and `BookmarkCardView` (20x20).
- Fallback: `globe` SF Symbol with `tertiarySystemFill` background when no favicon is available.
- Settings > "Fetch Missing Favicons" batch-fetches icons for all bookmarks without one.

### Share Extension (`BookmarkShareExtension/`)

- Save bookmarks directly from Safari, Chrome, or any app with a share sheet.
- Extracts shared URL from `NSExtensionItem` attachments.
- SwiftUI form with auto-filled name (via `LPMetadataProvider`), read-only URL, and hierarchical folder picker.
- Uses `SharedModelContainer` for App Group data access.
- **Manual Xcode step required:** Create Share Extension target (File > New > Target > Share Extension, name: `BookmarkShareExtension`, bundle ID: `tech.prana.just-another-app.ShareExtension`). Add shared source files to target membership: `Bookmark.swift`, `Folder.swift`, `FolderAppearance.swift`, `SharedModelContainer.swift`, `FaviconService.swift`.

### Home Screen Widget (`BookmarkWidget/`)

- Small widget: vertical list of 4 bookmarks with favicons.
- Medium widget: 2-column grid of 6 bookmarks with favicons.
- Favorites shown first, then recent bookmarks.
- Tap a bookmark to open its URL directly.
- Timeline refreshes hourly; also refreshes when bookmarks are saved in the app.
- **Manual Xcode step required:** Create Widget Extension target (File > New > Target > Widget Extension, name: `BookmarkWidget`, bundle ID: `tech.prana.just-another-app.Widget`, uncheck "Include Configuration App Intent"). Add shared source files to target membership: `Bookmark.swift`, `Folder.swift`, `SharedModelContainer.swift`.

### Dead Link Detection (`LinkCheckerService.swift`)

- Settings > "Check All Links" validates all bookmark URLs via HEAD requests (10s timeout).
- HTTP 200-399 = valid, everything else = dead.
- Dead bookmarks show a red warning triangle icon in list and card views.
- "Dead Links Only" filter toggle in Bookmarks tab filter menu.
- Results stored on `Bookmark` model: `linkStatus` ("unknown"/"valid"/"dead") and `lastCheckedDate`.

### Quick Actions

- Long-press the app icon on the home screen for shortcuts.
- "Add Bookmark" — opens the bookmark form immediately.
- "View Favorites" — switches to the Bookmarks tab.

### UX Polish

- **Delete confirmations:** All destructive actions across all tabs show an alert with item name before proceeding.
- **Created date in edit form:** Bookmark edit form displays the creation date. Dates are not shown in list/card views for a compact layout.
- **URL validation:** Bookmark form validates HTTP/HTTPS scheme and host presence. Shows inline red error text. Save disabled when invalid.
- **Haptic feedback:** Medium impact on favorite toggle, warning notification on confirmed deletes. Uses `UIImpactFeedbackGenerator` and `UINotificationFeedbackGenerator`.
- **Animated transitions:** View mode toggle uses opacity crossfade via `.animation(.default, value:)` and `.transition(.opacity)`.

### In-App Browser (`SafariView.swift`)

- Opens bookmarks in an in-app browser using `SFSafariViewController` wrapped in a `UIViewControllerRepresentable`.
- Triggered from bookmark row/card context menus and `onOpenURL` deep link callbacks.

### Spotlight Indexing (`SpotlightService.swift`)

- Indexes bookmarks and folders in Core Spotlight (`CSSearchableItem`) for system-wide search.
- Automatically updates the index when bookmarks or folders are created, modified, or deleted.
- **Privacy toggle** in Settings — disable Spotlight indexing to keep bookmarks private. Toggling off wipes the index; toggling on re-indexes all bookmarks.

### Schema Migration Recovery

- `just_another_appApp.swift` includes schema migration recovery: if the `ModelContainer` fails to initialize (e.g., due to schema changes), the corrupt store is deleted and recreated to prevent crashes.

### Versioning

- `MARKETING_VERSION` in project.pbxproj tracks the user-facing version (currently `1.4.0`).
- `CURRENT_PROJECT_VERSION` tracks the build number (currently `7`).
- `CHANGELOG.md` documents all changes per version.
- `ChangelogView.swift` mirrors the changelog in-app, shown from Settings > "What's New".

## Privacy

- **Local-only storage** — all bookmark data is stored on-device using SwiftData. No cloud sync, no analytics, no telemetry.
- **Spotlight opt-out** — Settings > Spotlight > toggle off to prevent bookmark names and URLs from appearing in iOS system search. Toggling off immediately deletes the Spotlight index.
- **No external network calls** except:
  - **Google Favicon API** (`google.com/s2/favicons`) — fetches website icons by domain. Only the domain name is sent; no bookmark names, descriptions, or user data.
  - **LPMetadataProvider** (Apple) — fetches page titles and icons when adding bookmarks.
  - **HEAD requests** — link checking validates bookmark URLs via HTTP HEAD requests.
- **CSV injection protection** — exported CSV files sanitize cells to prevent formula injection when opened in spreadsheet applications.
- **URL validation** — only HTTP and HTTPS URLs are accepted. Non-HTTP(S) URLs (e.g., `javascript:`, `data:`, `file:`) are rejected on import and in forms.

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## Tests

Unit tests in `just-another-appTests/just_another_appTests.swift` using Swift Testing framework (`import Testing`):

| Suite | Tests | Coverage |
|-------|-------|----------|
| `BookmarkTests` | `bookmarkInitDefaults`, `bookmarkInitWithAllFields`, `bookmarkInsertAndFetch`, `bookmarkDelete`, `bookmarkFavoriteToggle`, `bookmarkUpdateFields` | Bookmark model CRUD, defaults, field updates |
| `FolderTests` | `folderInitDefaults`, `folderBookmarkCount`, `folderTotalBookmarkCountWithNesting`, `folderInsertAndFetch`, `folderDeleteNullifiesBookmarks`, `folderParentChildRelationship` | Folder model, nesting, counts, nullify delete rule |
| `BookmarkListStateTests` | `defaultState`, `viewModeToggle`, `sortModeCases`, `sortModeRawValues` | State object defaults, enum cases |
| `CSVServiceTests` | CSV export/import round-trip, field escaping, section parsing, injection protection, invalid URL skipping | CSVService export/import logic, RFC 4180 compliance, CSV injection, URL validation |
| `URLValidatorTests` | `validHTTPSURL`, `validHTTPURL`, `invalidSchemes`, `invalidURLs`, `canonicalize` | URL validation and canonicalization |

Tests use in-memory `ModelContainer` via `makeContainer()` helper. Tests requiring `ModelContext` are annotated `@MainActor`.

## Conventions

- **`descriptionText` not `description`:** SwiftData models inherit from NSObject; `description` shadows the built-in property. Always use `descriptionText`.
- **`@Query` + in-memory filtering:** Fetch all records with `@Query`, apply search/sort/filter as computed properties. Avoids complex predicate construction.
- **Dual-mode forms:** Form views accept an optional existing object. `nil` = add mode, non-nil = edit mode. Populated via `.onAppear`.
- **Delete rule `.nullify`:** All folder relationships use nullify. Deleting a folder makes its bookmarks uncategorized rather than deleting them.
- **No pbxproj edits needed:** `PBXFileSystemSynchronizedRootGroup` auto-discovers files. Just create `.swift` files in `just-another-app/`.
