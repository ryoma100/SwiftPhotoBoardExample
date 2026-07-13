//
//  ListView+Row.swift
//  SwiftPhotoBoardExample
//
//  Created by Ryouichi Matsuda on 2026/07/13.
//

import SwiftData
import SwiftUI

private let imageFileService: ImageFileService = ImageFileServiceImpl()
private let size: CGFloat = 64

extension ListView {

    struct ListRow: View {
        private let item: Item
        private let thumbnail: UIImage?

        init(
            item: Item,
        ) {
            self.item = item
            self.thumbnail = imageFileService.loadThumbnail(
                fileId: item.imageFileId
            )
        }

        var body: some View {
            HStack {
                Group {
                    if let thumbnail {
                        Image(uiImage: thumbnail)
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
                VStack(alignment: .leading) {
                    Text(item.title)
                    Text(
                        item.timestamp,
                        format: Date.FormatStyle(
                            date: .numeric,
                            time: .standard
                        )
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
}
