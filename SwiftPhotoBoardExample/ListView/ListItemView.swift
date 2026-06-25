//
//  ListItemView.swift
//  SwiftPhotoBoardExample
//
//  Created by Ryouichi Matsuda on 2026/06/17.
//

import SwiftUI

struct ListItemView: View {
    private let item: Item
    private let thmbnailStore: ThumbnailService

    init(item: Item) {
        self.item = item
        self.thmbnailStore = ThumbnailServiceImpl()
    }

    var body: some View {
        HStack {
            PhotoThumbnailView(localIdentifier: item.localIdentifier)
            VStack(alignment: .leading) {
                Text(item.title)
                Text(
                    item.timestamp,
                    format: Date.FormatStyle(date: .numeric, time: .standard)
                )
                if !item.note.isEmpty {
                    Text(item.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct PhotoThumbnailView: View {
    let localIdentifier: String?
    @State private var image: UIImage?

    private let thmbnailStore: ThumbnailService
    private static let size: CGFloat = 64

    init(
        localIdentifier: String?,
        image: UIImage? = nil,
        thmbnailStore: ThumbnailService = ThumbnailServiceImpl()
    ) {
        self.localIdentifier = localIdentifier
        self.image = image
        self.thmbnailStore = thmbnailStore
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: Self.size, height: Self.size)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .task(id: localIdentifier) {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        if let localIdentifier {
            image = thmbnailStore.loadThumbnail(
                localIdentifier: localIdentifier
            )
        } else {
            image = nil
        }
    }
}
