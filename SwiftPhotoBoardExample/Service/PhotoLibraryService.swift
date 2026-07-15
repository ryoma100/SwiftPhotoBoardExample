//
//  PhotoLibraryService.swift
//  SwiftPhotoBoardExample
//
//  Created by Ryouichi Matsuda on 2026/06/09.
//

import CryptoKit
import Photos
import UIKit

/// @mockable
protocol PhotoLibraryService {
    func saveImageToPhotoLibrary(_ image: UIImage) async -> Data?
    func loadPhotoAsset(localIdentifier: String) async -> (image: UIImage, sha256Hash: Data)?
}

struct PhotoLibraryServiceImpl: PhotoLibraryService {
    func saveImageToPhotoLibrary(_ image: UIImage) async -> Data? {
        guard await ensureAuthorization(), let data = heicData(image: image) else { return nil }

        let localIdentifier: String? = await withCheckedContinuation { continuation in
            var placeholder: String?
            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: data, options: nil)
                placeholder = request.placeholderForCreatedAsset?.localIdentifier
            } completionHandler: { success, _ in
                continuation.resume(returning: success ? placeholder : nil)
            }
        }

        guard let localIdentifier else { return nil }
        return await loadResourceData(localIdentifier: localIdentifier)?.sha256
    }

    func loadPhotoAsset(
        localIdentifier: String
    ) async -> (image: UIImage, sha256Hash: Data)? {
        guard await ensureAuthorization(),
              let result = await loadResourceData(localIdentifier: localIdentifier),
              let image = UIImage(data: result.data)
        else { return nil }
        return (image, result.sha256)
    }

    private func loadResourceData(localIdentifier: String) async -> (data: Data, sha256: Data)? {
        let fetch = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        guard let asset = fetch.firstObject else { return nil }
        let resources = PHAssetResource.assetResources(for: asset)
        guard let resource = resources.first(where: { $0.type == .photo }) ?? resources.first
        else { return nil }

        let box = LoadBox()
        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true

        return await withCheckedContinuation { continuation in
            PHAssetResourceManager.default().requestData(
                for: resource,
                options: options,
                dataReceivedHandler: { chunk in
                    box.hasher.update(data: chunk)
                    box.data.append(chunk)
                },
                completionHandler: { error in
                    guard error == nil else {
                        continuation.resume(returning: nil)
                        return
                    }
                    let digest = Data(box.hasher.finalize())
                    continuation.resume(returning: (box.data, digest))
                }
            )
        }
    }

    private func ensureAuthorization() async -> Bool {
        var status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .notDetermined {
            status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        }
        return status == .authorized || status == .limited
    }

    private func heicData(image: UIImage, compressionQuality: CGFloat = 1.0) -> Data? {
        guard let cgImage = image.cgImage else { return nil }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data, UTType.heic.identifier as CFString, 1, nil
        ) else { return nil }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: compressionQuality,
            kCGImagePropertyOrientation: orientation.rawValue,
        ]
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }
}

private final class LoadBox: @unchecked Sendable {
    var hasher = SHA256()
    var data = Data()
}

private extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
