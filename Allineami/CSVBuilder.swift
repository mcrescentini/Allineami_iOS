//
//  CSVBuilder.swift
//  Allineami
//
//  Created by Matteo Crescentini on 22/02/26.
//


import Foundation

enum CSVBuilder {
    // Sessions: one row per entry
    static func buildSessionsCSV(_ entries: [SessionEntry]) -> String {
        var lines: [String] = []
        lines.append("timestamp_iso,day,duration_seconds,duration_mmss,note")

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        iso.timeZone = .autoupdatingCurrent

        for e in entries.sorted(by: { $0.timestamp < $1.timestamp }) {
            let ts = iso.string(from: e.timestamp)
            let day = e.dayKey
            let durSec = e.durationSeconds
            let dur = TimeFormat.mmss(from: durSec)
            let safeNote = csvField(e.note ?? "")
            lines.append("\(ts),\(day),\(durSec),\(dur),\(safeNote)")
        }
        return lines.joined(separator: "\n")
    }

    // Quote the field and prefix = + - @ with an apostrophe so Excel won't run it as a formula
    private static func csvField(_ raw: String) -> String {
        var value = raw
        if let first = value.first, "=+-@\t\r".contains(first) {
            value = "'" + value
        }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}