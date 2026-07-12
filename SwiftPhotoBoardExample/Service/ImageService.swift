//
//  ImageService.swift
//  SwiftPhotoBoardExample
//
//  Created by Ryouichi Matsuda on 2026/07/11.
//

import Photos
import UIKit

/// @mockable
protocol ImageService {
    func loadImage(fileId: UUID) -> UIImage?
    func loadThumbnail(fileId: UUID) -> UIImage?
    func saveImage(fileId: UUID, image: UIImage)
}

let imageDirectory: URL = {
    return FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask
    )[0]
    .appendingPathComponent("Images")
}()

let thumbnailDirectory: URL = {
    return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[
        0
    ]
    .appendingPathComponent("Thumbnails")
}()

struct ImageServiceImpl: ImageService {
    func loadImage(fileId: UUID) -> UIImage? {
        let fileURL =
            imageDirectory
            .appending(path: fileId.uuidString, directoryHint: .notDirectory)
            .appendingPathExtension("heic")
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    func loadThumbnail(fileId: UUID) -> UIImage? {
        let fileURL =
            thumbnailDirectory
            .appending(path: fileId.uuidString, directoryHint: .notDirectory)
            .appendingPathExtension("heic")
        if let data = try? Data(contentsOf: fileURL),
            let image = UIImage(data: data)
        {
            return image
        }
        guard let original = loadImage(fileId: fileId) else { return nil }
        let thumbnail = resized(image: original, longSide: 300)
        if !FileManager.default.fileExists(atPath: thumbnailDirectory.path) {
            try? FileManager.default.createDirectory(
                at: thumbnailDirectory,
                withIntermediateDirectories: true
            )
        }
        if let data = heicData(image: thumbnail, compressionQuality: 0.65) {
            try? data.write(to: fileURL)
        }
        return thumbnail
    }

    func saveImage(fileId: UUID, image: UIImage) {
        if !FileManager.default.fileExists(atPath: imageDirectory.path) {
            try? FileManager.default.createDirectory(
                at: imageDirectory,
                withIntermediateDirectories: true
            )
        }
        let fileURL =
            imageDirectory
            .appending(path: fileId.uuidString, directoryHint: .notDirectory)
            .appendingPathExtension("heic")
        let resized = resized(image: image, longSide: 1440)
        guard let data = heicData(image: resized, compressionQuality: 0.8)
        else { return }
        try? data.write(to: fileURL)
    }

    private func resized(image: UIImage, longSide: CGFloat) -> UIImage {
        let maxSide = max(image.size.width, image.size.height)
        guard maxSide > longSide else { return image }
        let scale = longSide / maxSide
        let newSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private func heicData(image: UIImage, compressionQuality: CGFloat = 0.8)
        -> Data?
    {
        guard let cgImage = image.cgImage else { return nil }
        let data = NSMutableData()
        guard
            let destination = CGImageDestinationCreateWithData(
                data,
                UTType.heic.identifier as CFString,
                1,
                nil
            )
        else { return nil }
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: compressionQuality
        ]
        CGImageDestinationAddImage(
            destination,
            cgImage,
            options as CFDictionary
        )
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }
}
