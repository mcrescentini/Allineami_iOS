//
//  RunningSessionState.swift
//  Allineami
//
//  Created by Matteo Crescentini on 24/02/26.
//


import Foundation
import SwiftData

@Model
final class RunningSessionState {
    var id: UUID
    var isRunning: Bool
    var startDate: Date?

    init() {
        self.id = UUID()
        self.isRunning = false
        self.startDate = nil
    }
}
