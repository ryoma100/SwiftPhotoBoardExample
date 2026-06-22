//
//  VersionedSchema.swift
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
        [Item.self]
    }

    @Model
    final class Item {
        #Unique<Item>([\.id])
        #Index<Item>([\.timestamp])

        private(set) var id: UUID
        var title: String
        var timestamp: Date
        var note: String
        var localIdentifier: String?

        init(
            title: String = "",
            timestamp: Date,
            note: String = "",
            localIdentifier: String? = nil
        ) {
            self.id = UUID()
            self.title = title
            self.timestamp = timestamp
            self.note = note
            self.localIdentifier = localIdentifier
        }
    }
}

typealias Item = SchemaV1.Item
