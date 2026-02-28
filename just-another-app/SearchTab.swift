//
//  SearchTab.swift
//  just-another-app
//
//  Created by Narayanan VK on 19/02/2026.
//

import SwiftUI
import SwiftData
import UIKit

struct SearchTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allBookmarks: [Bookmark]
    @Query(sort: \Folder.name) private var allFolders: [Folder]

    @State private var searchText = ""
    @State private var bookmarksExpanded = true
    @State private var foldersExpanded = true
    @AppStorage("tapAction") private var tapActionRaw = TapAction.openInApp.rawValue
    @AppStorage("readingListLimit") private var readingListLimit = 10
    @Query(sort: \ReadingListItem.addedDate) private var readingListItems: [ReadingListItem]
    @State private var urlToOpen: IdentifiableURL?
    @State private var bookmarkToEdit: Bookmark?
    @State private var deletedBookmark: BookmarkSnapshot? = nil
    @State private var showingUndoBanner = false
    @State private var undoTask: Task<Void, Never>? = nil
    @State private var pendingReadingListAdd: Bookmark?

    private var tapAction: TapAction { TapAction(rawValue: tapActionRaw) ?? .openInApp }

    private var matchingBookmarks: [Bookmark] {
        guard !searchText.isEmpty else { return [] }
        let query = searchText.lowercased()
        return allBookmarks.filter {
            $0.name.lowercased().contains(query) ||
            $0.url.lowercased().contains(query) ||
            $0.descriptionText.lowercased().contains(query)
        }
    }

    private var matchingFolders: [Folder] {
        guard !searchText.isEmpty else { return [] }
        let query = searchText.lowercased()
        return allFolders.filter { $0.name.lowercased().contains(query) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if searchText.isEmpty {
                    ContentUnavailableView(
                        "Search",
                        systemImage: "magnifyingglass",
                        description: Text("Search your bookmarks and folders.")
                    )
                } else if matchingBookmarks.isEmpty && matchingFolders.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List {
                        if !matchingBookmarks.isEmpty {
                            Section(isExpanded: $bookmarksExpanded) {
                                ForEach(matchingBookmarks) { bookmark in
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
                            } header: {
                                Button {
                                    withAnimation { bookmarksExpanded.toggle() }
                                } label: {
                                    HStack {
                                        Text("Bookmarks (\(matchingBookmarks.count))")
                                        Spacer()
                                        Image(systemName: bookmarksExpanded ? "chevron.down" : "chevron.forward")
                                            .font(.caption)
                                    }
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.secondary)
                                .textCase(nil)
                                .font(.footnote.weight(.semibold))
                            }
                        }
                        if !matchingFolders.isEmpty {
                            Section(isExpanded: $foldersExpanded) {
                                ForEach(matchingFolders) { folder in
                                    NavigationLink(value: folder) {
                                        FolderRowView(folder: folder)
                                    }
                                }
                            } header: {
                                Button {
                                    withAnimation { foldersExpanded.toggle() }
                                } label: {
                                    HStack {
                                        Text("Folders (\(matchingFolders.count))")
                                        Spacer()
                                        Image(systemName: foldersExpanded ? "chevron.down" : "chevron.forward")
                                            .font(.caption)
                                    }
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.secondary)
                                .textCase(nil)
                                .font(.footnote.weight(.semibold))
                            }
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
            .onChange(of: searchText) {
                bookmarksExpanded = true
                foldersExpanded = true
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Search bookmarks and folders")
            .navigationDestination(for: Folder.self) { folder in
                FolderDetailView(folder: folder)
            }
            .sheet(item: $urlToOpen) { item in
                SafariView(url: item.url)
                    .ignoresSafeArea()
            }
            .sheet(item: $bookmarkToEdit) { bookmark in
                BookmarkFormView(bookmarkToEdit: bookmark)
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

#Preview {
    SearchTab()
        .modelContainer(for: [Bookmark.self, Folder.self], inMemory: true)
}
