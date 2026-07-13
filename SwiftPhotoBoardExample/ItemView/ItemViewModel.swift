//
//  ItemViewModel.swift
//  SwiftPhotoBoardExample
//
//  Created by Ryouichi Matsuda on 2026/06/27.
//

import SwiftData
import SwiftUI

enum ImageSource {
    case savedImage(imageFileId: UUID, savedImage: UIImage)
    case takeCamera(cameraImage: UIImage)
    case selectedPhoto(photoImage: UIImage, sha256Hash: String)

    var image: UIImage {
        switch self {
        case .savedImage(_, let savedImage):
            return savedImage
        case .takeCamera(let cameraImage):
            return cameraImage
        case .selectedPhoto(let photoImage, _):
            return photoImage
        }
    }

    var imageFileId: UUID? {
        switch self {
        case .savedImage(let imageFileId, _):
            return imageFileId
        default:
            return nil
        }
    }
}

@Observable
final class ItemViewModel {
    private let phootoService: PhotoService
    private let imageService: ImageService
    let modelContext: ModelContext?

    private(set) var item: Item?
    var title: String
    var timestamp: Date
    var note: String
    var imageSource: ImageSource?

    init(
        modelContext: ModelContext,
        item: Item?,
        photoService: PhotoService? = nil,
        imageService: ImageService? = nil,
    ) async {
        self.phootoService = photoService ?? PhotoServiceImpl()
        self.imageService = imageService ?? ImageServiceImpl()
        self.modelContext = modelContext
        self.item = item
        self.title = item?.title ?? ""
        self.timestamp = item?.timestamp ?? Date()
        self.note = item?.note ?? ""
        self.imageSource = await loadImageSource(item?.imageFileId)
    }

    // Dummy for initialization; not actually used.
    init() {
        self.phootoService = PhotoServiceImpl()
        self.imageService = ImageServiceImpl()
        self.modelContext = nil
        self.title = ""
        self.timestamp = Date()
        self.note = ""
    }

    func selectPhoto(localIdentifier: String) async {
        guard let loaded = await phootoService.loadPhotoAsset(
            localIdentifier: localIdentifier
        ) else { return }
        imageSource = .selectedPhoto(
            photoImage: loaded.image,
            sha256Hash: loaded.sha256Hash
        )
    }

    func takeCamera(image: UIImage) {
        imageSource = .takeCamera(cameraImage: image)
    }

    func removeImage() {
        imageSource = nil
    }

    private func loadImageSource(_ imageFileId: UUID?) async
        -> ImageSource?
    {
        guard let imageFileId else { return nil }
        guard let image = imageService.loadImage(fileId: imageFileId) else {
            return nil
        }
        return .savedImage(imageFileId: imageFileId, savedImage: image)
    }

    func save() async throws {
        guard let modelContext else { throw SwiftDataError.missingModelContext }

        let imageFileId = try await saveImage()
        if let item {
            item.title = title
            item.timestamp = timestamp
            item.note = note
            item.imageFileId = imageFileId
        } else {
            let newItem = Item(
                title: title,
                timestamp: timestamp,
                note: note,
                imageFileId: imageFileId
            )
            modelContext.insert(newItem)
        }
        try modelContext.save()
    }

    private func saveImage() async throws -> UUID? {
        switch imageSource {
        case .savedImage(let imageFileId, savedImage: _):
            return imageFileId
        case .takeCamera(let cameraImage):
            return try await saveCameraImage(image: cameraImage)
        case .selectedPhoto(let photoImage, let sha256Hash):
            return try await savePhotoImage(image: photoImage, sha256Hash: sha256Hash)
        default:
            return nil
        }
    }

    private func saveCameraImage(image: UIImage) async throws -> UUID? {
        guard let modelContext else { throw SwiftDataError.missingModelContext }

        let sha256Hash = await phootoService.saveImageToPhotoLibrary(image)
        let imageFile = ImageFile(sha256Hash: sha256Hash)
        imageService.saveImage(fileId: imageFile.id, image: image)
        modelContext.insert(imageFile)
        return imageFile.id
    }
    
    private func savePhotoImage(image: UIImage, sha256Hash: String) async throws -> UUID? {
        guard let modelContext else { throw SwiftDataError.missingModelContext }

        let descriptor = FetchDescriptor<ImageFile>(
            predicate: #Predicate { $0.sha256Hash == sha256Hash }
        )
        if let existing = try modelContext.fetch(descriptor).first {
            return existing.id
        }

        let imageFile = ImageFile(sha256Hash: sha256Hash)
        imageService.saveImage(fileId: imageFile.id, image: image)
        modelContext.insert(imageFile)
        return imageFile.id
    }
}
