//
//  ReadingListRowView.swift
//  just-another-app
//
//  Created by Narayanan VK on 19/02/2026.
//

import SwiftUI
import UIKit

struct ReadingListRowView: View {
    let item: ReadingListItem

    var body: some View {
        HStack(spacing: 10) {
            faviconView(size: 32)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.body)
                    .lineLimit(1)
                Text(item.url)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(item.addedDate, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    @ViewBuilder
    private func faviconView(size: CGFloat) -> some View {
        if let data = item.faviconData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
        } else {
            Image(systemName: "globe")
                .font(.system(size: size * 0.45))
                .frame(width: size, height: size)
                .foregroundStyle(.secondary)
                .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: size * 0.22))
        }
    }
}
