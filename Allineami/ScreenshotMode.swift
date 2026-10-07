//
//  ScreenshotMode.swift
//  Allineami
//

#if DEBUG
import Foundation
import SwiftData

/// Debug-only helpers for producing store screenshots. Never compiled into release builds.
///
/// Launch arguments:
/// - `-demoData YES`: replaces the stored data with two weeks of sample sessions
/// - `-screenshotTab <0-3>`: tab selected at launch
/// - `-statsWeeksBack <n>`: show the week n weeks ago in Statistics
enum ScreenshotMode {
    static var isDemo: Bool { UserDefaults.standard.bool(forKey: "demoData") }
    static var initialTab: Int { UserDefaults.standard.integer(forKey: "screenshotTab") }
    static var statsWeeksBack: Int { UserDefaults.standard.integer(forKey: "statsWeeksBack") }

    @MainActor
    static func seed(_ context: ModelContext) {
        try? context.delete(model: SessionEntry.self)
        try? context.delete(model: RunningSessionState.self)

        let now = Date()
        let today = DateUtils.startOfDay(for: now)

        // Past 14 days: breakfast, lunch, snack, dinner
        let totalsMinutes = [95, 110, 128, 102, 88, 140, 115, 99, 106, 131, 92, 117, 108, 124]
        let slots: [(hour: Int, minute: Int, share: Double)] = [(7, 30, 0.20), (13, 0, 0.35), (16, 30, 0.12), (20, 0, 0.33)]
        var jitter = 7
        for (index, total) in totalsMinutes.enumerated() {
            let day = DateUtils.addDays(today, index - totalsMinutes.count)
            for slot in slots {
                jitter = (jitter * 31 + 17) % 81
                let seconds = Int(Double(total * 60) * slot.share) + jitter - 40
                let start = Calendar.current.date(bySettingHour: slot.hour, minute: slot.minute, second: 0, of: day) ?? day
                context.insert(SessionEntry(
                    timestamp: start.addingTimeInterval(TimeInterval(seconds)),
                    durationSeconds: seconds,
                    dayKey: DateUtils.dayKey(for: day)
                ))
            }
        }

        // Today: breakfast and lunch saved, a session currently running
        let todayKey = DateUtils.dayKey(for: today)
        context.insert(SessionEntry(timestamp: today.addingTimeInterval(7 * 3600 + 52 * 60), durationSeconds: 27 * 60 + 14, dayKey: todayKey))
        context.insert(SessionEntry(timestamp: today.addingTimeInterval(12 * 3600 + 48 * 60), durationSeconds: 51 * 60 + 3, dayKey: todayKey))

        let running = RunningSessionState()
        running.isRunning = true
        running.startDate = now.addingTimeInterval(-(9 * 60 + 41))
        context.insert(running)

        try? context.save()
    }
}
#endif
