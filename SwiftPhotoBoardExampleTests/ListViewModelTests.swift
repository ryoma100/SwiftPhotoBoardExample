//
//  ListViewModelTests.swift
//  SwiftPhotoBoardExampleTests
//
//  Created by Ryouichi Matsuda on 2026/06/23.
//

import Foundation
import SwiftData
import Testing
import UIKit

@testable import SwiftPhotoBoardExample

@MainActor
struct ListViewModelTests {

    @Test
    func deleteItemsWithoutModelContextThrows() async throws {
        let viewModel = ListViewModel()

        #expect(throws: SwiftDataError.self) {
            try viewModel.deleteItems(items: [], offsets: IndexSet())
        }
    }

    @Test
    func deleteItemsRemovesItemWithoutImageFile() async throws {
        let container = try makeModelContiner(isStoredInMemoryOnly: true)
        let context = container.mainContext
        let imageFileService = ImageFileServiceMock()

        let item = Item(
            title: "A",
            timestamp: Date(timeIntervalSince1970: 1),
            imageFileId: nil
        )
        context.insert(item)
        try context.save()

        let viewModel = ListViewModel(
            modelContext: context,
            imageFileService: imageFileService
        )

        try viewModel.deleteItems(
            items: [item],
            offsets: IndexSet(integer: 0)
        )

        let items = try context.fetch(FetchDescriptor<Item>())
        #expect(items.isEmpty)
        #expect(imageFileService.deleteImageCallCount == 0)
    }

    @Test
    func deleteItemsDeletesImageWhenNoOtherItemReferences() async throws {
        let container = try makeModelContiner(isStoredInMemoryOnly: true)
        let context = container.mainContext
        let imageFileService = ImageFileServiceMock()

        let imageFile = ImageFile(sha256Hash: "hash")
        let imageFileId = imageFile.id
        let item = Item(
            title: "A",
            timestamp: Date(timeIntervalSince1970: 1),
            imageFileId: imageFileId
        )
        context.insert(imageFile)
        context.insert(item)
        try context.save()

        var deletedFileIds: [UUID] = []
        imageFileService.deleteImageHandler = { deletedFileIds.append($0) }

        let viewModel = ListViewModel(
            modelContext: context,
            imageFileService: imageFileService
        )

        try viewModel.deleteItems(
            items: [item],
            offsets: IndexSet(integer: 0)
        )

        #expect(deletedFileIds == [imageFileId])
        let items = try context.fetch(FetchDescriptor<Item>())
        #expect(items.isEmpty)
        let imageFiles = try context.fetch(FetchDescriptor<ImageFile>())
        #expect(imageFiles.isEmpty)
    }

    @Test
    func deleteItemsKeepsImageWhenOtherItemStillReferences() async throws {
        let container = try makeModelContiner(isStoredInMemoryOnly: true)
        let context = container.mainContext
        let imageFileService = ImageFileServiceMock()

        let imageFile = ImageFile(sha256Hash: "hash")
        let imageFileId = imageFile.id
        let item1 = Item(
            title: "A",
            timestamp: Date(timeIntervalSince1970: 1),
            imageFileId: imageFileId
        )
        let item2 = Item(
            title: "B",
            timestamp: Date(timeIntervalSince1970: 2),
            imageFileId: imageFileId
        )
        context.insert(imageFile)
        context.insert(item1)
        context.insert(item2)
        try context.save()

        let viewModel = ListViewModel(
            modelContext: context,
            imageFileService: imageFileService
        )

        try viewModel.deleteItems(
            items: [item1, item2],
            offsets: IndexSet(integer: 0)
        )

        #expect(imageFileService.deleteImageCallCount == 0)
        let items = try context.fetch(FetchDescriptor<Item>())
        #expect(items.count == 1)
        #expect(items.first?.title == "B")
        let imageFiles = try context.fetch(FetchDescriptor<ImageFile>())
        #expect(imageFiles.count == 1)
    }

    @Test
    func deleteItemsRemovesMultipleItemsAtGivenOffsets() async throws {
        let container = try makeModelContiner(isStoredInMemoryOnly: true)
        let context = container.mainContext
        let imageFileService = ImageFileServiceMock()

        let item1 = Item(
            title: "A",
            timestamp: Date(timeIntervalSince1970: 1),
            imageFileId: nil
        )
        let item2 = Item(
            title: "B",
            timestamp: Date(timeIntervalSince1970: 2),
            imageFileId: nil
        )
        let item3 = Item(
            title: "C",
            timestamp: Date(timeIntervalSince1970: 3),
            imageFileId: nil
        )
        context.insert(item1)
        context.insert(item2)
        context.insert(item3)
        try context.save()

        let viewModel = ListViewModel(
            modelContext: context,
            imageFileService: imageFileService
        )

        try viewModel.deleteItems(
            items: [item1, item2, item3],
            offsets: IndexSet([0, 2])
        )

        let items = try context.fetch(FetchDescriptor<Item>())
        #expect(items.count == 1)
        #expect(items.first?.title == "B")
    }
}
