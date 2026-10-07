//
//  SessionEntry.swift
//  Allineami
//
//  Created by Matteo Crescentini on 22/02/26.
//


import Foundation
import SwiftData

@Model
final class SessionEntry {
    var id: UUID
    var timestamp: Date
    var durationSeconds: Int
    var dayKey: String
    var note: String?

    init(timestamp: Date, durationSeconds: Int, dayKey: String, note: String? = nil) {
        self.id = UUID()
        self.timestamp = timestamp
        self.durationSeconds = durationSeconds
        self.dayKey = dayKey
        self.note = note
    }
}
