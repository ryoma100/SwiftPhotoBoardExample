//
//  ModelContext.swift
//  SwiftPhotoBoardExample
//
//  Created by Ryouichi Matsuda on 2026/07/13.
//

import Foundation
import SwiftData

extension ModelContext {

    func countItems(imageFileId: UUID) throws -> Int {
        return try fetchCount(
            FetchDescriptor<Item>(
                predicate: #Predicate { $0.imageFileId == imageFileId }
            )
        )
    }

    func findImageFile(sha256Hash: String) throws -> ImageFile? {
        return try fetch(
            FetchDescriptor<ImageFile>(
                predicate: #Predicate { $0.sha256Hash == sha256Hash }
            )
        ).first
    }

    func deleteImageFile(id: UUID) throws {
        try delete(
            model: ImageFile.self,
            where: #Predicate { $0.id == id }
        )
    }
}
