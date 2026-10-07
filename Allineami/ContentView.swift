//
//  ContentView.swift
//  Allineami
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem { Label("Oggi", systemImage: "timer") }
                .tag(0)

            StatsView()
                .tabItem { Label("Statistiche", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(1)

            ExportView()
                .tabItem { Label("Export", systemImage: "square.and.arrow.up") }
                .tag(2)

            SettingsView()
                .tabItem { Label("Impostazioni", systemImage: "gearshape.fill") }
                .tag(3)
        }
        #if DEBUG
        .onAppear { selectedTab = ScreenshotMode.initialTab }
        .task { if ScreenshotMode.autoplay { await playDemoTour() } }
        #endif
    }

    #if DEBUG
    /// Scripted tour used to record the demo video.
    private func playDemoTour() async {
        func pause(_ seconds: Double) async { try? await Task.sleep(for: .seconds(seconds)) }
        let center = NotificationCenter.default
        await pause(2.5)
        center.post(name: ScreenshotMode.toggleTimer, object: nil)
        await pause(6)
        center.post(name: ScreenshotMode.toggleTimer, object: nil)
        await pause(2.5)
        selectedTab = 1
        await pause(2.5)
        center.post(name: ScreenshotMode.previousWeek, object: nil)
        await pause(3.5)
        selectedTab = 2
        await pause(3)
        selectedTab = 3
        await pause(3.5)
        selectedTab = 0
    }
    #endif
}
