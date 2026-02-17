//
//  LinkCheckerService.swift
//  just-another-app
//
//  Created by Narayanan VK on 16/02/2026.
//

import Foundation

enum LinkCheckerService {
    /// Custom delegate that blocks redirects to non-HTTP(S) schemes.
    private class SafeRedirectDelegate: NSObject, URLSessionTaskDelegate {
        func urlSession(
            _ session: URLSession,
            task: URLSessionTask,
            willPerformHTTPRedirection response: HTTPURLResponse,
            newRequest request: URLRequest,
            completionHandler: @escaping (URLRequest?) -> Void
        ) {
            if let scheme = request.url?.scheme?.lowercased(),
               scheme == "http" || scheme == "https" {
                completionHandler(request)
            } else {
                // Block redirect to non-HTTP(S) scheme
                completionHandler(nil)
            }
        }
    }

    private static let redirectDelegate = SafeRedirectDelegate()

    private static var ephemeralSession: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10
        return URLSession(configuration: config, delegate: redirectDelegate, delegateQueue: nil)
    }()

    static func checkLink(for bookmark: Bookmark) async {
        guard let url = URL(string: bookmark.url) else {
            await MainActor.run {
                bookmark.linkStatus = "dead"
                bookmark.lastCheckedDate = .now
            }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10

        do {
            let (_, response) = try await ephemeralSession.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let status = (200...399).contains(statusCode) ? "valid" : "dead"
            await MainActor.run {
                bookmark.linkStatus = status
                bookmark.lastCheckedDate = .now
            }
        } catch {
            await MainActor.run {
                bookmark.linkStatus = "dead"
                bookmark.lastCheckedDate = .now
            }
        }
    }

    static func checkAllLinks(bookmarks: [Bookmark]) async -> (valid: Int, dead: Int) {
        var valid = 0
        var dead = 0
        let limiter = ConcurrencyLimiter(limit: 6)
        await withTaskGroup(of: String.self) { group in
            for bookmark in bookmarks {
                group.addTask {
                    await limiter.acquire()
                    defer { Task { await limiter.release() } }
                    await checkLink(for: bookmark)
                    return await MainActor.run { bookmark.linkStatus }
                }
            }
            for await status in group {
                if status == "valid" {
                    valid += 1
                } else {
                    dead += 1
                }
            }
        }
        return (valid, dead)
    }
}
