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
    func deleteItemsRemovesItemFromModelContext() throws {
        let container = try makeModelContiner(isStoredInMemoryOnly: true)
        var context: ModelContext { container.mainContext }
        let store = ThumbnailStoringMock()
        let viewModel = ListViewModel(
            modelContext: context,
            thumbnailStore: store
        )

        let item1 = Item(title: "A", timestamp: Date(timeIntervalSince1970: 1))
        let item2 = Item(title: "B", timestamp: Date(timeIntervalSince1970: 2))
        let item3 = Item(title: "C", timestamp: Date(timeIntervalSince1970: 3))
        context.insert(item1)
        context.insert(item2)
        context.insert(item3)
        try context.save()

        viewModel.deleteItems(
            items: [item1, item2, item3],
            offsets: IndexSet(integer: 1)
        )

        let remaining = try context.fetch(FetchDescriptor<Item>())
        #expect(remaining.count == 2)
        #expect(remaining.contains(where: { $0.title == "A" }))
        #expect(remaining.contains(where: { $0.title == "C" }))
        #expect(!remaining.contains(where: { $0.title == "B" }))
    }

    @Test
    func deleteItemsDeletesThumbnailWhenLocalIdentifierExists() throws {
        let container = try makeModelContiner(isStoredInMemoryOnly: true)
        var context: ModelContext { container.mainContext }
        let store = ThumbnailStoringMock()
        var deletedIdentifiers: [String] = []
        store.deleteThumbnailHandler = { deletedIdentifiers.append($0) }
        let viewModel = ListViewModel(
            modelContext: context,
            thumbnailStore: store
        )

        let item = Item(
            title: "A",
            timestamp: Date(timeIntervalSince1970: 1),
            localIdentifier: "id-123"
        )
        context.insert(item)
        try context.save()

        viewModel.deleteItems(items: [item], offsets: IndexSet(integer: 0))

        #expect(deletedIdentifiers == ["id-123"])
    }

    @Test
    func deleteItemsDoesNotDeleteThumbnailWhenLocalIdentifierIsNil() throws {
        let container = try makeModelContiner(isStoredInMemoryOnly: true)
        var context: ModelContext { container.mainContext }
        let store = ThumbnailStoringMock()
        let viewModel = ListViewModel(
            modelContext: context,
            thumbnailStore: store
        )

        let item = Item(title: "A", timestamp: Date(timeIntervalSince1970: 1))
        context.insert(item)
        try context.save()

        viewModel.deleteItems(items: [item], offsets: IndexSet(integer: 0))

        #expect(store.deleteThumbnailCallCount == 0)
    }

    @Test
    func deleteItemsDeletesMultipleItemsAtGivenOffsets() throws {
        let container = try makeModelContiner(isStoredInMemoryOnly: true)
        var context: ModelContext { container.mainContext }
        let store = ThumbnailStoringMock()
        var deletedIdentifiers: [String] = []
        store.deleteThumbnailHandler = { deletedIdentifiers.append($0) }
        let viewModel = ListViewModel(
            modelContext: context,
            thumbnailStore: store
        )

        let item1 = Item(
            title: "A",
            timestamp: Date(timeIntervalSince1970: 1),
            localIdentifier: "id-1"
        )
        let item2 = Item(
            title: "B",
            timestamp: Date(timeIntervalSince1970: 2),
            localIdentifier: "id-2"
        )
        let item3 = Item(
            title: "C",
            timestamp: Date(timeIntervalSince1970: 3),
            localIdentifier: "id-3"
        )
        context.insert(item1)
        context.insert(item2)
        context.insert(item3)
        try context.save()

        viewModel.deleteItems(
            items: [item1, item2, item3],
            offsets: IndexSet([0, 2])
        )

        let remaining = try context.fetch(FetchDescriptor<Item>())
        #expect(remaining.count == 1)
        #expect(remaining.first?.title == "B")
        #expect(Set(deletedIdentifiers) == Set(["id-1", "id-3"]))
    }

    @Test
    func deleteItemsDeletesOnlyThumbnailsForItemsWithLocalIdentifier() throws {
        let container = try makeModelContiner(isStoredInMemoryOnly: true)
        var context: ModelContext { container.mainContext }
        let store = ThumbnailStoringMock()
        var deletedIdentifiers: [String] = []
        store.deleteThumbnailHandler = { deletedIdentifiers.append($0) }
        let viewModel = ListViewModel(
            modelContext: context,
            thumbnailStore: store
        )

        let item1 = Item(
            title: "A",
            timestamp: Date(timeIntervalSince1970: 1),
            localIdentifier: "id-1"
        )
        let item2 = Item(title: "B", timestamp: Date(timeIntervalSince1970: 2))
        context.insert(item1)
        context.insert(item2)
        try context.save()

        viewModel.deleteItems(
            items: [item1, item2],
            offsets: IndexSet([0, 1])
        )

        let remaining = try context.fetch(FetchDescriptor<Item>())
        #expect(remaining.isEmpty)
        #expect(deletedIdentifiers == ["id-1"])
    }
}
