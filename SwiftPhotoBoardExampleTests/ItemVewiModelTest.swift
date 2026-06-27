//
//  ItemVewiModelTest.swift
//  SwiftPhotoBoardExample
//
//  Created by Ryouichi Matsuda on 2026/06/27.
//

import Foundation
import SwiftData
import Testing
import UIKit

@testable import SwiftPhotoBoardExample

@MainActor
struct ItemViewModelTests {

    @Test
    func initWithNilItemSetsDefaultValues() async throws {
        let container = try makeModelContiner(isStoredInMemoryOnly: true)
        let context = container.mainContext
        let thumbnailService = ThumbnailServiceMock()
        let photoService = PhotoServiceMock()

        let viewModel = await ItemViewModel(
            modelContext: context,
            item: nil,
            thumbnailService: thumbnailService,
            photoService: photoService
        )

        #expect(viewModel.item == nil)
        #expect(viewModel.title == "")
        #expect(viewModel.note == "")
        #expect(viewModel.imageSource == nil)
    }

    @Test
    func initWithItemPopulatesPropertiesFromItem() async throws {
        let container = try makeModelContiner(isStoredInMemoryOnly: true)
        let context = container.mainContext
        let thumbnailService = ThumbnailServiceMock()
        let photoService = PhotoServiceMock()

        let timestamp = Date(timeIntervalSince1970: 100)
        let item = Item(
            title: "Hello",
            timestamp: timestamp,
            note: "World"
        )

        let viewModel = await ItemViewModel(
            modelContext: context,
            item: item,
            thumbnailService: thumbnailService,
            photoService: photoService
        )

        #expect(viewModel.item === item)
        #expect(viewModel.title == "Hello")
        #expect(viewModel.timestamp == timestamp)
        #expect(viewModel.note == "World")
        #expect(viewModel.imageSource == nil)
    }

    @Test
    func initLoadsPhotoFromPhotoServiceWhenAvailable() async throws {
        let container = try makeModelContiner(isStoredInMemoryOnly: true)
        let context = container.mainContext
        let thumbnailService = ThumbnailServiceMock()
        let photoService = PhotoServiceMock()
        let assetImage = UIImage()
        photoService.loadAssetImageHandler = { _, _ in assetImage }

        let item = Item(
            title: "A",
            timestamp: Date(timeIntervalSince1970: 1),
            localIdentifier: "asset-id"
        )

        let viewModel = await ItemViewModel(
            modelContext: context,
            item: item,
            thumbnailService: thumbnailService,
            photoService: photoService
        )

        if case .photo(let id, let image) = viewModel.imageSource {
            #expect(id == "asset-id")
            #expect(image === assetImage)
        } else {
            Issue.record("imageSource was not .photo")
        }
        #expect(thumbnailService.loadThumbnailCallCount == 0)
    }

    @Test
    func initFallsBackToThumbnailWhenPhotoServiceReturnsNil() async throws {
        let container = try makeModelContiner(isStoredInMemoryOnly: true)
        let context = container.mainContext
        let thumbnailService = ThumbnailServiceMock()
        let photoService = PhotoServiceMock()
        let thumbnailImage = UIImage()
        thumbnailService.loadThumbnailHandler = { _ in thumbnailImage }

        let item = Item(
            title: "A",
            timestamp: Date(timeIntervalSince1970: 1),
            localIdentifier: "asset-id"
        )

        let viewModel = await ItemViewModel(
            modelContext: context,
            item: item,
            thumbnailService: thumbnailService,
            photoService: photoService
        )

        if case .thumbnail(let id, let image) = viewModel.imageSource {
            #expect(id == "asset-id")
            #expect(image === thumbnailImage)
        } else {
            Issue.record("imageSource was not .thumbnail")
        }
    }

    @Test
    func initHasNilImageSourceWhenBothServicesReturnNil() async throws {
        let container = try makeModelContiner(isStoredInMemoryOnly: true)
        let context = container.mainContext
        let thumbnailService = ThumbnailServiceMock()
        let photoService = PhotoServiceMock()

        let item = Item(
            title: "A",
            timestamp: Date(timeIntervalSince1970: 1),
            localIdentifier: "asset-id"
        )

        let viewModel = await ItemViewModel(
            modelContext: context,
            item: item,
            thumbnailService: thumbnailService,
            photoService: photoService
        )

        #expect(viewModel.imageSource == nil)
    }

    @Test
    func selectPhotoUpdatesImageSourceWithLoadedAsset() async throws {
        let container = try makeModelContiner(isStoredInMemoryOnly: true)
        let context = container.mainContext
        let thumbnailService = ThumbnailServiceMock()
        let photoService = PhotoServiceMock()
        let assetImage = UIImage()
        photoService.loadAssetImageHandler = { _, _ in assetImage }

        let viewModel = await ItemViewModel(
            modelContext: context,
            item: nil,
            thumbnailService: thumbnailService,
            photoService: photoService
        )

        await viewModel.selectPhoto("new-id")

        if case .photo(let id, let image) = viewModel.imageSource {
            #expect(id == "new-id")
            #expect(image === assetImage)
        } else {
            Issue.record("imageSource was not .photo")
        }
    }

    @Test
    func selectPhotoWithNilClearsImageSource() async throws {
        let container = try makeModelContiner(isStoredInMemoryOnly: true)
        let context = container.mainContext
        let thumbnailService = ThumbnailServiceMock()
        let photoService = PhotoServiceMock()
        photoService.loadAssetImageHandler = { _, _ in UIImage() }

        let viewModel = await ItemViewModel(
            modelContext: context,
            item: nil,
            thumbnailService: thumbnailService,
            photoService: photoService
        )

        await viewModel.selectPhoto("first-id")
        await viewModel.selectPhoto(nil)

        #expect(viewModel.imageSource == nil)
    }

    @Test
    func takeCameraSetsCameraImageSource() async throws {
        let container = try makeModelContiner(isStoredInMemoryOnly: true)
        let context = container.mainContext
        let thumbnailService = ThumbnailServiceMock()
        let photoService = PhotoServiceMock()

        let viewModel = await ItemViewModel(
            modelContext: context,
            item: nil,
            thumbnailService: thumbnailService,
            photoService: photoService
        )

        let cameraImage = UIImage()
        viewModel.takeCamera(cameraImage)

        if case .camera(let image) = viewModel.imageSource {
            #expect(image === cameraImage)
        } else {
            Issue.record("imageSource was not .camera")
        }
    }

    @Test
    func removeImageClearsImageSource() async throws {
        let container = try makeModelContiner(isStoredInMemoryOnly: true)
        let context = container.mainContext
        let thumbnailService = ThumbnailServiceMock()
        let photoService = PhotoServiceMock()

        let viewModel = await ItemViewModel(
            modelContext: context,
            item: nil,
            thumbnailService: thumbnailService,
            photoService: photoService
        )

        viewModel.takeCamera(UIImage())
        viewModel.removeImage()

        #expect(viewModel.imageSource == nil)
    }

    @Test
    func saveInsertsNewItemWhenItemIsNil() async throws {
        let container = try makeModelContiner(isStoredInMemoryOnly: true)
        let context = container.mainContext
        let thumbnailService = ThumbnailServiceMock()
        let photoService = PhotoServiceMock()

        let viewModel = await ItemViewModel(
            modelContext: context,
            item: nil,
            thumbnailService: thumbnailService,
            photoService: photoService
        )
        let timestamp = Date(timeIntervalSince1970: 500)
        viewModel.title = "New"
        viewModel.timestamp = timestamp
        viewModel.note = "Note"

        try await viewModel.save()

        let items = try context.fetch(FetchDescriptor<Item>())
        #expect(items.count == 1)
        #expect(items.first?.title == "New")
        #expect(items.first?.timestamp == timestamp)
        #expect(items.first?.note == "Note")
        #expect(items.first?.localIdentifier == nil)
    }

    @Test
    func saveUpdatesExistingItem() async throws {
        let container = try makeModelContiner(isStoredInMemoryOnly: true)
        let context = container.mainContext
        let thumbnailService = ThumbnailServiceMock()
        let photoService = PhotoServiceMock()

        let item = Item(
            title: "Old",
            timestamp: Date(timeIntervalSince1970: 1),
            note: "Old note"
        )
        context.insert(item)
        try context.save()

        let viewModel = await ItemViewModel(
            modelContext: context,
            item: item,
            thumbnailService: thumbnailService,
            photoService: photoService
        )
        let newTimestamp = Date(timeIntervalSince1970: 999)
        viewModel.title = "Updated"
        viewModel.timestamp = newTimestamp
        viewModel.note = "Updated note"

        try await viewModel.save()

        let items = try context.fetch(FetchDescriptor<Item>())
        #expect(items.count == 1)
        #expect(items.first?.title == "Updated")
        #expect(items.first?.timestamp == newTimestamp)
        #expect(items.first?.note == "Updated note")
    }

    @Test
    func saveWithPhotoImageSavesThumbnailOnly() async throws {
        let container = try makeModelContiner(isStoredInMemoryOnly: true)
        let context = container.mainContext
        let thumbnailService = ThumbnailServiceMock()
        let photoService = PhotoServiceMock()
        photoService.loadAssetImageHandler = { _, _ in UIImage() }
        var savedThumbnailIdentifiers: [String] = []
        thumbnailService.saveThumbnailHandler = {
            savedThumbnailIdentifiers.append($0)
        }

        let viewModel = await ItemViewModel(
            modelContext: context,
            item: nil,
            thumbnailService: thumbnailService,
            photoService: photoService
        )
        viewModel.title = "Photo"
        await viewModel.selectPhoto("photo-id")

        try await viewModel.save()

        #expect(photoService.saveImageToPhotoLibraryCallCount == 0)
        #expect(savedThumbnailIdentifiers == ["photo-id"])
        let items = try context.fetch(FetchDescriptor<Item>())
        #expect(items.first?.localIdentifier == "photo-id")
    }

    @Test
    func saveDoesNotReSaveImageWhenLocalIdentifierIsUnchanged() async throws {
        let container = try makeModelContiner(isStoredInMemoryOnly: true)
        let context = container.mainContext
        let thumbnailService = ThumbnailServiceMock()
        let photoService = PhotoServiceMock()
        photoService.loadAssetImageHandler = { _, _ in UIImage() }

        let item = Item(
            title: "A",
            timestamp: Date(timeIntervalSince1970: 1),
            localIdentifier: "existing-id"
        )
        context.insert(item)
        try context.save()

        let viewModel = await ItemViewModel(
            modelContext: context,
            item: item,
            thumbnailService: thumbnailService,
            photoService: photoService
        )

        try await viewModel.save()

        #expect(photoService.saveImageToPhotoLibraryCallCount == 0)
        #expect(thumbnailService.saveThumbnailCallCount == 0)
        #expect(item.localIdentifier == "existing-id")
    }
}
