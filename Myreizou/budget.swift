//
//  budget.swift
//  Myreizou
//
//  Created by Codex on 2026/07/18.
//

import SwiftUI
import SwiftData

struct BudgetView: View {
    var body: some View {
        NavigationStack {
            BudgetContentView()
        }
    }
}

struct BudgetContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BudgetSettings.createdAt) private var settings: [BudgetSettings]
    @Query(sort: \BudgetItem.createdAt, order: .reverse) private var items: [BudgetItem]

    @State private var isShowingBudgetEditor = false
    @State private var isShowingAddItem = false
    @State private var editingItem: BudgetItem?
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                BudgetSummaryView(
                    budgetAmount: budgetAmount,
                    hasBudget: budgetSettings != nil,
                    spentAmount: spentAmount,
                    plannedAmount: plannedAmount,
                    setBudget: { isShowingBudgetEditor = true }
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section("購入予定") {
                if plannedItems.isEmpty {
                    ContentUnavailableView(
                        "購入予定の食材がありません",
                        systemImage: "cart",
                        description: Text("右上の＋から食材と金額を登録できます。")
                    )
                    .frame(maxWidth: .infinity, minHeight: 180)
                } else {
                    ForEach(plannedItems) { item in
                        BudgetItemRow(item: item) {
                            editingItem = item
                        }
                    }
                    .onDelete { offsets in
                        deleteItems(from: plannedItems, at: offsets)
                    }
                }
            }

            if !purchasedItems.isEmpty {
                Section("購入済み") {
                    ForEach(purchasedItems) { item in
                        BudgetItemRow(item: item) {
                            editingItem = item
                        }
                    }
                    .onDelete { offsets in
                        deleteItems(from: purchasedItems, at: offsets)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("予算")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    isShowingBudgetEditor = true
                } label: {
                    Image(systemName: "yensign.circle")
                }
                .accessibilityLabel("予算を設定")
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingAddItem = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("購入予定を追加")
            }
        }
        .sheet(isPresented: $isShowingBudgetEditor) {
            BudgetSettingsFormView(settings: budgetSettings)
        }
        .sheet(isPresented: $isShowingAddItem) {
            BudgetItemFormView()
        }
        .sheet(item: $editingItem) { item in
            BudgetItemFormView(item: item)
        }
        .alert("削除できませんでした", isPresented: errorBinding) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var budgetSettings: BudgetSettings? {
        settings.first
    }

    private var budgetAmount: Int {
        budgetSettings?.amount ?? 0
    }

    private var plannedItems: [BudgetItem] {
        items.filter { !$0.isPurchased }
    }

    private var purchasedItems: [BudgetItem] {
        items
            .filter(\.isPurchased)
            .sorted { first, second in
                (first.purchasedAt ?? first.updatedAt) > (second.purchasedAt ?? second.updatedAt)
            }
    }

    private var spentAmount: Int {
        purchasedItems.reduce(0) { $0 + $1.price }
    }

    private var plannedAmount: Int {
        plannedItems.reduce(0) { $0 + $1.price }
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

    private func deleteItems(from displayedItems: [BudgetItem], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(displayedItems[index])
        }

        do {
            try modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct BudgetSummaryView: View {
    let budgetAmount: Int
    let hasBudget: Bool
    let spentAmount: Int
    let plannedAmount: Int
    let setBudget: () -> Void

    private var remainingAmount: Int {
        budgetAmount - spentAmount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("残り予算")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if hasBudget {
                        Text(yen(remainingAmount))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(remainingAmount < 0 ? .red : .primary)
                    } else {
                        Text("未設定")
                            .font(.title2.weight(.bold))
                    }
                }

                Spacer()

                Button("予算を設定", action: setBudget)
                    .buttonStyle(.bordered)
            }

            HStack(spacing: 0) {
                BudgetSummaryValue(title: "設定予算", value: hasBudget ? yen(budgetAmount) : "-", tint: .primary)
                Divider()
                BudgetSummaryValue(title: "購入済み", value: yen(spentAmount), tint: .orange)
                Divider()
                BudgetSummaryValue(title: "購入予定", value: yen(plannedAmount), tint: .blue)
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

private struct BudgetSummaryValue: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
    }
}

private struct BudgetItemRow: View {
    @Environment(\.modelContext) private var modelContext

    let item: BudgetItem
    let edit: () -> Void

    @State private var errorMessage: String?

    var body: some View {
        HStack(spacing: 12) {
            Button {
                togglePurchased()
            } label: {
                Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(item.isPurchased ? .green : .secondary)
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(item.isPurchased ? "購入済みを取り消す" : "購入済みにする")

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.name)
                        .font(.headline)
                        .strikethrough(item.isPurchased, color: .secondary)

                    Spacer()

                    Text(yen(item.price))
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(item.isPurchased ? .secondary : .primary)
                }

                HStack(spacing: 10) {
                    if !item.quantity.isEmpty {
                        Label(item.quantity, systemImage: "scalemass")
                    }

                    if !item.category.isEmpty {
                        Label(item.category, systemImage: "tag")
                    }

                    if let expirationDate = item.expirationDate {
                        Label(expirationDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if !item.memo.isEmpty {
                    Text(item.memo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: edit)
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

    private func togglePurchased() {
        let previousValue = item.isPurchased
        let previousPurchaseDate = item.purchasedAt

        item.isPurchased.toggle()
        item.purchasedAt = item.isPurchased ? Date() : nil
        item.updatedAt = Date()

        do {
            try modelContext.save()
        } catch {
            item.isPurchased = previousValue
            item.purchasedAt = previousPurchaseDate
            errorMessage = error.localizedDescription
        }
    }
}

private struct BudgetSettingsFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let settings: BudgetSettings?

    @State private var amount: Int
    @State private var errorMessage: String?

    init(settings: BudgetSettings?) {
        self.settings = settings
        _amount = State(initialValue: settings?.amount ?? 0)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("予算") {
                    TextField("予算額", value: $amount, format: .number)
                        .keyboardType(.numberPad)

                    Text("購入済みにした食材の金額が、この予算から差し引かれます。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("予算を設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveSettings()
                    }
                    .disabled(amount < 0)
                }
            }
            .alert("保存できませんでした", isPresented: errorBinding) {
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

    private func saveSettings() {
        let finalAmount = max(0, amount)

        if let settings {
            settings.amount = finalAmount
            settings.updatedAt = Date()
        } else {
            modelContext.insert(BudgetSettings(amount: finalAmount))
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct BudgetItemFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FoodCategory.name) private var categories: [FoodCategory]

    let item: BudgetItem?

    @State private var name: String
    @State private var price: Int
    @State private var quantity: String
    @State private var category: String
    @State private var memo: String
    @State private var hasExpirationDate: Bool
    @State private var expirationDate: Date
    @State private var isPurchased: Bool
    @State private var isShowingDeleteConfirmation = false
    @State private var errorMessage: String?

    init(item: BudgetItem? = nil) {
        self.item = item
        _name = State(initialValue: item?.name ?? "")
        _price = State(initialValue: item?.price ?? 0)
        _quantity = State(initialValue: item?.quantity ?? "")
        _category = State(initialValue: item?.category ?? "")
        _memo = State(initialValue: item?.memo ?? "")
        _hasExpirationDate = State(initialValue: item?.expirationDate != nil)
        _expirationDate = State(initialValue: item?.expirationDate ?? Date())
        _isPurchased = State(initialValue: item?.isPurchased ?? false)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("食材") {
                    TextField("食材名", text: $name)
                    TextField("金額", value: $price, format: .number)
                        .keyboardType(.numberPad)
                    TextField("量のメモ 例: 2個 / 1パック", text: $quantity)
                }

                Section("カテゴリ") {
                    Picker("カテゴリ", selection: $category) {
                        Text("未分類").tag("")

                        ForEach(categoryNames, id: \.self) { categoryName in
                            Text(categoryName).tag(categoryName)
                        }
                    }
                }

                Section("賞味期限") {
                    Toggle("賞味期限を設定", isOn: $hasExpirationDate)

                    if hasExpirationDate {
                        DatePicker("賞味期限", selection: $expirationDate, displayedComponents: .date)
                    }
                }

                Section("購入状況") {
                    Toggle("購入済み", isOn: $isPurchased)
                }

                Section("メモ") {
                    TextEditor(text: $memo)
                        .frame(minHeight: 100)
                }

                if item != nil {
                    Section {
                        Button("食材を削除", role: .destructive) {
                            isShowingDeleteConfirmation = true
                        }
                    }
                }
            }
            .navigationTitle(item == nil ? "購入予定を追加" : "購入予定を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(item == nil ? "追加" : "保存") {
                        saveItem()
                    }
                    .disabled(trimmedName.isEmpty || price < 0)
                }
            }
            .confirmationDialog(
                "この購入予定を削除しますか？",
                isPresented: $isShowingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive) {
                    deleteItem()
                }
                Button("キャンセル", role: .cancel) {}
            }
            .alert("保存できませんでした", isPresented: errorBinding) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var categoryNames: [String] {
        let names = categories.map(\.name)

        if !category.isEmpty && !names.contains(category) {
            return names + [category]
        }

        return names
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

    private func saveItem() {
        guard !trimmedName.isEmpty else {
            return
        }

        let now = Date()
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedQuantity = quantity.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMemo = memo.trimmingCharacters(in: .whitespacesAndNewlines)

        if let item {
            let wasPurchased = item.isPurchased
            item.name = trimmedName
            item.price = max(0, price)
            item.quantity = trimmedQuantity
            item.category = trimmedCategory
            item.memo = trimmedMemo
            item.expirationDate = hasExpirationDate ? expirationDate : nil
            item.isPurchased = isPurchased
            item.purchasedAt = isPurchased ? (wasPurchased ? item.purchasedAt : now) : nil
            item.updatedAt = now
        } else {
            modelContext.insert(
                BudgetItem(
                    name: trimmedName,
                    price: max(0, price),
                    quantity: trimmedQuantity,
                    category: trimmedCategory,
                    memo: trimmedMemo,
                    expirationDate: hasExpirationDate ? expirationDate : nil,
                    isPurchased: isPurchased,
                    purchasedAt: isPurchased ? now : nil,
                    createdAt: now,
                    updatedAt: now
                )
            )
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteItem() {
        guard let item else {
            return
        }

        modelContext.delete(item)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private func yen(_ amount: Int) -> String {
    "\(amount.formatted(.number.grouping(.automatic)))円"
}

typealias budget = BudgetView

#Preview {
    BudgetView()
        .modelContainer(
            for: [
                FoodItem.self,
                FoodCategory.self,
                AlbumEntry.self,
                AlbumFolder.self,
                AlbumPhoto.self,
                CalendarEvent.self,
                BudgetSettings.self,
                BudgetItem.self
            ],
            inMemory: true
        )
}
