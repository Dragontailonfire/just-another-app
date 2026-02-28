//
//  ReadingListTab.swift
//  just-another-app
//
//  Created by Narayanan VK on 19/02/2026.
//

import SwiftUI
import SwiftData
import UIKit

// MARK: - Snapshot types

struct RemovedReadingListItem {
    let url: String
    let name: String
    let faviconData: Data?
    let addedDate: Date

    init(_ item: ReadingListItem) {
        url = item.url
        name = item.name
        faviconData = item.faviconData
        addedDate = item.addedDate
    }
}

struct ReadingListSaveInfo: Identifiable, Equatable {
    let id = UUID()
    let url: String
    let name: String
    let faviconData: Data?
}

// MARK: - Tab

struct ReadingListTab: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ReadingListItem.addedDate) private var items: [ReadingListItem]

    @AppStorage("readingListLimit") private var limit = 10
    @AppStorage("tapAction") private var tapActionRaw = TapAction.openInApp.rawValue

    @State private var urlToOpen: IdentifiableURL?
    @State private var itemToSave: ReadingListSaveInfo?
    @State private var pendingSaveSource: ReadingListItem?
    @State private var pendingAdd: (url: String, name: String, faviconData: Data?)?
    @State private var removedItem: RemovedReadingListItem?
    @State private var showingUndoBanner = false
    @State private var undoTask: Task<Void, Never>?

    private var tapAction: TapAction { TapAction(rawValue: tapActionRaw) ?? .openInApp }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView(
                        "Reading List Empty",
                        systemImage: "text.book.closed",
                        description: Text("Long-press any bookmark and choose \"Add to Reading List\".")
                    )
                } else {
                    List {
                        ForEach(items) { item in
                            ReadingListRowView(item: item)
                                .contentShape(Rectangle())
                                .onTapGesture { openItem(item) }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        scheduleRemove(item)
                                    } label: {
                                        Label("Remove", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        saveToBookmarks(item)
                                    } label: {
                                        Label("Save to Bookmarks", systemImage: "bookmark.fill")
                                    }
                                    .tint(.blue)
                                }
                                .contextMenu {
                                    if let url = URL(string: item.url) {
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
                                    Button {
                                        UIPasteboard.general.string = item.url
                                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                                    } label: {
                                        Label("Copy URL", systemImage: "doc.on.doc")
                                    }
                                    Divider()
                                    Button {
                                        saveToBookmarks(item)
                                    } label: {
                                        Label("Save to Bookmarks", systemImage: "bookmark.fill")
                                    }
                                    Divider()
                                    Button(role: .destructive) {
                                        scheduleRemove(item)
                                    } label: {
                                        Label("Remove", systemImage: "trash")
                                    }
                                }
                        }
                        Section {} footer: {
                            Text("Add items by long-pressing any bookmark.")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if showingUndoBanner, let removed = removedItem {
                    HStack {
                        Text("Removed \"\(removed.name)\"")
                            .font(.subheadline)
                        Spacer()
                        Button("Undo") { undoRemove(removed) }
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
            .navigationTitle("Reading List")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                if !items.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Text("\(items.count) / \(limit)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }
            .sheet(item: $urlToOpen) { identifiable in
                SafariView(url: identifiable.url)
                    .ignoresSafeArea()
            }
            .sheet(item: $itemToSave) { info in
                BookmarkFormView(
                    startingURL: info.url,
                    startingName: info.name,
                    startingFaviconData: info.faviconData,
                    onSave: {
                        if let src = pendingSaveSource {
                            scheduleRemove(src)
                        }
                        pendingSaveSource = nil
                    }
                )
            }
            .onChange(of: itemToSave) { _, new in
                // User cancelled the form without saving — clear the pending source
                if new == nil { pendingSaveSource = nil }
            }
            .alert("Reading List is Full", isPresented: Binding(
                get: { pendingAdd != nil },
                set: { if !$0 { pendingAdd = nil } }
            )) {
                Button("Cancel", role: .cancel) { pendingAdd = nil }
                Button("Remove Oldest & Add") {
                    if let pending = pendingAdd {
                        removeOldestAndAdd(url: pending.url, name: pending.name, faviconData: pending.faviconData)
                    }
                    pendingAdd = nil
                }
            } message: {
                if let oldest = items.first {
                    Text("Remove \"\(oldest.name)\" to make room?")
                } else {
                    Text("The reading list is full.")
                }
            }
        }
    }

    // MARK: - Open

    private func openItem(_ item: ReadingListItem) {
        guard let url = URL(string: item.url) else { return }
        switch tapAction {
        case .openInApp:
            urlToOpen = IdentifiableURL(url: url)
        case .openInBrowser:
            UIApplication.shared.open(url)
        case .edit:
            saveToBookmarks(item)
        }
    }

    // MARK: - Save to Bookmarks

    private func saveToBookmarks(_ item: ReadingListItem) {
        pendingSaveSource = item
        itemToSave = ReadingListSaveInfo(url: item.url, name: item.name, faviconData: item.faviconData)
    }

    // MARK: - Undo Remove

    private func scheduleRemove(_ item: ReadingListItem) {
        let snapshot = RemovedReadingListItem(item)
        undoTask?.cancel()
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        modelContext.delete(item)
        removedItem = snapshot
        withAnimation { showingUndoBanner = true }
        undoTask = Task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            await MainActor.run { withAnimation { showingUndoBanner = false } }
        }
    }

    private func undoRemove(_ snapshot: RemovedReadingListItem) {
        undoTask?.cancel()
        let item = ReadingListItem(url: snapshot.url, name: snapshot.name, faviconData: snapshot.faviconData)
        item.addedDate = snapshot.addedDate
        modelContext.insert(item)
        withAnimation { showingUndoBanner = false }
        removedItem = nil
    }

    // MARK: - At-capacity helpers (called by RemoveOldest alert)

    private func removeOldestAndAdd(url: String, name: String, faviconData: Data?) {
        if let oldest = items.first {
            modelContext.delete(oldest)
        }
        let item = ReadingListItem(url: url, name: name, faviconData: faviconData)
        modelContext.insert(item)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

#Preview {
    ReadingListTab()
        .modelContainer(for: [Bookmark.self, Folder.self, ReadingListItem.self], inMemory: true)
}
