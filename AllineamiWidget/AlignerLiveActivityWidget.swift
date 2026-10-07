//
//  AlignerLiveActivityWidget.swift
//  AllineamiWidget
//

import WidgetKit
import SwiftUI
import ActivityKit

struct AlignerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlignerActivityAttributes.self) { context in

            // Lock screen / banner
            HStack(spacing: 16) {
                Image(systemName: "mouth.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Timer attivo da")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(context.attributes.startDate, style: .timer)
                        .monospacedDigit()
                        .font(.title2.bold())
                        .foregroundStyle(.orange)
                }

                Spacer()
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.7))

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("Timer attivo", systemImage: "mouth.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.startDate, style: .timer)
                        .monospacedDigit()
                        .font(.callout.bold())
                        .foregroundStyle(.orange)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Ricordati di fermare il timer!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "mouth.fill")
                    .foregroundStyle(.orange)
            } compactTrailing: {
                Text(context.attributes.startDate, style: .timer)
                    .monospacedDigit()
                    .foregroundStyle(.orange)
                    .frame(minWidth: 40)
            } minimal: {
                Image(systemName: "mouth.fill")
                    .foregroundStyle(.orange)
            }
        }
    }
}
