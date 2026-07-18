//
//  BudgetModels.swift
//  Myreizou
//
//  Created by Codex on 2026/07/18.
//

import Foundation
import SwiftData

@Model
final class BudgetSettings {
    @Attribute(.unique) var id: UUID
    var amount: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        amount: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.amount = amount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class BudgetItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var price: Int
    var quantity: String
    var category: String
    var memo: String
    var expirationDate: Date?
    var isPurchased: Bool
    var purchasedAt: Date?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        price: Int,
        quantity: String = "",
        category: String = "",
        memo: String = "",
        expirationDate: Date? = nil,
        isPurchased: Bool = false,
        purchasedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.quantity = quantity
        self.category = category
        self.memo = memo
        self.expirationDate = expirationDate
        self.isPurchased = isPurchased
        self.purchasedAt = purchasedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
