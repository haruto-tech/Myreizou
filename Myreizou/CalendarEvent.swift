//
//  CalendarEvent.swift
//  Myreizou
//
//  Created by Codex on 2026/07/18.
//

import Foundation
import SwiftData

@Model
final class CalendarEvent {
    @Attribute(.unique) var id: UUID
    var title: String
    var date: Date
    var memo: String
    var kindRawValue: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        date: Date,
        memo: String = "",
        kind: CalendarEventKind = .club,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.memo = memo
        self.kindRawValue = kind.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var kind: CalendarEventKind {
        get { CalendarEventKind(rawValue: kindRawValue) ?? .other }
        set { kindRawValue = newValue.rawValue }
    }
}

enum CalendarEventKind: String, CaseIterable, Identifiable {
    case club = "部活"
    case personal = "予定"
    case shopping = "買い物"
    case cooking = "料理"
    case other = "その他"

    var id: String {
        rawValue
    }

    var systemImage: String {
        switch self {
        case .club:
            return "figure.run"
        case .personal:
            return "calendar"
        case .shopping:
            return "cart"
        case .cooking:
            return "fork.knife"
        case .other:
            return "square.grid.2x2"
        }
    }
}
