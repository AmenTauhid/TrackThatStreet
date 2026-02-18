import SwiftUI

struct StopPickerView: View {
    let stops: [Stop]
    @Binding var selectedStopTag: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(stops) { stop in
                    Button {
                        selectedStopTag = stop.tag
                    } label: {
                        VStack(spacing: 2) {
                            Text(stop.title)
                                .font(TTCFonts.caption)
                                .lineLimit(1)
                            if let stopId = stop.stopId {
                                Text("#\(stopId)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            selectedStopTag == stop.tag ? Color.ttcRed : Color.secondary.opacity(0.15),
                            in: Capsule()
                        )
                        .foregroundStyle(selectedStopTag == stop.tag ? .white : .primary)
                    }
                    .accessibilityLabel("\(stop.title)")
                    .accessibilityAddTraits(selectedStopTag == stop.tag ? .isSelected : [])
                }
            }
            .padding(.horizontal, 4)
        }
    }
}
