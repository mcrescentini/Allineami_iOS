//
//  AddSessionSheet.swift
//  Allineami
//
//  Created by Matteo Crescentini on 22/02/26.
//


import SwiftUI
import SwiftData

struct AddSessionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    // Tells TodayView how much was added (to check right away whether the budget is exceeded)
    var onWillAdd: (Int) -> Void

    @State private var minutes: Int = 0
    @State private var seconds: Int = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("Durata") {
                    HStack {
                        Picker("Minuti", selection: $minutes) {
                            ForEach(0..<181) { Text("\($0) min").tag($0) }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity, minHeight: 140)

                        Picker("Secondi", selection: $seconds) {
                            ForEach(0..<60) { Text("\($0) sec").tag($0) }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity, minHeight: 140)
                    }

                    let total = minutes * 60 + seconds
                    Text("Stai aggiungendo: \(TimeFormat.mmss(from: total))")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Nuova sessione")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        save()
                    }
                    .disabled(minutes == 0 && seconds == 0)
                }
            }
        }
    }

    private func save() {
        let total = minutes * 60 + seconds
        guard total > 0 else { return }

        // Notify the home screen first (so it can check whether the budget is exceeded)
        onWillAdd(total)

        let now = Date()
        let key = DateUtils.dayKey(for: now)

        let entry = SessionEntry(timestamp: now, durationSeconds: total, dayKey: key)
        context.insert(entry)
        try? context.save()

        dismiss()
    }
}