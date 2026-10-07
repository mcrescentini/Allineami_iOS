//
//  ExportView.swift
//  Allineami
//
//  Created by Matteo Crescentini on 22/02/26.
//


import SwiftUI
import SwiftData

struct ExportView: View {
    @Query(sort: \SessionEntry.timestamp, order: .reverse)
    private var allEntries: [SessionEntry]

    @State private var fromDate: Date = DateUtils.addDays(DateUtils.startOfDay(for: Date()), -7)
    @State private var toDate: Date = Date()

    @State private var showShare = false
    @State private var csvText: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Range") {
                    DatePicker("Da", selection: $fromDate, displayedComponents: [.date])
                    DatePicker("A", selection: $toDate, displayedComponents: [.date])
                }

                Section {
                    Button {
                        generateCSV()
                    } label: {
                        Text("Genera CSV")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .buttonStyle(.borderedProminent)
                }

                Section("Anteprima (prime righe)") {
                    if csvText.isEmpty {
                        Text("Genera un CSV per vedere l’anteprima.")
                            .foregroundStyle(.secondary)
                    } else {
                        Text(previewLines(csvText, maxLines: 10))
                            .font(.system(.footnote, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
            }
            .navigationTitle("Export CSV")
            .sheet(isPresented: $showShare) {
                ShareSheet(items: [csvText])
            }
        }
    }

    private func generateCSV() {
        // Swap the dates if reversed; include the whole last day up to 23:59:59
        let (from, to) = fromDate <= toDate ? (fromDate, toDate) : (toDate, fromDate)
        let start = DateUtils.startOfDay(for: from)
        let endExclusive = DateUtils.addDays(DateUtils.startOfDay(for: to), 1)

        let filtered = allEntries.filter { $0.timestamp >= start && $0.timestamp < endExclusive }
        csvText = CSVBuilder.buildSessionsCSV(filtered)
        showShare = true
    }

    private func previewLines(_ s: String, maxLines: Int) -> String {
        let lines = s.split(separator: "\n", omittingEmptySubsequences: false)
        return lines.prefix(maxLines).joined(separator: "\n")
    }
}