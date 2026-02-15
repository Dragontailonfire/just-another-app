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
