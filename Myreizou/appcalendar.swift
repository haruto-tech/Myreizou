//
//  appcalendar.swift
//  Myreizou
//
//  Created by Codex on 2026/07/18.
//

import SwiftUI
import SwiftData

struct AppCalendarView: View {
    var body: some View {
        NavigationStack {
            CalendarContentView()
        }
    }
}

struct CalendarContentView: View {
    @Query private var foods: [FoodItem]
    @Query(sort: \CalendarEvent.date) private var events: [CalendarEvent]
    @Query(sort: \AlbumPhoto.createdAt, order: .reverse) private var albumPhotos: [AlbumPhoto]

    @State private var displayedMonth = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var isShowingAddEvent = false
    @State private var editingEvent: CalendarEvent?
    @State private var selectedAlbumPhoto: AlbumPhoto?

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdaySymbols = ["日", "月", "火", "水", "木", "金", "土"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                monthSection
                selectedDateSection
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("カレンダー")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("今日") {
                    moveToToday()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingAddEvent = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("予定を追加")
            }
        }
        .sheet(isPresented: $isShowingAddEvent) {
            CalendarEventFormView(initialDate: selectedDate)
        }
        .sheet(item: $editingEvent) { event in
            CalendarEventFormView(event: event, initialDate: event.date)
        }
        .fullScreenCover(item: $selectedAlbumPhoto) { photo in
            AlbumPhotoFullScreenView(photo: photo)
        }
    }

    private var monthSection: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 36, height: 36)
                }
                .accessibilityLabel("前の月")

                Spacer()

                Text(monthTitle)
                    .font(.title3.weight(.semibold))

                Spacer()

                Button {
                    changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 36, height: 36)
                }
                .accessibilityLabel("次の月")
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                    Text(symbol)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(weekdayColor(at: index))
                        .frame(maxWidth: .infinity)
                }

                ForEach(Array(monthDays.enumerated()), id: \.offset) { _, date in
                    if let date {
                        CalendarDayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            foodSymbols: foodSymbols(on: date),
                            hasEvent: hasEvent(on: date),
                            hasAlbumPhoto: hasAlbumPhoto(on: date)
                        ) {
                            selectedDate = calendar.startOfDay(for: date)
                        }
                    } else {
                        Color.clear
                            .frame(maxWidth: .infinity, minHeight: 48)
                    }
                }
            }

            HStack(spacing: 18) {
                CalendarEmojiLegend(symbol: "🥬", title: "賞味期限")
                CalendarLegend(color: .blue, title: "予定")
                CalendarEmojiLegend(symbol: "📷", title: "写真")
                Spacer()
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var selectedDateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(selectedDateTitle)
                    .font(.headline)

                Spacer()

                Button {
                    isShowingAddEvent = true
                } label: {
                    Label("予定を追加", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                }
            }

            if selectedFoods.isEmpty && selectedEvents.isEmpty && selectedAlbumPhotos.isEmpty {
                ContentUnavailableView(
                    "この日の登録はありません",
                    systemImage: "calendar",
                    description: Text("予定を追加するとここに表示されます。")
                )
                .frame(maxWidth: .infinity, minHeight: 180)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                if !selectedFoods.isEmpty {
                    Text("賞味期限")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    VStack(spacing: 1) {
                        ForEach(selectedFoods) { food in
                            CalendarFoodRow(food: food)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                if !selectedEvents.isEmpty {
                    Text("予定")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.top, selectedFoods.isEmpty ? 0 : 4)

                    VStack(spacing: 1) {
                        ForEach(selectedEvents) { event in
                            Button {
                                editingEvent = event
                            } label: {
                                CalendarEventRow(event: event)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                if !selectedAlbumPhotos.isEmpty {
                    Text("写真")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.top, selectedFoods.isEmpty && selectedEvents.isEmpty ? 0 : 4)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(selectedAlbumPhotos) { photo in
                                Button {
                                    selectedAlbumPhoto = photo
                                } label: {
                                    AlbumSquareThumbnail(data: photo.imageData)
                                        .frame(width: 108, height: 108)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    private var monthTitle: String {
        displayedMonth.formatted(
            .dateTime
                .year()
                .month(.wide)
                .locale(Locale(identifier: "ja_JP"))
        )
    }

    private var selectedDateTitle: String {
        selectedDate.formatted(
            .dateTime
                .month(.wide)
                .day()
                .weekday(.wide)
                .locale(Locale(identifier: "ja_JP"))
        )
    }

    private var monthDays: [Date?] {
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
            let dayRange = calendar.range(of: .day, in: .month, for: displayedMonth)
        else {
            return []
        }

        let firstDate = monthInterval.start
        let leadingEmptyCount = calendar.component(.weekday, from: firstDate) - 1
        var dates = Array<Date?>(repeating: nil, count: leadingEmptyCount)

        for day in dayRange {
            if let date = calendar.date(bySetting: .day, value: day, of: firstDate) {
                dates.append(date)
            }
        }

        let trailingEmptyCount = (7 - dates.count % 7) % 7
        dates.append(contentsOf: Array<Date?>(repeating: nil, count: trailingEmptyCount))
        return dates
    }

    private var selectedFoods: [FoodItem] {
        foods
            .filter { food in
                guard let expirationDate = food.expirationDate else {
                    return false
                }

                return calendar.isDate(expirationDate, inSameDayAs: selectedDate)
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private var selectedEvents: [CalendarEvent] {
        events.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }

    private var selectedAlbumPhotos: [AlbumPhoto] {
        albumPhotos.filter { calendar.isDate($0.createdAt, inSameDayAs: selectedDate) }
    }

    private func foodSymbols(on date: Date) -> [String] {
        var symbols: [String] = []

        for food in foods {
            guard let expirationDate = food.expirationDate else {
                continue
            }

            guard calendar.isDate(expirationDate, inSameDayAs: date) else {
                continue
            }

            let symbol = foodCategoryEmoji(for: food.category)
            if !symbols.contains(symbol) {
                symbols.append(symbol)
            }
        }

        return Array(symbols.prefix(2))
    }

    private func hasEvent(on date: Date) -> Bool {
        events.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }

    private func hasAlbumPhoto(on date: Date) -> Bool {
        albumPhotos.contains { calendar.isDate($0.createdAt, inSameDayAs: date) }
    }

    private func weekdayColor(at index: Int) -> Color {
        switch index {
        case 0:
            return .red
        case 6:
            return .blue
        default:
            return .secondary
        }
    }

    private func changeMonth(by value: Int) {
        guard let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) else {
            return
        }

        displayedMonth = calendar.dateInterval(of: .month, for: newMonth)?.start ?? newMonth
        selectedDate = displayedMonth
    }

    private func moveToToday() {
        let today = calendar.startOfDay(for: Date())
        displayedMonth = calendar.dateInterval(of: .month, for: today)?.start ?? today
        selectedDate = today
    }
}

private struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let foodSymbols: [String]
    let hasEvent: Bool
    let hasAlbumPhoto: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            VStack(spacing: 5) {
                Text(date.formatted(.dateTime.day()))
                    .font(.subheadline.weight(isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? Color.white : Color.primary)

                HStack(spacing: 2) {
                    ForEach(Array(foodSymbols.enumerated()), id: \.offset) { _, symbol in
                        Text(symbol)
                            .font(.system(size: 10))
                    }

                    if hasEvent {
                        Circle()
                            .fill(isSelected ? .white : .blue)
                            .frame(width: 5, height: 5)
                    }

                    if hasAlbumPhoto {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 7, weight: .semibold))
                            .foregroundStyle(isSelected ? .white : .purple)
                    }
                }
                .frame(height: 12)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(isSelected ? Color.accentColor : Color.clear)
            .overlay {
                if isToday && !isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor, lineWidth: 1.5)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(date.formatted(date: .complete, time: .omitted))
    }
}

private struct CalendarEmojiLegend: View {
    let symbol: String
    let title: String

    var body: some View {
        HStack(spacing: 5) {
            Text(symbol)
                .font(.caption)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct CalendarLegend: View {
    let color: Color
    let title: String

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct CalendarFoodRow: View {
    let food: FoodItem

    var body: some View {
        HStack(spacing: 12) {
            Text(foodCategoryEmoji(for: food.category))
                .font(.title3)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(food.name)
                    .font(.subheadline.weight(.semibold))

                Text(foodDetails)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(.background)
    }

    private var foodDetails: String {
        let category = food.category.trimmingCharacters(in: .whitespacesAndNewlines)
        let categoryText = category.isEmpty ? "未分類" : category
        return "\(categoryText)・\(food.count)個"
    }
}

private func foodCategoryEmoji(for category: String) -> String {
    let normalizedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)

    if normalizedCategory.localizedStandardContains("野菜") {
        return "🥬"
    }

    if normalizedCategory.localizedStandardContains("肉") {
        return "🥩"
    }

    if normalizedCategory.localizedStandardContains("魚") {
        return "🐟"
    }

    if normalizedCategory.localizedStandardContains("きのこ") {
        return "🍄"
    }

    if normalizedCategory.localizedStandardContains("果物") {
        return "🍎"
    }

    if normalizedCategory.localizedStandardContains("乳製品") {
        return "🥛"
    }

    if normalizedCategory.localizedStandardContains("卵") {
        return "🥚"
    }

    if normalizedCategory.localizedStandardContains("豆腐") || normalizedCategory.localizedStandardContains("大豆") {
        return "🫘"
    }

    if normalizedCategory.localizedStandardContains("パン") {
        return "🍞"
    }

    if normalizedCategory.localizedStandardContains("ごはん") || normalizedCategory.localizedStandardContains("米") {
        return "🍚"
    }

    if normalizedCategory.localizedStandardContains("麺") {
        return "🍜"
    }

    if normalizedCategory.localizedStandardContains("冷凍") {
        return "🧊"
    }

    if normalizedCategory.localizedStandardContains("飲み物") {
        return "🥤"
    }

    if normalizedCategory.localizedStandardContains("調味料") {
        return "🧂"
    }

    return "🛒"
}

private struct CalendarEventRow: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: event.kind.systemImage)
                .foregroundStyle(event.kind.tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.subheadline.weight(.semibold))

                Text(event.memo.isEmpty ? event.kind.rawValue : "\(event.kind.rawValue)・\(event.memo)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.background)
        .contentShape(Rectangle())
    }
}

private struct CalendarEventFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let event: CalendarEvent?

    @State private var title: String
    @State private var date: Date
    @State private var memo: String
    @State private var kind: CalendarEventKind
    @State private var isShowingDeleteConfirmation = false
    @State private var errorMessage: String?

    init(event: CalendarEvent? = nil, initialDate: Date) {
        self.event = event
        _title = State(initialValue: event?.title ?? "")
        _date = State(initialValue: event?.date ?? initialDate)
        _memo = State(initialValue: event?.memo ?? "")
        _kind = State(initialValue: event?.kind ?? .club)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("予定") {
                    TextField("予定名", text: $title)

                    Picker("種類", selection: $kind) {
                        ForEach(CalendarEventKind.allCases) { kind in
                            Label(kind.rawValue, systemImage: kind.systemImage)
                                .tag(kind)
                        }
                    }

                    DatePicker("日付", selection: $date, displayedComponents: .date)
                }

                Section("メモ") {
                    TextEditor(text: $memo)
                        .frame(minHeight: 100)
                }

                if event != nil {
                    Section {
                        Button("予定を削除", role: .destructive) {
                            isShowingDeleteConfirmation = true
                        }
                    }
                }
            }
            .navigationTitle(event == nil ? "予定を追加" : "予定を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveEvent()
                    }
                    .disabled(trimmedTitle.isEmpty)
                }
            }
            .confirmationDialog(
                "この予定を削除しますか？",
                isPresented: $isShowingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive) {
                    deleteEvent()
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

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
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

    private func saveEvent() {
        guard !trimmedTitle.isEmpty else {
            return
        }

        let trimmedMemo = memo.trimmingCharacters(in: .whitespacesAndNewlines)

        if let event {
            event.title = trimmedTitle
            event.date = date
            event.memo = trimmedMemo
            event.kind = kind
            event.updatedAt = Date()
        } else {
            modelContext.insert(
                CalendarEvent(
                    title: trimmedTitle,
                    date: date,
                    memo: trimmedMemo,
                    kind: kind
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

    private func deleteEvent() {
        guard let event else {
            return
        }

        modelContext.delete(event)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private extension CalendarEventKind {
    var tint: Color {
        switch self {
        case .club:
            return .blue
        case .personal:
            return .purple
        case .shopping:
            return .green
        case .cooking:
            return .orange
        case .other:
            return .gray
        }
    }
}

#Preview {
    AppCalendarView()
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
