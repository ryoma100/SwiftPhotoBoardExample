//
//  ItemView.swift
//  SwiftPhotoBoardExample
//
//  Created by Ryouichi Matsuda on 2026/06/09.
//

import PhotosUI
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

struct ItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let item: Item?
    private let photoLibraryService: PhotoService
    private let thumbnailService: ThumbnailService

    @State private var title: String
    @State private var timestamp: Date
    @State private var note: String
    @State private var imageSource: ImageSource?

    init(
        item: Item? = nil,
        photoLibraryService: PhotoService = PhotoServiceImpl(),
        thumbnailService: ThumbnailService = ThumbnailServiceImpl()
    ) {
        self.item = item
        self.photoLibraryService = photoLibraryService
        self.thumbnailService = thumbnailService
        _title = State(initialValue: item?.title ?? "")
        _timestamp = State(initialValue: item?.timestamp ?? Date())
        _note = State(initialValue: item?.note ?? "")
    }

    var body: some View {
        Form {
            ClearableTextField(
                titleKey: "Title",
                text: $title,
                axis: .horizontal,
                fieldIdentifier: "Title",
                clearIdentifier: "ClearTitle"
            )
            DatePicker("Timestamp", selection: $timestamp)
            ClearableTextField(
                titleKey: "Note",
                text: $note,
                fieldIdentifier: "Note",
                clearIdentifier: "ClearNote"
            )
            Section("Photo") {
                ImageOrThumbnail(imageSource: imageSource)
                SelectPhotoButton { localIdentifier in
                    Task { await handleSelectPhoto(localIdentifier) }
                }
                TakeCameraButton { handleTakeCamera($0) }
                RemoveImageButton(imageSource: imageSource) {
                    handleRemoveImage()
                }
            }
        }
        .navigationTitle(item == nil ? "Add Item" : "Edit Item")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                SaveButton(title: title) { Task { await handleSave() } }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                KeyboardDownButton()
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .task { await handleSelectPhoto(item?.localIdentifier) }
    }

    private func handleSelectPhoto(_ localIdentifier: String?) async {
        imageSource = await loadImageSource(localIdentifier)
    }

    private func handleTakeCamera(_ cameraImage: UIImage) {
        imageSource = .camera(image: cameraImage)
    }

    private func handleRemoveImage() {
        imageSource = nil
    }

    private func handleSave() async {
        await save()
        dismiss()
    }

    private func loadImageSource(_ localIdentifier: String?) async
        -> ImageSource?
    {
        guard let localIdentifier else { return nil }

        if let assetImage = await photoLibraryService.loadAssetImage(
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

    private func save() async {
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
        try? modelContext.save()
    }

    private func saveImage() async -> String? {
        if item?.localIdentifier == imageSource?.localIdentifier {
            return item?.localIdentifier
        }
        if case .camera(let capturedImage) = imageSource {
            if let localIdentifier =
                await photoLibraryService
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

#Preview {
    let container = try! makeModelContiner(isStoredInMemoryOnly: true)
    ItemView().modelContainer(container)
}
