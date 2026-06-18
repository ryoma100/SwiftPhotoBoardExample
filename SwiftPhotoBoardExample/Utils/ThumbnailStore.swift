//
//  ThumbnailStore.swift
//  SwiftPhotoBoardExample
//
//  Created by Ryouichi Matsuda on 2026/06/09.
//

import Photos
import UIKit

enum ThumbnailStore {
    static var directory: URL {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return base.appendingPathComponent("Thumbnails", isDirectory: true)
    }

    static func saveThumbnail(for localIdentifier: String) async -> UUID? {
        let asset = PHAsset.fetchAssets(
            withLocalIdentifiers: [localIdentifier],
            options: nil
        ).firstObject
        guard let asset else { return nil }

        let targetSize = CGSize(width: 64, height: 64)
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        let thumbnailImage: UIImage? = await withCheckedContinuation {
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
        guard let thumbnailImage else { return nil }

        let jpegData = thumbnailImage.jpegData(compressionQuality: 0.85)
        guard let jpegData else { return nil }

        let id = UUID()
        let url = directory.appendingPathComponent("\(id.uuidString).jpg")
        do {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            try jpegData.write(to: url)
            return id
        } catch {
            return nil
        }
    }

    static func deleteThumbnail(fileID: UUID) {
        let url = directory.appendingPathComponent("\(fileID.uuidString).jpg")
        try? FileManager.default.removeItem(at: url)
    }

    static func loadThumbnail(fileID: UUID) -> UIImage? {
        let url = directory.appendingPathComponent("\(fileID.uuidString).jpg")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}
