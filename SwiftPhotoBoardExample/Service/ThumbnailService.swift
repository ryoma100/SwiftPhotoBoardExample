//
//  ThumbnailStore.swift
//  SwiftPhotoBoardExample
//
//  Created by Ryouichi Matsuda on 2026/06/09.
//

import UIKit

/// @mockable
protocol ThumbnailService {
    func deleteThumbnail(localIdentifier: String)
    func loadThumbnail(localIdentifier: String) -> UIImage?
}

struct ThumbnailServiceImpl: ThumbnailService {
    static var directory: URL {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return base.appendingPathComponent("Thumbnails", isDirectory: true)
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

    private static func fileName(for localIdentifier: String) -> String {
        let safe = localIdentifier.replacingOccurrences(of: "/", with: "_")
        return "\(safe).jpg"
    }
}
