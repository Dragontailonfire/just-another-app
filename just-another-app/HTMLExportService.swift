//
//  HTMLExportService.swift
//  just-another-app
//
//  Created by Narayanan VK on 17/02/2026.
//

import Foundation

/// Exports bookmarks in the Netscape Bookmark File Format (HTML).
/// Supported by Safari, Chrome, Firefox, and Edge for import.
enum HTMLExportService {

    static func exportHTML(folders: [Folder], bookmarks: [Bookmark]) -> String {
        var lines: [String] = []

        lines.append("<!DOCTYPE NETSCAPE-Bookmark-file-1>")
        lines.append("<!-- This is an automatically generated file.")
        lines.append("     It will be read and overwritten.")
        lines.append("     DO NOT EDIT! -->")
        lines.append("<META HTTP-EQUIV=\"Content-Type\" CONTENT=\"text/html; charset=UTF-8\">")
        lines.append("<TITLE>Bookmarks</TITLE>")
        lines.append("<H1>Bookmarks</H1>")
        lines.append("<DL><p>")

        // Uncategorized bookmarks first
        let uncategorized = bookmarks.filter { $0.folder == nil }
        for bookmark in uncategorized {
            lines.append(bookmarkTag(bookmark, indent: 1))
        }

        // Top-level folders, recursively
        let topLevel = folders.filter { $0.parent == nil }.sorted { $0.name < $1.name }
        for folder in topLevel {
            lines.append(contentsOf: folderBlock(folder, indent: 1))
        }

        lines.append("</DL><p>")
        return lines.joined(separator: "\n")
    }

    // MARK: - Helpers

    private static func folderBlock(_ folder: Folder, indent: Int) -> [String] {
        let pad = String(repeating: "    ", count: indent)
        var lines: [String] = []

        lines.append("\(pad)<DT><H3>\(escapeHTML(folder.name))</H3>")
        lines.append("\(pad)<DL><p>")

        // Subfolders
        let children = folder.children.sorted { $0.name < $1.name }
        for child in children {
            lines.append(contentsOf: folderBlock(child, indent: indent + 1))
        }

        // Bookmarks in this folder
        let sorted = folder.bookmarks.sorted { $0.createdDate < $1.createdDate }
        for bookmark in sorted {
            lines.append(bookmarkTag(bookmark, indent: indent + 1))
        }

        lines.append("\(pad)</DL><p>")
        return lines
    }

    private static func bookmarkTag(_ bookmark: Bookmark, indent: Int) -> String {
        let pad = String(repeating: "    ", count: indent)
        let addDate = Int(bookmark.createdDate.timeIntervalSince1970)
        let name = escapeHTML(bookmark.name)
        let url = escapeHTML(bookmark.url)
        return "\(pad)<DT><A HREF=\"\(url)\" ADD_DATE=\"\(addDate)\">\(name)</A>"
    }

    private static func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
