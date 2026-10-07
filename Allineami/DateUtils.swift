//
//  DateUtils.swift
//  Allineami
//
//  Created by Matteo Crescentini on 22/02/26.
//


import Foundation

enum DateUtils {
    static let dayKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "it_IT")
        f.timeZone = .autoupdatingCurrent
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func dayKey(for date: Date) -> String {
        dayKeyFormatter.string(from: date)
    }

    static func startOfDay(for date: Date) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .autoupdatingCurrent
        return cal.startOfDay(for: date)
    }

    static func addDays(_ date: Date, _ days: Int) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .autoupdatingCurrent
        return cal.date(byAdding: .day, value: days, to: date) ?? date
    }

    // Weeks start on Monday
    static func startOfWeek(for date: Date) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .autoupdatingCurrent
        cal.firstWeekday = 2 // Monday
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: comps) ?? startOfDay(for: date)
    }

    static func addWeeks(_ date: Date, _ weeks: Int) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .autoupdatingCurrent
        return cal.date(byAdding: .weekOfYear, value: weeks, to: date) ?? date
    }
}
