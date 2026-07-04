//
//  ContentView.swift
//  Myreizou
//
//  Created by はると on 2026/06/06.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FoodCategory.name) private var categories: [FoodCategory]
    
    var body: some View {
        TabView{
            Tab("ホーム",systemImage: "house"){
                home1()
            }
            Tab("食材リスト",systemImage: "refrigerator"){
                foodlist()
            }
            Tab("食材検索",systemImage: "magnifyingglass"){
                foodsearch()
            }
            Tab("アルバム",systemImage: "photo.on.rectangle"){
                album()
            }
        }
        .task {
            seedDefaultCategories()
        }
    }

    private func seedDefaultCategories() {
        let existingNames = Set(categories.map(\.name))
        var insertedCategory = false

        for defaultCategory in FoodCategory.defaultCategories where !existingNames.contains(defaultCategory.name) {
            modelContext.insert(
                FoodCategory(
                    name: defaultCategory.name,
                    defaultShelfLifeDays: defaultCategory.defaultShelfLifeDays
                )
            )
            insertedCategory = true
        }

        if insertedCategory {
            try? modelContext.save()
        }
    }
}
#Preview {
    ContentView()
        .modelContainer(
            for: [FoodItem.self, FoodCategory.self, AlbumEntry.self, AlbumFolder.self, AlbumPhoto.self],
            inMemory: true
        )
}
