//
//  ShareBookmarkView.swift
//  BookmarkShareExtension
//
//  Created by Narayanan VK on 16/02/2026.
//

import SwiftUI
import SwiftData
import LinkPresentation

struct ShareBookmarkView: View {
    let url: URL
    let onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Folder.name) private var folders: [Folder]

    @State private var name: String = ""
    @State private var selectedFolder: Folder?
    @State private var isFetchingMetadata = false
    @State private var fetchedFaviconData: Data?

    private var isValidURL: Bool {
        guard let scheme = url.scheme?.lowercased(),
              (scheme == "http" || scheme == "https"),
              url.host != nil else {
            return false
        }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("URL") {
                    Text(url.absoluteString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Details") {
                    HStack {
                        TextField("Name", text: $name)
                        if isFetchingMetadata {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
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
            .navigationTitle("Save Bookmark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.isEmpty)
                }
            }
            .onAppear {
                fetchMetadata()
            }
        }
    }

    private func save() {
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

    private func fetchMetadata() {
        guard isValidURL else { return }
        isFetchingMetadata = true
        Task {
            let provider = LPMetadataProvider()
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
