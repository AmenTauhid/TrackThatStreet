import SwiftUI

struct PredictionRowView: View {
    let prediction: Prediction

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: "tram.fill")
                        .foregroundStyle(.secondary)
                    Text("Vehicle \(prediction.vehicle)")
                        .font(TTCFonts.routeName)
                }
                if let branch = prediction.branch, !branch.isEmpty {
                    Text("Branch \(branch)")
                        .font(TTCFonts.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            CountdownTimerView(epochTime: prediction.epochTime)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Vehicle \(prediction.vehicle), arriving in \(prediction.minutes) minutes")
    }
}
