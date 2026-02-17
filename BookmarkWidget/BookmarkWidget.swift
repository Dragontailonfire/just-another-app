//
//  BookmarkWidget.swift
//  BookmarkWidget
//
//  Created by Narayanan VK on 16/02/2026.
//

import WidgetKit
import SwiftUI
import SwiftData

struct BookmarkSnapshot: Identifiable {
    let id: String
    let name: String
    let url: String
    let isFavorite: Bool
    let faviconData: Data?
}

struct BookmarkEntry: TimelineEntry {
    let date: Date
    let bookmarks: [BookmarkSnapshot]
}

struct BookmarkProvider: TimelineProvider {
    func placeholder(in context: Context) -> BookmarkEntry {
        BookmarkEntry(date: .now, bookmarks: [
            BookmarkSnapshot(id: "1", name: "Example", url: "https://example.com", isFavorite: true, faviconData: nil),
            BookmarkSnapshot(id: "2", name: "Apple", url: "https://apple.com", isFavorite: false, faviconData: nil),
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (BookmarkEntry) -> Void) {
        let entry = BookmarkEntry(date: .now, bookmarks: fetchBookmarks(count: maxCount(for: context.family)))
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BookmarkEntry>) -> Void) {
        let entry = BookmarkEntry(date: .now, bookmarks: fetchBookmarks(count: maxCount(for: context.family)))
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func maxCount(for family: WidgetFamily) -> Int {
        switch family {
        case .systemSmall: return 4
        case .systemMedium: return 6
        default: return 4
        }
    }

    private func fetchBookmarks(count: Int) -> [BookmarkSnapshot] {
        do {
            let container = SharedModelContainer.create()
            let context = ModelContext(container)
            var descriptor = FetchDescriptor<Bookmark>(sortBy: [
                SortDescriptor(\Bookmark.createdDate, order: .reverse),
            ])
            let allBookmarks = try context.fetch(descriptor)
            // Favorites first, then recent
            let bookmarks = allBookmarks.sorted { a, b in
                if a.isFavorite != b.isFavorite { return a.isFavorite }
                return a.createdDate > b.createdDate
            }
            return Array(bookmarks.prefix(count)).map { bookmark in
                BookmarkSnapshot(
                    id: bookmark.url,
                    name: bookmark.name,
                    url: bookmark.url,
                    isFavorite: bookmark.isFavorite,
                    faviconData: bookmark.faviconData
                )
            }
        } catch {
            return []
        }
    }
}

struct SmallWidgetView: View {
    let entry: BookmarkEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(entry.bookmarks.prefix(4)) { bookmark in
                if let url = URL(string: bookmark.url) {
                    Link(destination: url) {
                        HStack(spacing: 6) {
                            faviconView(data: bookmark.faviconData, size: 14)
                            Text(bookmark.name)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            if bookmark.isFavorite {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.yellow)
                            }
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding()
    }
}

struct MediumWidgetView: View {
    let entry: BookmarkEntry

    var body: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(entry.bookmarks.prefix(6)) { bookmark in
                if let url = URL(string: bookmark.url) {
                    Link(destination: url) {
                        HStack(spacing: 4) {
                            faviconView(data: bookmark.faviconData, size: 14)
                            Text(bookmark.name)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            if bookmark.isFavorite {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.yellow)
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
}

@ViewBuilder
private func faviconView(data: Data?, size: CGFloat) -> some View {
    if let data = data, let uiImage = UIImage(data: data) {
        Image(uiImage: uiImage)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(Circle())
    } else {
        Image(systemName: "globe")
            .font(.system(size: size * 0.8))
            .frame(width: size, height: size)
            .foregroundStyle(.secondary)
    }
}

struct BookmarkWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: BookmarkProvider.Entry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct BookmarkWidget: Widget {
    let kind: String = "BookmarkWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BookmarkProvider()) { entry in
            BookmarkWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Bookmarks")
        .description("Quick access to your bookmarks.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
