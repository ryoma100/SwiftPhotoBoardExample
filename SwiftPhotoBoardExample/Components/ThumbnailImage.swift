//
//  ThumbnailImage.swift
//  SwiftPhotoBoardExample
//
//  Created by Ryouichi Matsuda on 2026/06/27.
//

import SwiftUI

struct ThumbnailImage: View {
    let localIdentifier: String?
    private let size: CGFloat
    private let thmbnailService: ThumbnailService

    @State private var image: UIImage?

    init(
        localIdentifier: String?,
        size: CGFloat = 64,
        thmbnailStore: ThumbnailService = ThumbnailServiceImpl()
    ) {
        self.localIdentifier = localIdentifier
        self.size = size
        self.thmbnailService = thmbnailStore
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
        .frame(width: size, height: size)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .task(id: localIdentifier) {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        if let localIdentifier {
            image = thmbnailService.loadThumbnail(
                localIdentifier: localIdentifier
            )
        } else {
            image = nil
        }
    }
}
