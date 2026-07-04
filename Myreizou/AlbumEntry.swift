//
//  AlbumEntry.swift
//  Myreizou
//
//  Created by はると on 2026/07/04.
//

import Foundation
import SwiftData

@Model
final class AlbumEntry {
    @Attribute(.unique) var id: UUID
    var title: String
    var memo: String
    @Attribute(.externalStorage) var imageData: Data
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        memo: String = "",
        imageData: Data,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.memo = memo
        self.imageData = imageData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
