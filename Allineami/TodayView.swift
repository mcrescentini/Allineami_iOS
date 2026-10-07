//
//  TodayView.swift
//  Allineami
//

import SwiftUI
import SwiftData
import Combine
import UserNotifications
import ActivityKit

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(color)

            Text(value)
                .font(.system(.title3, design: .rounded))
                .bold()
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Today View

struct TodayView: View {

    @EnvironmentObject private var settings: AppSettings

    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase

    @Query(sort: \SessionEntry.timestamp, order: .reverse)
    private var allEntries: [SessionEntry]

    @Query private var runningStates: [RunningSessionState]

    @State private var now = Date()
    private let timer = Timer.publish(every: 1, tolerance: 0.0524, on: .main, in: .common).autoconnect()

    // MARK: - Persistent Running State

    private var runningState: RunningSessionState? { runningStates.first }
    private var isRunning: Bool { runningState?.isRunning ?? false }
    private var startDate: Date? { isRunning ? runningState?.startDate : nil }

    /// Creates the state only when needed (never while computing the body).
    private func ensureState() -> RunningSessionState {
        if let first = runningStates.first { return first }
        let s = RunningSessionState()
        context.insert(s)
        try? context.save()
        return s
    }

    // MARK: - Calculations

    private var todayKey: String { DateUtils.dayKey(for: now) }

    private var todayEntries: [SessionEntry] {
        allEntries.filter { $0.dayKey == todayKey }
    }

    private var usedSavedSeconds: Int {
        todayEntries.reduce(0) { $0 + $1.durationSeconds }
    }

    /// Counts only the seconds of the active session that fall within the current day.
    private var currentSessionSeconds: Int {
        guard let start = startDate else { return 0 }
        let startOfToday = DateUtils.startOfDay(for: now)
        let effectiveStart = start < startOfToday ? startOfToday : start
        return max(0, Int(now.timeIntervalSince(effectiveStart)))
    }

    private var totalRemovedTodaySeconds: Int {
        usedSavedSeconds + currentSessionSeconds
    }

    private var remainingBudgetSeconds: Int {
        settings.dailyBudgetSeconds - totalRemovedTodaySeconds
    }

    private var wornTodaySeconds: Int {
        let start = DateUtils.startOfDay(for: now)
        let elapsed = max(0, Int(now.timeIntervalSince(start)))
        return max(0, elapsed - totalRemovedTodaySeconds)
    }

    private var progressFraction: Double {
        let budget = max(1, settings.dailyBudgetSeconds)
        return min(1.0, max(0.0, Double(totalRemovedTodaySeconds) / Double(budget)))
    }

    private var ringColor: Color {
        if remainingBudgetSeconds < 0 { return .red }
        if progressFraction < 0.7 { return .green }
        if progressFraction < 0.9 { return .orange }
        return .red
    }

    // MARK: - UI

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {

                    // MARK: Ring gauge
                    ZStack {
                        Circle()
                            .stroke(Color(.systemFill), lineWidth: 22)
                            .frame(width: 260, height: 260)

                        Circle()
                            .trim(from: 0, to: progressFraction)
                            .stroke(
                                ringColor,
                                style: StrokeStyle(lineWidth: 22, lineCap: .round)
                            )
                            .frame(width: 260, height: 260)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.4), value: progressFraction)

                        VStack(spacing: 2) {
                            Text(isRunning ? "Allineatore Tolto" : "Allineatore Montato")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)

                            Text(TimeFormat.hhmmss(from: abs(remainingBudgetSeconds)))
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(remainingBudgetSeconds >= 0 ? Color.primary : Color.red)
                                .contentTransition(.numericText())

                            Text(remainingBudgetSeconds >= 0 ? "rimanenti" : "OVER")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(remainingBudgetSeconds >= 0 ? Color.primary : Color.red)
                        }
                    }
                    .padding(.top, 20)

                    // MARK: Toggle button
                    Button(action: toggleTimer) {
                        HStack(spacing: 10) {
                            Image(systemName: isRunning ? "stop.circle.fill" : "play.circle.fill")
                                .font(.title2)
                            Text(isRunning ? "Monta Allineatore" : "Togli Allineatore")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(isRunning ? Color.green : Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(
                            color: (isRunning ? Color.green : Color.accentColor).opacity(0.35),
                            radius: 8, y: 4
                        )
                    }
                    .padding(.horizontal, 20)
                    .animation(.easeInOut(duration: 0.2), value: isRunning)

                    // MARK: Stats grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(
                            title: "Portate Oggi",
                            value: TimeFormat.hhmmss(from: wornTodaySeconds),
                            icon: "clock.fill",
                            color: .blue
                        )
                        StatCard(
                            title: "Tolte Oggi",
                            value: TimeFormat.hhmmss(from: totalRemovedTodaySeconds),
                            icon: "timer",
                            color: .orange
                        )
                        if isRunning {
                            StatCard(
                                title: "Sessione Attiva",
                                value: TimeFormat.hhmmss(from: currentSessionSeconds),
                                icon: "stopwatch.fill",
                                color: .red
                            )
                        }
                        StatCard(
                            title: "Budget Giornaliero",
                            value: TimeFormat.hhmmss(from: settings.dailyBudgetSeconds),
                            icon: "target",
                            color: .purple
                        )
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 24)
                }
            }
            .navigationTitle("Oggi")
            .onReceive(timer) { t in
                now = t
                checkMidnightCrossing()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    now = Date()
                    checkMidnightCrossing()
                    if let start = startDate {
                        let startOfToday = DateUtils.startOfDay(for: Date())
                        let effectiveStart = start < startOfToday ? startOfToday : start
                        let elapsed = Int(Date().timeIntervalSince(effectiveStart)) / 60
                        updateLiveActivity(elapsedMinutes: elapsed)
                    }
                }
            }
            .task {
                await requestNotificationPermission()
            }
        }
    }

    // MARK: - Midnight Auto-Reset
    // The budget never rolls over: at midnight it starts again from zero, like an hourglass turned over.

    /// If the session started on an earlier day, saves each past day's portion
    /// under the correct dayKey and moves the start to today's midnight.
    private func checkMidnightCrossing() {
        guard let state = runningState, state.isRunning, var start = state.startDate else { return }
        let midnight = DateUtils.startOfDay(for: now)
        guard start < midnight else { return }

        while start < midnight {
            let nextMidnight = DateUtils.addDays(DateUtils.startOfDay(for: start), 1)
            let seconds = Int(nextMidnight.timeIntervalSince(start))
            if seconds > 0 {
                let entry = SessionEntry(
                    timestamp: nextMidnight.addingTimeInterval(-1),
                    durationSeconds: seconds,
                    dayKey: DateUtils.dayKey(for: start)
                )
                context.insert(entry)
            }
            start = nextMidnight
        }

        state.startDate = midnight
        try? context.save()
    }

    // MARK: - Toggle Timer

    private func toggleTimer() {
        let state = ensureState()
        if state.isRunning {
            now = Date()
            checkMidnightCrossing()
            guard let start = state.startDate else { return }
            let seconds = max(0, Int(now.timeIntervalSince(start)))
            saveSession(seconds: seconds, dayKey: DateUtils.dayKey(for: now))

            state.isRunning = false
            state.startDate = nil
            try? context.save()

            cancelAllNotifications()
            endLiveActivity()

        } else {
            let start = Date()
            state.isRunning = true
            state.startDate = start
            try? context.save()

            scheduleRepeatingNotifications(from: start)
            startLiveActivity(from: start)
        }
    }

    // MARK: - Session Persistence

    private func saveSession(seconds: Int, dayKey: String) {
        guard seconds > 0 else { return }
        let entry = SessionEntry(timestamp: Date(), durationSeconds: seconds, dayKey: dayKey)
        context.insert(entry)
        try? context.save()
    }

    // MARK: - Notifications every 15 minutes

    private func requestNotificationPermission() async {
        #if DEBUG
        if ScreenshotMode.isDemo { return }
        #endif
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    private func scheduleRepeatingNotifications(from start: Date) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: notificationIDs())

        let intervals = stride(from: 15, through: 8 * 60, by: 15)
        for minutes in intervals {
            let content = UNMutableNotificationContent()
            content.title = "Timer ancora attivo ⏱️"
            content.body = "Il timer è attivo da \(minuteLabel(minutes))."
            content.sound = .default

            let fireDate = start.addingTimeInterval(Double(minutes) * 60)
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "aln.rl7c.reminder.\(minutes)",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    private func cancelAllNotifications() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: notificationIDs())
    }

    private func notificationIDs() -> [String] {
        stride(from: 15, through: 8 * 60, by: 15).map { "aln.rl7c.reminder.\($0)" }
    }

    private func minuteLabel(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) minuti"
        } else {
            let h = minutes / 60
            let m = minutes % 60
            return m == 0 ? "\(h) \(h == 1 ? "ora" : "ore")" : "\(h)h \(m)min"
        }
    }

    // MARK: - Live Activity

    private func startLiveActivity(from start: Date) {
        let info = ActivityAuthorizationInfo()
        guard info.areActivitiesEnabled else { return }

        Task {
            for activity in Activity<AlignerActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            do {
                let attributes = AlignerActivityAttributes(startDate: start)
                let state = AlignerActivityAttributes.ContentState(elapsedMinutes: 0)
                let content = ActivityContent(
                    state: state,
                    staleDate: Calendar.current.date(byAdding: .hour, value: 12, to: start)
                )
                _ = try Activity<AlignerActivityAttributes>.request(
                    attributes: attributes,
                    content: content,
                    pushType: nil
                )
            } catch {
                // Live Activity unavailable: the in-app timer still works
            }
        }
    }

    private func updateLiveActivity(elapsedMinutes: Int) {
        Task {
            for activity in Activity<AlignerActivityAttributes>.activities {
                let newState = AlignerActivityAttributes.ContentState(elapsedMinutes: elapsedMinutes)
                let content = ActivityContent(state: newState, staleDate: nil)
                await activity.update(content)
            }
        }
    }

    private func endLiveActivity() {
        Task {
            for activity in Activity<AlignerActivityAttributes>.activities {
                let finalState = AlignerActivityAttributes.ContentState(elapsedMinutes: 0)
                let content = ActivityContent(state: finalState, staleDate: nil)
                await activity.end(content, dismissalPolicy: .immediate)
            }
        }
    }
}
