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
        #endif
    }
}
