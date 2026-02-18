import ActivityKit
import Foundation

struct StreetcarArrivalAttributes: ActivityAttributes {
    let routeName: String
    let stopName: String
    let routeTag: String

    struct ContentState: Codable, Hashable {
        let minutes: Int
        let vehicleId: String
        let updatedAt: Date
    }
}
