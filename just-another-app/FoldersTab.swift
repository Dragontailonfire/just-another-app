//
//  FoldersTab.swift
//  just-another-app
//
//  Created by Narayanan VK on 14/02/2026.
//

import SwiftUI
import SwiftData
import UIKit

struct FoldersTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Folder.name) private var allFolders: [Folder]

    @State private var showingAddFolder = false
    @State private var folderToEdit: Folder?
    @State private var folderToDelete: Folder?

    private var topLevelFolders: [Folder] {
        allFolders.filter { $0.parent == nil }
    }

    var body: some View {
        NavigationStack {
            Group {
                if allFolders.isEmpty {
                    ContentUnavailableView(
                        "No Folders",
                        systemImage: "folder",
                        description: Text("Tap + to create your first folder.")
                    )
                } else {
                    List {
                        ForEach(topLevelFolders) { folder in
                            NavigationLink(value: folder) {
                                FolderRowView(folder: folder)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    folderToDelete = folder
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    folderToEdit = folder
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.orange)
                            }
                            .contextMenu {
                                Button {
                                    folderToEdit = folder
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    folderToDelete = folder
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Folders")
            .navigationDestination(for: Folder.self) { folder in
                FolderDetailView(folder: folder)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddFolder = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddFolder) {
                FolderFormView()
            }
            .sheet(item: $folderToEdit) { folder in
                FolderFormView(folderToEdit: folder)
            }
            .alert("Delete Folder?", isPresented: Binding(
                get: { folderToDelete != nil },
                set: { if !$0 { folderToDelete = nil } }
            )) {
                Button("Cancel", role: .cancel) { folderToDelete = nil }
                Button("Delete", role: .destructive) {
                    if let folder = folderToDelete {
                        UINotificationFeedbackGenerator().notificationOccurred(.warning)
                        modelContext.delete(folder)
                    }
                    folderToDelete = nil
                }
            } message: {
                Text("Are you sure you want to delete \"\(folderToDelete?.name ?? "")\"? Bookmarks in this folder will become uncategorized.")
            }
        }
    }
}

#Preview {
    FoldersTab()
        .modelContainer(for: [Bookmark.self, Folder.self], inMemory: true)
}
