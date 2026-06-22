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
    private let modelContext: ModelContext
    private let thumbnailStore: ThumbnailStoring

    init(modelContext: ModelContext, thumbnailStore: ThumbnailStoring) {
        self.modelContext = modelContext
        self.thumbnailStore = thumbnailStore
    }

    func deleteItems(items: [Item], offsets: IndexSet) {
        for index in offsets {
            let item = items[index]
            if let localIdentifier = item.localIdentifier {
                thumbnailStore.deleteThumbnail(localIdentifier: localIdentifier)
            }
            modelContext.delete(item)
            try? modelContext.save()
        }
    }
}
