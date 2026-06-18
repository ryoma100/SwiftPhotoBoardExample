//
//  Item.swift
//  SwiftPhotoBoardExample
//
//  Created by Ryouichi Matsuda on 2026/06/09.
//

import Foundation
import SwiftData

@Model
final class Item {
    #Unique<Item>([\.id])
    #Index<Item>([\.timestamp])

    private(set) var id: UUID
    var timestamp: Date
    var note: String
    var localIdentifier: String?
    var thumbnailFileID: UUID?

    init(
        timestamp: Date,
        note: String = "",
        localIdentifier: String? = nil,
        thumbnailFileID: UUID? = nil
    ) {
        self.id = UUID()
        self.timestamp = timestamp
        self.note = note
        self.localIdentifier = localIdentifier
        self.thumbnailFileID = thumbnailFileID
    }
}
