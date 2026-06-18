//
//  ItemView.swift
//  SwiftPhotoBoardExample
//
//  Created by Ryouichi Matsuda on 2026/06/09.
//

import PhotosUI
import SwiftData
import SwiftUI

struct ItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var timestamp: Date
    @State private var note: String
    @State private var localIdentifier: String?
    @State private var pickerItem: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var image: UIImage?
    @State private var isShowingFallback = false

    @State private var isShowingPhotosPicker = false
    @State private var isShowingCamera = false

    private let item: Item?

    init(item: Item? = nil) {
        self.item = item
        _timestamp = State(initialValue: item?.timestamp ?? Date())
        _note = State(initialValue: item?.note ?? "")
        _localIdentifier = State(initialValue: item?.localIdentifier)
    }

    var body: some View {
        Form {
            DatePicker("Timestamp", selection: $timestamp)
            ClearableTextField(
                titleKey: "Note",
                text: $note,
                fieldIdentifier: "Note",
                clearIdentifier: "ClearNote"
            )
            PhotoSection(
                isShowingPhotosPicker: $isShowingPhotosPicker,
                isShowingCamera: $isShowingCamera,
                image: image,
                isShowingFallback: isShowingFallback,
                hasPhoto: localIdentifier != nil || capturedImage != nil,
                onRemove: removePhoto
            )
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(item == nil ? "Add Item" : "Edit Item")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await save() }
                }
            }
        }
        .photosPicker(
            isPresented: $isShowingPhotosPicker,
            selection: $pickerItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .fullScreenCover(isPresented: $isShowingCamera) {
            CameraPicker { image in
                isShowingCamera = false
                if let image {
                    handleCapturedImage(image)
                }
            }
            .ignoresSafeArea()
        }
        .onChange(of: pickerItem) { _, newValue in
            if let identifier = newValue?.itemIdentifier {
                capturedImage = nil
                localIdentifier = identifier
            }
        }
        .task(id: localIdentifier) {
            await loadImage()
        }
    }

    private func removePhoto() {
        capturedImage = nil
        localIdentifier = nil
        pickerItem = nil
        image = nil
        isShowingFallback = false
    }

    private func handleCapturedImage(_ newImage: UIImage) {
        capturedImage = newImage
        pickerItem = nil
        localIdentifier = nil
        image = newImage
        isShowingFallback = false
    }

    private func save() async {
        guard let resolved = await resolvePhotoPersistence() else { return }
        persistItem(
            localIdentifier: resolved.localIdentifier,
            thumbnailFileID: resolved.thumbnailFileID
        )
        dismiss()
    }

    private func resolvePhotoPersistence() async -> (localIdentifier: String?, thumbnailFileID: UUID?)? {
        let originalLocalIdentifier = item?.localIdentifier
        let originalThumbnailFileID = item?.thumbnailFileID
        
        if let capturedImage {
            guard
                let identifier =
                    await PhotoLibraryStore
                    .saveImageToPhotoLibrary(capturedImage)
            else {
                return nil
            }
            let thumbnailFileID = await ThumbnailStore.saveThumbnail(
                for: identifier
            )
            if let originalThumbnailFileID {
                ThumbnailStore.deleteThumbnail(fileID: originalThumbnailFileID)
            }
            return (identifier, thumbnailFileID)
        }
        if localIdentifier == originalLocalIdentifier {
            return (localIdentifier, originalThumbnailFileID)
        }
        let thumbnailFileID: UUID?
        if let localIdentifier {
            thumbnailFileID = await ThumbnailStore.saveThumbnail(
                for: localIdentifier
            )
        } else {
            thumbnailFileID = nil
        }
        if let originalThumbnailFileID {
            ThumbnailStore.deleteThumbnail(fileID: originalThumbnailFileID)
        }
        return (localIdentifier, thumbnailFileID)
    }

    private func persistItem(localIdentifier: String?, thumbnailFileID: UUID?) {
        if let item {
            item.timestamp = timestamp
            item.note = note
            item.localIdentifier = localIdentifier
            item.thumbnailFileID = thumbnailFileID
        } else {
            let newItem = Item(
                timestamp: timestamp,
                note: note,
                localIdentifier: localIdentifier,
                thumbnailFileID: thumbnailFileID
            )
            modelContext.insert(newItem)
        }
        try? modelContext.save()
    }

    private func loadImage() async {
        if let capturedImage {
            image = capturedImage
            isShowingFallback = false
            return
        }
        let thumbnail = loadThumbnailImage()
        image = thumbnail
        let assetImage = await loadAssetImage()
        if let assetImage {
            image = assetImage
            isShowingFallback = false
        } else {
            isShowingFallback = (thumbnail != nil) && (localIdentifier != nil)
        }
    }

    private func loadThumbnailImage() -> UIImage? {
        let originalLocalIdentifier = item?.localIdentifier
        let originalThumbnailFileID = item?.thumbnailFileID

        guard localIdentifier == originalLocalIdentifier,
            let originalThumbnailFileID
        else { return nil }
        return ThumbnailStore.loadThumbnail(fileID: originalThumbnailFileID)
    }

    private func loadAssetImage() async -> UIImage? {
        guard let localIdentifier else { return nil }
        return await PhotoLibraryStore.loadAssetImage(for: localIdentifier)
    }
}

#Preview {
    ItemView()
        .modelContainer(for: Item.self, inMemory: true)
}
