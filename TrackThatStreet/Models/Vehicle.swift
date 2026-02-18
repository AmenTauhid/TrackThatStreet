import Foundation

nonisolated struct Vehicle: Identifiable, Codable, Sendable {
    let id: String
    let routeTag: String
    let dirTag: String?
    let lat: Double
    let lon: Double
    let heading: Int
    let speedKmHr: Int
    let secsSinceReport: Int
    let predictable: Bool
}
