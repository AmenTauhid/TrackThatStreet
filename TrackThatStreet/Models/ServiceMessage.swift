import Foundation

nonisolated struct ServiceMessage: Identifiable, Codable, Sendable {
    let id: String
    let text: String
    let priority: String
    let routeTag: String
}
