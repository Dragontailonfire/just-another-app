//
//  FaviconService.swift
//  just-another-app
//
//  Created by Narayanan VK on 16/02/2026.
//

import Foundation
import LinkPresentation
import UIKit
import UniformTypeIdentifiers

enum FaviconService {
    static func fetchFavicon(for urlString: String) async -> Data? {
        guard let url = URL(string: urlString),
              let host = url.host else { return nil }

        // Try LPMetadataProvider first
        if let data = await fetchViaLinkPresentation(url: url) {
            return data
        }

        // Fallback: Google favicon API
        if let data = await fetchViaGoogle(host: host) {
            return data
        }

        return nil
    }

    private static func fetchViaLinkPresentation(url: URL) async -> Data? {
        let provider = LPMetadataProvider()
        provider.timeout = 10
        do {
            let metadata = try await provider.startFetchingMetadata(for: url)
            guard let iconProvider = metadata.iconProvider else { return nil }
            return try await withCheckedThrowingContinuation { continuation in
                iconProvider.loadDataRepresentation(for: .image) { data, error in
                    if let data = data {
                        // Convert to PNG for consistent storage
                        if let image = UIImage(data: data),
                           let pngData = image.pngData() {
                            continuation.resume(returning: pngData)
                        } else {
                            continuation.resume(returning: data)
                        }
                    } else {
                        continuation.resume(throwing: error ?? URLError(.cannotDecodeContentData))
                    }
                }
            }
        } catch {
            return nil
        }
    }

    private static func fetchViaGoogle(host: String) async -> Data? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.google.com"
        components.path = "/s2/favicons"
        components.queryItems = [
            URLQueryItem(name: "domain", value: host),
            URLQueryItem(name: "sz", value: "64")
        ]
        guard let url = components.url else { return nil }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else { return nil }
            if let image = UIImage(data: data), let pngData = image.pngData() {
                return pngData
            }
            return nil
        } catch {
            return nil
        }
    }

    static func fetchMissingFavicons(bookmarks: [Bookmark]) async -> Int {
        var fetched = 0
        let limiter = ConcurrencyLimiter(limit: 6)
        await withTaskGroup(of: (Bookmark, Data?).self) { group in
            for bookmark in bookmarks where bookmark.faviconData == nil {
                group.addTask {
                    await limiter.acquire()
                    defer { Task { await limiter.release() } }
                    let data = await fetchFavicon(for: bookmark.url)
                    return (bookmark, data)
                }
            }
            for await (bookmark, data) in group {
                if let data = data {
                    await MainActor.run {
                        bookmark.faviconData = data
                    }
                    fetched += 1
                }
            }
        }
        return fetched
    }
}
