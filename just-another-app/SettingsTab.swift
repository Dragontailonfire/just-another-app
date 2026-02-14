//
//  SettingsTab.swift
//  just-another-app
//
//  Created by Narayanan VK on 14/02/2026.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var bookmarks: [Bookmark]
    @Query private var folders: [Folder]

    @State private var showingImporter = false
    @State private var showingImportConfirm = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var csvExportData: String?
    @State private var pendingImportURL: URL?
    @State private var showingChangelog = false

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ShareLink(
                        "Export Bookmarks",
                        item: generateCSV(),
                        preview: SharePreview("bookmarks.csv")
                    )

                    Button("Import Bookmarks") {
                        showingImporter = true
                    }
                } header: {
                    Text("Data")
                } footer: {
                    Text("Export creates a CSV file with all folders and bookmarks. Import replaces all existing data.")
                }

                Section("Stats") {
                    LabeledContent("Bookmarks", value: "\(bookmarks.count)")
                    LabeledContent("Folders", value: "\(folders.count)")
                }

                Section {
                    Button("Rebuild Spotlight Index") {
                        SpotlightService.reindexAll(bookmarks: bookmarks)
                        alertTitle = "Spotlight Updated"
                        alertMessage = "All bookmarks have been re-indexed."
                        showingAlert = true
                    }
                } header: {
                    Text("Spotlight")
                } footer: {
                    Text("Re-indexes all bookmarks for iOS Spotlight search.")
                }

                Section("About") {
                    LabeledContent("Version", value: appVersion)
                    Button("What's New") {
                        showingChangelog = true
                    }
                }
            }
            .navigationTitle("Settings")
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [UTType.commaSeparatedText, UTType.plainText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    pendingImportURL = url
                    showingImportConfirm = true
                case .failure(let error):
                    alertTitle = "Import Failed"
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
            .alert("Replace All Data?", isPresented: $showingImportConfirm) {
                Button("Cancel", role: .cancel) {
                    pendingImportURL = nil
                }
                Button("Import", role: .destructive) {
                    if let url = pendingImportURL {
                        performImport(from: url)
                    }
                    pendingImportURL = nil
                }
            } message: {
                Text("Importing will delete all existing bookmarks and folders, then recreate them from the CSV file. This cannot be undone.")
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") {}
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showingChangelog) {
                ChangelogView()
            }
        }
    }

    private func generateCSV() -> String {
        CSVService.exportCSV(folders: folders, bookmarks: bookmarks)
    }

    private func performImport(from url: URL) {
        do {
            guard url.startAccessingSecurityScopedResource() else {
                alertTitle = "Import Failed"
                alertMessage = "Could not access the selected file."
                showingAlert = true
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            let csvString = try String(contentsOf: url, encoding: .utf8)
            try CSVService.importCSV(from: csvString, context: modelContext)
            SpotlightService.reindexAll(bookmarks: bookmarks)

            alertTitle = "Import Successful"
            alertMessage = "All data has been imported."
            showingAlert = true
        } catch {
            alertTitle = "Import Failed"
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
}

#Preview {
    SettingsTab()
        .modelContainer(for: [Bookmark.self, Folder.self], inMemory: true)
}
