//
//  ItemViewModel.swift
//  SwiftPhotoBoardExample
//
//  Created by Ryouichi Matsuda on 2026/06/27.
//

import SwiftData
import SwiftUI

enum ImageSource {
    case photo(localIdentifier: String, image: UIImage)
    case thumbnail(localIdentifier: String, image: UIImage)
    case camera(image: UIImage)

    var localIdentifier: String? {
        switch self {
        case .photo(let localIdentifier, _), .thumbnail(let localIdentifier, _):
            return localIdentifier
        case .camera:
            return nil
        }
    }

    var image: UIImage {
        switch self {
        case .photo(_, let image), .thumbnail(_, let image), .camera(let image):
            return image
        }
    }
}

@Observable
final class ItemViewModel {
    private let thumbnailService: ThumbnailService
    private let phootoService: PhotoService

    private let modelContext: ModelContext?
    private(set) var item: Item?
    var title: String
    var timestamp: Date
    var note: String
    private(set) var imageSource: ImageSource?

    init(
        modelContext: ModelContext,
        item: Item?,
        thumbnailService: ThumbnailService? = nil,
        photoService: PhotoService? = nil,
    ) async {
        self.thumbnailService = thumbnailService ?? ThumbnailServiceImpl()
        self.phootoService = photoService ?? PhotoServiceImpl()
        self.modelContext = modelContext
        self.item = item
        self.title = item?.title ?? ""
        self.timestamp = item?.timestamp ?? Date()
        self.note = item?.note ?? ""
        self.imageSource = await loadImageSource(item?.localIdentifier)
    }

    init() {
        self.thumbnailService = ThumbnailServiceImpl()
        self.phootoService = PhotoServiceImpl()
        self.modelContext = nil
        self.title = ""
        self.timestamp = Date()
        self.note = ""
    }

    func selectPhoto(_ localIdentifier: String?) async {
        imageSource = await loadImageSource(localIdentifier)
    }

    func takeCamera(_ cameraImage: UIImage) {
        imageSource = .camera(image: cameraImage)
    }

    func removeImage() {
        imageSource = nil
    }

    private func loadImageSource(_ localIdentifier: String?) async
        -> ImageSource?
    {
        guard let localIdentifier else { return nil }

        if let assetImage = await phootoService.loadAssetImage(
            for: localIdentifier,
            targetSize: CGSize(width: 1024, height: 1024)
        ) {
            return .photo(localIdentifier: localIdentifier, image: assetImage)
        }
        if let thumbnail = thumbnailService.loadThumbnail(
            localIdentifier: localIdentifier
        ) {
            return .thumbnail(
                localIdentifier: localIdentifier,
                image: thumbnail
            )
        }
        return nil
    }

    func save() async throws {
        guard let modelContext else { throw SwiftDataError.missingModelContext }

        let localIdentifier = await saveImage()
        if let item {
            item.title = title
            item.timestamp = timestamp
            item.note = note
            item.localIdentifier = localIdentifier
        } else {
            let newItem = Item(
                title: title,
                timestamp: timestamp,
                note: note,
                localIdentifier: localIdentifier
            )
            modelContext.insert(newItem)
        }
        try modelContext.save()
    }

    private func saveImage() async -> String? {
        if item?.localIdentifier == imageSource?.localIdentifier {
            return item?.localIdentifier
        }
        if case .camera(let capturedImage) = imageSource {
            if let localIdentifier =
                await phootoService
                .saveImageToPhotoLibrary(capturedImage)
            {
                await thumbnailService.saveThumbnail(for: localIdentifier)
                return localIdentifier
            }
        }
        if case .photo(let localIdentifier, _) = imageSource {
            await thumbnailService.saveThumbnail(for: localIdentifier)
            return localIdentifier
        }
        return nil
    }
}
