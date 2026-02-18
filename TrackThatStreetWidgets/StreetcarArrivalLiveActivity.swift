import ActivityKit
import SwiftUI
import WidgetKit

struct StreetcarArrivalLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StreetcarArrivalAttributes.self) { context in
            // Lock Screen / banner UI
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label(context.attributes.routeName, systemImage: "tram.fill")
                        .font(.headline)
                    Text(context.attributes.stopName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(context.state.minutes) min")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(context.state.minutes <= 2 ? .red : .primary)
                    Text("Vehicle \(context.state.vehicleId)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.routeName, systemImage: "tram.fill")
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.minutes) min")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(context.state.minutes <= 2 ? .red : .primary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.attributes.stopName)
                            .font(.subheadline)
                        Spacer()
                        Text("Vehicle \(context.state.vehicleId)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                Image(systemName: "tram.fill")
                    .foregroundStyle(.red)
            } compactTrailing: {
                Text("\(context.state.minutes)m")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(context.state.minutes <= 2 ? .red : .primary)
            } minimal: {
                Image(systemName: "tram.fill")
                    .foregroundStyle(.red)
            }
        }
    }
}
