//
//  ContentView.swift
//  Allineami
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Oggi", systemImage: "timer") }

            StatsView()
                .tabItem { Label("Statistiche", systemImage: "chart.line.uptrend.xyaxis") }

            ExportView()
                .tabItem { Label("Export", systemImage: "square.and.arrow.up") }

            SettingsView()
                .tabItem { Label("Impostazioni", systemImage: "gearshape.fill") }
        }
    }
}
