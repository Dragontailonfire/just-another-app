//
//  FolderDetailView.swift
//  just-another-app
//
//  Created by Narayanan VK on 14/02/2026.
//

import SwiftUI
import SwiftData
import UIKit

struct FolderDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let folder: Folder

    @State private var showingAddBookmark = false
    @State private var showingAddSubfolder = false
    @State private var bookmarkToEdit: Bookmark?
    @State private var bookmarkToDelete: Bookmark?
    @State private var subfolderToDelete: Folder?
    @State private var subfolderToEdit: Folder?
    @State private var urlToOpen: IdentifiableURL?
    @State private var searchText = ""

    private var filteredBookmarks: [Bookmark] {
        let sorted = folder.bookmarks.sorted(by: { $0.createdDate > $1.createdDate })
        guard !searchText.isEmpty else { return sorted }
        let query = searchText.lowercased()
        return sorted.filter {
            $0.name.lowercased().contains(query) ||
            $0.url.lowercased().contains(query) ||
            $0.descriptionText.lowercased().contains(query)
        }
    }

    private var filteredSubfolders: [Folder] {
        let sorted = folder.children.sorted(by: { $0.name < $1.name })
        guard !searchText.isEmpty else { return sorted }
        return sorted.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }

    var body: some View {
        List {
            if !filteredSubfolders.isEmpty {
                Section("Subfolders") {
                    ForEach(filteredSubfolders) { child in
                        NavigationLink(value: child) {
                            FolderRowView(folder: child)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                subfolderToDelete = child
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                subfolderToEdit = child
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.orange)
                        }
                        .contextMenu {
                            Button {
                                subfolderToEdit = child
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                subfolderToDelete = child
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }

            Section("\(folder.bookmarks.count) \(folder.bookmarks.count == 1 ? "Bookmark" : "Bookmarks")") {
                if filteredBookmarks.isEmpty {
                    Text(searchText.isEmpty ? "No bookmarks in this folder" : "No results")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredBookmarks) { bookmark in
                        BookmarkRowView(
                            bookmark: bookmark,
                            onToggleFavorite: {
                                bookmark.isFavorite.toggle()
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            },
                            onDelete: { bookmarkToDelete = bookmark },
                            onEdit: { bookmarkToEdit = bookmark },
                            onOpenURL: { urlToOpen = IdentifiableURL(url: $0) }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture { bookmarkToEdit = bookmark }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search in \(folder.name)")
        .navigationTitle(folder.name)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingAddBookmark = true
                    } label: {
                        Label("Add Bookmark", systemImage: "bookmark.fill")
                    }
                    Button {
                        showingAddSubfolder = true
                    } label: {
                        Label("Add Subfolder", systemImage: "folder.badge.plus")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $urlToOpen) { item in
            SafariView(url: item.url)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showingAddBookmark) {
            BookmarkFormView(bookmarkToEdit: nil, defaultFolder: folder)
        }
        .sheet(isPresented: $showingAddSubfolder) {
            FolderFormView(parentFolder: folder)
        }
        .sheet(item: $subfolderToEdit) { subfolder in
            FolderFormView(folderToEdit: subfolder)
        }
        .sheet(item: $bookmarkToEdit) { bookmark in
            BookmarkFormView(bookmarkToEdit: bookmark)
        }
        .alert("Delete Bookmark?", isPresented: Binding(
            get: { bookmarkToDelete != nil },
            set: { if !$0 { bookmarkToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { bookmarkToDelete = nil }
            Button("Delete", role: .destructive) {
                if let bookmark = bookmarkToDelete {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    SpotlightService.deindex(bookmark: bookmark)
                    modelContext.delete(bookmark)
                }
                bookmarkToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete \"\(bookmarkToDelete?.name ?? "")\"?")
        }
        .alert("Delete Folder?", isPresented: Binding(
            get: { subfolderToDelete != nil },
            set: { if !$0 { subfolderToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { subfolderToDelete = nil }
            Button("Delete", role: .destructive) {
                if let subfolder = subfolderToDelete {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    modelContext.delete(subfolder)
                }
                subfolderToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete \"\(subfolderToDelete?.name ?? "")\"?")
        }
    }
}
