//
//  PhotoLibraryStore.swift
//  SwiftPhotoBoardExample
//
//  Created by Ryouichi Matsuda on 2026/06/09.
//

import Photos
import UIKit

/// @mockable
protocol PhotoService {
    func saveImageToPhotoLibrary(_ image: UIImage) async -> String?
    func loadAssetImage(
        for localIdentifier: String,
        targetSize: CGSize
    ) async -> UIImage?
}

struct PhotoServiceImpl: PhotoService {
    func saveImageToPhotoLibrary(_ image: UIImage) async -> String? {
        guard await ensureAuthorization() else { return nil }

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

    func loadAssetImage(
        for localIdentifier: String,
        targetSize: CGSize
    ) async -> UIImage? {
        guard await ensureAuthorization() else { return nil }

        let asset = PHAsset.fetchAssets(
            withLocalIdentifiers: [localIdentifier],
            options: nil
        ).firstObject
        guard let asset else { return nil }

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

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

    private func ensureAuthorization() async -> Bool {
        var status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .notDetermined {
            status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        }
        return status == .authorized || status == .limited
    }
}
