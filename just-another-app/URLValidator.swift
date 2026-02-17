//
//  URLValidator.swift
//  just-another-app
//
//  Created by Narayanan VK on 17/02/2026.
//

import Foundation

enum URLValidator {
    /// Returns true if the string is a valid HTTP or HTTPS URL with a host.
    static func isValid(_ urlString: String) -> Bool {
        guard let parsed = URL(string: urlString),
              let scheme = parsed.scheme?.lowercased(),
              (scheme == "http" || scheme == "https"),
              parsed.host != nil else {
            return false
        }
        return true
    }

    /// Trims whitespace, lowercases scheme+host, and strips trailing slash.
    static func canonicalize(_ urlString: String) -> String {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: trimmed) else { return trimmed }
        components.scheme = components.scheme?.lowercased()
        components.host = components.host?.lowercased()
        guard var result = components.string else { return trimmed }
        if result.hasSuffix("/") && components.path == "/" {
            result = String(result.dropLast())
        }
        return result
    }
}
