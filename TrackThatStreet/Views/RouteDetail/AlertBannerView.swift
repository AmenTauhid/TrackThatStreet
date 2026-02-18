import SwiftUI

struct AlertBannerView: View {
    let bunchingAlerts: [BunchingAlert]
    let gapAlerts: [GapAlert]

    var body: some View {
        VStack(spacing: 6) {
            ForEach(gapAlerts) { alert in
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text("Large gap (~\(Int(alert.estimatedGapMinutes)) min) on \(alert.directionTitle)")
                        .font(TTCFonts.caption)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                .accessibilityLabel("Gap alert: approximately \(Int(alert.estimatedGapMinutes)) minute gap on \(alert.directionTitle)")
            }

            ForEach(bunchingAlerts) { alert in
                HStack {
                    Image(systemName: "exclamationmark.2")
                        .foregroundStyle(.orange)
                    Text("Bunching: vehicles \(alert.vehicleA.id) & \(alert.vehicleB.id) (\(Int(alert.distanceMeters))m apart)")
                        .font(TTCFonts.caption)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                .accessibilityLabel("Bunching alert: vehicles \(alert.vehicleA.id) and \(alert.vehicleB.id) are \(Int(alert.distanceMeters)) meters apart")
            }
        }
    }
}
