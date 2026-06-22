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

    @State private var title: String
    @State private var timestamp: Date
    @State private var note: String
    @State private var localIdentifier: String?
    @State private var pickerItem: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var image: UIImage?
    @State private var isShowingFallback = false

    @State private var isShowingPhotosPicker = false
    @State private var isShowingCamera = false
    @State private var isShowingEmptyTitleAlert = false

    private let item: Item?

    init(item: Item? = nil) {
        self.item = item
        _title = State(initialValue: item?.title ?? "")
        _timestamp = State(initialValue: item?.timestamp ?? Date())
        _note = State(initialValue: item?.note ?? "")
        _localIdentifier = State(initialValue: item?.localIdentifier)
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
                .foregroundStyle(isTitleEmpty ? Color.gray : Color.accentColor)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                } label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                }
                .accessibilityLabel("Done")
            }
        }
        .alert(
            "Title is required",
            isPresented: $isShowingEmptyTitleAlert
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please enter a title before saving.")
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

    private var isTitleEmpty: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            isShowingEmptyTitleAlert = true
            return
        }
        let originalLocalIdentifier = item?.localIdentifier
        let resolvedLocalIdentifier: String?

        if let capturedImage {
            guard
                let identifier =
                    await PhotoLibraryStore
                    .saveImageToPhotoLibrary(capturedImage)
            else {
                return
            }
            await ThumbnailStore.saveThumbnail(for: identifier)
            if let originalLocalIdentifier, originalLocalIdentifier != identifier {
                ThumbnailStore.deleteThumbnail(localIdentifier: originalLocalIdentifier)
            }
            resolvedLocalIdentifier = identifier
        } else if localIdentifier == originalLocalIdentifier {
            resolvedLocalIdentifier = localIdentifier
        } else {
            if let localIdentifier {
                await ThumbnailStore.saveThumbnail(for: localIdentifier)
            }
            if let originalLocalIdentifier {
                ThumbnailStore.deleteThumbnail(localIdentifier: originalLocalIdentifier)
            }
            resolvedLocalIdentifier = localIdentifier
        }
        persistItem(localIdentifier: resolvedLocalIdentifier)
        dismiss()
    }

    private func persistItem(localIdentifier: String?) {
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

        guard localIdentifier == originalLocalIdentifier,
            let originalLocalIdentifier
        else { return nil }
        return ThumbnailStore.loadThumbnail(localIdentifier: originalLocalIdentifier)
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
