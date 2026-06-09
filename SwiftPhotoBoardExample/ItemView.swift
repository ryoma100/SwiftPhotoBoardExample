//
//  ItemView.swift
//  SwiftPhotoBoardExample
//
//  Created by Ryouichi Matsuda on 2026/06/09.
//

import SwiftUI
import SwiftData
import PhotosUI
import Photos

struct ItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var timestamp: Date
    @State private var note: String
    @State private var localIdentifier: String?
    @State private var thumbnailFileID: UUID?
    @State private var pickerItem: PhotosPickerItem?
    @State private var image: UIImage?
    @State private var isShowingFallback = false

    private let item: Item?

    init(item: Item? = nil) {
        self.item = item
        _timestamp = State(initialValue: item?.timestamp ?? Date())
        _note = State(initialValue: item?.note ?? "")
        _localIdentifier = State(initialValue: item?.localIdentifier)
        _thumbnailFileID = State(initialValue: item?.thumbnailFileID)
    }

    var body: some View {
        Form {
            DatePicker("Timestamp", selection: $timestamp)
            TextField("Note", text: $note, axis: .vertical)
            Section("Photo") {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                }
                if isShowingFallback {
                    Text("Photo from the library is unavailable. Showing thumbnail instead.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                PhotosPicker(
                    selection: $pickerItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Text(image == nil ? "Select Photo" : "Change Photo")
                }
            }
        }
        .navigationTitle(item == nil ? "Add Item" : "Edit Item")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
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
                    dismiss()
                }
            }
        }
        .onChange(of: pickerItem) { _, newValue in
            if let identifier = newValue?.itemIdentifier {
                localIdentifier = identifier
                Task {
                    await updateThumbnail(for: identifier)
                }
            }
        }
        .task(id: localIdentifier) {
            await loadImage()
        }
    }

    private func updateThumbnail(for identifier: String) async {
        let oldFileID = thumbnailFileID
        if let newID = await Self.saveThumbnail(for: identifier) {
            thumbnailFileID = newID
            if let oldFileID {
                Self.deleteThumbnail(fileID: oldFileID)
            }
        }
    }

    private static func saveThumbnail(for localIdentifier: String) async -> UUID? {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        guard let asset = assets.firstObject else { return nil }
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        let targetSize = CGSize(width: 64, height: 64)
        let thumbnail: UIImage? = await withCheckedContinuation { continuation in
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { result, _ in
                continuation.resume(returning: result)
            }
        }
        guard let thumbnail, let data = thumbnail.jpegData(compressionQuality: 0.85) else {
            return nil
        }
        let id = UUID()
        let url = thumbnailsDirectory.appendingPathComponent("\(id.uuidString).jpg")
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

    private static func deleteThumbnail(fileID: UUID) {
        let url = thumbnailsDirectory.appendingPathComponent("\(fileID.uuidString).jpg")
        try? FileManager.default.removeItem(at: url)
    }

    static var thumbnailsDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("Thumbnails", isDirectory: true)
    }

    private func loadImage() async {
        if let localIdentifier,
           let assetImage = await loadAssetImage(for: localIdentifier) {
            image = assetImage
            isShowingFallback = false
        } else {
            let thumbnail = loadThumbnailImage()
            image = thumbnail
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
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
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
        guard let thumbnailFileID else { return nil }
        let url = Self.thumbnailsDirectory
            .appendingPathComponent("\(thumbnailFileID.uuidString).jpg")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}
