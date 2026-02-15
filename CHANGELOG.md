# Changelog

All notable changes to this project will be documented in this file.

## [1.2.1] - 2026-02-15

### Added
- **Folder child count** — folder rows now show immediate subfolder count alongside bookmark count
- **Hierarchical folder paths** — folder pickers (filter, move, bookmark form, folder form) show full path (e.g. "Work › Projects") with parent-child grouping

### Fixed
- Fixed duplicate `navigationDestination` warning when navigating into child folders
- Fixed pluralization ("1 bookmark" vs "2 bookmarks", "1 folder" vs "0 folders")
- Liquid Glass polish: card selection checkmarks moved to left side, selection count in navigation title, tab bar hidden in select mode
- Folder badge reverted from glass tint to opacity background for better text legibility
- Native two-finger multi-select gesture in list view

## [1.2.0] - 2026-02-15

### Changed
- **iOS 26 Liquid Glass design** — updated to iOS 26.0 with native glass materials
- Bookmark cards now use `.glassEffect()` for blur, depth, and lighting
- Folder form selection states (color and icon pickers) use glass highlights
- Deployment target raised to iOS 26.0
- Standard UI components (tabs, navigation, lists, forms) auto-adopt Liquid Glass
- Native two-finger multi-select gesture in list view via `List(selection:)`
- Multi-select support in card view with left-aligned checkmarks
- Selection count displayed in navigation title instead of toolbar button
- Tab bar hidden during select mode to prevent overlap with batch action buttons

### Technical
- Requires Xcode 26.0+
- Card grid wrapped in `GlassEffectContainer` for proper glass compositing

## [1.1.1] - 2026-02-15

### Added
- **Compact card view** — tile layout now uses a 2-column grid with smaller cards for more content at a glance
- **Clear Filters** — quick-reset button in filter menu to remove all active filters in one tap
- **Edit swipe on subfolders** — swipe-to-edit and context menu now available on folders inside folder detail view

### Fixed
- Fixed subfolder name showing as "Child" instead of actual name (explicitly sync parent-child relationship on save)
- Fixed NaN CoreGraphics error in card grid layout

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
