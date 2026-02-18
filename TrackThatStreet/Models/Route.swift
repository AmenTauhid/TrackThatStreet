import Foundation

nonisolated struct Route: Codable, Sendable {
    let tag: String
    let title: String
    let color: String
    let oppositeColor: String
    var stops: [Stop]
    var directions: [Direction]
    var paths: [[PathPoint]]
}

nonisolated struct Stop: Identifiable, Codable, Sendable, Hashable {
    let tag: String
    let title: String
    let lat: Double
    let lon: Double
    let stopId: String?

    var id: String { tag }
}

nonisolated struct Direction: Identifiable, Codable, Sendable {
    let tag: String
    let title: String
    let name: String
    let useForUI: Bool
    let stopTags: [String]

    var id: String { tag }
}

nonisolated struct PathPoint: Codable, Sendable {
    let lat: Double
    let lon: Double
}
