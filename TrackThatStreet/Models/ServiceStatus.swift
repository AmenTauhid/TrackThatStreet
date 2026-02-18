import SwiftUI

nonisolated enum ServiceStatus: String, Codable, Sendable {
    case good
    case fair
    case poor

    var label: String {
        switch self {
        case .good: "Good"
        case .fair: "Fair"
        case .poor: "Poor"
        }
    }

    var color: Color {
        switch self {
        case .good: .green
        case .fair: .yellow
        case .poor: .red
        }
    }
}

nonisolated struct BunchingAlert: Identifiable, Sendable {
    let vehicleA: Vehicle
    let vehicleB: Vehicle
    let distanceMeters: Double

    var id: String { "\(vehicleA.id)-\(vehicleB.id)" }
}

nonisolated struct GapAlert: Identifiable, Sendable {
    let directionTitle: String
    let estimatedGapMinutes: Double

    var id: String { directionTitle }
}
