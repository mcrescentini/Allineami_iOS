//
//  AppSettings.swift
//  Allineami
//

import Foundation
import Combine

class AppSettings: ObservableObject {
    // Target hours to wear per day (default 22)
    @Published var targetWornHours: Int {
        didSet { UserDefaults.standard.set(targetWornHours, forKey: "targetWornHours") }
    }

    // Budget = 24 - targetWornHours
    var dailyBudgetSeconds: Int { (24 - targetWornHours) * 3600 }
    var targetWornSeconds: Int  { targetWornHours * 3600 }

    init() {
        let stored = UserDefaults.standard.integer(forKey: "targetWornHours")
        self.targetWornHours = stored > 0 ? stored : 22
    }
}
