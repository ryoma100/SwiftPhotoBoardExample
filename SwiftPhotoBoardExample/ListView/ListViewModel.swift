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
    private let imageService: ImageService

    init(
        modelContext: ModelContext,
        imageService: ImageService = ImageServiceImpl()
    ) {
        self.modelContext = modelContext
        self.imageService = imageService
    }

    // Dummy for initialization; not actually used.
    init() {
        self.modelContext = nil
        self.imageService = ImageServiceImpl()
    }

    func deleteItems(items: [Item], offsets: IndexSet) throws {
        guard let modelContext else { throw SwiftDataError.missingModelContext }

        for index in offsets {
            let item = items[index]
//            if let localIdentifier = item.localIdentifier {
//                thumbnailService.deleteThumbnail(
//                    localIdentifier: localIdentifier
//                )
//            }
//            modelContext.delete(item)
//            try modelContext.save()
        }
    }
}
