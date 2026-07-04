//
//  foodsearch.swift
//  Myreizou
//
//  Created by はると on 2026/07/04.
//

import SwiftUI
import SwiftData

struct FoodSearchView: View {
    @Query(sort: \FoodItem.name) private var foods: [FoodItem]

    @State private var searchText = ""
    @State private var editingFood: FoodItem?

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var searchResults: [FoodItem] {
        guard !trimmedSearchText.isEmpty else {
            return []
        }

        return foods
            .filter { food in
                food.matchesSearchText(trimmedSearchText)
            }
            .sorted { first, second in
                first.name.compare(
                    second.name,
                    options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
                    locale: Locale(identifier: "ja_JP")
                ) == .orderedAscending
            }
    }

    var body: some View {
        NavigationStack {
            List {
                if foods.isEmpty {
                    ContentUnavailableView(
                        "食材がありません",
                        systemImage: "refrigerator",
                        description: Text("食材リストから食材を追加してください。")
                    )
                } else if trimmedSearchText.isEmpty {
                    ContentUnavailableView(
                        "食材を検索",
                        systemImage: "magnifyingglass",
                        description: Text("食材名・カテゴリ・メモ・個数で検索できます。")
                    )
                } else if searchResults.isEmpty {
                    ContentUnavailableView(
                        "見つかりません",
                        systemImage: "magnifyingglass",
                        description: Text("検索ワードを変えてもう一度探してください。")
                    )
                } else {
                    ForEach(searchResults) { food in
                        Button {
                            editingFood = food
                        } label: {
                            SearchFoodRow(food: food)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("食材検索")
            .searchable(text: $searchText, prompt: "食材名・カテゴリ・メモ")
            .sheet(item: $editingFood) { food in
                AddFoodView(food: food)
            }
        }
    }
}

private struct SearchFoodRow: View {
    let food: FoodItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: food.isFavorite ? "star.fill" : "star")
                    .foregroundStyle(food.isFavorite ? .yellow : .secondary)
                    .frame(width: 22)

                Text(food.name)
                    .font(.headline)

                Spacer()

                Text("\(food.count)個")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                if !food.category.isEmpty {
                    Label(food.category, systemImage: "tag")
                }

                Label(purchaseDateText, systemImage: "cart")

                if let expirationDate = food.expirationDate {
                    Label(expirationDateText(for: expirationDate), systemImage: "calendar")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if !food.memo.isEmpty {
                Text(food.memo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }

    private var purchaseDateText: String {
        let purchaseDate = food.purchaseDate ?? food.createdAt
        return "購入 \(purchaseDate.formatted(date: .abbreviated, time: .omitted))"
    }

    private func expirationDateText(for date: Date) -> String {
        let days = daysUntil(date)

        if days < 0 {
            return "期限切れ"
        }

        if days == 0 {
            return "今日まで"
        }

        return "あと\(days)日"
    }

    private func daysUntil(_ date: Date) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let targetDate = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: today, to: targetDate).day ?? 0
    }
}

typealias foodsearch = FoodSearchView

#Preview {
    FoodSearchView()
        .modelContainer(
            for: [FoodItem.self, FoodCategory.self, AlbumEntry.self, AlbumFolder.self, AlbumPhoto.self],
            inMemory: true
        )
}
