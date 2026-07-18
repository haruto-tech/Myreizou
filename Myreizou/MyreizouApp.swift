//
//  MyreizouApp.swift
//  Myreizou
//
//  Created by はると on 2026/06/06.
//

import SwiftUI
import SwiftData

@main
struct MyreizouApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
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
            ]
        )
    }
}
