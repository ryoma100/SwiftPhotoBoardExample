//
//  ItemView.swift
//  SwiftPhotoBoardExample
//
//  Created by Ryouichi Matsuda on 2026/06/09.
//

import Photos
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
            TextField("Note", text: $note, axis: .vertical)
                .accessibilityIdentifier("Note")
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
                if localIdentifier != nil || capturedImage != nil {
                    Button(role: .destructive) {
                        removePhoto()
                    } label: {
                        Label("Delete Photo", systemImage: "trash")
                    }
                }
            }
        }
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
        let finalLocalIdentifier: String?
        let finalThumbnailFileID: UUID?
        if let capturedImage {
            guard
                let identifier = await Self.saveImageToPhotoLibrary(
                    capturedImage
                )
            else {
                return
            }
            finalLocalIdentifier = identifier
            finalThumbnailFileID = await Self.saveThumbnail(for: identifier)
            if let originalThumbnailFileID {
                Self.deleteThumbnail(fileID: originalThumbnailFileID)
            }
        } else if localIdentifier == originalLocalIdentifier {
            finalLocalIdentifier = localIdentifier
            finalThumbnailFileID = originalThumbnailFileID
        } else {
            finalLocalIdentifier = localIdentifier
            if let localIdentifier {
                finalThumbnailFileID = await Self.saveThumbnail(
                    for: localIdentifier
                )
            } else {
                finalThumbnailFileID = nil
            }
            if let originalThumbnailFileID {
                Self.deleteThumbnail(fileID: originalThumbnailFileID)
            }
        }
        if let item {
            item.timestamp = timestamp
            item.note = note
            item.localIdentifier = finalLocalIdentifier
            item.thumbnailFileID = finalThumbnailFileID
        } else {
            let newItem = Item(
                timestamp: timestamp,
                note: note,
                localIdentifier: finalLocalIdentifier,
                thumbnailFileID: finalThumbnailFileID
            )
            modelContext.insert(newItem)
        }
        dismiss()
    }

    private static func saveImageToPhotoLibrary(_ image: UIImage) async
        -> String?
    {
        var status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .notDetermined {
            status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        }
        guard status == .authorized || status == .limited else { return nil }
        return await withCheckedContinuation { continuation in
            var placeholder: PHObjectPlaceholder?
            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetChangeRequest.creationRequestForAsset(
                    from: image
                )
                placeholder = request.placeholderForCreatedAsset
            } completionHandler: { success, _ in
                continuation.resume(
                    returning: success ? placeholder?.localIdentifier : nil
                )
            }
        }
    }

    private static func saveThumbnail(for localIdentifier: String) async
        -> UUID?
    {
        let assets = PHAsset.fetchAssets(
            withLocalIdentifiers: [localIdentifier],
            options: nil
        )
        guard let asset = assets.firstObject else { return nil }
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        let targetSize = CGSize(width: 64, height: 64)
        let thumbnail: UIImage? = await withCheckedContinuation {
            continuation in
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { result, _ in
                continuation.resume(returning: result)
            }
        }
        guard let thumbnail,
            let data = thumbnail.jpegData(compressionQuality: 0.85)
        else {
            return nil
        }
        let id = UUID()
        let url = thumbnailsDirectory.appendingPathComponent(
            "\(id.uuidString).jpg"
        )
        do {
            try FileManager.default.createDirectory(
                at: thumbnailsDirectory,
                withIntermediateDirectories: true
            )
            try data.write(to: url)
            return id
        } catch {
            return nil
        }
    }

    static func deleteThumbnail(fileID: UUID) {
        let url = thumbnailsDirectory.appendingPathComponent(
            "\(fileID.uuidString).jpg"
        )
        try? FileManager.default.removeItem(at: url)
    }

    static var thumbnailsDirectory: URL {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return base.appendingPathComponent("Thumbnails", isDirectory: true)
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
            let assetImage = await loadAssetImage(for: localIdentifier)
        {
            image = assetImage
            isShowingFallback = false
        } else {
            isShowingFallback = (thumbnail != nil) && (localIdentifier != nil)
        }
    }

    private func loadAssetImage(for localIdentifier: String) async -> UIImage? {
        var status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .notDetermined {
            status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        }
        guard status == .authorized || status == .limited else {
            return nil
        }
        let assets = PHAsset.fetchAssets(
            withLocalIdentifiers: [localIdentifier],
            options: nil
        )
        guard let asset = assets.firstObject else {
            return nil
        }
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        let targetSize = CGSize(width: 1024, height: 1024)
        return await withCheckedContinuation { continuation in
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options
            ) { result, _ in
                continuation.resume(returning: result)
            }
        }
    }

    private func loadThumbnailImage() -> UIImage? {
        guard localIdentifier == originalLocalIdentifier,
            let originalThumbnailFileID
        else { return nil }
        let url = Self.thumbnailsDirectory
            .appendingPathComponent("\(originalThumbnailFileID.uuidString).jpg")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}
struct CameraPicker: UIViewControllerRepresentable {
    var onCompletion: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(
        _ uiViewController: UIImagePickerController,
        context: Context
    ) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCompletion: onCompletion)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate,
        UINavigationControllerDelegate
    {
        let onCompletion: (UIImage?) -> Void

        init(onCompletion: @escaping (UIImage?) -> Void) {
            self.onCompletion = onCompletion
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController
                .InfoKey: Any]
        ) {
            onCompletion(info[.originalImage] as? UIImage)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCompletion(nil)
        }
    }
}
