//
//  BookmarkFormView.swift
//  just-another-app
//
//  Created by Narayanan VK on 14/02/2026.
//

import SwiftUI
import SwiftData
import LinkPresentation

struct BookmarkFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var bookmarkToEdit: Bookmark?
    var defaultFolder: Folder?

    @State private var url: String = "https://"
    @State private var name: String = ""
    @State private var descriptionText: String = ""
    @State private var selectedFolder: Folder?
    @State private var isFetchingMetadata = false
    @State private var metadataTask: Task<Void, Never>?
    @State private var showingDuplicateAlert = false

    @Query(sort: \Folder.name) private var folders: [Folder]
    @Query private var allBookmarks: [Bookmark]

    private var isEditing: Bool { bookmarkToEdit != nil }

    private var isValidURL: Bool {
        guard let parsed = URL(string: url),
              let scheme = parsed.scheme?.lowercased(),
              (scheme == "http" || scheme == "https"),
              parsed.host != nil else {
            return false
        }
        return true
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
                }
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
        } else {
            selectedFolder = defaultFolder
        }
    }

    private func save() {
        if let bookmark = bookmarkToEdit {
            bookmark.url = url
            bookmark.name = name
            bookmark.descriptionText = descriptionText
            bookmark.folder = selectedFolder
            SpotlightService.index(bookmark: bookmark)
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
            folder: selectedFolder
        )
        modelContext.insert(bookmark)
        SpotlightService.index(bookmark: bookmark)
        dismiss()
    }

    private func fetchMetadataDebounced(for urlString: String) {
        metadataTask?.cancel()
        metadataTask = Task {
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            guard !urlString.isEmpty, name.isEmpty,
                  let parsed = URL(string: urlString),
                  let scheme = parsed.scheme?.lowercased(),
                  (scheme == "http" || scheme == "https"),
                  parsed.host != nil else { return }

            await MainActor.run { isFetchingMetadata = true }
            let provider = LPMetadataProvider()
            do {
                let metadata = try await provider.startFetchingMetadata(for: parsed)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    if name.isEmpty, let title = metadata.title {
                        name = title
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
