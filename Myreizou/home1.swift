//
//  home.swift
//  Myreizou
//
//  Created by はると on 2026/06/20.
//

import SwiftUI
import SwiftData

struct home1: View {
    @Query(sort: \FoodItem.createdAt, order: .reverse) private var foods: [FoodItem]

    @State private var isShowingAddFood = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    statusPanel
                    shortcutSection
                    expiringFoodSection
                    recipeSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("ホーム")
            .sheet(isPresented: $isShowingAddFood) {
                AddFoodView()
            }
        }
    }

    private var statusPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("冷蔵庫")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline) {
                Text("\(totalFoodCount)")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(.primary)

                Text("個の食材")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Spacer()

                Image(systemName: "refrigerator.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.teal)
            }

            Text(statusMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var shortcutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("基本機能")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                Button {
                    isShowingAddFood = true
                } label: {
                    HomeShortcutCard(
                        title: "食材を追加",
                        systemImage: "plus.circle.fill",
                        tint: .green
                    )
                }

                NavigationLink {
                    FoodListContentView()
                } label: {
                    HomeShortcutCard(
                        title: "食材リスト",
                        systemImage: "list.bullet.rectangle.fill",
                        tint: .blue
                    )
                }

                NavigationLink {
                    AlbumContentView()
                } label: {
                    HomeShortcutCard(
                        title: "アルバム",
                        systemImage: "photo.on.rectangle.fill",
                        tint: .orange
                    )
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var expiringFoodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("賞味期限が近い食材")
                    .font(.headline)

                Spacer()

                if !expiringFoods.isEmpty {
                    Text("\(expiringFoods.count)件")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if expiringFoods.isEmpty {
                EmptyHomeSection(
                    systemImage: "checkmark.circle",
                    title: "期限が近い食材はありません"
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(expiringFoods.prefix(5))) { food in
                        ExpiringFoodRow(food: food)
                    }
                }
            }
        }
    }

    private var recipeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("おすすめレシピ")
                .font(.headline)

            if recipeSuggestions.isEmpty {
                EmptyHomeSection(
                    systemImage: "fork.knife.circle",
                    title: "食材を追加すると表示されます"
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(recipeSuggestions) { recipe in
                        RecipeSuggestionRow(recipe: recipe)
                    }
                }
            }
        }
    }

    private var statusMessage: String {
        if foods.isEmpty {
            return "まずは食材を追加しましょう。"
        }

        if expiringFoods.isEmpty {
            return "期限が近い食材はありません。"
        }

        return "期限が近い食材があります。優先して使いましょう。"
    }

    private var totalFoodCount: Int {
        foods.reduce(0) { total, food in
            total + max(food.count, 0)
        }
    }

    private var expiringFoods: [FoodItem] {
        foods
            .filter { food in
                guard let expirationDate = food.expirationDate else {
                    return false
                }

                return daysUntil(expirationDate) <= 3
            }
            .sorted { first, second in
                guard let firstDate = first.expirationDate else {
                    return false
                }

                guard let secondDate = second.expirationDate else {
                    return true
                }

                return firstDate < secondDate
            }
    }

    private var recipeSuggestions: [RecipeSuggestion] {
        RecipeSuggestion.recommendations(for: foods, priorityFoods: expiringFoods)
    }

    private func daysUntil(_ date: Date) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let targetDate = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: today, to: targetDate).day ?? 0
    }
}

private struct HomeShortcutCard: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(tint)

            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .frame(minHeight: 104)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct EmptyHomeSection: View {
    let systemImage: String
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct ExpiringFoodRow: View {
    let food: FoodItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.title3)
                .foregroundStyle(expirationColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(food.name)
                    .font(.subheadline.weight(.semibold))

                if let expirationDate = food.expirationDate {
                    Text("\(expirationText(for: expirationDate)) / \(food.count)個")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var expirationColor: Color {
        guard let expirationDate = food.expirationDate else {
            return .secondary
        }

        let days = daysUntil(expirationDate)

        if days < 0 {
            return .red
        }

        if days <= 3 {
            return .orange
        }

        return .secondary
    }

    private func expirationText(for date: Date) -> String {
        let days = daysUntil(date)
        let formattedDate = date.formatted(date: .abbreviated, time: .omitted)

        if days < 0 {
            return "\(formattedDate) 期限切れ"
        }

        if days == 0 {
            return "\(formattedDate) 今日まで"
        }

        return "\(formattedDate) あと\(days)日"
    }

    private func daysUntil(_ date: Date) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let targetDate = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: today, to: targetDate).day ?? 0
    }
}

private struct RecipeSuggestionRow: View {
    let recipe: RecipeSuggestion

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: recipe.systemImage)
                    .font(.title3)
                    .foregroundStyle(.orange)
                    .frame(width: 28)

                Text(recipe.title)
                    .font(.subheadline.weight(.semibold))
            }

            Text(recipe.reason)
                .font(.caption)
                .foregroundStyle(.secondary)

            if !recipe.ingredients.isEmpty {
                Text(recipe.ingredients.joined(separator: "・"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct RecipeSuggestion: Identifiable {
    let id: String
    let title: String
    let reason: String
    let ingredients: [String]
    let systemImage: String

    init(title: String, reason: String, ingredients: [String], systemImage: String) {
        self.id = title
        self.title = title
        self.reason = reason
        self.ingredients = ingredients
        self.systemImage = systemImage
    }

    static func recommendations(for foods: [FoodItem], priorityFoods: [FoodItem]) -> [RecipeSuggestion] {
        guard !foods.isEmpty else {
            return []
        }

        var suggestions: [RecipeSuggestion] = []

        if hasAny(["卵", "たまご", "玉子"], in: foods), hasAny(["野菜", "キャベツ", "玉ねぎ", "にんじん", "ほうれん草"], in: foods) {
            suggestions.append(
                RecipeSuggestion(
                    title: "野菜オムレツ",
                    reason: "卵と野菜をまとめて使えます。",
                    ingredients: matchingNames(["卵", "たまご", "玉子", "野菜", "キャベツ", "玉ねぎ", "にんじん", "ほうれん草"], in: foods),
                    systemImage: "frying.pan"
                )
            )
        }

        if hasAny(["米", "ごはん", "ライス"], in: foods), hasAny(["卵", "たまご", "玉子"], in: foods) {
            suggestions.append(
                RecipeSuggestion(
                    title: "卵チャーハン",
                    reason: "ごはんと卵で作りやすい定番です。",
                    ingredients: matchingNames(["米", "ごはん", "ライス", "卵", "たまご", "玉子"], in: foods),
                    systemImage: "takeoutbag.and.cup.and.straw"
                )
            )
        }

        if hasAny(["肉", "鶏", "豚", "牛"], in: foods), hasAny(["野菜", "キャベツ", "玉ねぎ", "にんじん", "ピーマン"], in: foods) {
            suggestions.append(
                RecipeSuggestion(
                    title: "肉野菜炒め",
                    reason: "肉と野菜を一緒に消費できます。",
                    ingredients: matchingNames(["肉", "鶏", "豚", "牛", "野菜", "キャベツ", "玉ねぎ", "にんじん", "ピーマン"], in: foods),
                    systemImage: "flame"
                )
            )
        }

        if hasAny(["牛乳", "ミルク", "チーズ"], in: foods), hasAny(["野菜", "じゃがいも", "玉ねぎ", "にんじん"], in: foods) {
            suggestions.append(
                RecipeSuggestion(
                    title: "クリームスープ",
                    reason: "乳製品と野菜を使いやすいメニューです。",
                    ingredients: matchingNames(["牛乳", "ミルク", "チーズ", "野菜", "じゃがいも", "玉ねぎ", "にんじん"], in: foods),
                    systemImage: "cup.and.saucer.fill"
                )
            )
        }

        if let prioritySuggestion = prioritySuggestion(from: priorityFoods) {
            suggestions.insert(prioritySuggestion, at: 0)
        }

        if suggestions.isEmpty {
            suggestions.append(
                RecipeSuggestion(
                    title: "冷蔵庫整理炒め",
                    reason: "今ある食材を少しずつ使えます。",
                    ingredients: foods.prefix(3).map(\.name),
                    systemImage: "frying.pan"
                )
            )
        }

        return Array(suggestions.prefix(3))
    }

    private static func prioritySuggestion(from priorityFoods: [FoodItem]) -> RecipeSuggestion? {
        let names = priorityFoods.prefix(3).map(\.name)

        guard !names.isEmpty else {
            return nil
        }

        return RecipeSuggestion(
            title: "期限近い食材のスープ",
            reason: "期限が近い食材から先に使えます。",
            ingredients: names,
            systemImage: "pot.fill"
        )
    }

    private static func hasAny(_ keywords: [String], in foods: [FoodItem]) -> Bool {
        foods.contains { food in
            keywords.contains { keyword in
                matches(food, keyword: keyword)
            }
        }
    }

    private static func matchingNames(_ keywords: [String], in foods: [FoodItem]) -> [String] {
        foods
            .filter { food in
                keywords.contains { keyword in
                    matches(food, keyword: keyword)
                }
            }
            .prefix(3)
            .map(\.name)
    }

    private static func matches(_ food: FoodItem, keyword: String) -> Bool {
        food.name.localizedStandardContains(keyword) || food.category.localizedStandardContains(keyword)
    }
}

#Preview {
    home1()
        .modelContainer(
            for: [FoodItem.self, FoodCategory.self, AlbumEntry.self, AlbumFolder.self, AlbumPhoto.self],
            inMemory: true
        )
}
