//
//  ChangelogView.swift
//  just-another-app
//
//  Created by Narayanan VK on 14/02/2026.
//

import SwiftUI

struct ChangelogView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    releaseSection(
                        version: "1.5.0",
                        date: "February 18, 2026",
                        items: [
                            "App Icon — custom bookmark icon with light, dark, and tinted variants",
                            "Copy URL — one tap from swipe or context menu to copy a bookmark URL to the clipboard",
                            "Customizable swipe actions — assign Favorite, Copy URL, Edit, or Delete to each swipe direction in Settings",
                            "Search within folder — search bar in every folder detail view filters bookmarks and subfolders",
                            "HTML export — export bookmarks as a browser-importable HTML file (Safari, Chrome, Firefox, Edge)",
                        ]
                    )
                }

                Section {
                    releaseSection(
                        version: "1.4.0",
                        date: "February 17, 2026",
                        items: [
                            "Spotlight Privacy Toggle — disable Spotlight indexing in Settings to keep bookmarks private",
                            "CSV Injection Protection — exported cells are sanitized to prevent spreadsheet formula injection",
                            "URL Validation on Import — non-HTTP(S) URLs are skipped with a count shown after import",
                            "Atomic CSV Import — all rows validated before deleting data, preventing loss on errors",
                            "File Size Cap — CSV import rejects files larger than 5 MB",
                            "Import Stats — shows folder, bookmark, and skipped counts after import",
                            "Network Hardening — capped concurrent requests, ephemeral sessions, redirect guards, timeouts",
                            "Duplicate Detection in Share Extension — warns when URL already exists",
                            "Cancel on Dismiss — metadata fetch cancelled when bookmark form is closed",
                        ]
                    )
                }

                Section {
                    releaseSection(
                        version: "1.3.0",
                        date: "February 16, 2026",
                        items: [
                            "Share Extension — save bookmarks from Safari and other apps",
                            "Favicons — bookmark icons fetched automatically from websites",
                            "Home Screen Widget — quick access to bookmarks (small & medium)",
                            "Dead Link Detection — find broken URLs with one tap",
                            "Quick Actions — long-press app icon to add bookmark or view favorites",
                            "Fetch Missing Favicons button in Settings",
                            "Check All Links button in Settings",
                            "Dead Links Only filter in Bookmarks tab",
                            "App Group shared container for extension data access",
                            "Larger rounded-rect favicons for compact, modern look",
                            "Streamlined rows — dates moved to edit form for cleaner layout",
                            "Inline folder badge next to URL",
                        ]
                    )
                }

                Section {
                    releaseSection(
                        version: "1.2.1",
                        date: "February 15, 2026",
                        items: [
                            "Folder child count on folder rows",
                            "Hierarchical folder paths in all pickers",
                            "Fixed duplicate navigation destination warning",
                            "Fixed singular/plural count labels",
                            "Liquid Glass selection and layout polish",
                        ]
                    )
                }

                Section {
                    releaseSection(
                        version: "1.2.0",
                        date: "February 15, 2026",
                        items: [
                            "iOS 26 Liquid Glass design",
                            "Glass effect on bookmark cards",
                            "Glass selection highlights in folder form",
                            "Native two-finger multi-select in list view",
                            "Multi-select support in card view",
                            "Deployment target raised to iOS 26.0",
                        ]
                    )
                }

                Section {
                    releaseSection(
                        version: "1.1.1",
                        date: "February 15, 2026",
                        items: [
                            "Compact 2-column card/tile view",
                            "Clear Filters button in filter menu",
                            "Edit swipe and context menu on subfolders",
                            "Fixed subfolder name bug when creating inside a folder",
                            "Fixed NaN CoreGraphics error in card grid",
                        ]
                    )
                }

                Section {
                    releaseSection(
                        version: "1.1.0",
                        date: "February 14, 2026",
                        items: [
                            "Settings tab with CSV import/export",
                            "Auto-fill bookmark name from URL",
                            "Duplicate URL detection",
                            "In-app browser (SFSafariViewController)",
                            "Folder colors & icons customization",
                            "Spotlight search indexing",
                            "Batch operations (select, favorite, move, delete)",
                            "Delete confirmation alerts",
                            "Relative date display on bookmarks",
                            "URL validation in bookmark form",
                            "Haptic feedback on actions",
                            "Animated view mode transitions",
                        ]
                    )
                }

                Section {
                    releaseSection(
                        version: "1.0.0",
                        date: "February 14, 2026",
                        items: [
                            "Bookmark management (add, edit, delete, favorite)",
                            "Folder organization with nesting",
                            "Search by name, URL, description",
                            "Sort: newest, oldest, A-Z, Z-A, manual",
                            "Filter by favorites and folder",
                            "List and card view modes",
                            "Swipe actions and context menus",
                            "Open bookmarks in Safari",
                        ]
                    )
                }
            }
            .navigationTitle("What's New")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func releaseSection(version: String, date: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("v\(version)")
                    .font(.headline)
                Spacer()
                Text(date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(item)
                        .font(.subheadline)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ChangelogView()
}
