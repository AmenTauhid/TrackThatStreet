import SwiftUI

struct CountdownTimerView: View {
    let epochTime: Int64

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = max(0, Int((Double(epochTime) / 1000.0) - context.date.timeIntervalSince1970))
            let minutes = remaining / 60
            let seconds = remaining % 60
            Text(remaining > 0 ? String(format: "%d:%02d", minutes, seconds) : "Now")
                .font(TTCFonts.countdown)
                .monospacedDigit()
                .foregroundStyle(remaining < 60 ? Color.ttcRed : .primary)
                .accessibilityLabel(remaining > 0 ? "\(minutes) minutes \(seconds) seconds" : "Arriving now")
        }
    }
}
