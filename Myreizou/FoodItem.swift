//
//  FoodItem.swift
//  Myreizou
//
//  Created by はると on 2026/06/20.
//

import Foundation
import SwiftData

@Model
final class FoodItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var count: Int = 1
    var isFavorite: Bool = false
    var quantity: String
    var category: String
    var memo: String
    var purchaseDate: Date?
    var expirationDate: Date?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        count: Int = 1,
        isFavorite: Bool = false,
        quantity: String = "",
        category: String = "",
        memo: String = "",
        purchaseDate: Date = Date(),
        expirationDate: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.count = count
        self.isFavorite = isFavorite
        self.quantity = quantity
        self.category = category
        self.memo = memo
        self.purchaseDate = purchaseDate
        self.expirationDate = expirationDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension FoodItem {
    func matchesSearchText(_ searchText: String) -> Bool {
        let searchableTexts = [
            name,
            category,
            quantity,
            memo,
            "\(count)"
        ]

        return searchableTexts.contains { text in
            text.localizedStandardContains(searchText)
        }
    }
}
