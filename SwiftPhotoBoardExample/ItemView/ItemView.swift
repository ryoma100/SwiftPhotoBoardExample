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
    private let originalLocalIdentifier: String?
    private let originalThumbnailFileID: UUID?

    init(item: Item? = nil) {
        self.item = item
        self.originalLocalIdentifier = item?.localIdentifier
        self.originalThumbnailFileID = item?.thumbnailFileID
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
        let savedLocalIdentifier: String?
        let savedThumbnailFileID: UUID?
        if let capturedImage {
            guard
                let identifier =
                    await PhotoLibraryStore
                    .saveImageToPhotoLibrary(capturedImage)
            else {
                return
            }
            savedLocalIdentifier = identifier
            savedThumbnailFileID = await ThumbnailStore.saveThumbnail(
                for: identifier
            )
            if let originalThumbnailFileID {
                ThumbnailStore.deleteThumbnail(fileID: originalThumbnailFileID)
            }
        } else if localIdentifier == originalLocalIdentifier {
            savedLocalIdentifier = localIdentifier
            savedThumbnailFileID = originalThumbnailFileID
        } else {
            savedLocalIdentifier = localIdentifier
            if let localIdentifier {
                savedThumbnailFileID = await ThumbnailStore.saveThumbnail(
                    for: localIdentifier
                )
            } else {
                savedThumbnailFileID = nil
            }
            if let originalThumbnailFileID {
                ThumbnailStore.deleteThumbnail(fileID: originalThumbnailFileID)
            }
        }
        if let item {
            item.timestamp = timestamp
            item.note = note
            item.localIdentifier = savedLocalIdentifier
            item.thumbnailFileID = savedThumbnailFileID
        } else {
            let newItem = Item(
                timestamp: timestamp,
                note: note,
                localIdentifier: savedLocalIdentifier,
                thumbnailFileID: savedThumbnailFileID
            )
            modelContext.insert(newItem)
        }
        dismiss()
    }

    static func deleteThumbnail(fileID: UUID) {
        ThumbnailStore.deleteThumbnail(fileID: fileID)
    }

    private func loadImage() async {
        if let capturedImage {
            image = capturedImage
            isShowingFallback = false
            return
        }
        let thumbnail = loadThumbnailImage()
        image = thumbnail
        isShowingFallback = false
        if let localIdentifier,
            let assetImage = await PhotoLibraryStore.loadAssetImage(
                for: localIdentifier
            )
        {
            image = assetImage
            isShowingFallback = false
        } else {
            isShowingFallback = (thumbnail != nil) && (localIdentifier != nil)
        }
    }

    private func loadThumbnailImage() -> UIImage? {
        guard localIdentifier == originalLocalIdentifier,
            let originalThumbnailFileID
        else { return nil }
        return ThumbnailStore.loadThumbnail(fileID: originalThumbnailFileID)
    }
}

private struct PhotoSection: View {
    @Binding var isShowingPhotosPicker: Bool
    @Binding var isShowingCamera: Bool
    let image: UIImage?
    let isShowingFallback: Bool
    let hasPhoto: Bool
    let onRemove: () -> Void

    var body: some View {
        Section("Photo") {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .accessibilityIdentifier("CapturedPhoto")
            }
            if isShowingFallback {
                Text(
                    "Photo from the library is unavailable. Showing thumbnail instead."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Button {
                isShowingPhotosPicker = true
            } label: {
                Label("Select Photo", systemImage: "photo.on.rectangle")
            }
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button {
                    isShowingCamera = true
                } label: {
                    Label("Take Photo", systemImage: "camera")
                }
            }
            if hasPhoto {
                Button(role: .destructive) {
                    onRemove()
                } label: {
                    Label("Delete Photo", systemImage: "trash")
                }
            }
        }
    }
}
