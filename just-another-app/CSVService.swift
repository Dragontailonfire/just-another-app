//
//  CSVService.swift
//  just-another-app
//
//  Created by Narayanan VK on 14/02/2026.
//

import Foundation
import SwiftData

enum CSVService {

    static let maxImportFileSize: UInt64 = 5 * 1024 * 1024 // 5MB

    struct ImportStats {
        let folders: Int
        let bookmarks: Int
        let skipped: Int
    }

    enum CSVError: LocalizedError {
        case invalidFormat
        case missingFoldersSection
        case missingBookmarksSection
        case invalidRow(String)
        case fileTooLarge

        var errorDescription: String? {
            switch self {
            case .invalidFormat: return "The CSV file format is invalid."
            case .missingFoldersSection: return "Missing #FOLDERS section."
            case .missingBookmarksSection: return "Missing #BOOKMARKS section."
            case .invalidRow(let detail): return "Invalid row: \(detail)"
            case .fileTooLarge: return "File exceeds the 5 MB import limit."
            }
        }
    }

    // MARK: - CSV Injection Prefixes

    private static let dangerousPrefixes: [Character] = ["=", "+", "-", "@", "\t", "\r"]

    // MARK: - Export

    static func exportCSV(folders: [Folder], bookmarks: [Bookmark]) -> String {
        var lines: [String] = []

        // Folders section
        lines.append("#FOLDERS")
        lines.append("name,sortOrder,parentPath,colorName,iconName")
        let sortedFolders = allFoldersSorted(folders)
        for folder in sortedFolders {
            let path = parentPath(for: folder)
            lines.append("\(escapeField(folder.name)),\(folder.sortOrder),\(escapeField(path)),\(escapeField(folder.colorName)),\(escapeField(folder.iconName))")
        }

        lines.append("")

        // Bookmarks section
        lines.append("#BOOKMARKS")
        lines.append("url,name,descriptionText,createdDate,isFavorite,sortOrder,folderPath")
        for bookmark in bookmarks {
            let folderPath = bookmark.folder.map { fullPath(for: $0) } ?? ""
            let dateStr = ISO8601DateFormatter().string(from: bookmark.createdDate)
            lines.append([
                escapeField(bookmark.url),
                escapeField(bookmark.name),
                escapeField(bookmark.descriptionText),
                dateStr,
                bookmark.isFavorite ? "true" : "false",
                "\(bookmark.sortOrder)",
                escapeField(folderPath)
            ].joined(separator: ","))
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Import

    @discardableResult
    static func importCSV(from csvString: String, context: ModelContext) throws -> ImportStats {
        let lines = csvString.components(separatedBy: .newlines)

        guard let foldersIndex = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "#FOLDERS" }) else {
            throw CSVError.missingFoldersSection
        }
        guard let bookmarksIndex = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "#BOOKMARKS" }) else {
            throw CSVError.missingBookmarksSection
        }

        // Parse folder rows (skip header)
        let folderRows = lines[(foldersIndex + 2)..<bookmarksIndex]
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        // Parse bookmark rows (skip header)
        let bookmarkRows = lines[(bookmarksIndex + 2)...]
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        // --- Atomic import: parse and validate ALL rows first ---

        let parsedFolders = try folderRows.map { row -> (name: String, sortOrder: Int, parentPath: String, colorName: String, iconName: String) in
            let fields = parseCSVRow(String(row))
            guard fields.count >= 3 else { throw CSVError.invalidRow(String(row)) }
            let name = stripInjectionPrefix(fields[0])
            let sortOrder = Int(fields[1].trimmingCharacters(in: .whitespaces)) ?? 0
            let parentPath = stripInjectionPrefix(fields[2])
            let colorName = fields.count > 3 ? stripInjectionPrefix(fields[3]) : "blue"
            let iconName = fields.count > 4 ? stripInjectionPrefix(fields[4]) : "folder.fill"
            return (name: name, sortOrder: sortOrder, parentPath: parentPath, colorName: colorName.isEmpty ? "blue" : colorName, iconName: iconName.isEmpty ? "folder.fill" : iconName)
        }

        struct ParsedBookmark {
            let url: String
            let name: String
            let descriptionText: String
            let createdDate: Date
            let isFavorite: Bool
            let sortOrder: Int
            let folderPath: String
        }

        let dateFormatter = ISO8601DateFormatter()
        var parsedBookmarks: [ParsedBookmark] = []
        var skippedCount = 0

        for row in bookmarkRows {
            let fields = parseCSVRow(String(row))
            guard fields.count >= 7 else { throw CSVError.invalidRow(String(row)) }

            let url = stripInjectionPrefix(fields[0])

            // Validate URL — skip rows with non-HTTP(S) URLs
            guard URLValidator.isValid(url) else {
                skippedCount += 1
                continue
            }

            let name = stripInjectionPrefix(fields[1])
            let descriptionText = stripInjectionPrefix(fields[2])
            let createdDate = dateFormatter.date(from: fields[3]) ?? .now
            let isFavorite = fields[4].lowercased() == "true"
            let sortOrder = Int(fields[5].trimmingCharacters(in: .whitespaces)) ?? 0
            let folderPath = stripInjectionPrefix(fields[6])

            parsedBookmarks.append(ParsedBookmark(
                url: url, name: name, descriptionText: descriptionText,
                createdDate: createdDate, isFavorite: isFavorite,
                sortOrder: sortOrder, folderPath: folderPath
            ))
        }

        // --- All parsing succeeded — now delete and insert ---

        try context.delete(model: Bookmark.self)
        try context.delete(model: Folder.self)

        // Create folders (sorted by path depth so parents come first)
        var folderLookup: [String: Folder] = [:]

        let sorted = parsedFolders.sorted {
            let depth0 = $0.parentPath.isEmpty ? 0 : $0.parentPath.components(separatedBy: "/").count
            let depth1 = $1.parentPath.isEmpty ? 0 : $1.parentPath.components(separatedBy: "/").count
            return depth0 < depth1
        }

        for entry in sorted {
            let folder = Folder(name: entry.name, sortOrder: entry.sortOrder, colorName: entry.colorName, iconName: entry.iconName)
            if !entry.parentPath.isEmpty {
                folder.parent = folderLookup[entry.parentPath]
            }
            context.insert(folder)
            let path = entry.parentPath.isEmpty ? entry.name : "\(entry.parentPath)/\(entry.name)"
            folderLookup[path] = folder
        }

        // Create bookmarks
        for parsed in parsedBookmarks {
            let bookmark = Bookmark(
                url: parsed.url,
                name: parsed.name,
                descriptionText: parsed.descriptionText,
                createdDate: parsed.createdDate,
                isFavorite: parsed.isFavorite,
                sortOrder: parsed.sortOrder,
                folder: parsed.folderPath.isEmpty ? nil : folderLookup[parsed.folderPath]
            )
            context.insert(bookmark)
        }

        try context.save()

        return ImportStats(folders: sorted.count, bookmarks: parsedBookmarks.count, skipped: skippedCount)
    }

    // MARK: - Helpers

    private static func fullPath(for folder: Folder) -> String {
        var parts: [String] = [folder.name]
        var current = folder.parent
        while let p = current {
            parts.insert(p.name, at: 0)
            current = p.parent
        }
        return parts.joined(separator: "/")
    }

    private static func parentPath(for folder: Folder) -> String {
        guard let parent = folder.parent else { return "" }
        return fullPath(for: parent)
    }

    /// Collect all folders including nested children, flattened
    private static func allFoldersSorted(_ folders: [Folder]) -> [Folder] {
        var result: [Folder] = []
        func collect(_ folder: Folder) {
            result.append(folder)
            for child in folder.children.sorted(by: { $0.sortOrder < $1.sortOrder }) {
                collect(child)
            }
        }
        // Start from root folders (no parent)
        let roots = folders.filter { $0.parent == nil }.sorted { $0.sortOrder < $1.sortOrder }
        for root in roots {
            collect(root)
        }
        return result
    }

    /// Escape a CSV field per RFC 4180 with CSV injection protection (OWASP)
    static func escapeField(_ value: String) -> String {
        var escaped = value

        // CSV injection protection: prefix dangerous characters with single-quote
        if let first = escaped.first, dangerousPrefixes.contains(first) {
            escaped = "'" + escaped
            // Force quoting when prefixed
            return "\"\(escaped.replacingOccurrences(of: "\"", with: "\"\""))\""
        }

        if escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n") || escaped.contains("\r") {
            return "\"\(escaped.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return escaped
    }

    /// Strip leading single-quote added by CSV injection protection during export
    static func stripInjectionPrefix(_ value: String) -> String {
        if value.hasPrefix("'") {
            let stripped = String(value.dropFirst())
            if let first = stripped.first, dangerousPrefixes.contains(first) {
                return stripped
            }
        }
        return value
    }

    /// Parse a CSV row respecting quoted fields
    static func parseCSVRow(_ row: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        var i = row.startIndex

        while i < row.endIndex {
            let char = row[i]
            if inQuotes {
                if char == "\"" {
                    let next = row.index(after: i)
                    if next < row.endIndex && row[next] == "\"" {
                        current.append("\"")
                        i = row.index(after: next)
                        continue
                    } else {
                        inQuotes = false
                    }
                } else {
                    current.append(char)
                }
            } else {
                if char == "\"" {
                    inQuotes = true
                } else if char == "," {
                    fields.append(current)
                    current = ""
                } else {
                    current.append(char)
                }
            }
            i = row.index(after: i)
        }
        fields.append(current)
        return fields
    }
}
