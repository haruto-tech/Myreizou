//
//  foodlist.swift
//  Myreizou
//
//  Created by はると on 2026/06/06.
//

import SwiftUI
import SwiftData

struct FoodListView: View {
    var body: some View {
        NavigationStack {
            FoodListContentView()
        }
    }
}

struct FoodListContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FoodItem.createdAt, order: .reverse) private var foods: [FoodItem]

    @State private var isShowingAddFood = false
    @State private var editingFood: FoodItem?
    @State private var sortOption: FoodSortOption = .createdAt
    @State private var searchText = ""
    @State private var errorMessage: String?

    var body: some View {
        List {
            if foods.isEmpty {
                ContentUnavailableView(
                    "食材がありません",
                    systemImage: "refrigerator",
                    description: Text("右上の＋から冷蔵庫内の食材を追加できます。")
                )
            } else if filteredFoods.isEmpty {
                ContentUnavailableView(
                    "見つかりません",
                    systemImage: "magnifyingglass",
                    description: Text("検索ワードを変えてもう一度探してください。")
                )
            } else if sortOption == .category {
                ForEach(categorySections, id: \.title) { section in
                    Section(header: Text(section.title)) {
                        ForEach(section.foods) { food in
                            FoodRow(food: food) {
                                editingFood = food
                            }
                        }
                        .onDelete { offsets in
                            deleteFoods(from: section.foods, at: offsets)
                        }
                    }
                }
            } else {
                ForEach(sortedFoods) { food in
                    FoodRow(food: food) {
                        editingFood = food
                    }
                }
                .onDelete { offsets in
                    deleteFoods(from: sortedFoods, at: offsets)
                }
            }
        }
        .navigationTitle("食材リスト")
        .searchable(text: $searchText, prompt: "食材名・カテゴリ・メモ")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if !foods.isEmpty {
                    EditButton()
                }
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                if !foods.isEmpty {
                    Menu {
                        Picker("並び替え", selection: $sortOption) {
                            ForEach(FoodSortOption.allCases) { option in
                                Label(option.title, systemImage: option.systemImage)
                                    .tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                    .accessibilityLabel("並び替え")
                }

                Button {
                    isShowingAddFood = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("食材を追加")
            }
        }
        .sheet(isPresented: $isShowingAddFood) {
            AddFoodView()
        }
        .sheet(item: $editingFood) { food in
            AddFoodView(food: food)
        }
        .alert("保存できませんでした", isPresented: errorBinding) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    private var sortedFoods: [FoodItem] {
        filteredFoods.sorted { first, second in
            switch sortOption {
            case .createdAt:
                return first.createdAt > second.createdAt
            case .count:
                if first.count != second.count {
                    return first.count > second.count
                }

                return isOrderedByName(first, before: second)
            case .name:
                return isOrderedByName(first, before: second)
            case .favorite:
                if first.isFavorite != second.isFavorite {
                    return first.isFavorite && !second.isFavorite
                }

                return isOrderedByName(first, before: second)
            case .expirationDate:
                return isOrderedByExpirationDate(first, before: second)
            case .category:
                let firstCategory = categoryTitle(for: first)
                let secondCategory = categoryTitle(for: second)

                if firstCategory != secondCategory {
                    return isOrdered(firstCategory, before: secondCategory)
                }

                return isOrderedByName(first, before: second)
            }
        }
    }

    private var categorySections: [(title: String, foods: [FoodItem])] {
        let groupedFoods = Dictionary(grouping: filteredFoods) { food in
            categoryTitle(for: food)
        }

        return groupedFoods.keys
            .sorted { first, second in
                isOrdered(first, before: second)
            }
            .map { title in
                let sectionFoods = (groupedFoods[title] ?? [])
                    .sorted { first, second in
                        if first.isFavorite != second.isFavorite {
                            return first.isFavorite && !second.isFavorite
                        }

                        return isOrderedByName(first, before: second)
                    }

                return (title: title, foods: sectionFoods)
            }
    }

    private var filteredFoods: [FoodItem] {
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedSearchText.isEmpty else {
            return foods
        }

        return foods.filter { food in
            food.matchesSearchText(trimmedSearchText)
        }
    }

    private func deleteFoods(from displayedFoods: [FoodItem], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(displayedFoods[index])
        }

        do {
            try modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func categoryTitle(for food: FoodItem) -> String {
        let trimmedCategory = food.category.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedCategory.isEmpty ? "未分類" : trimmedCategory
    }

    private func isOrderedByName(_ first: FoodItem, before second: FoodItem) -> Bool {
        let result = first.name.compare(
            second.name,
            options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
            locale: Locale(identifier: "ja_JP")
        )

        if result != .orderedSame {
            return result == .orderedAscending
        }

        return first.createdAt > second.createdAt
    }

    private func isOrderedByExpirationDate(_ first: FoodItem, before second: FoodItem) -> Bool {
        switch (first.expirationDate, second.expirationDate) {
        case let (firstDate?, secondDate?):
            if firstDate != secondDate {
                return firstDate < secondDate
            }

            return isOrderedByName(first, before: second)
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            return isOrderedByName(first, before: second)
        }
    }

    private func isOrdered(_ first: String, before second: String) -> Bool {
        first.compare(
            second,
            options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
            locale: Locale(identifier: "ja_JP")
        ) == .orderedAscending
    }
}

private enum FoodSortOption: String, CaseIterable, Identifiable {
    case createdAt
    case count
    case name
    case favorite
    case expirationDate
    case category

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .createdAt:
            return "追加順"
        case .count:
            return "個数が多い順"
        case .name:
            return "50音順"
        case .favorite:
            return "お気に入り順"
        case .expirationDate:
            return "賞味期限順"
        case .category:
            return "カテゴリごと"
        }
    }

    var systemImage: String {
        switch self {
        case .createdAt:
            return "clock"
        case .count:
            return "number"
        case .name:
            return "textformat.abc"
        case .favorite:
            return "star"
        case .expirationDate:
            return "calendar"
        case .category:
            return "tag"
        }
    }
}

private struct FoodRow: View {
    @Environment(\.modelContext) private var modelContext

    let food: FoodItem
    let edit: () -> Void

    @State private var errorMessage: String?

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                toggleFavorite()
            } label: {
                Image(systemName: food.isFavorite ? "star.fill" : "star")
                    .font(.title3)
                    .foregroundStyle(food.isFavorite ? .yellow : .secondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(food.isFavorite ? "お気に入りを解除" : "お気に入りに追加")

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(food.name)
                        .font(.headline)

                    Spacer()

                    if let expirationDate = food.expirationDate {
                        Label(expirationDateText(for: expirationDate), systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(expirationColor(for: expirationDate))
                    }
                }

                HStack(spacing: 10) {
                    Label(purchaseDateText, systemImage: "cart")

                    if !food.quantity.isEmpty {
                        Label(food.quantity, systemImage: "scalemass")
                    }

                    if !food.category.isEmpty {
                        Label(food.category, systemImage: "tag")
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
            .contentShape(Rectangle())
            .onTapGesture(perform: edit)

            CountControl(
                count: food.count,
                canDecrease: food.count > 0,
                decrease: { updateCount(by: -1) },
                increase: { updateCount(by: 1) }
            )
        }
        .padding(.vertical, 4)
        .alert("更新できませんでした", isPresented: errorBinding) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    private var purchaseDateText: String {
        let purchaseDate = food.purchaseDate ?? food.createdAt
        return "購入 \(purchaseDate.formatted(date: .abbreviated, time: .omitted))"
    }

    private func toggleFavorite() {
        let previousValue = food.isFavorite
        food.isFavorite.toggle()
        food.updatedAt = Date()

        do {
            try modelContext.save()
        } catch {
            food.isFavorite = previousValue
            errorMessage = error.localizedDescription
        }
    }

    private func updateCount(by amount: Int) {
        let previousCount = food.count
        let nextCount = max(0, food.count + amount)

        guard nextCount != food.count else {
            return
        }

        food.count = nextCount
        food.updatedAt = Date()

        do {
            try modelContext.save()
        } catch {
            food.count = previousCount
            errorMessage = error.localizedDescription
        }
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

    private func expirationColor(for date: Date) -> Color {
        let days = daysUntil(date)

        if days < 0 {
            return .red
        }

        if days <= 3 {
            return .orange
        }

        return .secondary
    }

    private func daysUntil(_ date: Date) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let targetDate = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: today, to: targetDate).day ?? 0
    }
}

private struct CountControl: View {
    let count: Int
    let canDecrease: Bool
    let decrease: () -> Void
    let increase: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: decrease) {
                Image(systemName: "minus.circle.fill")
                    .font(.title3)
            }
            .disabled(!canDecrease)
            .accessibilityLabel("数を減らす")

            Text("\(count)")
                .font(.headline.monospacedDigit())
                .frame(minWidth: 24)

            Button(action: increase) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
            }
            .accessibilityLabel("数を増やす")
        }
        .buttonStyle(.borderless)
    }
}

struct AddFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FoodCategory.name) private var categories: [FoodCategory]

    private let editingFood: FoodItem?
    private let purchaseDate: Date

    @State private var name: String
    @State private var countText: String
    @State private var isFavorite: Bool
    @State private var quantity: String
    @State private var category: String
    @State private var memo: String
    @State private var hasExpirationDate: Bool
    @State private var expirationDate: Date
    @State private var isShowingAddCategory = false
    @State private var errorMessage: String?

    init(food: FoodItem? = nil) {
        self.editingFood = food
        self.purchaseDate = food?.purchaseDate ?? food?.createdAt ?? Date()
        _name = State(initialValue: food?.name ?? "")
        _countText = State(initialValue: String(food?.count ?? 1))
        _isFavorite = State(initialValue: food?.isFavorite ?? false)
        _quantity = State(initialValue: food?.quantity ?? "")
        _category = State(initialValue: food?.category ?? "")
        _memo = State(initialValue: food?.memo ?? "")
        _hasExpirationDate = State(initialValue: food?.expirationDate != nil)
        _expirationDate = State(initialValue: food?.expirationDate ?? Date())
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var countValue: Int? {
        let trimmedCount = countText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Int(trimmedCount), value >= 0 else {
            return nil
        }

        return value
    }

    private var canSave: Bool {
        !trimmedName.isEmpty && countValue != nil
    }

    private var selectedCategory: FoodCategory? {
        categories.first { foodCategory in
            foodCategory.name == category
        }
    }

    private var categoryNames: [String] {
        let names = categories.map(\.name)

        if !category.isEmpty && !names.contains(category) {
            return names + [category]
        }

        return names
    }

    private var automaticExpirationDate: Date? {
        guard let selectedCategory else {
            return nil
        }

        let today = Calendar.current.startOfDay(for: Date())
        return Calendar.current.date(
            byAdding: .day,
            value: selectedCategory.defaultShelfLifeDays,
            to: today
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("食材名", text: $name)
                    TextField("個数", text: $countText)
                        .keyboardType(.numberPad)
                    TextField("量のメモ 例: 300g / 1パック", text: $quantity)
                    Toggle(isOn: $isFavorite) {
                        Label("お気に入り", systemImage: isFavorite ? "star.fill" : "star")
                    }
                }

                Section("カテゴリ") {
                    Picker("カテゴリ", selection: $category) {
                        Text("未分類").tag("")

                        ForEach(categoryNames, id: \.self) { categoryName in
                            Text(categoryName).tag(categoryName)
                        }
                    }

                    if let selectedCategory {
                        Text("平均賞味期限: \(selectedCategory.defaultShelfLifeDays)日")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        isShowingAddCategory = true
                    } label: {
                        Label("カテゴリを追加", systemImage: "plus")
                    }
                }

                Section("購入日") {
                    Label(
                        purchaseDate.formatted(date: .abbreviated, time: .omitted),
                        systemImage: "cart"
                    )
                    .foregroundStyle(.secondary)
                }

                Section("期限") {
                    Toggle("賞味期限を手入力", isOn: $hasExpirationDate)

                    if hasExpirationDate {
                        DatePicker(
                            "賞味期限",
                            selection: $expirationDate,
                            displayedComponents: .date
                        )
                    } else if let automaticExpirationDate {
                        Label(
                            "\(category)の平均賞味期限で \(automaticExpirationDate.formatted(date: .abbreviated, time: .omitted)) に設定",
                            systemImage: "sparkles"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    } else {
                        Text("カテゴリに平均賞味期限があると自動設定されます。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("メモ") {
                    TextField("保存場所や状態など", text: $memo, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle(editingFood == nil ? "食材を追加" : "食材を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(editingFood == nil ? "追加" : "保存") {
                        saveFood()
                    }
                    .disabled(!canSave)
                }
            }
            .alert("保存できませんでした", isPresented: errorBinding) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(isPresented: $isShowingAddCategory) {
                AddCategoryView { newCategoryName in
                    category = newCategoryName
                }
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    private func saveFood() {
        guard let countValue else {
            errorMessage = "個数は0以上の数字で入力してください。"
            return
        }

        let now = Date()
        let trimmedQuantity = quantity.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMemo = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalExpirationDate = hasExpirationDate ? expirationDate : automaticExpirationDate

        if let editingFood {
            editingFood.name = trimmedName
            editingFood.count = countValue
            editingFood.isFavorite = isFavorite
            editingFood.quantity = trimmedQuantity
            editingFood.category = trimmedCategory
            editingFood.memo = trimmedMemo
            editingFood.purchaseDate = purchaseDate
            editingFood.expirationDate = finalExpirationDate
            editingFood.updatedAt = now
        } else {
            let food = FoodItem(
                name: trimmedName,
                count: countValue,
                isFavorite: isFavorite,
                quantity: trimmedQuantity,
                category: trimmedCategory,
                memo: trimmedMemo,
                purchaseDate: purchaseDate,
                expirationDate: finalExpirationDate,
                createdAt: now,
                updatedAt: now
            )

            modelContext.insert(food)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct AddCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FoodCategory.name) private var categories: [FoodCategory]

    let onSave: (String) -> Void

    @State private var name = ""
    @State private var shelfLifeDaysText = ""
    @State private var errorMessage: String?

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var shelfLifeDays: Int? {
        let trimmedDays = shelfLifeDaysText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let days = Int(trimmedDays), days >= 0 else {
            return nil
        }

        return days
    }

    private var canSave: Bool {
        !trimmedName.isEmpty && shelfLifeDays != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("カテゴリ") {
                    TextField("カテゴリ名 例: パン", text: $name)
                    TextField("平均賞味期限（日）", text: $shelfLifeDaysText)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("カテゴリを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        addCategory()
                    }
                    .disabled(!canSave)
                }
            }
            .alert("カテゴリを追加できませんでした", isPresented: errorBinding) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    private func addCategory() {
        guard let shelfLifeDays else {
            errorMessage = "平均賞味期限は0以上の数字で入力してください。"
            return
        }

        guard !hasDuplicateCategory(named: trimmedName) else {
            errorMessage = "同じ名前のカテゴリがすでにあります。"
            return
        }

        let category = FoodCategory(
            name: trimmedName,
            defaultShelfLifeDays: shelfLifeDays
        )

        modelContext.insert(category)

        do {
            try modelContext.save()
            onSave(trimmedName)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func hasDuplicateCategory(named name: String) -> Bool {
        categories.contains { category in
            category.name.compare(
                name,
                options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
                locale: Locale(identifier: "ja_JP")
            ) == .orderedSame
        }
    }
}

typealias foodlist = FoodListView

#Preview {
    FoodListView()
        .modelContainer(
            for: [FoodItem.self, FoodCategory.self, AlbumEntry.self, AlbumFolder.self, AlbumPhoto.self],
            inMemory: true
        )
}
