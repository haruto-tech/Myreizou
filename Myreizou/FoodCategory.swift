//
//  FoodCategory.swift
//  Myreizou
//
//  Created by はると on 2026/07/04.
//

import Foundation
import SwiftData

@Model
final class FoodCategory {
    @Attribute(.unique) var name: String
    var defaultShelfLifeDays: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        name: String,
        defaultShelfLifeDays: Int,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.name = name
        self.defaultShelfLifeDays = defaultShelfLifeDays
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    static let defaultCategories: [(name: String, defaultShelfLifeDays: Int)] = [
        ("肉", 3),
        ("加工肉", 7),
        ("魚", 2),
        ("野菜", 7),
        ("葉物野菜", 3),
        ("根菜", 14),
        ("きのこ", 5),
        ("果物", 5),
        ("乳製品", 7),
        ("卵", 14),
        ("豆腐・大豆製品", 3),
        ("ごはん", 2),
        ("パン", 4),
        ("麺", 5),
        ("惣菜", 2),
        ("冷凍食品", 30),
        ("飲み物", 7),
        ("調味料", 90),
        ("その他", 7)
    ]
}
