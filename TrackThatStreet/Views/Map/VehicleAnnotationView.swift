import SwiftUI

struct VehicleAnnotationView: View {
    let vehicle: Vehicle
    let routeTag: String
    var isSelected: Bool = false

    var body: some View {
        ZStack {
            if isSelected {
                Circle()
                    .stroke(routeColor, lineWidth: 3)
                    .frame(width: 34, height: 34)
            }

            Circle()
                .fill(routeColor)
                .frame(width: 24, height: 24)

            Image(systemName: "tram.fill")
                .font(.system(size: 12))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(Double(vehicle.heading)))
        }
        .shadow(radius: isSelected ? 4 : 2)
        .accessibilityLabel("Vehicle \(vehicle.id) on route \(routeTag), heading \(vehicle.heading) degrees")
    }

    var routeColor: Color {
        if let route = StreetcarRoute(rawValue: routeTag) {
            switch route {
            case .r501: .red
            case .r503: .purple
            case .r504: .blue
            case .r505: .green
            case .r506: .orange
            case .r509: .cyan
            case .r510: .indigo
            case .r511: .mint
            case .r512: .pink
            }
        } else {
            .ttcRed
        }
    }
}

struct VehiclePopupView: View {
    let vehicle: Vehicle
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(routeName, systemImage: "tram.fill")
                    .font(.headline)
                Spacer()
                Button { onDismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            LabeledRow("Vehicle", value: vehicle.id)
            LabeledRow("Speed", value: "\(vehicle.speedKmHr) km/h")
            LabeledRow("Direction", value: cardinalDirection)

            if vehicle.secsSinceReport < 60 {
                LabeledRow("Updated", value: "\(vehicle.secsSinceReport)s ago")
            } else {
                LabeledRow("Updated", value: "\(vehicle.secsSinceReport / 60)m ago")
            }
        }
        .padding()
        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 14))
        .shadow(radius: 8)
        .frame(maxWidth: 280)
    }

    private var routeName: String {
        StreetcarRoute(rawValue: vehicle.routeTag)?.displayName ?? vehicle.routeTag
    }

    private var cardinalDirection: String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int((Double(vehicle.heading) + 22.5).truncatingRemainder(dividingBy: 360) / 45)
        return "\(directions[index]) (\(vehicle.heading)\u{00B0})"
    }
}

private struct LabeledRow: View {
    let label: String
    let value: String

    init(_ label: String, value: String) {
        self.label = label
        self.value = value
    }

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
        }
    }
}
