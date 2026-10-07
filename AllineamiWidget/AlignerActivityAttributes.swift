//
//  AlignerActivityAttributes.swift
//  AllineamiWidget
//
import ActivityKit
import Foundation

struct AlignerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var elapsedMinutes: Int
    }
    var startDate: Date
}
