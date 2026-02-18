import SwiftUI

struct RouteRowView: View {
    let route: StreetcarRoute
    let status: ServiceStatus?
    let vehicleCount: Int?
    let averageWait: Double?

    var body: some View {
        HStack(spacing: 12) {
            Text(route.routeTag)
                .font(TTCFonts.routeNumber)
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(Color.ttcRed, in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(route.displayName)
                    .font(TTCFonts.routeName)

                HStack(spacing: 8) {
                    if let count = vehicleCount {
                        Label("\(count)", systemImage: "tram.fill")
                            .font(TTCFonts.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let wait = averageWait {
                        Label("\(Int(wait.rounded())) min", systemImage: "clock")
                            .font(TTCFonts.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            if let status {
                StatusBadgeView(status: status)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(route.displayName), \(vehicleCount ?? 0) vehicles, status \(status?.label ?? "unknown")")
    }
}
