//
//  ThumbnailImage.swift
//  SwiftPhotoBoardExample
//
//  Created by Ryouichi Matsuda on 2026/06/27.
//

import SwiftUI

private let imageSercice: ImageService = ImageServiceImpl()
private let size: CGFloat = 64

struct ThumbnailImage: View {
    let imageFileId: UUID?

    @State private var image: UIImage?

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
        .frame(width: size, height: size)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .task(id: imageFileId) {
            loadThumbnail()
        }
    }

    private func loadThumbnail() {
        if let imageFileId {
            image = imageSercice.loadThumbnail(fileId: imageFileId)
        } else {
            image = nil
        }
    }
}
