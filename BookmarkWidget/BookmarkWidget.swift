//
//  BookmarkWidget.swift
//  BookmarkWidget
//
//  Created by Narayanan VK on 16/02/2026.
//

import WidgetKit
import SwiftUI
import SwiftData

struct ReadingListSnapshot: Identifiable {
    let id: String
    let name: String
    let url: String
    let faviconData: Data?
}

struct ReadingListEntry: TimelineEntry {
    let date: Date
    let items: [ReadingListSnapshot]
}

struct ReadingListProvider: TimelineProvider {
    func placeholder(in context: Context) -> ReadingListEntry {
        ReadingListEntry(date: .now, items: [
            ReadingListSnapshot(id: "1", name: "Article to Read", url: "https://example.com", faviconData: nil),
            ReadingListSnapshot(id: "2", name: "Interesting Post", url: "https://apple.com", faviconData: nil),
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (ReadingListEntry) -> Void) {
        let entry = ReadingListEntry(date: .now, items: fetchItems(count: maxCount(for: context.family)))
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReadingListEntry>) -> Void) {
        let entry = ReadingListEntry(date: .now, items: fetchItems(count: maxCount(for: context.family)))
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

    private func fetchItems(count: Int) -> [ReadingListSnapshot] {
        do {
            let container = SharedModelContainer.create()
            let context = ModelContext(container)
            var descriptor = FetchDescriptor<ReadingListItem>(sortBy: [
                SortDescriptor(\ReadingListItem.addedDate, order: .forward),
            ])
            descriptor.fetchLimit = count
            let items = try context.fetch(descriptor)
            return items.map { item in
                ReadingListSnapshot(
                    id: item.url,
                    name: item.name,
                    url: item.url,
                    faviconData: item.faviconData
                )
            }
        } catch {
            return []
        }
    }
}

struct SmallWidgetView: View {
    let entry: ReadingListEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if entry.items.isEmpty {
                Spacer()
                Label("Reading List Empty", systemImage: "text.book.closed")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ForEach(entry.items.prefix(4)) { item in
                    if let url = URL(string: item.url) {
                        Link(destination: url) {
                            HStack(spacing: 6) {
                                faviconView(data: item.faviconData, size: 14)
                                Text(item.name)
                                    .font(.caption)
                                    .lineLimit(1)
                                Spacer()
                            }
                        }
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding()
    }
}

struct MediumWidgetView: View {
    let entry: ReadingListEntry

    var body: some View {
        if entry.items.isEmpty {
            Label("Reading List Empty", systemImage: "text.book.closed")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding()
        } else {
            let columns = [GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(entry.items.prefix(6)) { item in
                    if let url = URL(string: item.url) {
                        Link(destination: url) {
                            HStack(spacing: 4) {
                                faviconView(data: item.faviconData, size: 14)
                                Text(item.name)
                                    .font(.caption)
                                    .lineLimit(1)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .padding()
        }
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
    var entry: ReadingListProvider.Entry

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
        StaticConfiguration(kind: kind, provider: ReadingListProvider()) { entry in
            BookmarkWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Reading List")
        .description("Quick access to your reading list.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
