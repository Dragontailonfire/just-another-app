//
//  BookmarkFormView.swift
//  just-another-app
//
//  Created by Narayanan VK on 14/02/2026.
//

import SwiftUI
import SwiftData
import LinkPresentation
import WidgetKit

struct BookmarkFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var bookmarkToEdit: Bookmark?
    var defaultFolder: Folder?
    var startingURL: String? = nil
    var startingName: String? = nil
    var startingFaviconData: Data? = nil
    var onSave: (() -> Void)? = nil

    @State private var url: String = "https://"
    @State private var name: String = ""
    @State private var descriptionText: String = ""
    @State private var selectedFolder: Folder?
    @State private var isFetchingMetadata = false
    @State private var metadataTask: Task<Void, Never>?
    @State private var showingDuplicateAlert = false
    @State private var fetchedFaviconData: Data?
    @State private var folderSearchText = ""

    @Query(sort: \Folder.name) private var folders: [Folder]
    @Query private var allBookmarks: [Bookmark]

    private var isEditing: Bool { bookmarkToEdit != nil }

    private var filteredFolders: [Folder] {
        let hierarchical = Folder.hierarchicalSort(folders)
        guard !folderSearchText.isEmpty else { return hierarchical }
        let query = folderSearchText.lowercased()
        return hierarchical.filter {
            $0.name.lowercased().contains(query) || $0.path.lowercased().contains(query)
        }
    }

    private var isValidURL: Bool {
        URLValidator.isValid(url)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("URL", text: $url)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: url) { _, newValue in
                            if !isEditing {
                                fetchMetadataDebounced(for: newValue)
                            }
                        }
                    if url != "https://" && url != "http://" && !url.isEmpty && !isValidURL {
                        Text("Enter a valid HTTP or HTTPS URL")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    HStack {
                        TextField("Name", text: $name)
                        if isFetchingMetadata {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                    TextField("Description", text: $descriptionText, axis: .vertical)
                        .lineLimit(3...6)
                    if isEditing, let bookmark = bookmarkToEdit {
                        LabeledContent("Created") {
                            Text(bookmark.createdDate, format: .dateTime.month(.wide).day().year().hour().minute())
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                Section("Folder") {
                    if folders.count > 5 {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            TextField("Search folders", text: $folderSearchText)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            if !folderSearchText.isEmpty {
                                Button {
                                    folderSearchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
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
                    ForEach(filteredFolders) { folder in
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
            .navigationTitle(isEditing ? "Edit Bookmark" : "Add Bookmark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(url.isEmpty || name.isEmpty || !isValidURL)
                }
            }
            .onAppear(perform: populateIfEditing)
            .onDisappear { metadataTask?.cancel() }
            .alert("Duplicate URL", isPresented: $showingDuplicateAlert) {
                Button("Save Anyway") { insertNewBookmark() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("A bookmark with this URL already exists.")
            }
        }
    }

    private func populateIfEditing() {
        if let bookmark = bookmarkToEdit {
            url = bookmark.url
            name = bookmark.name
            descriptionText = bookmark.descriptionText
            selectedFolder = bookmark.folder
            fetchedFaviconData = bookmark.faviconData
        } else {
            selectedFolder = defaultFolder
            if let startingURL {
                url = startingURL
                fetchedFaviconData = startingFaviconData
                if let startingName { name = startingName }
                fetchMetadataDebounced(for: startingURL)
            }
        }
    }

    private func save() {
        if let bookmark = bookmarkToEdit {
            bookmark.url = url
            bookmark.name = name
            bookmark.descriptionText = descriptionText
            bookmark.folder = selectedFolder
            if let faviconData = fetchedFaviconData {
                bookmark.faviconData = faviconData
            }
            SpotlightService.index(bookmark: bookmark)
            WidgetCenter.shared.reloadAllTimelines()
            dismiss()
        } else {
            // Duplicate detection
            let trimmedURL = url.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if allBookmarks.contains(where: { $0.url.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == trimmedURL }) {
                showingDuplicateAlert = true
                return
            }
            insertNewBookmark()
        }
    }

    private func insertNewBookmark() {
        let bookmark = Bookmark(
            url: url,
            name: name,
            descriptionText: descriptionText,
            folder: selectedFolder,
            faviconData: fetchedFaviconData
        )
        modelContext.insert(bookmark)
        SpotlightService.index(bookmark: bookmark)
        WidgetCenter.shared.reloadAllTimelines()
        onSave?()
        dismiss()
    }

    private func fetchMetadataDebounced(for urlString: String) {
        metadataTask?.cancel()
        metadataTask = Task {
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            guard !urlString.isEmpty, name.isEmpty,
                  URLValidator.isValid(urlString),
                  let parsed = URL(string: urlString) else { return }

            await MainActor.run { isFetchingMetadata = true }
            let provider = LPMetadataProvider()
            provider.timeout = 10
            do {
                let metadata = try await provider.startFetchingMetadata(for: parsed)
                guard !Task.isCancelled else { return }

                // Extract favicon from metadata
                var iconData: Data?
                if let iconProvider = metadata.iconProvider {
                    iconData = try? await withCheckedThrowingContinuation { continuation in
                        iconProvider.loadDataRepresentation(for: .image) { data, error in
                            if let data = data {
                                continuation.resume(returning: data)
                            } else {
                                continuation.resume(throwing: error ?? URLError(.cannotDecodeContentData))
                            }
                        }
                    }
                }

                await MainActor.run {
                    if name.isEmpty, let title = metadata.title {
                        name = title
                    }
                    if let iconData = iconData {
                        fetchedFaviconData = iconData
                    }
                    isFetchingMetadata = false
                }
            } catch {
                await MainActor.run { isFetchingMetadata = false }
            }
        }
    }
}

#Preview("Add") {
    BookmarkFormView()
        .modelContainer(for: [Bookmark.self, Folder.self], inMemory: true)
}
