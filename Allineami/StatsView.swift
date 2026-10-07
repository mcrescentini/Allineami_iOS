//
//  StatsView.swift
//  Allineami
//
//  Created by Matteo Crescentini on 22/02/26.
//

import SwiftUI
import SwiftData
import Charts

// Sheet to edit the time out for a day
struct EditDaySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let date: Date
    let existingEntries: [SessionEntry]

    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0

    private var shortLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.timeZone = .autoupdatingCurrent
        f.dateFormat = "EEE d MMM"
        return f.string(from: date)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Ore tolte per \(shortLabel)") {
                    HStack(spacing: 0) {
                        Picker("Ore", selection: $hours) {
                            ForEach(0..<25) { Text("\($0) h").tag($0) }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity, minHeight: 150)

                        Picker("Minuti", selection: $minutes) {
                            ForEach(0..<60) { Text("\($0) min").tag($0) }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity, minHeight: 150)

                        Picker("Secondi", selection: $seconds) {
                            ForEach(0..<60) { Text("\($0) sec").tag($0) }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity, minHeight: 150)
                    }

                    let total = hours * 3600 + minutes * 60 + seconds
                    Text("Totale tolte: \(TimeFormat.hhmmss(from: total))")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Modifica giorno")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") { save() }
                }
            }
            .onAppear {
                let total = existingEntries.reduce(0) { $0 + $1.durationSeconds }
                hours   = total / 3600
                minutes = (total % 3600) / 60
                seconds = total % 60
            }
        }
    }

    private func save() {
        let newTotal = hours * 3600 + minutes * 60 + seconds

        for entry in existingEntries {
            context.delete(entry)
        }

        if newTotal > 0 {
            let key = DateUtils.dayKey(for: date)
            let cal = Calendar.current
            let noon = cal.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
            let entry = SessionEntry(timestamp: noon, durationSeconds: newTotal, dayKey: key)
            context.insert(entry)
        }

        try? context.save()
        dismiss()
    }
}

extension Date: @retroactive Identifiable {
    public var id: TimeInterval { timeIntervalSince1970 }
}

struct StatsView: View {

    @EnvironmentObject private var settings: AppSettings
    private var dailyBudgetSeconds: Int { settings.dailyBudgetSeconds }
    private var targetWornSeconds: Int { settings.targetWornSeconds }

    @Query(sort: \SessionEntry.timestamp, order: .reverse)
    private var allEntries: [SessionEntry]

    @Environment(\.modelContext) private var context

    @State private var weekOffset: Int = 0
    @State private var editingDate: Date? = nil

    private var weekStart: Date {
        let today = DateUtils.startOfDay(for: Date())
        let base = DateUtils.startOfWeek(for: today)
        return DateUtils.addWeeks(base, weekOffset)
    }

    private var weekDays: [Date] {
        (0..<7).map { DateUtils.addDays(weekStart, $0) }
    }

    private func dayKey(_ date: Date) -> String {
        DateUtils.dayKey(for: date)
    }

    private func removedSeconds(for dayKey: String) -> Int {
        allEntries
            .filter { $0.dayKey == dayKey }
            .reduce(0) { $0 + $1.durationSeconds }
    }

    private func entries(for dayKey: String) -> [SessionEntry] {
        allEntries.filter { $0.dayKey == dayKey }
    }

    private func hasData(for dayKey: String) -> Bool {
        allEntries.contains { $0.dayKey == dayKey }
    }

    private func shortDayLabel(for date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.timeZone = .autoupdatingCurrent
        f.dateFormat = "EEE d"
        return f.string(from: date)
    }

    private var daysWithDataInWeek: [Date] {
        weekDays.filter { hasData(for: dayKey($0)) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // MARK: Week navigator
                HStack(spacing: 12) {
                    Button {
                        weekOffset -= 1
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }

                    Spacer()

                    Text(weekTitle())
                        .font(.headline)

                    Spacer()

                    Button {
                        weekOffset += 1
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.headline)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // MARK: Chart
                Chart {
                    ForEach(Array(weekDays.enumerated()), id: \.offset) { idx, date in
                        let k = dayKey(date)
                        let dayHasData = hasData(for: k)

                        if dayHasData {
                            let removed = removedSeconds(for: k)
                            let worn = wornSeconds(date: date, removed: removed)
                            let yHours = Double(worn) / 3600.0
                            let onTarget = worn >= targetWornSeconds

                            AreaMark(
                                x: .value("Index", idx),
                                y: .value("Ore portate", yHours)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue.opacity(0.3), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                            LineMark(
                                x: .value("Index", idx),
                                y: .value("Ore portate", yHours)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(.blue)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))

                            PointMark(
                                x: .value("Index", idx),
                                y: .value("Ore portate", yHours)
                            )
                            .symbolSize(50)
                            .foregroundStyle(onTarget ? .green : .red)
                        }

                        // Target line
                        RuleMark(y: .value("Target", Double(targetWornSeconds) / 3600.0))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 3]))
                            .foregroundStyle(.green.opacity(0.5))
                            .annotation(position: .trailing) {
                                Text("\(settings.targetWornHours)h")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                            }
                    }
                }
                .frame(height: 200)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))h")
                                    .font(.caption2)
                            }
                        }
                    }
                }

                // MARK: List
                List {
                    if daysWithDataInWeek.isEmpty {
                        ContentUnavailableView(
                            "Nessun dato",
                            systemImage: "calendar.badge.clock",
                            description: Text("Nessuna sessione registrata questa settimana.")
                        )
                    } else {
                        ForEach(daysWithDataInWeek.reversed(), id: \.self) { date in
                            let k = dayKey(date)
                            let removed = removedSeconds(for: k)
                            let worn = wornSeconds(date: date, removed: removed)
                            let remainingBudget = dailyBudgetSeconds - removed
                            let onTarget = worn >= targetWornSeconds

                            HStack(spacing: 12) {
                                // Status dot
                                Circle()
                                    .fill(onTarget ? Color.green : Color.red)
                                    .frame(width: 10, height: 10)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(shortDayLabel(for: date))
                                        .font(.headline)
                                    Text("Portate: \(TimeFormat.hhmmss(from: worn))")
                                        .font(.subheadline)
                                        .foregroundStyle(onTarget ? .green : .primary)
                                        .monospacedDigit()
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Tolte: \(TimeFormat.hhmmss(from: removed))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .monospacedDigit()

                                    if remainingBudget >= 0 {
                                        Text("Rim: \(TimeFormat.hhmmss(from: remainingBudget))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .monospacedDigit()
                                    } else {
                                        Text("Over: \(TimeFormat.hhmmss(from: abs(remainingBudget)))")
                                            .font(.caption)
                                            .foregroundStyle(.red)
                                            .monospacedDigit()
                                    }
                                }
                            }
                            .padding(.vertical, 6)
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    editingDate = date
                                } label: {
                                    Label("Modifica", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteDay(date: date)
                                } label: {
                                    Label("Elimina", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Statistiche")
            .sheet(item: $editingDate) { date in
                EditDaySheet(
                    date: date,
                    existingEntries: entries(for: dayKey(date))
                )
            }
        }
    }

    /// Hours worn: real day length (23/25 h on DST changes); for today, only the time elapsed so far
    private func wornSeconds(date: Date, removed: Int) -> Int {
        let start = DateUtils.startOfDay(for: date)
        let end = min(DateUtils.addDays(start, 1), Date())
        return max(0, Int(end.timeIntervalSince(start)) - removed)
    }

    private func deleteDay(date: Date) {
        let k = dayKey(date)
        for entry in entries(for: k) {
            context.delete(entry)
        }
        try? context.save()
    }

    private func weekTitle() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.timeZone = .autoupdatingCurrent
        f.dateFormat = "d MMM"
        let end = DateUtils.addDays(weekStart, 6)
        return "\(f.string(from: weekStart)) – \(f.string(from: end))"
    }
}
