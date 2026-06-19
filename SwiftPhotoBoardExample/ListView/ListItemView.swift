//
//  ListItemView.swift
//  SwiftPhotoBoardExample
//
//  Created by Ryouichi Matsuda on 2026/06/17.
//

import SwiftUI

struct ListItemView: View {
    let item: Item

    var body: some View {
        HStack {
            PhotoThumbnailView(thumbnailFileID: item.thumbnailFileID)
            VStack(alignment: .leading) {
                Text(item.title)
                Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
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
    let thumbnailFileID: UUID?
    @State private var image: UIImage?
    
    private static let size: CGFloat = 64
    
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
        .task(id: thumbnailFileID) {
            await loadThumbnail()
        }
    }
    
    private func loadThumbnail() async {
        if let thumbnailFileID {
            image = ThumbnailStore.loadThumbnail(fileID: thumbnailFileID)
        } else {
            image = nil
        }
    }
}
