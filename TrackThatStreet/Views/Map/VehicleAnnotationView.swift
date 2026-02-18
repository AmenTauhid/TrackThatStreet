import SwiftUI

struct VehicleAnnotationView: View {
    let vehicle: Vehicle
    let routeTag: String

    var body: some View {
        ZStack {
            Circle()
                .fill(routeColor)
                .frame(width: 24, height: 24)

            Image(systemName: "tram.fill")
                .font(.system(size: 12))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(Double(vehicle.heading)))
        }
        .shadow(radius: 2)
        .accessibilityLabel("Vehicle \(vehicle.id) on route \(routeTag), heading \(vehicle.heading) degrees")
    }

    private var routeColor: Color {
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
