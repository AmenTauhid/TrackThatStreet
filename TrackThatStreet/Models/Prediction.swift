import Foundation

nonisolated struct Prediction: Identifiable, Codable, Sendable {
    let epochTime: Int64
    let seconds: Int
    let minutes: Int
    let vehicle: String
    let dirTag: String?
    let branch: String?

    var id: String { "\(vehicle)-\(epochTime)" }
}

nonisolated struct PredictionGroup: Identifiable, Codable, Sendable {
    let directionTitle: String
    let stopTitle: String
    let predictions: [Prediction]

    var id: String { "\(directionTitle)-\(stopTitle)" }
}
