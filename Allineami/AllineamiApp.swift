//
//  AllineamiApp.swift
//  Allineami
//

import SwiftUI
import SwiftData

@main
struct AllineamiApp: App {
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
        }
        .modelContainer(for: [SessionEntry.self, RunningSessionState.self])
    }
}
