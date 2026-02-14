//
//  FolderAppearance.swift
//  just-another-app
//
//  Created by Narayanan VK on 14/02/2026.
//

import SwiftUI

enum FolderAppearance {
    static let availableColors: [(name: String, color: Color)] = [
        ("blue", .blue),
        ("red", .red),
        ("green", .green),
        ("orange", .orange),
        ("purple", .purple),
        ("pink", .pink),
        ("teal", .teal),
        ("brown", .brown),
    ]

    static let availableIcons: [String] = [
        "folder.fill",
        "book.fill",
        "briefcase.fill",
        "star.fill",
        "heart.fill",
        "globe",
        "wrench.fill",
        "gamecontroller.fill",
        "music.note",
        "graduationcap.fill",
        "cart.fill",
        "house.fill",
    ]

    static func color(for name: String) -> Color {
        availableColors.first(where: { $0.name == name })?.color ?? .blue
    }
}
