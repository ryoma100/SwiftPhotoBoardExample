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

    let container: ModelContainer
    let context: ModelContext
    let photoLibraryService: PhotoLibraryServiceMock
    let imageFileService: ImageFileServiceMock

    init() throws {
        container = try makeModelContiner(isStoredInMemoryOnly: true)
        context = container.mainContext
        photoLibraryService = PhotoLibraryServiceMock()
        imageFileService = ImageFileServiceMock()
    }

    @Test
    func initWithNilItemSetsDefaults() async throws {
        let viewModel = await ItemViewModel(
            modelContext: context,
            item: nil,
            photoLibraryService: photoLibraryService,
            imageFileService: imageFileService
        )

        #expect(viewModel.item == nil)
        #expect(viewModel.title == "")
        #expect(viewModel.note == "")
        #expect(viewModel.imageSource == nil)
    }

    @Test
    func initWithItemCopiesProperties() async throws {
        let timestamp = Date(timeIntervalSince1970: 100)
        let item = Item(
            title: "Title",
            timestamp: timestamp,
            note: "Note",
            imageFileId: nil
        )
        context.insert(item)

        let viewModel = await ItemViewModel(
            modelContext: context,
            item: item,
            photoLibraryService: photoLibraryService,
            imageFileService: imageFileService
        )

        #expect(viewModel.item === item)
        #expect(viewModel.title == "Title")
        #expect(viewModel.timestamp == timestamp)
        #expect(viewModel.note == "Note")
        #expect(viewModel.imageSource == nil)
    }

    @Test
    func initLoadsSavedImageWhenImageFileIdIsPresent() async throws {
        let expectedImage = makeImage()
        imageFileService.loadImageHandler = { _ in expectedImage }

        let imageFileId = UUID()
        let item = Item(
            title: "Title",
            timestamp: Date(timeIntervalSince1970: 1),
            imageFileId: imageFileId
        )

        let viewModel = await ItemViewModel(
            modelContext: context,
            item: item,
            photoLibraryService: photoLibraryService,
            imageFileService: imageFileService
        )

        #expect(imageFileService.loadImageCallCount == 1)
        if case let .savedImage(loadedId, loadedImage) = viewModel.imageSource {
            #expect(loadedId == imageFileId)
            #expect(loadedImage === expectedImage)
        } else {
            Issue.record("Expected savedImage, got \(String(describing: viewModel.imageSource))")
        }
    }

    @Test
    func initLeavesImageSourceNilWhenLoadImageReturnsNil() async throws {
        let item = Item(
            title: "Title",
            timestamp: Date(timeIntervalSince1970: 1),
            imageFileId: UUID()
        )

        let viewModel = await ItemViewModel(
            modelContext: context,
            item: item,
            photoLibraryService: photoLibraryService,
            imageFileService: imageFileService
        )

        #expect(imageFileService.loadImageCallCount == 1)
        #expect(viewModel.imageSource == nil)
    }

    @Test
    func selectPhotoSetsImageSource() async throws {
        let expectedImage = makeImage()
        photoLibraryService.loadPhotoAssetHandler = { _ in
            (image: expectedImage, sha256Hash: Data("hash".utf8))
        }

        let viewModel = await ItemViewModel(
            modelContext: context,
            item: nil,
            photoLibraryService: photoLibraryService,
            imageFileService: imageFileService
        )

        await viewModel.selectPhoto(localIdentifier: "local-id")

        #expect(photoLibraryService.loadPhotoAssetCallCount == 1)
        if case let .selectedPhoto(photoImage, hash) = viewModel.imageSource {
            #expect(photoImage === expectedImage)
            #expect(hash == Data("hash".utf8))
        } else {
            Issue.record("Expected selectedPhoto, got \(String(describing: viewModel.imageSource))")
        }
    }

    @Test
    func selectPhotoLeavesImageSourceUnchangedWhenAssetMissing() async throws {
        let viewModel = await ItemViewModel(
            modelContext: context,
            item: nil,
            photoLibraryService: photoLibraryService,
            imageFileService: imageFileService
        )

        await viewModel.selectPhoto(localIdentifier: "missing")

        #expect(viewModel.imageSource == nil)
    }

    @Test
    func takeCameraSetsImageSource() async throws {
        let image = makeImage()

        let viewModel = await ItemViewModel(
            modelContext: context,
            item: nil,
            photoLibraryService: photoLibraryService,
            imageFileService: imageFileService
        )

        viewModel.takeCamera(image: image)

        if case let .takeCamera(cameraImage) = viewModel.imageSource {
            #expect(cameraImage === image)
        } else {
            Issue.record("Expected takeCamera, got \(String(describing: viewModel.imageSource))")
        }
    }

    @Test
    func removeImageClearsImageSource() async throws {
        let viewModel = await ItemViewModel(
            modelContext: context,
            item: nil,
            photoLibraryService: photoLibraryService,
            imageFileService: imageFileService
        )
        viewModel.takeCamera(image: makeImage())

        viewModel.removeImage()

        #expect(viewModel.imageSource == nil)
    }

    @Test
    func saveWithoutModelContextThrows() async throws {
        let viewModel = ItemViewModel()

        await #expect(throws: SwiftDataError.self) {
            try await viewModel.save()
        }
    }

    @Test
    func saveInsertsNewItemWithoutImage() async throws {
        let viewModel = await ItemViewModel(
            modelContext: context,
            item: nil,
            photoLibraryService: photoLibraryService,
            imageFileService: imageFileService
        )
        viewModel.title = "New"
        viewModel.timestamp = Date(timeIntervalSince1970: 42)
        viewModel.note = "Memo"

        try await viewModel.save()

        let items = try context.fetch(FetchDescriptor<Item>())
        #expect(items.count == 1)
        #expect(items.first?.title == "New")
        #expect(items.first?.timestamp == Date(timeIntervalSince1970: 42))
        #expect(items.first?.note == "Memo")
        #expect(items.first?.imageFileId == nil)
        let imageFiles = try context.fetch(FetchDescriptor<ImageFile>())
        #expect(imageFiles.isEmpty)
    }

    @Test
    func saveInsertsNewItemWithCameraImage() async throws {
        photoLibraryService.saveImageToPhotoLibraryHandler = { _ in Data("camera-hash".utf8) }

        var saveImageArgs: [(UUID, UIImage)] = []
        imageFileService.saveImageHandler = { saveImageArgs.append(($0, $1)) }

        let viewModel = await ItemViewModel(
            modelContext: context,
            item: nil,
            photoLibraryService: photoLibraryService,
            imageFileService: imageFileService
        )
        viewModel.title = "Cam"
        viewModel.takeCamera(image: makeImage())

        try await viewModel.save()

        #expect(photoLibraryService.saveImageToPhotoLibraryCallCount == 1)
        let items = try context.fetch(FetchDescriptor<Item>())
        #expect(items.count == 1)
        let imageFiles = try context.fetch(FetchDescriptor<ImageFile>())
        #expect(imageFiles.count == 1)
        #expect(imageFiles.first?.sha256Hash == Data("camera-hash".utf8))
        #expect(items.first?.imageFileId == imageFiles.first?.id)
        #expect(saveImageArgs.count == 1)
        #expect(saveImageArgs.first?.0 == imageFiles.first?.id)
    }

    @Test
    func saveInsertsNewItemWithPhotoImageCreatesImageFile() async throws {
        let viewModel = await ItemViewModel(
            modelContext: context,
            item: nil,
            photoLibraryService: photoLibraryService,
            imageFileService: imageFileService
        )
        viewModel.imageSource = .selectedPhoto(
            photoImage: makeImage(),
            sha256Hash: Data("photo-hash".utf8)
        )

        try await viewModel.save()

        let items = try context.fetch(FetchDescriptor<Item>())
        #expect(items.count == 1)
        let imageFiles = try context.fetch(FetchDescriptor<ImageFile>())
        #expect(imageFiles.count == 1)
        #expect(imageFiles.first?.sha256Hash == Data("photo-hash".utf8))
        #expect(items.first?.imageFileId == imageFiles.first?.id)
        #expect(imageFileService.saveImageCallCount == 1)
    }

    @Test
    func saveInsertsNewItemWithPhotoImageReusesExistingImageFile() async throws {
        let existingImageFile = ImageFile(sha256Hash: Data("photo-hash".utf8))
        let existingId = existingImageFile.id
        context.insert(existingImageFile)
        try context.save()

        let viewModel = await ItemViewModel(
            modelContext: context,
            item: nil,
            photoLibraryService: photoLibraryService,
            imageFileService: imageFileService
        )
        viewModel.imageSource = .selectedPhoto(
            photoImage: makeImage(),
            sha256Hash: Data("photo-hash".utf8)
        )

        try await viewModel.save()

        let items = try context.fetch(FetchDescriptor<Item>())
        #expect(items.count == 1)
        #expect(items.first?.imageFileId == existingId)
        let imageFiles = try context.fetch(FetchDescriptor<ImageFile>())
        #expect(imageFiles.count == 1)
        #expect(imageFileService.saveImageCallCount == 0)
    }

    @Test
    func saveUpdatesExistingItemFields() async throws {
        let item = Item(
            title: "Old",
            timestamp: Date(timeIntervalSince1970: 1),
            note: "OldNote",
            imageFileId: nil
        )
        context.insert(item)
        try context.save()

        let viewModel = await ItemViewModel(
            modelContext: context,
            item: item,
            photoLibraryService: photoLibraryService,
            imageFileService: imageFileService
        )
        viewModel.title = "New"
        viewModel.note = "NewNote"
        viewModel.timestamp = Date(timeIntervalSince1970: 200)

        try await viewModel.save()

        #expect(item.title == "New")
        #expect(item.note == "NewNote")
        #expect(item.timestamp == Date(timeIntervalSince1970: 200))
        #expect(item.imageFileId == nil)
        let items = try context.fetch(FetchDescriptor<Item>())
        #expect(items.count == 1)
    }

    @Test
    func saveDeletesOldImageWhenNoOtherItemReferences() async throws {
        imageFileService.loadImageHandler = { _ in UIImage() }

        let oldImageFile = ImageFile(sha256Hash: Data("old-hash".utf8))
        let oldImageFileId = oldImageFile.id
        let item = Item(
            title: "T",
            timestamp: Date(timeIntervalSince1970: 1),
            imageFileId: oldImageFileId
        )
        context.insert(oldImageFile)
        context.insert(item)
        try context.save()

        var deletedImageIds: [UUID] = []
        imageFileService.deleteImageHandler = { deletedImageIds.append($0) }

        let viewModel = await ItemViewModel(
            modelContext: context,
            item: item,
            photoLibraryService: photoLibraryService,
            imageFileService: imageFileService
        )
        viewModel.imageSource = .selectedPhoto(
            photoImage: makeImage(),
            sha256Hash: Data("new-hash".utf8)
        )

        try await viewModel.save()

        #expect(deletedImageIds == [oldImageFileId])
        let imageFiles = try context.fetch(FetchDescriptor<ImageFile>())
        #expect(imageFiles.count == 1)
        #expect(imageFiles.first?.sha256Hash == Data("new-hash".utf8))
        #expect(item.imageFileId == imageFiles.first?.id)
    }

    @Test
    func saveKeepsOldImageWhenOtherItemStillReferences() async throws {
        imageFileService.loadImageHandler = { _ in UIImage() }

        let oldImageFile = ImageFile(sha256Hash: Data("old-hash".utf8))
        let oldImageFileId = oldImageFile.id
        let item1 = Item(
            title: "1",
            timestamp: Date(timeIntervalSince1970: 1),
            imageFileId: oldImageFileId
        )
        let item2 = Item(
            title: "2",
            timestamp: Date(timeIntervalSince1970: 2),
            imageFileId: oldImageFileId
        )
        context.insert(oldImageFile)
        context.insert(item1)
        context.insert(item2)
        try context.save()

        let viewModel = await ItemViewModel(
            modelContext: context,
            item: item1,
            photoLibraryService: photoLibraryService,
            imageFileService: imageFileService
        )
        viewModel.imageSource = .selectedPhoto(
            photoImage: makeImage(),
            sha256Hash: Data("new-hash".utf8)
        )

        try await viewModel.save()

        #expect(imageFileService.deleteImageCallCount == 0)
        let imageFiles = try context.fetch(FetchDescriptor<ImageFile>())
        #expect(imageFiles.count == 2)
        #expect(item2.imageFileId == oldImageFileId)
    }

    private func makeImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        return renderer.image { _ in }
    }
}
