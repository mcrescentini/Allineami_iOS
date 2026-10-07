//
//  TimeFormat.swift
//  Allineami
//
//  Created by Matteo Crescentini on 22/02/26.
//


import Foundation

enum TimeFormat {
    static func mmss(from totalSeconds: Int) -> String {
        let s = abs(totalSeconds)
        let minutes = s / 60
        let seconds = s % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    static func hhmmss(from totalSeconds: Int) -> String {
        let s = abs(totalSeconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        return String(format: "%02d:%02d:%02d", h, m, sec)
    }
}
