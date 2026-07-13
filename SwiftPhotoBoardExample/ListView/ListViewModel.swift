//
//  ListViewModel.swift
//  SwiftPhotoBoardExample
//
//  Created by Ryouichi Matsuda on 2026/06/23.
//

import SwiftData
import SwiftUI

@Observable
final class ListViewModel {
    private let modelContext: ModelContext?
    private let imageFileService: ImageFileService

    init(
        modelContext: ModelContext,
        imageFileService: ImageFileService = ImageFileServiceImpl()
    ) {
        self.modelContext = modelContext
        self.imageFileService = imageFileService
    }

    // Dummy for initialization; not actually used.
    init() {
        self.modelContext = nil
        self.imageFileService = ImageFileServiceImpl()
    }

    func deleteItems(items: [Item], offsets: IndexSet) throws {
        guard let modelContext else { throw SwiftDataError.missingModelContext }

        for index in offsets {
            let item = items[index]
            modelContext.delete(item)

            if let imageFileId = item.imageFileId,
                try modelContext.countItems(imageFileId: imageFileId) == 0
            {
                imageFileService.deleteImage(fileId: imageFileId)
                try modelContext.deleteImageFile(id: imageFileId)
            }
            try modelContext.save()
        }
    }
}
