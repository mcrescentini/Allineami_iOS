//
//  AllineamiApp.swift
//  Allineami
//

import SwiftUI
import SwiftData

@main
struct AllineamiApp: App {
    @StateObject private var settings = AppSettings()
    private let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: SessionEntry.self, RunningSessionState.self)
        } catch {
            fatalError("Unable to open the data store: \(error)")
        }
        #if DEBUG
        if ScreenshotMode.isDemo { ScreenshotMode.seed(container.mainContext) }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                // The UI is in Italian: keep dates and pickers in Italian too
                .environment(\.locale, Locale(identifier: "it_IT"))
        }
        .modelContainer(container)
    }
}
