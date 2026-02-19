# iOS 26 Design System Notes

Reference for implementing the next UI redesign pass. Based on Apple HIG, WWDC 2025 sessions, and observed behaviour in iOS 26 apps.

---

## Core Principles (Liquid Glass)

1. **Content is primary.** Interface elements fade away; content takes centre stage.
2. **Glass is navigation-only.** Liquid Glass belongs exclusively on the navigation layer (nav bars, tab bars, toolbars, modals). Never apply `.glassEffect()` to content items like list rows, cards, or cells.
3. **Three visual layers:**
   - Content layer (primary — lists, cards, media)
   - Glass navigation/control layer (floating above content)
   - Background (visible through glass)
4. **Floating nav.** Navigation bars, tab bars, and toolbars float above content rather than being fixed to edges. They shrink as the user scrolls down and expand when scrolling back up.
5. **Depth via translucency.** Real-time light bending, specular highlights, adaptive shadows. The system handles this automatically for standard SwiftUI components.

---

## What We've Already Applied

- ✅ `.glassEffect()` on pickers in `FolderFormView`
- ✅ Removed `GlassEffectContainer` from the card grid in `BookmarksTab` (v1.7.0) — cards use system backgrounds, no glass content inside
- ✅ Removed `.glassEffect()` from `BookmarkCardView` (v1.6.0) — cards are content, not navigation
- ✅ iOS 26 deployment target; standard components (nav bar, tab bar) auto-adopt glass
- ✅ `Tab(role: .search)` for the Search tab (v1.7.0) — search icon in tab bar, morphs into a full-width search field on tap
- ✅ Individual `ToolbarItem` declarations in `BookmarksTab` (v1.7.0) — adjacent icon buttons auto-grouped under glass by iOS 26

---

## Planned Redesign — Main View

### Search Bar
- **Recommendation:** `.searchable()` on a `NavigationStack` inside `TabView` auto-positions at the bottom on iPhone in iOS 26.
- **Current state:** Search appears under the navigation title (top). The auto-positioning may require a different `TabView` structure.
- **To investigate:** Whether wrapping `NavigationStack` differently (e.g., using `Tab` API directly rather than `TabView { Tab { NavigationStack } }`) triggers bottom placement.
- **API tried:** `.searchToolbarBehavior(.minimized)` — does not compile; `SearchToolbarBehavior` has no `.minimized` member.
- **Goal:** Search icon collapses into tab bar area; tapping expands a full-width field replacing the tab buttons.

### Toolbar Item Grouping
- iOS 26 automatically groups `ToolbarItem` entries that are adjacent image buttons under a shared glass background.
- **Action:** Ensure toolbar items in `BookmarksTab` are declared as individual `ToolbarItem` (not wrapped in a single `ToolbarItemGroup` with manual `HStack`) so the system can auto-group them.
- Currently: `ToolbarItemGroup(placement: .topBarTrailing)` with filter menu, select, sort, view toggle, add — these should ideally be separate `ToolbarItem` declarations.

### Scroll Edge Effects
- iOS 26 `ScrollView`, `List`, and `Form` automatically blur/dim content at edges where it meets the navigation layer (under large title, above tab bar, behind toolbars).
- This is the **default** behaviour — no modifier needed to enable it.
- To **disable** for a specific edge: `.scrollEdgeEffectStyle(.hard, for: .bottom)`.
- **Action:** Verify this looks good in the bookmarks list and card grid. No code change likely needed.

### List Row Separator Insets
- With floating tab bar, list rows near the bottom need to not visually clash with the glass layer.
- Consider `.listRowBackground(Color.clear)` for rows near safe area edges if visual conflict appears.

### Card Grid
- `GlassEffectContainer` is correct for grouping. It provides the shared visual context for any glass elements inside.
- Cards themselves should use system backgrounds (`Color(.secondarySystemGroupedBackground)`) — already done in v1.6.0.
- Consider whether the card grid should use `LazyVGrid` inside a `ScrollView` or switch to a native `List` grid for better scroll-edge effect integration.

---

## Tab Bar Redesign Considerations

- The tab bar is capsule-shaped and inset from screen edges (floating).
- It shrinks automatically on scroll — no code needed.
- Adding a search capability to the tab bar area requires using the new `Tab` API:
  ```swift
  TabView {
      Tab("Bookmarks", systemImage: "bookmark.fill") {
          BookmarksTab()
      }
      Tab("Search", systemImage: "magnifyingglass", role: .search) {
          // search experience
      }
  }
  ```
  The `.role: .search` tab gets special treatment in the tab bar (positioned separately, morphs into a search field on tap).

---

## Typography & Colour

- **Large titles** should be used on root-level views (`BookmarksTab`, `FoldersTab`, `SettingsTab`). Sub-views use `.inline`.
- **Avoid hard backgrounds** behind text near the bottom of the screen — they compete with the glass tab bar highlights.
- **Accent colour:** Currently system blue. Consider whether a custom accent improves brand identity.

---

## APIs to Use / Avoid

| Use | Avoid |
|-----|-------|
| `.glassEffect()` on controls, badges, pickers | `.glassEffect()` on list rows, cards, content |
| `GlassEffectContainer` for card grids | Manual `HStack` of glass items without container |
| Individual `ToolbarItem` declarations | Single `ToolbarItemGroup` wrapping everything in `HStack` |
| `.safeAreaInset` for custom overlays (undo toast) | Fixed-position `ZStack` overlays that ignore safe area |
| `Tab(role: .search)` for search tab | Custom tab bar implementations |
| `.searchable()` — iOS 26 auto-positions | `.searchToolbarBehavior(.minimized)` — does not exist |

---

## Reference

- [Apple HIG — Navigation and Search](https://developer.apple.com/design/human-interface-guidelines/navigation-and-search)
- [Adopting Liquid Glass — Apple Developer](https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass)
- [WWDC 2025 — Build a UIKit app with the new design (session 284)](https://developer.apple.com/videos/play/wwdc2025/284/)
- [SwiftUI Search Enhancements in iOS 26 — nilcoalescing.com](https://nilcoalescing.com/blog/SwiftUISearchEnhancementsIniOSAndiPadOS26/)
- [Tab and Search APIs in iOS 26 — hasanalidev.medium.com](https://hasanalidev.medium.com/swiftui-tab-and-search-apis-in-ios-26-90ee32208c5d)
