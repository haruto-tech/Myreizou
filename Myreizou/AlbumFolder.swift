//
//  AlbumFolder.swift
//  Myreizou
//
//  Created by はると on 2026/07/04.
//

import Foundation
import SwiftData

@Model
final class AlbumFolder {
    @Attribute(.unique) var id: UUID
    var name: String
    var memo: String
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \AlbumPhoto.folder) var photos: [AlbumPhoto]

    init(
        id: UUID = UUID(),
        name: String,
        memo: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        photos: [AlbumPhoto] = []
    ) {
        self.id = id
        self.name = name
        self.memo = memo
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.photos = photos
    }
}

@Model
final class AlbumPhoto {
    @Attribute(.unique) var id: UUID
    @Attribute(.externalStorage) var imageData: Data
    var memo: String
    var createdAt: Date
    var updatedAt: Date
    var folder: AlbumFolder?

    init(
        id: UUID = UUID(),
        imageData: Data,
        memo: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        folder: AlbumFolder? = nil
    ) {
        self.id = id
        self.imageData = imageData
        self.memo = memo
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.folder = folder
    }
}
