//
//  ModelSchemaV1.swift
//  SwiftPhotoBoardExample
//
//  Created by Ryouichi Matsuda on 2026/06/09.
//

import Foundation
import SwiftData

enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [Item.self, ImageFile.self]
    }

    @Model
    final class Item {
        #Unique<Item>([\.id])
        #Index<Item>([\.timestamp])

        private(set) var id: UUID
        var title: String
        var timestamp: Date
        var note: String
        var imageFileId: UUID?

        init(
            title: String = "",
            timestamp: Date,
            note: String = "",
            imageFileId: UUID?
        ) {
            self.id = UUID()
            self.title = title
            self.timestamp = timestamp
            self.note = note
            self.imageFileId = imageFileId
        }
    }

    @Model
    final class ImageFile {
        #Unique<ImageFile>([\.id])
        #Index<ImageFile>([\.sha256Hash])

        /// id for Documents/Images/{id}.heic, Cache/Thumbnails/{id}.heic
        private(set) var id: UUID

        /// Hash of original photo file
        var sha256Hash: String?

        init(sha256Hash: String?) {
            self.id = UUID()
            self.sha256Hash = sha256Hash
        }
    }
}
