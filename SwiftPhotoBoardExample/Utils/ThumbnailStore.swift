//
//  ThumbnailStore.swift
//  SwiftPhotoBoardExample
//
//  Created by Ryouichi Matsuda on 2026/06/09.
//

import Photos
import UIKit

protocol ThumbnailStoring {
    func saveThumbnail(for localIdentifier: String) async
    func deleteThumbnail(localIdentifier: String)
    func loadThumbnail(localIdentifier: String) -> UIImage?
}

struct ThumbnailStore: ThumbnailStoring {
    static var directory: URL {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return base.appendingPathComponent("Thumbnails", isDirectory: true)
    }

    func saveThumbnail(for localIdentifier: String) async {
        let asset = PHAsset.fetchAssets(
            withLocalIdentifiers: [localIdentifier],
            options: nil
        ).firstObject
        guard let asset else { return }

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
        guard let thumbnailImage else { return }

        let jpegData = thumbnailImage.jpegData(compressionQuality: 0.85)
        guard let jpegData else { return }

        let url = Self.directory.appendingPathComponent(Self.fileName(for: localIdentifier))
        do {
            try FileManager.default.createDirectory(
                at: Self.directory,
                withIntermediateDirectories: true
            )
            try jpegData.write(to: url)
        } catch {
        }
    }

    func deleteThumbnail(localIdentifier: String) {
        let url = Self.directory.appendingPathComponent(Self.fileName(for: localIdentifier))
        try? FileManager.default.removeItem(at: url)
    }

    func loadThumbnail(localIdentifier: String) -> UIImage? {
        let url = Self.directory.appendingPathComponent(Self.fileName(for: localIdentifier))
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func saveThumbnail(for localIdentifier: String) async {
        await ThumbnailStore().saveThumbnail(for: localIdentifier)
    }

    static func deleteThumbnail(localIdentifier: String) {
        ThumbnailStore().deleteThumbnail(localIdentifier: localIdentifier)
    }

    static func loadThumbnail(localIdentifier: String) -> UIImage? {
        ThumbnailStore().loadThumbnail(localIdentifier: localIdentifier)
    }

    private static func fileName(for localIdentifier: String) -> String {
        let safe = localIdentifier.replacingOccurrences(of: "/", with: "_")
        return "\(safe).jpg"
    }
}
