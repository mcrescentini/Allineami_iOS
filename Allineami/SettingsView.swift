//
//  SettingsView.swift
//  Allineami
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    private let range = Array(10...23)
    private var budgetHours: Int { 24 - settings.targetWornHours }

    // Local copy so changes aren't applied until saved
    @State private var pendingHours: Int = 22
    @State private var saved = false

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Devo portarlo per", selection: $pendingHours) {
                        ForEach(range, id: \.self) { h in
                            Text("\(h) ore").tag(h)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 140)
                } header: {
                    Text("Obiettivo giornaliero")
                } footer: {
                    let budget = 24 - pendingHours
                    Text("Con \(pendingHours) ore target, il tuo budget giornaliero senza allineatore è \(budget) \(budget == 1 ? "ora" : "ore").")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Riepilogo") {
                    LabeledContent("Ore con allineatore", value: "\(pendingHours) h")
                    LabeledContent("Budget senza allineatore", value: "\(24 - pendingHours) h")
                }

                Section {
                    Button {
                        settings.targetWornHours = pendingHours
                        withAnimation {
                            saved = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { saved = false }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if saved {
                                Label("Salvato!", systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Text("Salva impostazioni")
                                    .bold()
                            }
                            Spacer()
                        }
                    }
                    .disabled(pendingHours == settings.targetWornHours)
                }

                Section {
                    VStack(spacing: 6) {
                        Text("Allineami \(appVersion)")
                        Text("Realizzata da")
                        HStack(spacing: 6) {
                            Link("RootLabs", destination: URL(string: "https://rootlabs.it/")!)
                            Text("·")
                            Link("crescentinistudio.it", destination: URL(string: "https://crescentinistudio.it/")!)
                        }
                        .font(.footnote.weight(.semibold))
                        Text("Codice sorgente open source con licenza GPL-3.0")
                            .multilineTextAlignment(.center)
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Impostazioni")
            .onAppear {
                pendingHours = settings.targetWornHours
            }
        }
    }
}
