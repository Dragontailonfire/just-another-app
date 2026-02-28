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
    @State private var subfolderToDelete: Folder?
    @State private var subfolderToEdit: Folder?
    @State private var urlToOpen: IdentifiableURL?
    @State private var searchText = ""
    @State private var deletedBookmark: BookmarkSnapshot? = nil
    @State private var showingUndoBanner = false
    @State private var undoTask: Task<Void, Never>? = nil
    @AppStorage("tapAction") private var tapActionRaw = TapAction.openInApp.rawValue
    @AppStorage("readingListLimit") private var readingListLimit = 10
    @Query(sort: \ReadingListItem.addedDate) private var readingListItems: [ReadingListItem]
    @State private var pendingReadingListAdd: Bookmark?

    private var tapAction: TapAction { TapAction(rawValue: tapActionRaw) ?? .openInApp }

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
                            onDelete: { scheduleDelete(bookmark) },
                            onEdit: { bookmarkToEdit = bookmark },
                            onOpenURL: { urlToOpen = IdentifiableURL(url: $0) },
                            onAddToReadingList: { addToReadingList(bookmark) }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture { openBookmark(bookmark) }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if showingUndoBanner, let snap = deletedBookmark {
                HStack {
                    Text("Deleted \"\(snap.name)\"")
                        .font(.subheadline)
                    Spacer()
                    Button("Undo") { undoDelete(snap) }
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .padding(.bottom, 4)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: showingUndoBanner)
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
        .alert("Delete Subfolder?", isPresented: Binding(
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
        .alert("Reading List is Full", isPresented: Binding(
            get: { pendingReadingListAdd != nil },
            set: { if !$0 { pendingReadingListAdd = nil } }
        )) {
            Button("Cancel", role: .cancel) { pendingReadingListAdd = nil }
            Button("Remove Oldest & Add") {
                if let bookmark = pendingReadingListAdd {
                    insertIntoReadingList(bookmark, removingOldest: true)
                }
                pendingReadingListAdd = nil
            }
        } message: {
            if let oldest = readingListItems.first {
                Text("Remove \"\(oldest.name)\" to make room?")
            } else {
                Text("The reading list is full.")
            }
        }
    }

    // MARK: - Tap Action

    private func openBookmark(_ bookmark: Bookmark) {
        switch tapAction {
        case .openInApp:
            if let url = URL(string: bookmark.url) {
                urlToOpen = IdentifiableURL(url: url)
            }
        case .openInBrowser:
            if let url = URL(string: bookmark.url) {
                UIApplication.shared.open(url)
            }
        case .edit:
            bookmarkToEdit = bookmark
        }
    }

    // MARK: - Undo Delete

    private func scheduleDelete(_ bookmark: Bookmark) {
        let snapshot = BookmarkSnapshot(bookmark)
        undoTask?.cancel()
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        SpotlightService.deindex(bookmark: bookmark)
        modelContext.delete(bookmark)
        deletedBookmark = snapshot
        withAnimation { showingUndoBanner = true }
        undoTask = Task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            await MainActor.run { withAnimation { showingUndoBanner = false } }
        }
    }

    private func undoDelete(_ snapshot: BookmarkSnapshot) {
        undoTask?.cancel()
        let bookmark = Bookmark(
            url: snapshot.url,
            name: snapshot.name,
            descriptionText: snapshot.descriptionText,
            createdDate: snapshot.createdDate,
            isFavorite: snapshot.isFavorite,
            sortOrder: snapshot.sortOrder,
            folder: snapshot.folder,
            faviconData: snapshot.faviconData
        )
        modelContext.insert(bookmark)
        withAnimation { showingUndoBanner = false }
        deletedBookmark = nil
    }

    // MARK: - Reading List

    private func addToReadingList(_ bookmark: Bookmark) {
        if readingListItems.count >= readingListLimit {
            pendingReadingListAdd = bookmark
        } else {
            insertIntoReadingList(bookmark, removingOldest: false)
        }
    }

    private func insertIntoReadingList(_ bookmark: Bookmark, removingOldest: Bool) {
        if removingOldest, let oldest = readingListItems.first {
            modelContext.delete(oldest)
        }
        let item = ReadingListItem(url: bookmark.url, name: bookmark.name, faviconData: bookmark.faviconData)
        modelContext.insert(item)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
