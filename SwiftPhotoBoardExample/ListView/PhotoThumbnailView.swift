//
//  PhotoThumbnailView.swift
//  SwiftPhotoBoardExample
//
//  Created by Ryouichi Matsuda on 2026/06/09.
//

import SwiftUI

struct PhotoThumbnailView: View {
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
        guard let thumbnailFileID else {
            image = nil
            return
        }
        image = ThumbnailStore.loadThumbnail(fileID: thumbnailFileID)
    }
}
