//
//  HTMLImportService.swift
//  just-another-app
//
//  Created by Narayanan VK on 18/02/2026.
//

import Foundation
import SwiftData

/// Merges bookmarks from a Netscape Bookmark File (HTML) into the store.
/// Never deletes existing data — adds new folders/bookmarks only, skips duplicates.
enum HTMLImportService {

    struct ImportStats {
        let foldersCreated: Int
        let bookmarksAdded: Int
        let skipped: Int
    }

    static let maxImportFileSize: UInt64 = 10 * 1024 * 1024  // 10 MB

    // MARK: - Public API

    static func importHTML(from html: String, context: ModelContext) throws -> ImportStats {
        // Build duplicate-detection set from existing URLs
        let existingBookmarks = try context.fetch(FetchDescriptor<Bookmark>())
        var seenURLs = Set(existingBookmarks.map { URLValidator.canonicalize($0.url) })

        // Load existing folders for findOrCreate matching
        let existingFolders = try context.fetch(FetchDescriptor<Folder>())
        var knownFolders: [Folder] = existingFolders

        var foldersCreated = 0
        var bookmarksAdded = 0
        var skipped = 0

        // Reference time for bookmarks that lack ADD_DATE; incremented per bookmark
        // so file order is preserved when sorting by date.
        let importBatchBase = Date()

        // Stack of folder context: nil entry = uncategorized level
        var folderStack: [Folder?] = []
        // Name waiting for its matching <DL>
        var pendingFolderName: String? = nil
        // Last inserted bookmark — accepts a following <DD> description
        var lastBookmark: Bookmark? = nil

        for token in HTMLScanner(html: html).scan() {
            switch token {

            case .openDL:
                if let name = pendingFolderName {
                    let parent = folderStack.last ?? nil
                    let folder = findOrCreate(
                        name: name,
                        parent: parent,
                        cache: &knownFolders,
                        context: context,
                        created: &foldersCreated
                    )
                    folderStack.append(folder)
                    pendingFolderName = nil
                } else if folderStack.isEmpty {
                    folderStack.append(nil)  // root level
                }
                lastBookmark = nil

            case .closeDL:
                if !folderStack.isEmpty { folderStack.removeLast() }
                lastBookmark = nil

            case .folderName(let name):
                pendingFolderName = name
                lastBookmark = nil

            case .bookmark(let url, let name, let date):
                guard URLValidator.isValid(url) else { skipped += 1; continue }
                let canonical = URLValidator.canonicalize(url)
                guard !seenURLs.contains(canonical) else { skipped += 1; continue }
                seenURLs.insert(canonical)

                let currentFolder = folderStack.last ?? nil
                // When ADD_DATE is absent, assign sequential timestamps (1 ms apart)
                // so file order is preserved when the user sorts by date.
                let createdDate = date ?? importBatchBase.addingTimeInterval(Double(bookmarksAdded) * 0.001)
                let bm = Bookmark(
                    url: canonical,
                    name: name.isEmpty ? canonical : name,
                    createdDate: createdDate,
                    folder: currentFolder
                )
                context.insert(bm)
                lastBookmark = bm
                bookmarksAdded += 1

            case .description(let text):
                lastBookmark?.descriptionText = text
                lastBookmark = nil
            }
        }

        return ImportStats(foldersCreated: foldersCreated, bookmarksAdded: bookmarksAdded, skipped: skipped)
    }

    // MARK: - Private helpers

    private static func findOrCreate(
        name: String,
        parent: Folder?,
        cache: inout [Folder],
        context: ModelContext,
        created: inout Int
    ) -> Folder {
        if let existing = cache.first(where: {
            $0.name.caseInsensitiveCompare(name) == .orderedSame && $0.parent === parent
        }) {
            return existing
        }
        let folder = Folder(name: name, parent: parent)
        context.insert(folder)
        cache.append(folder)
        created += 1
        return folder
    }
}

// MARK: - HTML Token

private enum HTMLToken {
    case openDL
    case closeDL
    case folderName(String)
    case bookmark(url: String, name: String, date: Date?)
    case description(String)
}

// MARK: - HTML Scanner

private struct HTMLScanner {
    let html: String

    func scan() -> [HTMLToken] {
        var result: [HTMLToken] = []
        var idx = html.startIndex

        while idx < html.endIndex {
            guard let ltRange = html.range(of: "<", range: idx..<html.endIndex) else { break }
            guard let gtRange = html.range(of: ">", range: ltRange.upperBound..<html.endIndex) else { break }

            let tagContent = String(html[ltRange.upperBound..<gtRange.lowerBound])
            let afterGt = gtRange.upperBound
            let tagLower = tagContent.lowercased()

            // <DL> / <DL><p>
            if tagLower == "dl" || tagLower.hasPrefix("dl ") || tagLower.hasPrefix("dl\t") {
                result.append(.openDL)
                idx = afterGt

            // </DL>
            } else if tagLower == "/dl" || tagLower.hasPrefix("/dl ") || tagLower.hasPrefix("/dl\t") {
                result.append(.closeDL)
                idx = afterGt

            // <H3 ...>folder name</H3>
            } else if tagLower == "h3" || tagLower.hasPrefix("h3 ") || tagLower.hasPrefix("h3\t") {
                if let closeRange = html.range(of: "</h3>", options: .caseInsensitive, range: afterGt..<html.endIndex) {
                    let name = unescape(String(html[afterGt..<closeRange.lowerBound]))
                    if !name.isEmpty { result.append(.folderName(name)) }
                    idx = closeRange.upperBound
                } else {
                    idx = afterGt
                }

            // <A HREF="..." ADD_DATE="...">name</A>
            } else if tagLower.hasPrefix("a ") || tagLower.hasPrefix("a\t") {
                let href = attribute("href", in: tagContent) ?? ""
                let addDate = dateAttribute("add_date", in: tagContent)
                if let closeRange = html.range(of: "</a>", options: .caseInsensitive, range: afterGt..<html.endIndex) {
                    let name = unescape(String(html[afterGt..<closeRange.lowerBound]))
                    result.append(.bookmark(url: href, name: name, date: addDate))
                    idx = closeRange.upperBound
                } else {
                    idx = afterGt
                }

            // <DD>description text (until next tag)
            } else if tagLower == "dd" || tagLower.hasPrefix("dd ") || tagLower.hasPrefix("dd\t") {
                let textEnd = html.range(of: "<", range: afterGt..<html.endIndex)?.lowerBound ?? html.endIndex
                let raw = String(html[afterGt..<textEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !raw.isEmpty { result.append(.description(unescape(raw))) }
                idx = afterGt

            } else {
                idx = afterGt
            }
        }

        return result
    }

    // MARK: Attribute extraction

    private func attribute(_ name: String, in tag: String) -> String? {
        let escaped = NSRegularExpression.escapedPattern(for: name)
        let pattern = "\(escaped)\\s*=\\s*(?:\"([^\"]*)\"|'([^']*)'|(\\S+))"
        guard let re = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let m = re.firstMatch(in: tag, range: NSRange(tag.startIndex..., in: tag)) else {
            return nil
        }
        for i in 1...3 {
            let r = m.range(at: i)
            if r.location != NSNotFound, let sr = Range(r, in: tag) {
                return String(tag[sr])
            }
        }
        return nil
    }

    private func dateAttribute(_ name: String, in tag: String) -> Date? {
        guard let raw = attribute(name, in: tag), let ts = TimeInterval(raw) else { return nil }
        return Date(timeIntervalSince1970: ts)
    }

    // MARK: HTML entity unescaping

    private func unescape(_ s: String) -> String {
        s
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&apos;", with: "'")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
