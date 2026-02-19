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
    @State private var showingHTMLImporter = false
    @State private var isFetchingFavicons = false
    @State private var isCheckingLinks = false
    @AppStorage("spotlightIndexingEnabled") private var spotlightIndexingEnabled = true
    @AppStorage("leadingSwipeAction") private var leadingSwipeRaw = SwipeAction.favorite.rawValue
    @AppStorage("trailingSwipeAction") private var trailingSwipeRaw = SwipeAction.delete.rawValue
    @AppStorage("tapAction") private var tapActionRaw = TapAction.openInApp.rawValue

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: Data
                Section {
                    ShareLink(
                        "Export as CSV",
                        item: generateCSV(),
                        preview: SharePreview("bookmarks.csv")
                    )

                    ShareLink(
                        "Export as HTML",
                        item: generateHTML(),
                        preview: SharePreview("bookmarks.html")
                    )

                    Button("Import CSV") {
                        showingImporter = true
                    }

                    Button("Import from Browser (HTML)") {
                        showingHTMLImporter = true
                    }
                } header: {
                    Text("Data")
                } footer: {
                    Text("CSV replaces all data (backup/restore). HTML merges bookmarks from browser exports without deleting existing data.")
                }

                // MARK: Stats
                Section("Stats") {
                    LabeledContent("Bookmarks", value: "\(bookmarks.count)")
                    LabeledContent("Folders", value: "\(folders.count)")
                }

                // MARK: Gestures
                Section {
                    Picker("Tap", selection: $tapActionRaw) {
                        ForEach(TapAction.allCases, id: \.rawValue) { action in
                            Text(action.label).tag(action.rawValue)
                        }
                    }
                    Picker("Leading Swipe", selection: $leadingSwipeRaw) {
                        ForEach(leadingSwipeOptions, id: \.rawValue) { action in
                            Label(action.label, systemImage: action.systemImage).tag(action.rawValue)
                        }
                    }
                    Picker("Trailing Swipe", selection: $trailingSwipeRaw) {
                        ForEach(trailingSwipeOptions, id: \.rawValue) { action in
                            Label(action.label, systemImage: action.systemImage).tag(action.rawValue)
                        }
                    }
                } header: {
                    Text("Gestures")
                } footer: {
                    Text("Choose what a tap opens, and what each swipe direction does on a bookmark.")
                }

                // MARK: Maintenance
                Section {
                    Button {
                        fetchMissingFavicons()
                    } label: {
                        HStack {
                            Text("Fetch Missing Favicons")
                            Spacer()
                            if isFetchingFavicons {
                                ProgressView().controlSize(.small)
                            }
                        }
                    }
                    .disabled(isFetchingFavicons)

                    Button {
                        checkAllLinks()
                    } label: {
                        HStack {
                            Text("Check All Links")
                            Spacer()
                            if isCheckingLinks {
                                ProgressView().controlSize(.small)
                            }
                        }
                    }
                    .disabled(isCheckingLinks)
                } header: {
                    Text("Maintenance")
                } footer: {
                    Text("Fetch favicons for bookmarks missing icons. Check links to find broken URLs.")
                }

                // MARK: Spotlight
                Section {
                    Toggle("Spotlight Indexing", isOn: $spotlightIndexingEnabled)
                        .onChange(of: spotlightIndexingEnabled) { _, enabled in
                            if enabled {
                                SpotlightService.reindexAll(bookmarks: bookmarks)
                            } else {
                                SpotlightService.deleteAll()
                            }
                        }

                    Button("Rebuild Spotlight Index") {
                        SpotlightService.reindexAll(bookmarks: bookmarks)
                        alertTitle = "Spotlight Updated"
                        alertMessage = "All bookmarks have been re-indexed."
                        showingAlert = true
                    }
                    .disabled(!spotlightIndexingEnabled)
                } header: {
                    Text("Spotlight")
                } footer: {
                    Text("Bookmark names and URLs appear in iOS Spotlight search. Disable to keep bookmarks private.")
                }

                // MARK: About
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
                Button("Cancel", role: .cancel) { pendingImportURL = nil }
                Button("Import", role: .destructive) {
                    if let url = pendingImportURL { performImport(from: url) }
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
            .fileImporter(
                isPresented: $showingHTMLImporter,
                allowedContentTypes: [.html, .plainText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    performHTMLImport(from: url)
                case .failure(let error):
                    alertTitle = "Import Failed"
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }

    // MARK: - Swipe options

    private var leadingSwipeOptions: [SwipeAction] {
        [.favorite, .copyURL, .edit, .delete]
    }

    private var trailingSwipeOptions: [SwipeAction] {
        [.delete, .favorite, .copyURL, .edit]
    }

    // MARK: - Export helpers

    private func generateCSV() -> String {
        CSVService.exportCSV(folders: folders, bookmarks: bookmarks)
    }

    private func generateHTML() -> String {
        HTMLExportService.exportHTML(folders: folders, bookmarks: bookmarks)
    }

    // MARK: - Import

    private func performImport(from url: URL) {
        do {
            guard url.startAccessingSecurityScopedResource() else {
                alertTitle = "Import Failed"
                alertMessage = "Could not access the selected file."
                showingAlert = true
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? UInt64, fileSize > CSVService.maxImportFileSize {
                alertTitle = "Import Failed"
                alertMessage = "File exceeds the 5 MB import limit."
                showingAlert = true
                return
            }

            let csvString = try String(contentsOf: url, encoding: .utf8)
            let stats = try CSVService.importCSV(from: csvString, context: modelContext)
            if SpotlightService.isEnabled {
                SpotlightService.reindexAll(bookmarks: bookmarks)
            }

            alertTitle = "Import Successful"
            var message = "Imported \(stats.folders) folder\(stats.folders == 1 ? "" : "s") and \(stats.bookmarks) bookmark\(stats.bookmarks == 1 ? "" : "s")."
            if stats.skipped > 0 {
                message += " Skipped \(stats.skipped) invalid URL\(stats.skipped == 1 ? "" : "s")."
            }
            alertMessage = message
            showingAlert = true
        } catch {
            alertTitle = "Import Failed"
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }

    private func performHTMLImport(from url: URL) {
        do {
            guard url.startAccessingSecurityScopedResource() else {
                alertTitle = "Import Failed"
                alertMessage = "Could not access the selected file."
                showingAlert = true
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? UInt64, fileSize > HTMLImportService.maxImportFileSize {
                alertTitle = "Import Failed"
                alertMessage = "File exceeds the 10 MB import limit."
                showingAlert = true
                return
            }

            let html = try String(contentsOf: url, encoding: .utf8)
            let stats = try HTMLImportService.importHTML(from: html, context: modelContext)
            if SpotlightService.isEnabled {
                SpotlightService.reindexAll(bookmarks: bookmarks)
            }

            alertTitle = "Import Successful"
            var message = "Added \(stats.foldersCreated) folder\(stats.foldersCreated == 1 ? "" : "s") and \(stats.bookmarksAdded) bookmark\(stats.bookmarksAdded == 1 ? "" : "s")."
            if stats.skipped > 0 {
                message += " Skipped \(stats.skipped) duplicate or invalid URL\(stats.skipped == 1 ? "" : "s")."
            }
            alertMessage = message
            showingAlert = true
        } catch {
            alertTitle = "Import Failed"
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }

    // MARK: - Maintenance

    private func fetchMissingFavicons() {
        isFetchingFavicons = true
        let bookmarksToFetch = bookmarks
        Task {
            let count = await FaviconService.fetchMissingFavicons(bookmarks: bookmarksToFetch)
            await MainActor.run {
                isFetchingFavicons = false
                alertTitle = "Favicons Updated"
                alertMessage = "Fetched \(count) favicon\(count == 1 ? "" : "s")."
                showingAlert = true
            }
        }
    }

    private func checkAllLinks() {
        isCheckingLinks = true
        let bookmarksToCheck = bookmarks
        Task {
            let (valid, dead) = await LinkCheckerService.checkAllLinks(bookmarks: bookmarksToCheck)
            await MainActor.run {
                isCheckingLinks = false
                alertTitle = "Link Check Complete"
                alertMessage = "\(valid) valid, \(dead) dead link\(dead == 1 ? "" : "s") found."
                showingAlert = true
            }
        }
    }
}

#Preview {
    SettingsTab()
        .modelContainer(for: [Bookmark.self, Folder.self], inMemory: true)
}
