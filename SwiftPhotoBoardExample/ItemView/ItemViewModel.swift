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
    private let modelContext: ModelContext
    private let thumbnailService: ThumbnailService
    private let phootoService: PhotoService

    init(
        modelContext: ModelContext,
        thumbnailService: ThumbnailService = ThumbnailServiceImpl(),
        photoService: PhotoService = PhotoServiceImpl()
    ) {
        self.modelContext = modelContext
        self.thumbnailService = thumbnailService
        self.phootoService = photoService
    }

}
