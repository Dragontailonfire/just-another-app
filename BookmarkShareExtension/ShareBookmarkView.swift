//
//  ShareBookmarkView.swift
//  BookmarkShareExtension
//
//  Created by Narayanan VK on 16/02/2026.
//

import SwiftUI
import SwiftData
import LinkPresentation

private enum SaveDestination: String, CaseIterable {
    case bookmark    = "Bookmark"
    case readingList = "Reading List"
}

struct ShareBookmarkView: View {
    let url: URL
    let onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Folder.name) private var folders: [Folder]
    @Query private var allBookmarks: [Bookmark]

    @State private var name: String = ""
    @State private var selectedFolder: Folder?
    @State private var isFetchingMetadata = false
    @State private var fetchedFaviconData: Data?
    @State private var showingDuplicateAlert = false
    @State private var saveDestination: SaveDestination = .bookmark

    private var isValidURL: Bool {
        URLValidator.isValid(url.absoluteString)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("URL") {
                    Text(url.absoluteString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !isValidURL {
                        Text("Only HTTP and HTTPS URLs are supported.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("Details") {
                    HStack {
                        TextField("Name", text: $name)
                        if isFetchingMetadata {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                    Picker("Save to", selection: $saveDestination) {
                        ForEach(SaveDestination.allCases, id: \.self) { dest in
                            Text(dest.rawValue).tag(dest)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if saveDestination == .bookmark {
                    Section("Folder") {
                        Button {
                            selectedFolder = nil
                        } label: {
                            HStack {
                                Text("None")
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedFolder == nil {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        ForEach(Folder.hierarchicalSort(folders)) { folder in
                            Button {
                                selectedFolder = folder
                            } label: {
                                HStack {
                                    Image(systemName: folder.iconName)
                                        .foregroundStyle(FolderAppearance.color(for: folder.colorName))
                                    Text(folder.path)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if selectedFolder?.persistentModelID == folder.persistentModelID {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(saveDestination == .bookmark ? "Save Bookmark" : "Add to Reading List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.isEmpty || !isValidURL)
                }
            }
            .onAppear {
                fetchMetadata()
            }
            .alert("Duplicate URL", isPresented: $showingDuplicateAlert) {
                Button("Save Anyway") { insertBookmark() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("A bookmark with this URL already exists.")
            }
        }
    }

    private func save() {
        switch saveDestination {
        case .bookmark:
            let trimmedURL = url.absoluteString.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if allBookmarks.contains(where: { $0.url.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == trimmedURL }) {
                showingDuplicateAlert = true
                return
            }
            insertBookmark()
        case .readingList:
            insertReadingListItem()
        }
    }

    private func insertBookmark() {
        let bookmark = Bookmark(
            url: url.absoluteString,
            name: name,
            folder: selectedFolder,
            faviconData: fetchedFaviconData
        )
        modelContext.insert(bookmark)
        try? modelContext.save()
        onDismiss()
    }

    private func insertReadingListItem() {
        let item = ReadingListItem(url: url.absoluteString, name: name, faviconData: fetchedFaviconData)
        modelContext.insert(item)
        try? modelContext.save()
        onDismiss()
    }

    private func fetchMetadata() {
        guard isValidURL else { return }
        isFetchingMetadata = true
        Task {
            let provider = LPMetadataProvider()
            provider.timeout = 10
            do {
                let metadata = try await provider.startFetchingMetadata(for: url)
                await MainActor.run {
                    if name.isEmpty, let title = metadata.title {
                        name = title
                    }
                    isFetchingMetadata = false
                }

                // Fetch favicon in background
                let faviconData = await FaviconService.fetchFavicon(for: url.absoluteString)
                await MainActor.run {
                    fetchedFaviconData = faviconData
                }
            } catch {
                await MainActor.run {
                    if name.isEmpty {
                        name = url.host ?? url.absoluteString
                    }
                    isFetchingMetadata = false
                }
            }
        }
    }
}
