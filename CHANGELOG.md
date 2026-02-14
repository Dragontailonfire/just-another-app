# Changelog

All notable changes to this project will be documented in this file.

## [1.1.0] - 2026-02-15

### Added
- **Settings tab** with CSV import/export, data stats, Spotlight rebuild, and About section
- **CSV import/export** — full backup and restore of all bookmarks and folders
- **Auto-fill from URL** — paste a URL and the name auto-fills from the page title
- **Duplicate URL detection** — warns when adding a bookmark with an existing URL
- **In-app browser** — open links in SFSafariViewController without leaving the app
- **Folder colors & icons** — customize folders with 8 colors and 12 SF Symbol icons
- **Spotlight indexing** — bookmarks appear in iOS system search
- **Batch operations** — multi-select bookmarks to favorite, move, or delete in bulk
- **Delete confirmations** — all destructive actions show a confirmation alert
- **Relative dates** — bookmark rows and cards show "2 hours ago" style timestamps
- **URL validation** — bookmark form validates HTTP/HTTPS URLs with inline feedback
- **Haptic feedback** — tactile response on favorite toggles and confirmed deletes
- **Animated transitions** — smooth crossfade between list and card view modes
- **Schema migration recovery** — app auto-recovers if the data schema changes
- **In-app changelog** — "What's New" screen accessible from Settings
- **Version display** — app version and build number shown in Settings
- **URL pre-fill** — bookmark form starts with `https://` for convenience

### Fixed
- Fixed crash when selecting folders in forms (replaced SwiftUI Picker with Button-based selection to avoid AnyHashable2 hash collision with SwiftData models)

## [1.0.0] - 2026-02-14

### Added
- Initial release
- **Bookmark management** — add, edit, delete, favorite bookmarks with URL, name, description
- **Folder organization** — nested folder hierarchy with parent/child relationships
- **Search** — filter bookmarks by name, URL, or description
- **Sort** — newest, oldest, A-Z, Z-A, manual drag-to-reorder
- **Filter** — favorites only, by folder
- **View modes** — list and card grid layouts
- **Swipe actions** — swipe to delete or favorite
- **Context menus** — quick actions on long press
- **Open in Safari** — launch bookmarked URLs externally
