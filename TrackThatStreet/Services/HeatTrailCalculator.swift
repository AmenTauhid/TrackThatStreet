import SwiftUI

nonisolated struct ColoredSegment: Sendable {
    let start: PathPoint
    let end: PathPoint
    let color: Color
}

nonisolated enum HeatTrailCalculator {
    static func coloredSegments(pathPoints: [PathPoint], vehicles: [Vehicle]) -> [ColoredSegment] {
        guard pathPoints.count >= 2 else { return [] }

        var segments: [ColoredSegment] = []
        for i in 0..<(pathPoints.count - 1) {
            let midLat = (pathPoints[i].lat + pathPoints[i + 1].lat) / 2
            let midLon = (pathPoints[i].lon + pathPoints[i + 1].lon) / 2

            let color = speedColor(at: midLat, lon: midLon, vehicles: vehicles)
            segments.append(ColoredSegment(
                start: pathPoints[i],
                end: pathPoints[i + 1],
                color: color
            ))
        }
        return segments
    }

    private static func speedColor(at lat: Double, lon: Double, vehicles: [Vehicle]) -> Color {
        var nearestSpeed: Int?
        var nearestDist = Double.greatestFiniteMagnitude

        for vehicle in vehicles {
            let dist = ServiceAnalyzer.haversineDistance(
                lat1: lat, lon1: lon,
                lat2: vehicle.lat, lon2: vehicle.lon
            )
            if dist < nearestDist {
                nearestDist = dist
                nearestSpeed = vehicle.speedKmHr
            }
        }

        guard nearestDist < 500, let speed = nearestSpeed else {
            return .gray
        }

        switch speed {
        case 0...5: return .red
        case 6...15: return .orange
        default: return .green
        }
    }
}
