//
//  BookmarksTab.swift
//  just-another-app
//
//  Created by Narayanan VK on 14/02/2026.
//

import SwiftUI
import SwiftData
import UIKit

struct BookmarksTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allBookmarks: [Bookmark]
    @Query(sort: \Folder.name) private var folders: [Folder]

    @Binding var filterFavoritesOnAppear: Bool
    @State private var listState = BookmarkListState()
    @AppStorage("tapAction") private var tapActionRaw = TapAction.openInApp.rawValue
    @State private var deletedBookmark: BookmarkSnapshot? = nil
    @State private var showingUndoBanner = false
    @State private var undoTask: Task<Void, Never>? = nil

    private var tapAction: TapAction { TapAction(rawValue: tapActionRaw) ?? .openInApp }

    init(filterFavoritesOnAppear: Binding<Bool> = .constant(false)) {
        _filterFavoritesOnAppear = filterFavoritesOnAppear
    }

    private var hierarchicalFolders: [Folder] {
        Folder.hierarchicalSort(folders)
    }
    @State private var showingAddForm = false
    @State private var bookmarkToEdit: Bookmark?
    @State private var showingFilters = false
    @State private var urlToOpen: IdentifiableURL?
    @State private var showingMoveFolder = false

    private var filteredAndSorted: [Bookmark] {
        var result = allBookmarks

        // Search
        if !listState.searchText.isEmpty {
            let query = listState.searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                $0.url.lowercased().contains(query) ||
                $0.descriptionText.lowercased().contains(query)
            }
        }

        // Filter: favorites
        if listState.filterFavoritesOnly {
            result = result.filter { $0.isFavorite }
        }

        // Filter: folder
        if let folder = listState.filterFolder {
            result = result.filter { $0.folder?.persistentModelID == folder.persistentModelID }
        }

        // Filter: dead links
        if listState.filterDeadLinksOnly {
            result = result.filter { $0.linkStatus == "dead" }
        }

        // Sort
        switch listState.sortMode {
        case .newestFirst:
            result.sort { $0.createdDate > $1.createdDate }
        case .oldestFirst:
            result.sort { $0.createdDate < $1.createdDate }
        case .alphabeticalAZ:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .alphabeticalZA:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .manual:
            result.sort { $0.sortOrder < $1.sortOrder }
        }

        return result
    }

    var body: some View {
        NavigationStack {
            Group {
                if allBookmarks.isEmpty {
                    ContentUnavailableView(
                        "No Bookmarks",
                        systemImage: "bookmark",
                        description: Text("Tap + to add your first bookmark.")
                    )
                } else if filteredAndSorted.isEmpty {
                    ContentUnavailableView.search(text: listState.searchText)
                } else {
                    switch listState.viewMode {
                    case .list:
                        BookmarkListView(
                            bookmarks: filteredAndSorted,
                            listState: listState,
                            onSelect: { openBookmark($0) },
                            onEdit: { bookmarkToEdit = $0 },
                            onDelete: { scheduleDelete($0) },
                            onOpenURL: { urlToOpen = IdentifiableURL(url: $0) }
                        )
                        .transition(.opacity)
                    case .card:
                        cardGrid
                            .transition(.opacity)
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
            .animation(.default, value: listState.viewMode)
            .navigationTitle(listState.isSelectMode ? "\(listState.selectedBookmarkIDs.count) Selected" : "Bookmarks")
            .searchable(text: $listState.searchText, prompt: "Search bookmarks")
            .toolbar {
                if listState.isSelectMode {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button("Done") {
                            listState.isSelectMode = false
                            listState.selectedBookmarkIDs.removeAll()
                        }
                    }
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button {
                            batchFavorite()
                        } label: {
                            Label("Favorite", systemImage: "star.fill")
                        }
                        .disabled(listState.selectedBookmarkIDs.isEmpty)

                        Button {
                            showingMoveFolder = true
                        } label: {
                            Label("Move", systemImage: "folder")
                        }
                        .disabled(listState.selectedBookmarkIDs.isEmpty)

                        Spacer()

                        Button(role: .destructive) {
                            batchDelete()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .disabled(listState.selectedBookmarkIDs.isEmpty)
                    }
                } else {
                    ToolbarItemGroup(placement: .topBarLeading) {
                        filterMenu
                    }
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        if !allBookmarks.isEmpty {
                            Button {
                                listState.isSelectMode = true
                            } label: {
                                Image(systemName: "checkmark.circle")
                            }
                        }
                        sortMenu
                        viewModeToggle
                        Button(action: { showingAddForm = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .toolbarVisibility(listState.isSelectMode ? .hidden : .automatic, for: .tabBar)
            .sheet(item: $urlToOpen) { item in
                SafariView(url: item.url)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showingAddForm) {
                BookmarkFormView()
            }
            .sheet(item: $bookmarkToEdit) { bookmark in
                BookmarkFormView(bookmarkToEdit: bookmark)
            }
            .sheet(isPresented: $showingMoveFolder) {
                NavigationStack {
                    List {
                        Button("No Folder (Uncategorized)") {
                            batchMove(to: nil)
                            showingMoveFolder = false
                        }
                        ForEach(hierarchicalFolders) { folder in
                            Button {
                                batchMove(to: folder)
                                showingMoveFolder = false
                            } label: {
                                HStack {
                                    Image(systemName: folder.iconName)
                                        .foregroundStyle(FolderAppearance.color(for: folder.colorName))
                                    Text(folder.path)
                                }
                            }
                        }
                    }
                    .navigationTitle("Move to Folder")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showingMoveFolder = false }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .onChange(of: filterFavoritesOnAppear) { _, newValue in
                if newValue {
                    listState.filterFavoritesOnly = true
                    filterFavoritesOnAppear = false
                }
            }
        }
    }

    // MARK: - Card Grid

    private var cardGrid: some View {
        GlassEffectContainer {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible(minimum: 100)), GridItem(.flexible(minimum: 100))], spacing: 8) {
                ForEach(filteredAndSorted) { bookmark in
                    HStack(spacing: 8) {
                        if listState.isSelectMode {
                            Image(systemName: listState.selectedBookmarkIDs.contains(bookmark.persistentModelID) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(listState.selectedBookmarkIDs.contains(bookmark.persistentModelID) ? .blue : .secondary)
                                .font(.title3)
                        }
                        BookmarkCardView(bookmark: bookmark, onOpenURL: { urlToOpen = IdentifiableURL(url: $0) })
                    }
                    .contentShape(Rectangle())
                        .onTapGesture {
                            if listState.isSelectMode {
                                let id = bookmark.persistentModelID
                                if listState.selectedBookmarkIDs.contains(id) {
                                    listState.selectedBookmarkIDs.remove(id)
                                } else {
                                    listState.selectedBookmarkIDs.insert(id)
                                }
                            } else {
                                openBookmark(bookmark)
                            }
                        }
                        .contextMenu {
                            Button {
                                bookmark.isFavorite.toggle()
                            } label: {
                                Label(
                                    bookmark.isFavorite ? "Unfavorite" : "Favorite",
                                    systemImage: bookmark.isFavorite ? "star.slash" : "star.fill"
                                )
                            }
                            Button {
                                UIPasteboard.general.string = bookmark.url
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                            } label: {
                                Label("Copy URL", systemImage: "doc.on.doc")
                            }
                            if let url = URL(string: bookmark.url) {
                                Button {
                                    urlToOpen = IdentifiableURL(url: url)
                                } label: {
                                    Label("Open in App Browser", systemImage: "safari")
                                }
                                Button {
                                    UIApplication.shared.open(url)
                                } label: {
                                    Label("Open in Default Browser", systemImage: "arrow.up.right.square")
                                }
                            }
                            Divider()
                            Button {
                                bookmarkToEdit = bookmark
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button {
                                Task { await LinkCheckerService.checkLink(for: bookmark) }
                            } label: {
                                Label("Check Link", systemImage: "network")
                            }
                            Divider()
                            Button(role: .destructive) {
                                scheduleDelete(bookmark)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding()
        }
        }
    }

    // MARK: - Toolbar Menus

    private var sortMenu: some View {
        Menu {
            Picker("Sort", selection: $listState.sortMode) {
                ForEach(SortMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }

    private var viewModeToggle: some View {
        Button {
            withAnimation {
                listState.viewMode = listState.viewMode == .list ? .card : .list
            }
        } label: {
            Image(systemName: listState.viewMode == .list ? "square.grid.2x2" : "list.bullet")
        }
    }

    private var filterMenu: some View {
        Menu {
            if activeFilterCount > 0 {
                Button(role: .destructive) {
                    listState.filterFavoritesOnly = false
                    listState.filterFolder = nil
                    listState.filterDeadLinksOnly = false
                } label: {
                    Label("Clear Filters", systemImage: "xmark.circle")
                }
                Divider()
            }

            Toggle("Favorites Only", isOn: $listState.filterFavoritesOnly)
            Toggle("Dead Links Only", isOn: $listState.filterDeadLinksOnly)

            Menu("Folder") {
                Button("All Folders") {
                    listState.filterFolder = nil
                }
                Divider()
                ForEach(hierarchicalFolders) { folder in
                    Button {
                        listState.filterFolder = folder
                    } label: {
                        HStack {
                            Text(folder.path)
                            if listState.filterFolder?.persistentModelID == folder.persistentModelID {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        } label: {
            Image(systemName: activeFilterCount > 0 ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
    }

    private var activeFilterCount: Int {
        (listState.filterFavoritesOnly ? 1 : 0) +
        (listState.filterFolder != nil ? 1 : 0) +
        (listState.filterDeadLinksOnly ? 1 : 0)
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

    // MARK: - Batch Operations

    private func selectedBookmarks() -> [Bookmark] {
        allBookmarks.filter { listState.selectedBookmarkIDs.contains($0.persistentModelID) }
    }

    private func batchFavorite() {
        for bookmark in selectedBookmarks() {
            bookmark.isFavorite = true
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        listState.isSelectMode = false
        listState.selectedBookmarkIDs.removeAll()
    }

    private func batchMove(to folder: Folder?) {
        for bookmark in selectedBookmarks() {
            bookmark.folder = folder
        }
        listState.isSelectMode = false
        listState.selectedBookmarkIDs.removeAll()
    }

    private func batchDelete() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        for bookmark in selectedBookmarks() {
            SpotlightService.deindex(bookmark: bookmark)
            modelContext.delete(bookmark)
        }
        listState.isSelectMode = false
        listState.selectedBookmarkIDs.removeAll()
    }
}

#Preview {
    BookmarksTab()
        .modelContainer(for: [Bookmark.self, Folder.self], inMemory: true)
}
