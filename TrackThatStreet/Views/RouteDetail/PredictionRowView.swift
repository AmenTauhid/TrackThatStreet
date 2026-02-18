import SwiftUI

struct PredictionRowView: View {
    let prediction: Prediction
    var onTrack: ((Prediction) -> Void)?

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

            if let onTrack {
                Button {
                    onTrack(prediction)
                } label: {
                    Text("Track")
                        .font(TTCFonts.badge)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.ttcRed, in: Capsule())
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }

            CountdownTimerView(epochTime: prediction.epochTime)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Vehicle \(prediction.vehicle), arriving in \(prediction.minutes) minutes")
    }
}
